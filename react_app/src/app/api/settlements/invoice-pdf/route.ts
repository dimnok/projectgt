import { NextResponse } from "next/server";

import {
  buildSettlementInvoicePdf,
  type SettlementInvoicePdfInput,
} from "@/features/settlements/utils/settlement-invoice-pdf";
import { getUserIdFromRequest } from "@/lib/supabase/server";

/** PDF собирается библиотекой @react-pdf — нужен Node-рантайм. */
export const runtime = "nodejs";
/** Ответ зависит от запроса: кэшировать нельзя. */
export const dynamic = "force-dynamic";

/**
 * Формирует PDF «Счёт на оплату» на сервере (Node).
 *
 * Данные счёта, компании, банковского счёта и контрагента приходят из браузера:
 * запись в базу не идёт, поэтому достаточно убедиться, что запрос от
 * авторизованного пользователя.
 */
export async function POST(request: Request) {
  const userId = await getUserIdFromRequest(request);
  if (!userId) {
    return NextResponse.json({ error: "Требуется авторизация" }, { status: 401 });
  }

  let input: SettlementInvoicePdfInput;
  try {
    input = (await request.json()) as SettlementInvoicePdfInput;
  } catch {
    return NextResponse.json({ error: "Некорректный запрос" }, { status: 400 });
  }

  if (!input?.operation?.invoiceNumber || !input?.company?.nameFull) {
    return NextResponse.json(
      { error: "Недостаточно данных для счёта" },
      { status: 400 }
    );
  }

  try {
    const bytes = await buildSettlementInvoicePdf(input);
    const fileName = `Счёт на оплату № ${input.operation.invoiceNumber}.pdf`;

    return new Response(Buffer.from(bytes), {
      status: 200,
      headers: {
        "Content-Type": "application/pdf",
        "Content-Disposition": `inline; filename*=UTF-8''${encodeURIComponent(
          fileName
        )}`,
      },
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Не удалось сформировать счёт";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
