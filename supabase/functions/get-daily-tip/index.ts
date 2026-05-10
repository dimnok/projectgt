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

    const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        "model": "openai/gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content": "Ты — эксперт-электрик с многолетним стажем. Твоя задача — давать короткие, практичные и профессиональные советы для мобильного приложения строительной компании. Ответ должен быть строго в формате JSON с полями 'title' и 'content'."
          },
          {
            "role": "user",
            "content": "Сгенерируй один уникальный совет дня по части электромонтажных работ. Категория 'Электрика'."
          }
        ],
        "response_format": { "type": "json_object" }
      })
    })

    const aiData = await response.json()
    
    if (aiData.error) {
      throw new Error(`OpenRouter API Error: ${JSON.stringify(aiData.error)}`)
    }

    if (!aiData.choices || aiData.choices.length === 0) {
      throw new Error('OpenRouter returned empty choices')
    }

    const aiContent = JSON.parse(aiData.choices[0].message.content)

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
