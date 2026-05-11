import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, x-client-info, apikey",
};

function buildOpeningMessage(data: any) {
  const dateObj = new Date(data.date);
  const formattedDate = dateObj.toLocaleDateString('ru-RU');
  const objectName = data.object_name.replace(/\s+/g, '_');

  let message = `#${objectName}\n`;
  message += `начало_смены_${formattedDate}\n\n`;

  // Ответственный со сокращенными инициалами
  const responsibleInitials = data.opened_by_name
    .split(' ')
    .map((word: string, idx: number) => (idx === 0 ? word : word.charAt(0) + '.'))
    .join(' ');

  message += `👤 Ответственный: \n${responsibleInitials}\n`;
  message += `👥 Специалисты\n`;

  if (data.worker_names && data.worker_names.length > 0) {
    for (let i = 0; i < data.worker_names.length; i++) {
      const initials = data.worker_names[i]
        .split(' ')
        .map((word: string, idx: number) => (idx === 0 ? word : word.charAt(0) + '.'))
        .join(' ');
      message += `${i + 1}. ${initials}\n`;
    }
  } else {
    message += `  (специалисты не указаны)\n`;
  }

  return message;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  try {
    const { work_id, worker_names } = await req.json();

    if (!work_id) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Missing work_id parameter',
        }),
        {
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders,
          },
        }
      );
    }

    const botToken = Deno.env.get('TELEGRAM_BOT_TOKEN');
    const chatId = Deno.env.get('TELEGRAM_CHAT_ID');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    
    // ✅ Используем внутренний URL для работы с БД на self-hosted сервере
    // Это исключает "сетевую петлю" и зависание функции
    const internalDbUrl = "http://kong:8000";

    if (!botToken || !chatId || !serviceRoleKey) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Missing configuration',
        }),
        {
          status: 500,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders,
          },
        }
      );
    }

    const supabase = createClient(internalDbUrl, serviceRoleKey, {
      global: {
        headers: {
          Authorization: `Bearer ${serviceRoleKey}`,
        },
      },
    });

    // Получаем данные смены
    const { data: workData, error: workError } = await supabase
      .from('works')
      .select(`
        id,
        date,
        photo_url,
        objects(name),
        profiles!opened_by(full_name)
      `)
      .eq('id', work_id)
      .single();

    if (workError || !workData) {
      return new Response(
        JSON.stringify({
          success: false,
          error: `Work not found: ${workError?.message}`,
        }),
        {
          status: 404,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders,
          },
        }
      );
    }

    const openingData = {
      work_id: (workData as any).id,
      date: (workData as any).date,
      object_name: (workData as any).objects?.name || 'Unknown',
      opened_by_name: (workData as any).profiles?.full_name || 'Unknown',
      photo_url: (workData as any).photo_url,
      worker_names: worker_names || [],
    };

    const messageText = buildOpeningMessage(openingData);

    // Отправляем основное сообщение в Telegram
    const telegramUrl = `https://api.telegram.org/bot${botToken}/sendMessage`;
    const telegramResponse = await fetch(telegramUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        chat_id: chatId,
        text: messageText,
        parse_mode: 'HTML',
      }),
    });

    const telegramData = await telegramResponse.json();

    if (!telegramResponse.ok) {
      return new Response(
        JSON.stringify({
          success: false,
          error: telegramData.description || 'Telegram API error',
        }),
        {
          status: telegramResponse.status,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders,
          },
        }
      );
    }

    const messageId = telegramData.result?.message_id;

    return new Response(
      JSON.stringify({
        success: true,
        message_id: messageId,
        workers_count: (worker_names || []).length,
      }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      }
    );
  }
});
