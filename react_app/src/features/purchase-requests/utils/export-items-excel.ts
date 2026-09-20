import type { PurchaseRequestItem } from "@/features/purchase-requests/types/purchase-request.types";

function downloadWorkbook(buffer: ArrayBuffer, fileName: string) {
  const blob = new Blob([buffer], {
    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  });
  const url = window.URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = fileName;
  document.body.appendChild(anchor);
  anchor.click();
  document.body.removeChild(anchor);
  window.URL.revokeObjectURL(url);
}

/** Имя файла выгрузки. Безопасное для файловой системы. */
function purchaseRequestItemsExcelFileName(requestNumber: string) {
  const safe = requestNumber
    .trim()
    .replace(/[\\/:*?"<>|]/g, "_")
    .replace(/\s+/g, "_");
  return `Заявка_${safe || "заявка"}.xlsx`;
}

export async function exportPurchaseRequestItemsExcel({
  requestNumber,
  items,
}: {
  requestNumber: string;
  items: PurchaseRequestItem[];
}) {
  if (items.length === 0) {
    throw new Error("Нет позиций для выгрузки");
  }

  const ExcelJS = await import("exceljs");
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet("Позиции");
  sheet.addRow(["№", "Наименование", "Количество", "Ед. изм.", "Артикул"]);

  items.forEach((item, index) => {
    sheet.addRow([
      index + 1,
      item.name,
      item.quantity,
      item.unit,
      item.article?.trim() ?? "",
    ]);
  });

  const buffer = await workbook.xlsx.writeBuffer();
  downloadWorkbook(
    buffer as ArrayBuffer,
    purchaseRequestItemsExcelFileName(requestNumber)
  );
}
