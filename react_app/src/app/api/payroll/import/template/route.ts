import ExcelJS from "exceljs";
import { NextResponse } from "next/server";

import {
  templateColumns,
  type PayrollImportKind,
} from "@/features/payrolls/utils/payroll-import";
import { getUserIdFromRequest } from "@/lib/supabase/server";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const KINDS: PayrollImportKind[] = ["payout", "bonus", "penalty"];

const FILE_NAMES: Record<PayrollImportKind, string> = {
  payout: "Шаблон_выплаты.xlsx",
  bonus: "Шаблон_премии.xlsx",
  penalty: "Шаблон_удержания.xlsx",
};

/** Отдаёт пустой шаблон `.xlsx` с заголовками и примером строки. */
export async function GET(request: Request) {
  const userId = await getUserIdFromRequest(request);
  if (!userId) {
    return NextResponse.json({ error: "Нужно войти в аккаунт" }, { status: 401 });
  }

  const requested = new URL(request.url).searchParams.get("kind") ?? "payout";
  const kind: PayrollImportKind = KINDS.includes(requested as PayrollImportKind)
    ? (requested as PayrollImportKind)
    : "payout";

  const headers = templateColumns(kind);
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet("Импорт");

  sheet.addRow(headers);
  sheet.getRow(1).font = { bold: true };

  sheet.addRow(
    kind === "payout"
      ? ["Иванов Иван Иванович", 50000, "01.09.2026", "Аванс за сентябрь"]
      : [
          "Иванов Иван Иванович",
          5000,
          "01.09.2026",
          "Название объекта",
          "Комментарий",
        ]
  );

  headers.forEach((header, index) => {
    sheet.getColumn(index + 1).width = header === "ФИО" ? 34 : 20;
  });

  const buffer = await workbook.xlsx.writeBuffer();
  const fileName = FILE_NAMES[kind];

  return new NextResponse(new Uint8Array(buffer), {
    headers: {
      "Content-Type":
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "Content-Disposition": `attachment; filename="payroll-template.xlsx"; filename*=UTF-8''${encodeURIComponent(fileName)}`,
      "Cache-Control": "no-store",
    },
  });
}
