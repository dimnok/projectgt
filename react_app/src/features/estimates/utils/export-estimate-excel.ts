import type {
  EstimateCompletion,
  EstimateItem,
} from "@/features/estimates/types/estimate.types";
import { getEstimateExecution } from "@/features/estimates/utils/estimate-execution";

export interface ExportEstimateExcelOptions {
  items: EstimateItem[];
  completionById?: Map<string, EstimateCompletion>;
  objectName?: string;
  contractNumber?: string;
  estimateTitle?: string;
}

const FONT_FAMILY = "Calibri";

const borderThin = {
  top: { style: "thin" as const, color: { argb: "FFD0D7DE" } },
  left: { style: "thin" as const, color: { argb: "FFD0D7DE" } },
  bottom: { style: "thin" as const, color: { argb: "FFD0D7DE" } },
  right: { style: "thin" as const, color: { argb: "FFD0D7DE" } },
};

function sanitizeFileName(name: string): string {
  return name.replace(/[\\/:*?"<>|]/g, "_").replace(/\s+/g, " ").trim();
}

/**
 * Generates and downloads an Excel file (.xlsx) with estimate items
 * and execution columns directly in the browser using ExcelJS.
 */
export async function exportEstimateToExcel({
  items,
  completionById = new Map(),
  objectName,
  contractNumber,
  estimateTitle,
}: ExportEstimateExcelOptions): Promise<void> {
  const ExcelJS = await import("exceljs");
  const workbook = new ExcelJS.Workbook();
  workbook.creator = "ProjectGT";
  workbook.created = new Date();

  const sheet = workbook.addWorksheet("Смета", {
    views: [
      {
        state: "frozen",
        xSplit: 0,
        ySplit: 2,
        activeCell: "A3",
      },
    ],
  });

  // 14 columns:
  // 1: Система, 2: Подсистема, 3: №, 4: Наименование, 5: Артикул, 6: Производитель, 7: Ед. изм.
  // 8: Кол-во (план), 9: Цена, 10: Сумма (план)
  // 11: Кол-во (вып.), 12: Сумма (вып.)
  // 13: Кол-во (ост.), 14: Сумма (ост.)
  sheet.columns = [
    { width: 20 }, // Система
    { width: 20 }, // Подсистема
    { width: 8 },  // №
    { width: 45 }, // Наименование
    { width: 15 }, // Артикул
    { width: 16 }, // Производитель
    { width: 10 }, // Ед. изм.
    { width: 14 }, // Кол-во
    { width: 14 }, // Цена
    { width: 16 }, // Сумма
    { width: 14 }, // Вып. кол-во
    { width: 16 }, // Вып. сумма
    { width: 14 }, // Ост. кол-во
    { width: 16 }, // Ост. сумма
  ];

  // Верхний ярус шапки (строка 1)
  const topRow = sheet.addRow([]);
  topRow.height = 24;

  topRow.getCell(1).value = "Позиция сметы";
  sheet.mergeCells("A1:G1");

  topRow.getCell(8).value = "По смете / договору";
  sheet.mergeCells("H1:J1");

  topRow.getCell(11).value = "Выполнение";
  sheet.mergeCells("K1:L1");

  topRow.getCell(13).value = "Остаток";
  sheet.mergeCells("M1:N1");

  // Нижний ярус шапки (строка 2)
  const headerRow = sheet.addRow([
    "Система",
    "Подсистема",
    "№",
    "Наименование",
    "Артикул",
    "Производитель",
    "Ед. изм.",
    "Кол-во",
    "Цена",
    "Сумма",
    "Кол-во вып.",
    "Сумма вып.",
    "Ост. кол-во",
    "Ост. сумма",
  ]);
  headerRow.height = 26;

  // Стилизация двух ярусов заголовка
  const headerRows = [topRow, headerRow];
  for (const row of headerRows) {
    row.font = { name: FONT_FAMILY, size: 10, bold: true, color: { argb: "FF1F2328" } };
    for (let c = 1; c <= 14; c++) {
      const cell = row.getCell(c);
      cell.border = borderThin;
      cell.alignment = { vertical: "middle", horizontal: "center", wrapText: true };
      
      // Разная подложка для смысловых групп
      if (c <= 7) {
        // Позиция: нейтральный светлый серый
        cell.fill = {
          type: "pattern",
          pattern: "solid",
          fgColor: { argb: "FFF6F8FA" },
        };
      } else if (c <= 10) {
        // Договор: мягкий серо-голубой
        cell.fill = {
          type: "pattern",
          pattern: "solid",
          fgColor: { argb: "FFEAEFF7" },
        };
      } else if (c <= 12) {
        // Выполнение: мягкий светло-зеленый
        cell.fill = {
          type: "pattern",
          pattern: "solid",
          fgColor: { argb: "FFE6F4EA" },
        };
      } else {
        // Остаток: мягкий желтовато-песочный
        cell.fill = {
          type: "pattern",
          pattern: "solid",
          fgColor: { argb: "FFFEF7E0" },
        };
      }
    }
  }

  const startRow = 3;
  let currentRowIndex = startRow;

  // Добавление строк данных с формулами
  for (const item of items) {
    const execution = getEstimateExecution(item, completionById.get(item.id));
    const rIdx = currentRowIndex;

    const row = sheet.addRow([
      item.system || "—",
      item.subsystem || "—",
      item.number || "—",
      item.name || "—",
      item.article || "—",
      item.manufacturer || "—",
      item.unit || "—",
      item.quantity,
      item.price,
      { formula: `H${rIdx}*I${rIdx}`, result: item.total },
      execution.completedQuantity,
      { formula: `K${rIdx}*I${rIdx}`, result: execution.completedTotal },
      { formula: `H${rIdx}-K${rIdx}`, result: execution.remainingQuantity },
      { formula: `M${rIdx}*I${rIdx}`, result: execution.remainingTotal },
    ]);

    row.font = { name: FONT_FAMILY, size: 10, color: { argb: "FF24292F" } };

    for (let c = 1; c <= 14; c++) {
      const cell = row.getCell(c);
      cell.border = borderThin;

      // Текстовые поля (1..7)
      if (c <= 7) {
        cell.alignment = {
          vertical: "middle",
          horizontal: c === 3 ? "center" : "left",
          wrapText: false,
        };
      } else {
        // Числовые поля (8..14)
        cell.alignment = { vertical: "middle", horizontal: "right" };
        // Форматирование: денежные колонки (9, 10, 12, 14) с 2 знаками, количество с разделителями
        if (c === 9 || c === 10 || c === 12 || c === 14) {
          cell.numFmt = "#,##0.00 ₽";
        } else {
          cell.numFmt = "#,##0.00";
        }

        // Подсветка отрицательного остатка красным шрифтом
        if ((c === 13 && execution.remainingQuantity < 0) || (c === 14 && execution.remainingTotal < 0)) {
          cell.font = { name: FONT_FAMILY, size: 10, color: { argb: "FFCF222E" }, bold: true };
        }
      }
    }

    currentRowIndex += 1;
  }

  const endRow = currentRowIndex - 1;

  // Итоговые расчетные значения для начального отображения формул
  const sumTotal = items.reduce((acc, it) => acc + it.total, 0);
  const sumCompletedTotal = items.reduce(
    (acc, it) => acc + getEstimateExecution(it, completionById.get(it.id)).completedTotal,
    0
  );
  const sumRemainingTotal = items.reduce(
    (acc, it) => acc + getEstimateExecution(it, completionById.get(it.id)).remainingTotal,
    0
  );

  // Строка Итого (формулы только для денежных сумм: J, L, N. Итоги по количеству не выводятся)
  const footerRow = sheet.addRow([
    "",
    "",
    "",
    "Итого:",
    "",
    "",
    "",
    "", // H: количество не суммируется
    "", // I: цена
    items.length > 0
      ? { formula: `SUM(J${startRow}:J${endRow})`, result: sumTotal }
      : 0,
    "", // K: вып. количество не суммируется
    items.length > 0
      ? { formula: `SUM(L${startRow}:L${endRow})`, result: sumCompletedTotal }
      : 0,
    "", // M: ост. количество не суммируется
    items.length > 0
      ? { formula: `SUM(N${startRow}:N${endRow})`, result: sumRemainingTotal }
      : 0,
  ]);
  footerRow.height = 24;

  for (let c = 1; c <= 14; c++) {
    const cell = footerRow.getCell(c);
    cell.border = {
      top: { style: "medium" as const, color: { argb: "FF1F2328" } },
      bottom: { style: "double" as const, color: { argb: "FF1F2328" } },
      left: { style: "thin" as const, color: { argb: "FFD0D7DE" } },
      right: { style: "thin" as const, color: { argb: "FFD0D7DE" } },
    };
    cell.font = { name: FONT_FAMILY, size: 10, bold: true, color: { argb: "FF1F2328" } };
    cell.fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: "FFF0F2F5" },
    };

    if (c === 4) {
      cell.alignment = { vertical: "middle", horizontal: "right" };
    } else if (c >= 8) {
      cell.alignment = { vertical: "middle", horizontal: "right" };
      if (c === 10 || c === 12 || c === 14) {
        cell.numFmt = "#,##0.00 ₽";
      } else {
        cell.numFmt = "#,##0.00";
      }

      if (c === 14 && sumRemainingTotal < 0) {
        cell.font = { name: FONT_FAMILY, size: 10, color: { argb: "FFCF222E" }, bold: true };
      }
    }
  }

  // Включаем автофильтр по строке подзаголовков (строка 2, колонки A..N)
  sheet.autoFilter = {
    from: {
      row: 2,
      column: 1,
    },
    to: {
      row: endRow > 2 ? endRow : 2,
      column: 14,
    },
  };

  // Автоматический расчет ширины колонок по их содержимому
  const headerLabels = [
    "Система",
    "Подсистема",
    "№",
    "Наименование",
    "Артикул",
    "Производитель",
    "Ед. изм.",
    "Кол-во",
    "Цена",
    "Сумма",
    "Кол-во вып.",
    "Сумма вып.",
    "Ост. кол-во",
    "Ост. сумма",
  ];

  // Минимальные ширины для каждой колонки с учетом кнопки автофильтра (~3 знака)
  const minWidths = [15, 15, 8, 30, 14, 15, 10, 12, 14, 16, 13, 16, 13, 16];

  for (let c = 1; c <= 14; c++) {
    let maxContentLength = headerLabels[c - 1]?.length ?? 10;

    for (let r = startRow; r <= endRow; r++) {
      const cell = sheet.getRow(r).getCell(c);
      let strLen = 0;

      if (cell.value != null) {
        if (typeof cell.value === "object" && "result" in cell.value) {
          const res = cell.value.result;
          strLen = res != null ? String(res).length + 4 : 0;
        } else if (typeof cell.value === "number") {
          strLen = String(Math.round(cell.value)).length + 5;
        } else {
          // Если есть переносы строк внутри исходного текста, берем самую длинную строку
          const lines = String(cell.value).split(/\r?\n/);
          strLen = Math.max(...lines.map((l) => l.length));
        }
      }

      if (strLen > maxContentLength) {
        maxContentLength = strLen;
      }
    }

    // Запас под поля ячейки и стрелочку автофильтра (+4 символа)
    const calculatedWidth = maxContentLength + 4;
    const finalWidth = Math.max(calculatedWidth, minWidths[c - 1] ?? 10);

    sheet.getColumn(c).width = finalWidth;
  }

  // Генерация буфера и скачивание в браузере
  const buffer = await workbook.xlsx.writeBuffer();
  const blob = new Blob([buffer], {
    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  });

  const parts: string[] = ["Смета"];
  if (contractNumber) parts.push(`Договор_${sanitizeFileName(contractNumber)}`);
  if (estimateTitle) parts.push(sanitizeFileName(estimateTitle));
  else if (objectName) parts.push(sanitizeFileName(objectName));

  const fileName = `${parts.join("_")}.xlsx`;

  const url = window.URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = fileName;
  document.body.appendChild(anchor);
  anchor.click();
  document.body.removeChild(anchor);
  window.URL.revokeObjectURL(url);
}
