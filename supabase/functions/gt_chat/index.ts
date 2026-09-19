import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * ГТ Чат: ответ помощника на последнее сообщение диалога.
 *
 * Вызывается из веб-приложения после того, как человек отправил сообщение
 * (его сохраняет функция `chat_message_add_user`). Здесь мы читаем переписку,
 * спрашиваем модель и дописываем ответ в диалог.
 *
 * Вход: `{ thread_id: string }`. Текст вопроса берём из базы, а не из запроса:
 * так модель видит всю переписку целиком, и подменить историю нельзя.
 *
 * Модель отвечает с доступом к поиску в интернете (плагин `web` шлюза):
 * свежие данные — погода, курсы, нормы — берутся из найденного, а не из памяти.
 * Поиск можно выключить секретом `GT_CHAT_WEB_SEARCH=off`.
 *
 * Данные компании: у модели есть инструменты (tool calling). Сейчас один —
 * `get_shift_status_today`: кто сегодня в открытой смене, кто уже закрыл смену
 * и кто не вышел. Инструмент вызывается от имени человека, поэтому чужие
 * компании и объекты недоступны: права и область объектов проверяет сама
 * функция базы `chat_shift_status_today`.
 *
 * Выход: `{ message: { id, body, created_at } }`.
 *
 * Права: проверяются чтением переписки от имени пользователя
 * (`chat_thread_messages`), то есть ответить можно только в свой диалог.
 * Ключ провайдера живёт в секретах функций и в браузер не попадает.
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
};

/** Провайдер — OpenAI-совместимый шлюз KodikRouter. */
const KODIKROUTER_URL = "https://api.kodikrouter.ru/v1/chat/completions";
const DEFAULT_MODEL = "deepseek/deepseek-v4.1-flash";

/** Сколько последних сообщений отправляем модели: дальше память только дороже. */
const HISTORY_LIMIT = 24;

/** Сколько ждём провайдера. Ниже лимита среды функций. */
const PROVIDER_TIMEOUT_MS = 75_000;

/**
 * Ограничения на длину ответа. Модель сначала рассуждает, и рассуждения
 * входят в тот же лимит: при меньшем значении ответ приходил пустым.
 */
const MAX_ANSWER_TOKENS = 3000;

/** Поиск в интернете: плагин шлюза `web`. Выключается секретом GT_CHAT_WEB_SEARCH=off. */
const WEB_SEARCH_PLUGIN = { id: "web" };

/** Сколько шагов подряд модель может запрашивать данные, прежде чем отвечать. */
const MAX_TOOL_STEPS = 3;

/** Инструменты модели: готовые безопасные запросы к базе. */
const TOOLS = [
  {
    type: "function",
    function: {
      name: "get_shift_status_today",
      description:
        "Смены на сегодня по компании или по объекту: кто сейчас в открытой смене, " +
        "кто уже закрыл смену и кто не вышел. Вызывай на вопросы вида «кто на смене», " +
        "«кто не вышел», «кто работает сегодня». Если объект не назван — данные по всей компании.",
      parameters: {
        type: "object",
        properties: {
          object_name: {
            type: "string",
            description:
              "Название объекта как в программе, например «ЦОД Салтыковка». " +
              "Не указывай, если нужна вся компания.",
          },
        },
        required: [],
      },
    },
  },
];

type HistoryRow = {
  id: string;
  author_kind: string;
  body: string;
  created_at: string;
};

type ToolCall = {
  id: string;
  type?: string;
  function?: { name?: string; arguments?: string };
};

type ProviderMessage =
  | { role: "system" | "user"; content: string }
  | { role: "assistant"; content: string | null; tool_calls?: ToolCall[] }
  | { role: "tool"; tool_call_id: string; content: string };

type ProviderChoice = {
  message?: { role?: string; content?: string | null; tool_calls?: ToolCall[] };
  finish_reason?: string;
};

type ShiftRow = {
  employee_name: string;
  employee_position: string | null;
  object_name: string | null;
  status: string;
  total_count: number;
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** Сегодняшняя дата по Москве: база и смены живут по местному дню. */
function todayInMoscow(): string {
  return new Intl.DateTimeFormat("ru-RU", {
    timeZone: "Europe/Moscow",
    dateStyle: "long",
  }).format(new Date());
}

/** Переписка → сообщения для модели. Ответы помощника помечаем как assistant. */
function toModelMessages(rows: HistoryRow[]): ProviderMessage[] {
  const messages: ProviderMessage[] = [];

  for (const row of rows) {
    const content = row.body?.trim();
    if (!content) {
      continue;
    }
    messages.push({
      role: row.author_kind === "ai" ? "assistant" : "user",
      content,
    });
  }

  return messages;
}

function buildSystemPrompt(today: string): string {
  return `Ты — ГТ Чат, помощник в программе «Proстройка» для строительной компании. Сегодня ${today} (Москва).

Как отвечать:
- Отвечай по-русски, кратко и по делу, простым текстом.
- Не используй таблицы, заголовки и выделение звёздочками: чат показывает текст как есть. Перечисления делай строками, начиная с «- » или «1) ».
- Если к вопросу приложены результаты поиска в интернете — опирайся на них, а не на память, и укажи 1–2 источника ссылками вида [название](адрес).
- Свежие события, курсы, погоду и цены не выдумывай: нет данных поиска — скажи, что не знаешь.

Данные компании:
- У тебя есть функция get_shift_status_today: смены на сегодня — кто в открытой смене, кто уже закрыл смену, кто не вышел. Объект можно не указывать, тогда данные по всей компании.
- Вопросы про людей и смены («кто не вышел», «кто на смене сегодня») требуют вызова функции. По памяти на такие вопросы не отвечай.
- Если функция вернула ошибку (например, объект не найден) — скажи об этом и предложи уточнить название объекта.
- Других данных компании (суммы, сметы, зарплаты, остатки) у тебя нет — не выдумывай их.
- Если не знаешь ответа — скажи прямо, не догадывайся.`;
}

/**
 * Вызов шлюза. Возвращает либо выбор модели, либо готовую ошибку для клиента.
 */
async function callProvider(params: {
  apiKey: string;
  model: string;
  webSearchEnabled: boolean;
  messages: ProviderMessage[];
  allowTools: boolean;
}): Promise<
  { ok: true; choice: ProviderChoice } | { ok: false; status: number; error: string }
> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), PROVIDER_TIMEOUT_MS);

  let response: Response;
  try {
    response = await fetch(KODIKROUTER_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${params.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: params.model,
        temperature: 0.3,
        max_tokens: MAX_ANSWER_TOKENS,
        ...(params.webSearchEnabled ? { plugins: [WEB_SEARCH_PLUGIN] } : {}),
        ...(params.allowTools ? { tools: TOOLS, tool_choice: "auto" } : {}),
        messages: params.messages,
      }),
      signal: controller.signal,
    });
  } catch (error) {
    console.error("gt_chat: провайдер не ответил", error);
    return {
      ok: false,
      status: 504,
      error: "Помощник не ответил вовремя. Попробуйте ещё раз",
    };
  } finally {
    clearTimeout(timer);
  }

  if (!response.ok) {
    const body = await response.text().catch(() => "");
    console.error("gt_chat: ошибка провайдера", response.status, body.slice(0, 500));
    return { ok: false, status: 502, error: "Помощник недоступен. Попробуйте ещё раз" };
  }

  const completion = await response.json() as {
    choices?: ProviderChoice[];
    usage?: { completion_tokens?: number };
  };
  const choice = completion.choices?.[0];
  if (!choice) {
    console.error("gt_chat: пустой ответ провайдера", completion.usage?.completion_tokens);
    return { ok: false, status: 502, error: "Помощник не ответил. Попробуйте ещё раз" };
  }

  return { ok: true, choice };
}

/**
 * Выполнение запроса модели. Данные читаются от имени человека,
 * поэтому чужие компании и объекты закрыты проверками внутри функции базы.
 * Ошибку возвращаем модели текстом: она сможет уточнить название объекта.
 */
async function runTool(
  call: ToolCall,
  asUser: ReturnType<typeof createClient>,
  companyId: string
): Promise<string> {
  const name = call.function?.name ?? "";
  if (name !== "get_shift_status_today") {
    return JSON.stringify({ error: `Неизвестная функция: ${name}` });
  }

  let objectName = "";
  const rawArguments = call.function?.arguments?.trim();
  if (rawArguments) {
    try {
      const parsed = JSON.parse(rawArguments) as { object_name?: unknown };
      if (typeof parsed.object_name === "string") {
        objectName = parsed.object_name.trim();
      }
    } catch {
      return JSON.stringify({ error: "Не удалось разобрать параметры вызова" });
    }
  }

  const { data, error } = await asUser.rpc("chat_shift_status_today", {
    p_company_id: companyId,
    p_object_name: objectName || null,
  });

  if (error) {
    console.error("gt_chat: запрос данных не выполнен", error.message);
    return JSON.stringify({ error: error.message });
  }

  const rows = (data ?? []) as ShiftRow[];
  const pick = (status: string) =>
    rows
      .filter((row) => row.status === status)
      .map((row) => ({
        name: row.employee_name,
        position: row.employee_position || null,
        object: row.object_name || null,
      }));

  const inShift = pick("in_shift");
  const finished = pick("finished");
  const absent = pick("absent");

  return JSON.stringify({
    object: objectName || "вся компания",
    in_shift: inShift,
    finished_today: finished,
    absent,
    totals: {
      in_shift: inShift.length,
      finished_today: finished.length,
      absent: absent.length,
      checked: rows[0]?.total_count ?? rows.length,
    },
    note:
      "in_shift — сейчас в открытой смене; finished_today — смена уже закрыта или есть отметка посещаемости; absent — сегодня не выходил.",
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get("KODIKROUTER_API_KEY");
    if (!apiKey) {
      return json({ error: "ГТ Чат не настроен: нет ключа модели" }, 500);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const clientKey = Deno.env.get("SUPABASE_ANON_KEY") ?? serviceKey;
    const authorization = req.headers.get("Authorization") ?? "";

    if (!supabaseUrl || !serviceKey) {
      return json({ error: "Не задано подключение к базе" }, 500);
    }

    const payload = await req.json().catch(() => null) as {
      thread_id?: string;
    } | null;

    const threadId = payload?.thread_id?.trim();
    if (!threadId) {
      return json({ error: "Нужен диалог" }, 400);
    }

    // Диалог и переписка читаются от имени пользователя: чужие закрыты RLS.
    const asUser = createClient(supabaseUrl, clientKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });

    const { data: thread, error: threadError } = await asUser
      .from("chat_threads")
      .select("id, company_id")
      .eq("id", threadId)
      .maybeSingle();

    if (threadError) {
      console.error("gt_chat: диалог недоступен", threadError.message);
      return json({ error: "Нет доступа к диалогу" }, 403);
    }
    if (!thread) {
      return json({ error: "Диалог не найден" }, 404);
    }

    const companyId = String(thread.company_id);

    const { data: history, error: historyError } = await asUser.rpc(
      "chat_thread_messages",
      { p_thread_id: threadId, p_limit: HISTORY_LIMIT },
    );

    if (historyError) {
      console.error("gt_chat: переписка недоступна", historyError.message);
      return json({ error: "Нет доступа к диалогу" }, 403);
    }

    const rows = (history ?? []) as HistoryRow[];
    const last = rows[rows.length - 1];
    if (!last) {
      return json({ error: "В диалоге пока нет сообщений" }, 400);
    }
    if (last.author_kind === "ai") {
      return json({ error: "Последнее сообщение уже от помощника" }, 409);
    }

    const model = Deno.env.get("GT_CHAT_MODEL") ?? DEFAULT_MODEL;
    const webSearchEnabled = (Deno.env.get("GT_CHAT_WEB_SEARCH") ?? "on") !== "off";

    const messages: ProviderMessage[] = [
      { role: "system", content: buildSystemPrompt(todayInMoscow()) },
      ...toModelMessages(rows),
    ];

    let answer = "";

    for (let step = 0; step < MAX_TOOL_STEPS; step += 1) {
      const result = await callProvider({
        apiKey,
        model,
        webSearchEnabled,
        messages,
        allowTools: true,
      });
      if (!result.ok) {
        return json({ error: result.error }, result.status);
      }

      const { choice } = result;
      const toolCalls = choice.message?.tool_calls ?? [];

      if (toolCalls.length === 0) {
        answer = (choice.message?.content ?? "").trim();
        break;
      }

      // Модель просит данные: выполняем запросы и возвращаем результат.
      messages.push({
        role: "assistant",
        content: choice.message?.content ?? null,
        tool_calls: toolCalls,
      });

      for (const call of toolCalls) {
        const toolResult = await runTool(call, asUser, companyId);
        messages.push({ role: "tool", tool_call_id: call.id, content: toolResult });
      }
    }

    // Модель так и не ответила текстом — просим ответ без новых запросов.
    if (!answer) {
      const finalResult = await callProvider({
        apiKey,
        model,
        webSearchEnabled,
        messages,
        allowTools: false,
      });
      if (finalResult.ok) {
        answer = (finalResult.choice.message?.content ?? "").trim();
      } else {
        return json({ error: finalResult.error }, finalResult.status);
      }
    }

    if (!answer) {
      console.error("gt_chat: пустой ответ после запросов данных");
      return json({ error: "Помощник не ответил. Попробуйте ещё раз" }, 502);
    }

    // Ответ пишем ключом service_role: у пользователя права на запись в ленту нет.
    const admin = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false },
    });

    const { data: saved, error: saveError } = await admin
      .from("chat_messages")
      .insert({
        thread_id: threadId,
        company_id: companyId,
        author_kind: "ai",
        body: answer,
      })
      .select("id, body, created_at")
      .single();

    if (saveError || !saved) {
      console.error("gt_chat: не удалось сохранить ответ", saveError?.message);
      return json({ error: "Не удалось сохранить ответ помощника" }, 500);
    }

    await admin
      .from("chat_threads")
      .update({ last_message_at: saved.created_at })
      .eq("id", threadId);

    return json({ message: saved });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Ошибка чата";
    console.error("gt_chat: неожиданная ошибка", message);
    return json({ error: message }, 500);
  }
});
