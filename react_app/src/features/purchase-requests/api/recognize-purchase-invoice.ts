import { env } from "@/config/env";
import { getRequiredClient } from "@/lib/supabase/client";
import type {
  PurchaseRequestInvoiceItemDraft,
  RecognizedInvoice,
} from "@/features/purchase-requests/types/purchase-request.types";
import {
  extractPdfText,
  MIN_INVOICE_TEXT_LENGTH,
} from "@/features/purchase-requests/utils/pdf-text";

/** Сколько ждём ответ сервиса распознавания, прежде чем показать ошибку. */
const RECOGNITION_TIMEOUT_MS = 90_000;

/** Ответ серверной функции распознавания. */
type RecognitionResponse = {
  supplier?: { name?: string | null; inn?: string | null };
  invoiceNumber?: string | null;
  invoiceDate?: string | null;
  total?: number | null;
  items?: {
    article?: string | null;
    name?: string;
    unit?: string | null;
    quantity?: number | null;
    price?: number | null;
    sum?: number | null;
  }[];
  error?: string;
};

/**
 * Вызов серверной функции распознавания.
 *
 * Обращаемся напрямую, а не через обёртку клиента: так видно настоящий код
 * ответа и текст ошибки от сервера, а не общее «функция вернула ошибку».
 */
async function requestRecognition(
  requestId: string,
  text: string
): Promise<RecognitionResponse> {
  const client = getRequiredClient();
  const {
    data: { session },
  } = await client.auth.getSession();
  if (!session?.access_token) {
    throw new Error("Нужно войти в аккаунт");
  }

  const controller = new AbortController();
  const timer = window.setTimeout(
    () => controller.abort(),
    RECOGNITION_TIMEOUT_MS
  );

  try {
    const response = await fetch(
      `${env.supabaseUrl}/functions/v1/recognize_purchase_invoice`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: env.supabasePublishableKey,
          Authorization: `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({ request_id: requestId, text }),
        signal: controller.signal,
      }
    );

    const payload = (await response
      .json()
      .catch(() => null)) as RecognitionResponse | null;

    if (!response.ok) {
      throw new Error(
        payload?.error ??
          `Сервис распознавания вернул ошибку (${response.status})`
      );
    }
    return payload ?? {};
  } catch (error) {
    if (error instanceof Error && error.name === "AbortError") {
      throw new Error(
        "Сервис распознавания не ответил за 90 секунд. Попробуйте ещё раз"
      );
    }
    throw error;
  } finally {
    window.clearTimeout(timer);
  }
}

/**
 * Распознаёт счёт на оплату.
 *
 * Текст из PDF достаём в браузере и отправляем в серверную функцию: она
 * проверяет права, спрашивает модель и возвращает шапку и позиции. Ничего
 * не сохраняет — человек проверяет результат и только потом сохраняет счёт.
 */
export async function recognizePurchaseRequestInvoice(input: {
  requestId: string;
  file: File;
}): Promise<RecognizedInvoice> {
  const text = await extractPdfText(input.file);
  if (text.trim().length < MIN_INVOICE_TEXT_LENGTH) {
    throw new Error(
      "В файле нет текстового слоя — похоже, это скан или фото. Нужен PDF с текстом"
    );
  }

  const payload = await requestRecognition(input.requestId, text);
  const items: PurchaseRequestInvoiceItemDraft[] = (payload.items ?? [])
    .map((item) => ({
      article: item.article ?? null,
      name: (item.name ?? "").trim(),
      unit: item.unit ?? null,
      quantity: item.quantity ?? null,
      price: item.price ?? null,
      amount: item.sum ?? null,
    }))
    .filter((item) => item.name !== "");

  return {
    supplierName: payload.supplier?.name ?? null,
    supplierInn: payload.supplier?.inn ?? null,
    invoiceNumber: payload.invoiceNumber ?? null,
    invoiceDate: payload.invoiceDate ?? null,
    total: typeof payload.total === "number" ? payload.total : null,
    items,
  };
}
