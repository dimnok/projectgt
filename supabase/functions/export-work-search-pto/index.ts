import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { encode } from "https://deno.land/std@0.208.0/encoding/base64.ts";
import ExcelJS from "npm:exceljs@4.4.0";

// Парсим номер позиции для правильной сортировки
function parsePositionNumber(num: string): [string, number] {
  const str = (num || "").trim();
  if (!str) return ["", 0];
  const match = str.match(/^([^0-9]*)([-.,]?)(.*)$/);
  if (!match) return [str, 0];
  const prefix = match[1] || "";
  const numPart = match[3] || "";
  let numValue = 0;
  if (numPart) {
    const normalized = numPart.replace(",", ".");
    const numMatch = normalized.match(/\d+(\.?\d+)?/);
    if (numMatch) {
      numValue = parseFloat(numMatch[0]);
    }
  }
  return [prefix, numValue];
}

function aggregateResults(results: any[]) {
  const aggregated = new Map();
  for (const result of results) {
    // Берем m15_name или m15Name
    const m15 = result.m15_name || result.m15Name || "";
    const key = `${result.system}|${result.subsystem}|${result.section}|${result.floor}|${result.positionNumber}|${result.workName}|${m15}|${result.unit}`;
    
    if (aggregated.has(key)) {
      const row = aggregated.get(key);
      row.quantity += result.quantity;
    } else {
      aggregated.set(key, {
        system: result.system,
        subsystem: result.subsystem,
        section: result.section,
        floor: result.floor,
        positionNumber: result.positionNumber,
        workName: result.workName,
        m15_name: m15, // Используем m15_name как основное имя поля
        unit: result.unit,
        quantity: result.quantity
      });
    }
  }
  
  const sorted = Array.from(aggregated.values()).sort((a: any, b: any) => {
    if (a.system !== b.system) return (a.system || "").localeCompare(b.system || "");
    if (a.subsystem !== b.subsystem) return (a.subsystem || "").localeCompare(b.subsystem || "");
    if (a.section !== b.section) return (a.section || "").localeCompare(b.section || "");
    if (a.floor !== b.floor) return (a.floor || "").localeCompare(b.floor || "");
    const [prefixA, numA] = parsePositionNumber(a.positionNumber || "");
    const [prefixB, numB] = parsePositionNumber(b.positionNumber || "");
    if (prefixA !== prefixB) return prefixA.localeCompare(prefixB);
    return numA - numB;
  });
  
  return sorted;
}

function aggregateGeneralResults(results: any[]) {
  const aggregated = new Map();
  for (const result of results) {
    const m15 = result.m15_name || result.m15Name || "";
    const key = `${result.objectName}|${result.contractNumber}|${result.system}|${result.subsystem}|${result.positionNumber}|${result.workName}|${m15}`;
    
    if (aggregated.has(key)) {
      const row = aggregated.get(key);
      row.quantity += result.quantity;
      row.total = (row.total || 0) + (result.total || 0);
    } else {
      aggregated.set(key, {
        objectName: result.objectName,
        contractNumber: result.contractNumber,
        system: result.system,
        subsystem: result.subsystem,
        positionNumber: result.positionNumber,
        workName: result.workName,
        m15_name: m15, // Используем m15_name как основное имя поля
        unit: result.unit,
        quantity: result.quantity,
        price: result.price,
        total: result.total
      });
    }
  }
  
  const sorted = Array.from(aggregated.values()).sort((a: any, b: any) => {
    if (a.contractNumber !== b.contractNumber) return (a.contractNumber || "").localeCompare(b.contractNumber || "");
    if (a.system !== b.system) return (a.system || "").localeCompare(b.system || "");
    if (a.subsystem !== b.subsystem) return (a.subsystem || "").localeCompare(b.subsystem || "");
    const [prefixA, numA] = parsePositionNumber(a.positionNumber || "");
    const [prefixB, numB] = parsePositionNumber(b.positionNumber || "");
    if (prefixA !== prefixB) return prefixA.localeCompare(prefixB);
    return numA - numB;
  });
  
  return sorted;
}

function generateFilename(objectName: string, _type: string) {
  const now = new Date();
  const day = String(now.getDate()).padStart(2, '0');
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const year = now.getFullYear();
  const dateStr = `${day}-${month}-${year}`;
  const sanitizedName = objectName.replace(/[/<>:"|?*\\]/g, "").trim();
  return `${sanitizedName}_${dateStr}.xlsx`;
}

const borderStyle: any = {
  top: { style: "thin", color: { argb: "FF000000" } },
  left: { style: "thin", color: { argb: "FF000000" } },
  bottom: { style: "thin", color: { argb: "FF000000" } },
  right: { style: "thin", color: { argb: "FF000000" } }
};

const headerFill: any = {
  type: "pattern",
  pattern: "solid",
  fgColor: { argb: "FF4472C4" }
};

const headerFont = {
  bold: true,
  color: { argb: "FFFFFFFF" },
  size: 11
};

const headerAlignment: any = {
  horizontal: "center",
  vertical: "middle",
  wrapText: true
};

async function createXlsxWithExcelJS(aggregated: any[], original: any[]) {
  const workbook = new ExcelJS.Workbook();
  
  // Первый лист - ПТО (агрегированные данные)
  const ptoSheet = workbook.addWorksheet("ПТО");
  ptoSheet.columns = [
    { header: "Система", key: "system", width: 15 },
    { header: "Подсистема", key: "subsystem", width: 15 },
    { header: "Участок", key: "section", width: 12 },
    { header: "Этаж", key: "floor", width: 10 },
    { header: "№", key: "positionNumber", width: 10 },
    { header: "Наименование", key: "workName", width: 25 },
    { header: "М-15", key: "m15_name", width: 25 }, // Используем m15_name
    { header: "Ед. изм.", key: "unit", width: 10 },
    { header: "Кол-во", key: "quantity", width: 10 }
  ];
  
  ptoSheet.getRow(1).fill = headerFill;
  ptoSheet.getRow(1).font = headerFont;
  ptoSheet.getRow(1).alignment = headerAlignment;
  ptoSheet.getRow(1).height = 25;
  for(let col = 1; col <= 9; col++) {
    ptoSheet.getCell(1, col).border = borderStyle;
  }
  
  for (const item of aggregated) {
    ptoSheet.addRow({
      system: item.system || "-",
      subsystem: item.subsystem || "-",
      section: item.section || "-",
      floor: item.floor || "-",
      positionNumber: item.positionNumber || "-",
      workName: item.workName || "-",
      m15_name: item.m15_name || "-", // Здесь m15_name
      unit: item.unit || "-",
      quantity: item.quantity || 0
    });
  }
  
  for(let i = 2; i <= aggregated.length + 1; i++) {
    const row = ptoSheet.getRow(i);
    row.height = undefined;
    for(let col = 1; col <= 9; col++) {
      const cell = ptoSheet.getCell(i, col);
      cell.border = borderStyle;
      if (col === 6 || col === 7) {
        cell.alignment = {
          horizontal: "left",
          vertical: "middle",
          wrapText: true
        };
      } else {
        cell.alignment = {
          horizontal: "center",
          vertical: "middle"
        };
      }
      if (col === 9) {
        cell.numFmt = '0.00';
      }
    }
  }
  
  // Автоширина
  ptoSheet.columns.forEach((column) => {
    let maxLength = 0;
    column.eachCell?.({ includeEmpty: true }, (cell) => {
      try {
        let cellLength = 0;
        if (cell.value) {
          const valueString = String(cell.value);
          cellLength = valueString.length;
        }
        if (cellLength > maxLength) maxLength = cellLength;
      } catch (e) {}
    });
    const optimalWidth = Math.min(maxLength + 2, 50);
    if (column) column.width = optimalWidth > 10 ? optimalWidth : 10;
  });
  
  // Второй лист - Общий
  const aggregatedGeneral = aggregateGeneralResults(original);
  const generalSheet = workbook.addWorksheet("Общий");
  generalSheet.columns = [
    { header: "Объект", key: "objectName", width: 15 },
    { header: "Договор", key: "contractNumber", width: 12 },
    { header: "Система", key: "system", width: 15 },
    { header: "Подсистема", key: "subsystem", width: 15 },
    { header: "№", key: "positionNumber", width: 10 },
    { header: "Наименование", key: "workName", width: 25 },
    { header: "М-15", key: "m15_name", width: 25 }, // Используем m15_name
    { header: "Ед. изм.", key: "unit", width: 10 },
    { header: "Кол-во", key: "quantity", width: 10 },
    { header: "Цена", key: "price", width: 12 },
    { header: "Сумма", key: "total", width: 12 }
  ];
  
  generalSheet.getRow(1).fill = headerFill;
  generalSheet.getRow(1).font = headerFont;
  generalSheet.getRow(1).alignment = headerAlignment;
  generalSheet.getRow(1).height = 25;
  for(let col = 1; col <= 11; col++) {
    generalSheet.getCell(1, col).border = borderStyle;
  }
  
  for (const item of aggregatedGeneral) {
    generalSheet.addRow({
      objectName: item.objectName || "-",
      contractNumber: item.contractNumber || "-",
      system: item.system || "-",
      subsystem: item.subsystem || "-",
      positionNumber: item.positionNumber || "-",
      workName: item.workName || "-",
      m15_name: item.m15_name || "-", // Здесь m15_name
      unit: item.unit || "-",
      quantity: item.quantity || 0,
      price: item.price || 0,
      total: item.total || 0
    });
  }
  
  for(let i = 2; i <= aggregatedGeneral.length + 1; i++) {
    const row = generalSheet.getRow(i);
    row.height = undefined;
    for(let col = 1; col <= 11; col++) {
      const cell = generalSheet.getCell(i, col);
      cell.border = borderStyle;
      if (col === 6 || col === 7) {
        cell.alignment = {
          horizontal: "left",
          vertical: "middle",
          wrapText: true
        };
      } else {
        cell.alignment = {
          horizontal: "center",
          vertical: "middle"
        };
      }
      if (col === 9) {
        cell.numFmt = '0.00';
      } else if (col === 10 || col === 11) {
        cell.numFmt = '#,##0.00';
      }
    }
  }
  
  generalSheet.columns.forEach((column) => {
    let maxLength = 0;
    column.eachCell?.({ includeEmpty: true }, (cell) => {
      try {
        let cellLength = 0;
        if (cell.value) {
          const valueString = String(cell.value);
          cellLength = valueString.length;
        }
        if (cellLength > maxLength) maxLength = cellLength;
      } catch (e) {}
    });
    const optimalWidth = Math.min(maxLength + 2, 50);
    if (column) column.width = optimalWidth > 10 ? optimalWidth : 10;
  });
  
  const buffer = await workbook.xlsx.writeBuffer();
  return buffer;
}

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info"
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: cors });
  }
  
  try {
    const requestData = await req.json();
    
    if (!requestData.results || requestData.results.length === 0) {
      return new Response(JSON.stringify({
        success: false,
        message: "Нет данных для экспорта"
      }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
    }
    
    // Агрегирование
    const aggregated = aggregateResults(requestData.results);
    const xlsxBuffer = await createXlsxWithExcelJS(aggregated, requestData.results);
    const base64 = encode(xlsxBuffer);
    const filename = generateFilename(requestData.objectName, requestData.exportType);
    
    return new Response(JSON.stringify({
      success: true,
      filename,
      base64,
      rows: aggregated.length,
      message: `XLSX готов: ${aggregated.length} строк`
    }), { status: 200, headers: { ...cors, "Content-Type": "application/json" } });
  } catch (error) {
    return new Response(JSON.stringify({
      success: false,
      message: `Ошибка: ${error instanceof Error ? error.message : String(error)}`
    }), { status: 500, headers: { ...cors, "Content-Type": "application/json" } });
  }
});
