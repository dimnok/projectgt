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

/** Экранирование для Telegram parse_mode HTML. */
function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

function groupWorkItems(items: any[]) {
  const groups = new Map<string, any[]>();
  for (const item of items) {
    const key = `${item.section}_${item.floor}_${item.system}_${item.subsystem}`;
    if (!groups.has(key)) {
      groups.set(key, []);
    }
    groups.get(key)!.push(item);
  }
  return groups;
}

function lineTotal(item: any): number {
  const t = item.total;
  if (t == null || t === "") return 0;
  const n = typeof t === "number" ? t : parseFloat(String(t));
  return Number.isFinite(n) ? n : 0;
}

function isOwnItem(item: any): boolean {
  const c = item.contractor_id;
  return c == null || c === "";
}

function contractorShortName(item: any): string {
  const rel = item.contractors;
  if (!rel) return "";
  if (Array.isArray(rel)) {
    const r = rel[0];
    return r?.short_name != null ? String(r.short_name).trim() : "";
  }
  if (typeof rel === "object" && rel.short_name != null) {
    return String(rel.short_name).trim();
  }
  return "";
}

function sumItemsTotal(items: any[]): number {
  return items.reduce((s, it) => s + lineTotal(it), 0);
}

/** Тело отчёта: группы 🔧 (как в старом формате). */
function buildGroupedWorkBody(items: any[]): string {
  if (!items.length) return "";
  const groups = groupWorkItems(items);
  const sortedKeys = Array.from(groups.keys()).sort();
  let out = "";
  for (const key of sortedKeys) {
    const groupItems = groups.get(key)!;
    out += `🔧 ${escapeHtml(key)}\n`;
    for (const item of groupItems) {
      const qtyStr = String(item.quantity).replace(".", ",");
      const sc = item.specialists_count;
      const n =
        sc == null || sc === ""
          ? NaN
          : typeof sc === "number"
          ? sc
          : parseInt(String(sc), 10);
      const specSuffix =
        sc != null && sc !== "" && Number.isFinite(n) && n >= 0
          ? ` <i>спец.: ${escapeHtml(String(n))}</i>`
          : "";
      out += `- ${escapeHtml(String(item.name))} — ${qtyStr} ${escapeHtml(String(item.unit ?? ""))}${specSuffix}\n`;
    }
    out += "\n";
  }
  return out;
}

/** Разбивает текст на части ≤ лимита по переносам строк. */
function splitTelegramChunks(text: string, maxLen: number): string[] {
  if (text.length <= maxLen) return [text];
  const chunks: string[] = [];
  let start = 0;
  while (start < text.length) {
    const rest = text.length - start;
    if (rest <= maxLen) {
      chunks.push(text.slice(start));
      break;
    }
    const end = start + maxLen;
    let cut = text.lastIndexOf("\n\n", end);
    if (cut <= start) cut = text.lastIndexOf("\n", end);
    if (cut <= start) cut = end;
    chunks.push(text.slice(start, cut));
    start = cut < text.length && text.charAt(cut) === "\n" ? cut + 1 : cut;
  }
  return chunks;
}

function buildMessages(work: any): string[] {
  const dateObj = new Date(work.date);
  const formattedDate = dateObj.toLocaleDateString("ru-RU");
  const objectNameFormatted = String(work.object_name).replace(/\s+/g, "_");
  const header = `#${escapeHtml(objectNameFormatted)}\nзавершение_смены_${escapeHtml(formattedDate)}\n\n`;

  const allItems: any[] = work.work_items || [];
  const employees = Number(work.employees_count) || 0;
  const dbTotal = Number(work.total_amount) || 0;

  if (!allItems.length) {
    const emptyStats =
      `\n📊 ВЫРАБОТКА\nОбщая — ${formatCurrency(0)}\n` +
      (employees > 0 ? `На специалиста — ${formatCurrency(0)}\n` : "");
    const grand = `\n✅ ИТОГО: Общая — ${formatCurrency(dbTotal)}`;
    return splitTelegramChunks(
      header + `⚠️ Нет данных о работах\n` + emptyStats + grand,
      TELEGRAM_MAX_LENGTH
    );
  }

  const ownItems = allItems.filter(isOwnItem);
  const ownTotal = sumItemsTotal(ownItems);

  const byContractor = new Map<string, { name: string; items: any[] }>();
  for (const item of allItems) {
    if (isOwnItem(item)) continue;
    const id = String(item.contractor_id);
    const shortName = contractorShortName(item);
    const displayName = shortName || "Контрагент";
    if (!byContractor.has(id)) {
      byContractor.set(id, { name: displayName, items: [] });
    }
    byContractor.get(id)!.items.push(item);
  }

  const contractorRows = Array.from(byContractor.entries()).sort((a, b) =>
    a[1].name.localeCompare(b[1].name, "ru")
  );

  let body = "";

  body += "👷 Наши работы\n\n";
  body += buildGroupedWorkBody(ownItems) || "⚠️ Нет работ собственным выполнением\n\n";

  body += `📊 ВЫРАБОТКА\nОбщая — ${formatCurrency(ownTotal)}\n`;
  if (employees > 0) {
    body += `На специалиста — ${formatCurrency(ownTotal / employees)}\n`;
  }

  for (const [, { name, items: cItems }] of contractorRows) {
    const cTotal = sumItemsTotal(cItems);
    body += `\n🤝 ${escapeHtml(name)}\n`;
    body += buildGroupedWorkBody(cItems);
    body += `Общая — ${formatCurrency(cTotal)}\n`;
  }

  const computedGrand =
    ownTotal +
    contractorRows.reduce((s, [, v]) => s + sumItemsTotal(v.items), 0);
  const grandTotal = dbTotal > 0 ? dbTotal : computedGrand;
  body += `\n✅ ИТОГО: Общая — ${formatCurrency(grandTotal)}`;

  return splitTelegramChunks(header + body, TELEGRAM_MAX_LENGTH);
}

serve(async (req: Request) => {
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
        {
          status: 400,
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
        {
          status: 500,
          headers: { "Content-Type": "application/json", ...corsHeaders }
        }
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false }
    });

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
          unit,
          contractor_id,
          specialists_count,
          total,
          contractors(short_name)
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
        {
          status: 404,
          headers: { "Content-Type": "application/json", ...corsHeaders }
        }
      );
    }

    const work = {
      work_id: (workData as any).id,
      date: (workData as any).date,
      object_name: (workData as any).objects?.name || "Unknown",
      total_amount: (workData as any).total_amount,
      employees_count: (workData as any).employees_count,
      work_items: (workData as any).work_items || [],
      telegram_message_id: (workData as any).telegram_message_id
    };

    const messages = buildMessages(work);

    const telegramUrl = `https://api.telegram.org/bot${botToken}/sendMessage`;
    const sentMessageIds: number[] = [];

    for (let i = 0; i < messages.length; i++) {
      const message = messages[i];
      const requestBody: Record<string, unknown> = {
        chat_id: chatId,
        text: message,
        parse_mode: "HTML"
      };

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
          {
            status: telegramResponse.status,
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
      {
        status: 200,
        headers: { "Content-Type": "application/json", ...corsHeaders }
      }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error"
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders }
      }
    );
  }
});
