import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const OPENROUTER_API_KEY = Deno.env.get('OPENROUTER_API_KEY')
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

serve(async (req) => {
  try {
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!)
    const today = new Date().toISOString().split('T')[0]

    // 1. Проверяем, есть ли уже совет на сегодня
    const { data: existingTip, error: fetchError } = await supabase
      .from('daily_tips')
      .select('*')
      .eq('display_date', today)
      .single()

    if (existingTip) {
      return new Response(JSON.stringify(existingTip), {
        headers: { "Content-Type": "application/json" },
      })
    }

    // 2. Если нет, генерируем новый через OpenRouter
    if (!OPENROUTER_API_KEY) {
      throw new Error('OPENROUTER_API_KEY is not set in environment variables')
    }

    // Генерируем случайную тему для разнообразия советов
    const topics = [
      "сборка электрощитов", "заземление и молниезащита", "маркировка кабельных линий", 
      "прокладка слаботочки", "обслуживание электроинструмента", "коммуникация с заказчиком",
      "неочевидные требования ПУЭ", "скрытые ошибки новичков при прокладке", "монтаж светодиодных лент",
      "выбор расходников и клемм", "поиск скрытой проводки", "чистовой монтаж розеток"
    ];
    const randomTopic = topics[Math.floor(Math.random() * topics.length)];

    const systemPrompt = `Ты — опытный шеф-электрик. Твоя задача — дать ОДИН короткий, практичный и небанальный совет для профи-монтажников.
Узкая тема для сегодняшнего совета: "${randomTopic}".
Внимание: Не пиши банальные базовые вещи вроде "всегда отключайте напряжение" или "используйте СИЗ". Дай реальный, профессиональный лайфхак из практики.
Ответ должен быть строго в формате JSON:
{
  "title": "Заголовок (2-4 слова)",
  "content": "Текст совета (1-3 емких предложения)"
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
          { "role": "user", "content": "Выдай уникальный профессиональный совет по электрике." }
        ]
      })
    })

    const aiData = await response.json()
    
    if (aiData.error) {
      throw new Error(`OpenRouter API Error: ${JSON.stringify(aiData.error)}`)
    }

    if (!aiData.choices || aiData.choices.length === 0) {
      throw new Error('OpenRouter returned empty choices')
    }

    let aiContentText = aiData.choices[0].message.content;
    // Очищаем ответ от маркдаун разметки
    aiContentText = aiContentText.replace(/```json/g, '').replace(/```/g, '').trim();
    
    const aiContent = JSON.parse(aiContentText);

    // 3. Сохраняем в базу
    const { data: newTip, error: insertError } = await supabase
      .from('daily_tips')
      .insert({
        title: aiContent.title,
        content: aiContent.content,
        category: 'Электрика',
        display_date: today
      })
      .select()
      .single()

    if (insertError) throw insertError

    return new Response(JSON.stringify(newTip), {
      headers: { "Content-Type": "application/json" },
    })

  } catch (error) {
    console.error('Error in get-daily-tip:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }
})
