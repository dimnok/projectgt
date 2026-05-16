import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const OPENROUTER_API_KEY = Deno.env.get('OPENROUTER_API_KEY')
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!)
    const { company_id, contract_id } = await req.json()

    if (!company_id) {
      throw new Error('company_id is required')
    }

    let targetContractId = contract_id;

    // 1. Если договор не передан, находим самый свежий активный договор
    if (!targetContractId) {
      const { data: latestContract, error: contractError } = await supabase
        .from('contracts')
        .select('id, number, amount, date, end_date')
        .eq('company_id', company_id)
        .eq('status', 'active')
        .order('date', { ascending: false })
        .limit(1)
        .single()

      if (contractError && contractError.code !== 'PGRST116') {
        throw contractError;
      }

      if (!latestContract) {
        return new Response(JSON.stringify({ 
          error: 'Нет активных договоров для анализа' 
        }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })
      }
      
      targetContractId = latestContract.id;
    }

    // 2. Получаем данные по выбранному договору
    const { data: contract, error: getContractError } = await supabase
      .from('contracts')
      .select('id, number, amount, date, end_date, object_id')
      .eq('id', targetContractId)
      .single()

    if (getContractError) throw getContractError;

    if (!contract.end_date) {
      return new Response(JSON.stringify({ 
        error: 'В договоре не указана дата окончания' 
      }), { headers: { ...corsHeaders, "Content-Type": "application/json" } })
    }

    // 3. Считаем выполненный объем работ по этому договору через существующую RPC функцию
    const { data: calculatedAmount, error: rpcError } = await supabase.rpc(
      'calculate_contract_works',
      {
        contract_id: targetContractId,
        object_id: null
      }
    )

    let executedAmount = 0;
    if (!rpcError && calculatedAmount) {
      executedAmount = Number(calculatedAmount);
    }

    // Параметры для анализа
    const contractAmount = contract.amount || 0;
    const endDate = new Date(contract.end_date);
    const today = new Date();
    
    // Считаем оставшиеся дни (без учета выходных)
    const timeDiff = endDate.getTime() - today.getTime();
    let daysLeft = Math.ceil(timeDiff / (1000 * 3600 * 24));
    if (daysLeft < 0) daysLeft = 0;

    const remainingAmount = Math.max(0, contractAmount - executedAmount);
    const normPerInstaller = 15000;
    
    // Защита от деления на ноль: если дней не осталось, считаем план как за 1 день
    const safeDaysLeft = daysLeft > 0 ? daysLeft : 1;
    
    // Серверные вычисления плана
    const dailyPlanAmount = remainingAmount / safeDaysLeft;
    const requiredInstallers = Math.ceil(dailyPlanAmount / normPerInstaller);
    const installersPlanToday = requiredInstallers;
    
    // Сбор фактических данных за последние 7 дней для аналитики ИИ
    const weekAgoDate = new Date(today.getTime() - 7 * 24 * 3600 * 1000).toISOString();
    
    let averageEmployees = 0;
    let averageDailyProductionFact = 0;
    
    if (contract.object_id) {
      const { data: recentWorks, error: recentWorksError } = await supabase
        .from('works')
        .select('employees_count, date, total_amount')
        .eq('company_id', company_id)
        .eq('object_id', contract.object_id)
        .eq('status', 'closed')
        .gte('date', weekAgoDate);

      let recentTotalEmployees = 0;
      let recentTotalProduction = 0;
      let validDaysCount = 0;

      if (!recentWorksError && recentWorks && recentWorks.length > 0) {
        const uniqueDays = new Set<string>();
        recentWorks.forEach(w => {
           recentTotalEmployees += (w.employees_count || 0);
           recentTotalProduction += Number(w.total_amount || 0);
           if (w.date) uniqueDays.add(w.date);
        });
        validDaysCount = uniqueDays.size > 0 ? uniqueDays.size : 1;
      } else {
        validDaysCount = 1;
      }

      // Среднее количество людей (считаем только по тем дням, когда люди реально выходили на объект)
      averageEmployees = validDaysCount > 0 ? Math.ceil(recentTotalEmployees / validDaysCount) : 0;
      averageDailyProductionFact = validDaysCount > 0 ? (recentTotalProduction / validDaysCount) : 0;
    }
    
    // Считаем дефицит
    const deficitInstallers = requiredInstallers - averageEmployees;
    
    // 4. Отправляем запрос в OpenRouter
    if (!OPENROUTER_API_KEY) {
      throw new Error('OPENROUTER_API_KEY is not set in environment variables')
    }

    const systemPrompt = `Ты — опытный аналитик строительных проектов.
Твоя задача — проанализировать текущие показатели и выдать конструктивную рекомендацию (1-3 предложения) для начальника участка.

ИСХОДНЫЕ ДАННЫЕ:
- Требуемый темп для сдачи в срок: ${dailyPlanAmount.toFixed(0)} руб./день.
- Необходимая ежедневная явка: ${requiredInstallers} монтажников.
- Фактическая явка (в среднем за неделю): ${averageEmployees} монтажников.
- Нехватка людей: ${deficitInstallers > 0 ? deficitInstallers : 0} чел.
- Времени до сдачи: ${daysLeft} дней.

ИНСТРУКЦИЯ ПО ФОРМИРОВАНИЮ ОТВЕТА:
1. Если есть нехватка людей: Обрати внимание на отставание от графика. Порекомендуй увеличить бригаду на нужное количество человек для выполнения ежедневного плана.
2. Если людей достаточно: Отметь хороший темп работы, поблагодари за соблюдение графика и порекомендуй удерживать текущие показатели.
3. Стиль ответа: Профессионально, конструктивно, по делу, с использованием конкретных цифр.

Ответ должен быть строго в формате JSON:
{
  "recommendation": "текст рекомендации"
}`;

    const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        "model": "perceptron/perceptron-mk1",
        "messages": [
          { "role": "system", "content": systemPrompt },
          { "role": "user", "content": "Опираясь на расчеты, выдай рекомендацию." }
        ]
      })
    })

    const aiData = await response.json()
    if (aiData.error) {
      throw new Error(`OpenRouter API Error: ${JSON.stringify(aiData.error)}`)
    }

    let aiContentText = aiData.choices[0].message.content;
    // Очищаем ответ от маркдаун разметки (```json ... ```), которую модель может добавить
    aiContentText = aiContentText.replace(/```json/g, '').replace(/```/g, '').trim();

    const aiContent = JSON.parse(aiContentText);

    // Дополняем ответ нашими сырыми данными и серверными вычислениями
    const result = {
      contract_number: contract.number,
      contract_amount: contractAmount,
      executed_amount: executedAmount,
      days_left: daysLeft,
      required_installers: requiredInstallers,
      daily_plan_amount: dailyPlanAmount,
      installers_plan_today: installersPlanToday,
      average_installers_fact: averageEmployees,
      average_daily_production_fact: averageDailyProductionFact,
      recommendation: aiContent.recommendation || "Идем по графику."
    };

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })

  } catch (error) {
    console.error('Error in analyze-contract-plan:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }
})
