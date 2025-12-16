import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, x-client-info, apikey"
};

const TELEGRAM_MAX_LENGTH = 4096;

function formatCurrency(amount: number): string {
  if (!amount) return "0 ₽";
  const formatter = new Intl.NumberFormat("ru-RU", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
  return formatter.format(amount).replace(/,/g, ",") + " ₽";
}

function groupWorkItems(items: any[]) {
  const groups = new Map();
  for (const item of items) {
    const key = `${item.section}_${item.floor}_${item.system}_${item.subsystem}`;
    if (!groups.has(key)) {
      groups.set(key, []);
    }
    groups.get(key).push(item);
  }
  return groups;
}

function buildMessages(work: any): string[] {
  const dateObj = new Date(work.date);
  const formattedDate = dateObj.toLocaleDateString("ru-RU");
  const objectNameFormatted = work.object_name.replace(/\s+/g, "_");
  const header = `#${objectNameFormatted}\nзавершение_смены_${formattedDate}\n\n`;
  
  // Конструируем футер с выработкой
  let footerText = `📊 ВЫРАБОТКА\nОбщая — ${formatCurrency(work.total_amount)}\n`;
  if (work.employees_count && work.employees_count > 0 && work.total_amount) {
    footerText += `На специалиста — ${formatCurrency(work.total_amount / work.employees_count)}`;
  }
  const footer = `\n${footerText}`;
  
  // Обработка случая, когда нет работ
  if (!work.work_items || work.work_items.length === 0) {
    const message = header + `⚠️ Нет данных о работах\n` + footer;
    return [message];
  }

  const groups = groupWorkItems(work.work_items);
  const sortedKeys = Array.from(groups.keys()).sort();
  const messages: string[] = [];
  let currentMessage = header;

  for (const key of sortedKeys) {
    const items = groups.get(key);
    let groupText = `🔧 ${key}\n`;

    for (const item of items) {
      const qtyStr = item.quantity.toString().replace(".", ",");
      groupText += `- ${item.name} — ${qtyStr} ${item.unit}\n`;
    }
    groupText += "\n";

    const potentialLength = currentMessage.length + groupText.length + footer.length;
    if (potentialLength > TELEGRAM_MAX_LENGTH && currentMessage !== header) {
      messages.push(currentMessage);
      currentMessage = header + groupText;
    } else {
      currentMessage += groupText;
    }
  }

  currentMessage += footer;
  messages.push(currentMessage);

  return messages;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders
    });
  }

  try {
    const { work_id } = await req.json();

    if (!work_id) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing work_id parameter"
        }),
        {\n          status: 400,
          headers: { "Content-Type": "application/json", ...corsHeaders }
        }
      );
    }

    const botToken = Deno.env.get("TELEGRAM_BOT_TOKEN");
    const chatId = Deno.env.get("TELEGRAM_CHAT_ID");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || Deno.env.get("SERVICE_ROLE_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");

    if (!botToken || !chatId || !serviceRoleKey || !supabaseUrl) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing configuration" }),
        {\n          status: 500,
          headers: { "Content-Type": "application/json", ...corsHeaders }
        }
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { data: workData, error: workError } = await supabase
      .from("works")
      .select(`
        id,
        date,
        total_amount,
        employees_count,
        telegram_message_id,
        objects(name),
        work_items(
          section,
          floor,
          system,
          subsystem,
          name,
          quantity,
          unit
        )
      `)
      .eq("id", work_id)
      .single();

    if (workError || !workData) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Work not found"
        }),
        {\n          status: 404,
          headers: { "Content-Type": "application/json", ...corsHeaders }
        }
      );
    }

    const work = {
      work_id: workData.id,
      date: workData.date,
      object_name: workData.objects?.name || "Unknown",
      total_amount: workData.total_amount,
      employees_count: workData.employees_count,
      work_items: workData.work_items || [],
      telegram_message_id: workData.telegram_message_id
    };

    const messages = buildMessages(work);

    const telegramUrl = `https://api.telegram.org/bot${botToken}/sendMessage`;
    const sentMessageIds: number[] = [];

    for (let i = 0; i < messages.length; i++) {
      const message = messages[i];
      const requestBody: any = {
        chat_id: chatId,
        text: message,
        parse_mode: "HTML"
      };

      // Если это первое сообщение и есть утреннее message_id - связываем
      if (i === 0 && work.telegram_message_id) {
        requestBody.reply_to_message_id = work.telegram_message_id;
      }

      const telegramResponse = await fetch(telegramUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(requestBody)
      });

      const telegramData = await telegramResponse.json();

      if (!telegramResponse.ok) {
        return new Response(
          JSON.stringify({
            success: false,
            error: telegramData.description || "Telegram API error"
          }),
          {\n            status: telegramResponse.status,
            headers: { "Content-Type": "application/json", ...corsHeaders }
          }
        );
      }

      sentMessageIds.push(telegramData.result?.message_id);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message_ids: sentMessageIds,
        messages_count: messages.length,
        items_count: work.work_items.length,
        total_amount: work.total_amount,
        reply_to_message_id: work.telegram_message_id
      }),
      {\n        status: 200,
        headers: { "Content-Type": "application/json", ...corsHeaders }
      }
    );
  } catch (error) {\n    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error"
      }),
      {\n        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders }
      }
    );
  }
});

