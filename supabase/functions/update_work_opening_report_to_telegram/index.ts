import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, x-client-info, apikey",
};

function buildUpdatedOpeningMessage(data: any) {
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

  if (data.worker_hours && data.worker_hours.length > 0) {
    for (let i = 0; i < data.worker_hours.length; i++) {
      const { name, hours } = data.worker_hours[i];
      const initials = name
        .split(' ')
        .map((word: string, idx: number) => (idx === 0 ? word : word.charAt(0) + '.'))
        .join(' ');
      const hoursStr = hours > 0 ? ` - ${hours} ч.` : '';
      message += `${i + 1}. ${initials}${hoursStr}\n`;
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
    const { work_id, telegram_message_id } = await req.json();

    if (!work_id || !telegram_message_id) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Missing work_id or telegram_message_id',
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

    const supabase = createClient(internalDbUrl, serviceRoleKey);

    // Получаем базовые данные смены БЕЗ вложенного джойна на employees
    const { data: workData, error: workError } = await supabase
      .from('works')
      .select(`
        id,
        date,
        objects(name),
        profiles!opened_by(full_name),
        work_hours(employee_id, hours)
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

    // Отдельно получаем данные сотрудников по employee_id
    const workerHours: any[] = [];
    if (workData.work_hours && Array.isArray(workData.work_hours) && workData.work_hours.length > 0) {
      const employeeIds = workData.work_hours.map((wh: any) => wh.employee_id).filter(Boolean);

      if (employeeIds.length > 0) {
        // Получаем last_name, first_name, middle_name (не full_name!)
        const { data: employees, error: empError } = await supabase
          .from('employees')
          .select('id, last_name, first_name, middle_name')
          .in('id', employeeIds);

        if (!empError && employees) {
          // Собираем ФИО из отдельных полей
          const employeeMap = new Map(
            employees.map((emp: any) => {
              const fullName = [
                emp.last_name,
                emp.first_name,
                emp.middle_name,
              ]
                .filter(Boolean)
                .join(' ');
              return [emp.id, fullName];
            })
          );

          for (const wh of workData.work_hours as any[]) {
            const fullName = employeeMap.get(wh.employee_id);
            if (fullName) {
              workerHours.push({
                name: fullName,
                hours: wh.hours || 0,
              });
            }
          }
        }
      }
    }

    const openingData = {
      work_id: workData.id,
      date: workData.date,
      object_name: (workData as any).objects?.name || 'Unknown',
      opened_by_name: (workData as any).profiles?.full_name || 'Unknown',
      worker_hours: workerHours,
    };

    const updatedMessage = buildUpdatedOpeningMessage(openingData);

    // Редактируем утреннее сообщение в Telegram
    const telegramUrl = `https://api.telegram.org/bot${botToken}/editMessageText`;
    const editResponse = await fetch(telegramUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        chat_id: chatId,
        message_id: telegram_message_id,
        text: updatedMessage,
        parse_mode: 'HTML',
      }),
    });

    const editData = await editResponse.json();

    if (!editResponse.ok) {
      // Если текст сообщения не изменился, Telegram возвращает ошибку "message is not modified".
      // Мы считаем это успехом, чтобы задача не висела в очереди на повтор.
      if (editData.description?.includes("message is not modified")) {
        return new Response(
          JSON.stringify({
            success: true,
            message: "Message not modified",
          }),
          {
            status: 200,
            headers: {
              "Content-Type": "application/json",
              ...corsHeaders,
            },
          }
        );
      }

      return new Response(
        JSON.stringify({
          success: false,
          error: editData.description || 'Telegram API error',
          details: editData,
        }),
        {
          status: editResponse.status,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders,
          },
        }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message_id: telegram_message_id,
        workers_count: workerHours.length,
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
