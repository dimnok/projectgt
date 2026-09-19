import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Распознавание счёта на оплату.
 *
 * Вызывается из веб-приложения кнопкой «Распознать» в окне добавления счёта.
 * Функция только разбирает текст и возвращает данные — ничего не сохраняет.
 * Решение, что писать в заявку, принимает человек.
 *
 * Вход: `{ request_id: string, text: string }`. Текст из PDF достаёт браузер:
 * на устройстве пользователя это доли секунды, а тяжёлый PDF-парсер в среде
 * функции работал непредсказуемо долго. Здесь остаётся только обращение к модели.
 *
 * Выход: шапка счёта (поставщик, номер, дата, итог) и позиции.
 *
 * Права: проверяются на стороне базы (`purchase_request_can_recognize_invoice`),
 * то есть разбор доступен только тому, кто ведёт счета по этой заявке.
 * Ключ провайдера живёт в секретах функций и в браузер не попадает.
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
};

/** Провайдер разбора — OpenAI-совместимый шлюз KodikRouter. */
const KODIKROUTER_URL = "https://api.kodikrouter.ru/v1/chat/completions";
const DEFAULT_MODEL = "deepseek/deepseek-v4.1-flash";

/** Ограничения входа: слишком короткий текст — значит, текстового слоя нет. */
const MIN_TEXT_LENGTH = 120;

/**
 * Сколько ждём провайдера. Ниже лимита среды функций, чтобы при медленном
 * ответе вернуть понятную ошибку, а не быть прерванными рантаймом.
 */
const PROVIDER_TIMEOUT_MS = 75_000;

/** Промпт разбора: строгий JSON, без пояснений и markdown. */
const SYSTEM_PROMPT = `Ты помощник бухгалтера. Из текста счёта на оплату извлеки данные.
Ответ — СТРОГО JSON без пояснений и без markdown:
{
 "supplier": {"name": string|null, "inn": string|null},
 "invoiceNumber": string|null,
 "invoiceDate": string|null,
 "total": number|null,
 "items": [{"article": string|null, "name": string, "unit": string|null, "quantity": number, "price": number, "sum": number}]
}
Правила:
- supplier — из блока «Поставщик» (наименование и ИНН).
- invoiceDate — только дата счёта, формат ГГГГ-ММ-ДД.
- total — итоговая сумма к оплате числом.
- items — только строки таблицы товаров/услуг.
- name — наименование без артикула, одной строкой (переносы склей).
- article — артикул или код товара, если он есть в счёте.
- quantity, price, sum — числа (точка как разделитель, без пробелов).
- НДС, скидки, итоги и банковские реквизиты в items не включай.
- Чего нет — null; позиций нет — пустой массив.`;

type RecognizedItem = {
  article: string | null;
  name: string;
  unit: string | null;
  quantity: number | null;
  price: number | null;
  sum: number | null;
};

type RecognitionResult = {
  supplier: { name: string | null; inn: string | null };
  invoiceNumber: string | null;
  invoiceDate: string | null;
  total: number | null;
  items: RecognizedItem[];
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** «112 704,92» и «1 665.00» → 112704.92. Пустое и мусор — null. */
function toNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value !== "string") {
    return null;
  }
  const normalized = value
    .replace(/[\s\u00a0]/g, "")
    .replace(",", ".")
    .replace(/[^\d.\-]/g, "");
  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : null;
}

function toText(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed ? trimmed : null;
}

/** Достаёт JSON из ответа модели: убирает markdown-обёртку и лишний текст. */
function parseModelJson(raw: string): Record<string, unknown> | null {
  let text = raw.trim();
  const fence = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fence) {
    text = fence[1].trim();
  }
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start === -1 || end <= start) {
    return null;
  }
  try {
    return JSON.parse(text.slice(start, end + 1)) as Record<string, unknown>;
  } catch {
    return null;
  }
}

/** Приводит ответ модели к строгому виду и отбрасывает пустые позиции. */
function normalizeResult(raw: Record<string, unknown>): RecognitionResult {
  const supplier = (raw.supplier ?? {}) as Record<string, unknown>;
  const rawItems = Array.isArray(raw.items) ? raw.items : [];

  const items: RecognizedItem[] = [];
  for (const entry of rawItems) {
    if (!entry || typeof entry !== "object") {
      continue;
    }
    const item = entry as Record<string, unknown>;
    const name = toText(item.name);
    if (!name) {
      continue;
    }
    items.push({
      article: toText(item.article),
      name,
      unit: toText(item.unit),
      quantity: toNumber(item.quantity),
      price: toNumber(item.price),
      sum: toNumber(item.sum),
    });
  }

  return {
    supplier: {
      name: toText(supplier.name),
      inn: toText(supplier.inn)?.replace(/\D/g, "") || null,
    },
    invoiceNumber: toText(raw.invoiceNumber),
    invoiceDate: toText(raw.invoiceDate),
    total: toNumber(raw.total),
    items,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get("KODIKROUTER_API_KEY");
    if (!apiKey) {
      return json({ error: "Распознавание не настроено" }, 500);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const clientKey = Deno.env.get("SUPABASE_ANON_KEY") ?? serviceKey;
    const authorization = req.headers.get("Authorization") ?? "";

    if (!supabaseUrl || !serviceKey) {
      return json({ error: "Не задано подключение к базе" }, 500);
    }

    const payload = await req.json().catch(() => null) as {
      request_id?: string;
      text?: string;
    } | null;

    const requestId = payload?.request_id?.trim();
    const documentText = payload?.text?.trim();
    if (!requestId || !documentText) {
      return json({ error: "Нужны заявка и текст счёта" }, 400);
    }

    // Проверка прав: клиент от имени пользователя, поэтому auth.uid() — он.
    const asUser = createClient(supabaseUrl, clientKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });

    const { data: allowed, error: allowError } = await asUser.rpc(
      "purchase_request_can_recognize_invoice",
      { p_request_id: requestId },
    );
    if (allowError) {
      return json({ error: "Не удалось проверить права" }, 500);
    }
    if (!allowed) {
      return json({ error: "Нет доступа к счетам этой заявки" }, 403);
    }

    // Скан или фото приходят без текста — распознать их нечем, сообщаем честно.
    if (documentText.length < MIN_TEXT_LENGTH) {
      return json(
        { error: "В файле нет текстового слоя — похоже, это скан или фото" },
        422,
      );
    }

    const model = Deno.env.get("KODIKROUTER_MODEL") ?? DEFAULT_MODEL;
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), PROVIDER_TIMEOUT_MS);

    let response: Response;
    try {
      response = await fetch(KODIKROUTER_URL, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model,
          temperature: 0,
          // Просим отвечать без долгих рассуждений: так быстрее и стабильнее.
          reasoning_effort: "minimal",
          messages: [
            { role: "system", content: SYSTEM_PROMPT },
            { role: "user", content: documentText },
          ],
        }),
        signal: controller.signal,
      });
    } catch (error) {
      console.error("recognize_purchase_invoice: провайдер не ответил", error);
      return json(
        { error: "Сервис распознавания не ответил вовремя. Попробуйте ещё раз" },
        504,
      );
    } finally {
      clearTimeout(timer);
    }

    if (!response.ok) {
      const body = await response.text().catch(() => "");
      console.error(
        "recognize_purchase_invoice: ошибка провайдера",
        response.status,
        body.slice(0, 500),
      );
      return json(
        { error: "Сервис распознавания недоступен. Попробуйте ещё раз" },
        502,
      );
    }

    const completion = await response.json() as {
      choices?: { message?: { content?: string }; finish_reason?: string }[];
      usage?: { completion_tokens?: number };
    };
    const content = completion.choices?.[0]?.message?.content ?? "";
    const parsed = parseModelJson(content);
    if (!parsed) {
      console.error(
        "recognize_purchase_invoice: пустой или неразборчивый ответ",
        completion.choices?.[0]?.finish_reason,
        completion.usage?.completion_tokens,
      );
      return json(
        {
          error:
            "Модель не вернула данные. Попробуйте ещё раз — или подключите более быструю модель",
        },
        502,
      );
    }

    return json(normalizeResult(parsed));
  } catch (error) {
    const message = error instanceof Error ? error.message : "Ошибка распознавания";
    return json({ error: message }, 500);
  }
});
