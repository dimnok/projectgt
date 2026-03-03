import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import ExcelJS from "https://esm.sh/exceljs@4.4.0";
import { encode } from "https://deno.land/std@0.168.0/encoding/base64.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { contractId, companyId } = await req.json();

    if (!contractId || !companyId) {
      throw new Error("Не указаны contractId или companyId");
    }

    // 1. Получаем инфо о контракте и объекте
    const { data: contract, error: contractError } = await supabase
      .from("contracts")
      .select("number, objects(name)")
      .eq("id", contractId)
      .single();

    if (contractError) throw contractError;

    // 2. Получаем все сметные позиции для этого контракта
    const { data: estimates, error: estimatesError } = await supabase
      .from("estimates")
      .select("*")
      .eq("contract_id", contractId);

    if (estimatesError) throw estimatesError;

    // Сортировка смет как в приложении (аналог EstimateSorter.compareByNumber)
    const compareEstimateNumbers = (a: any, b: any) => {
      const parseNumberSortKey = (val: string) => {
        const normalized = (val || "").trim().toLowerCase();
        if (!normalized) return { priority: 3, segments: [], normalized: "" };

        if (/^\d+$/.test(normalized)) {
          return { priority: 0, segments: [parseInt(normalized)], normalized };
        }
        if (/^\d+(?:\.\d+)+$/.test(normalized)) {
          const parts = normalized.split('.').map(p => parseInt(p) || 0);
          return { priority: 1, segments: parts, normalized };
        }
        if (normalized.startsWith('д-')) {
          const valNum = parseInt(normalized.substring(2)) || 0;
          return { priority: 2, segments: [valNum], normalized };
        }
        return { priority: 3, segments: [], normalized };
      };

      const keyA = parseNumberSortKey(a.number);
      const keyB = parseNumberSortKey(b.number);

      if (keyA.priority !== keyB.priority) return keyA.priority - keyB.priority;

      const minLen = Math.min(keyA.segments.length, keyB.segments.length);
      for (let i = 0; i < minLen; i++) {
        if (keyA.segments[i] !== keyB.segments[i]) return keyA.segments[i] - keyB.segments[i];
      }

      if (keyA.segments.length !== keyB.segments.length) {
        return keyA.segments.length - keyB.segments.length;
      }

      if (keyA.normalized !== keyB.normalized) {
        return keyA.normalized.localeCompare(keyB.normalized);
      }

      return (a.id || "").localeCompare(b.id || "");
    };

    const sortedEstimates = (estimates || []).sort(compareEstimateNumbers);

    // 3. Получаем все ВОРы для этого контракта
    const { data: vorsRaw, error: vorsError } = await supabase
      .from("vors")
      .select("*")
      .eq("contract_id", contractId);

    if (vorsError) throw vorsError;

    // Сортировка ВОР по номеру (ВОР-1, ВОР-2...)
    const extractVorOrder = (value: string) => {
      const match = value.match(/\d+/);
      if (!match) return 1 << 30;
      return parseInt(match[0]) || (1 << 30);
    };

    const vors = (vorsRaw || []).sort((a: any, b: any) => {
      const aOrder = extractVorOrder(a.number || "");
      const bOrder = extractVorOrder(b.number || "");
      if (aOrder !== bOrder) return aOrder - bOrder;
      return (a.number || "").toLowerCase().localeCompare((b.number || "").toLowerCase());
    });

    // 4. Получаем все vor_items для этих ВОР
    const vorIds = vors.map((v: any) => v.id);
    let vorItems: any[] = [];
    if (vorIds.length > 0) {
      const { data, error } = await supabase
        .from("vor_items")
        .select("estimate_item_id, vor_id, quantity")
        .in("vor_id", vorIds);
      if (error) throw error;
      vorItems = data || [];
    }

    // Группировка данных вор
    const completionMap: Record<string, Record<string, number>> = {};
    vorItems.forEach((item: any) => {
      const eId = item.estimate_item_id;
      const vId = item.vor_id;
      if (!completionMap[eId]) completionMap[eId] = {};
      completionMap[eId][vId] = (completionMap[eId][vId] || 0) + (item.quantity || 0);
    });

    // Группировка данных: Смета -> Позиции
    const groupedData: Record<string, any[]> = {};
    const estimateTitlesOrder: string[] = [];
    
    // ВАЖНО: берем порядок смет строго из отсортированного списка позиций
    sortedEstimates.forEach((item: any) => {
      const title = item.estimate_title || "БЕЗ НАЗВАНИЯ";
      if (!groupedData[title]) {
        groupedData[title] = [];
        estimateTitlesOrder.push(title);
      }
      groupedData[title].push(item);
    });

    // 5. Генерация Excel
    const workbook = new ExcelJS.Workbook();

    // Стили
    const defaultFont = { name: 'Times New Roman', size: 10 };
    const headerFont = { name: 'Times New Roman', size: 10, bold: true };
    const titleFont = { name: 'Times New Roman', size: 10, bold: true, italic: true };
    const footerFont = { name: 'Times New Roman', size: 10, bold: true };

    const fillSheet = (worksheetName: string, isFinancial: boolean) => {
      const worksheet = workbook.addWorksheet(worksheetName);

      // Заголовки (Двухуровневые для финансового листа)
      const headers = [
        "Система",
        "Подсистема",
        "№",
        "Наименование",
        "Ед. изм.",
      ];

      if (isFinancial) {
        headers.push("Кол-во по смете", "Цена", "Сумма по смете");
        vors.forEach((vor: any) => {
          const num = vor.number || "ВОР";
          headers.push(`${num}\n(объем)`, `${num}\n(сумма)`);
        });
        headers.push("ИТОГО\n(объем)", "ИТОГО\n(сумма)");
      } else {
        headers.push("Кол-во по смете");
        vors.forEach((vor: any) => {
          headers.push(vor.number || `ВОР-${vor.id.substring(0, 4)}`);
        });
        headers.push("ИТОГО");
      }

      const headerRow = worksheet.addRow(headers);
      headerRow.font = headerFont;
      headerRow.alignment = { vertical: 'middle', horizontal: 'center', wrapText: true };
      headerRow.height = 45;

      worksheet.views = [{ state: 'frozen', xSplit: 0, ySplit: 1, activeCell: 'A2' }];
      worksheet.autoFilter = {
        from: { row: 1, column: 1 },
        to: { row: 1, column: headers.length }
      };

      const totalCols = headers.length;

      // Добавление данных
      estimateTitlesOrder.forEach((estimateTitle) => {
        const firstItem = groupedData[estimateTitle][0];
        const systemName = firstItem?.system || "";

        // Строка наименования сметы (теперь с названием системы в первой колонке)
        const titleRow = worksheet.addRow([systemName, "", "", estimateTitle]);
        titleRow.height = 25;
        for (let i = 1; i <= totalCols; i++) {
          const cell = titleRow.getCell(i);
          cell.font = titleFont;
          cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE9ECEF' } };
          cell.border = { top: { style: 'thin' }, left: { style: 'thin' }, bottom: { style: 'thin' }, right: { style: 'thin' } };
          cell.alignment = { vertical: 'middle', horizontal: (i === 1 || i === 4) ? 'left' : 'center' };
        }

        // Переменные для итогов по группе
        let groupEstimateSum = 0;
        const groupVorSums: Record<string, number> = {}; // vor_id -> sum
        let groupTotalSum = 0;

        groupedData[estimateTitle].forEach((item: any) => {
          const rowData = [
            item.system || "",
            item.subsystem || "",
            item.number || "",
            item.name || "",
            item.unit || "",
          ];

          if (isFinancial) {
            rowData.push(item.quantity || 0);
            rowData.push(item.price || 0);
            rowData.push(item.total || 0);
            groupEstimateSum += (item.total || 0);
          } else {
            rowData.push(item.quantity || 0);
          }

          let totalQty = 0;
          let totalAmount = 0;
          const itemCompletion = completionMap[item.id] || {};
          
          vors.forEach((vor: any) => {
            const qty = itemCompletion[vor.id] || 0;
            if (isFinancial) {
              const amount = qty * (item.price || 0);
              rowData.push(qty, amount);
              totalQty += qty;
              totalAmount += amount;
              groupVorSums[vor.id] = (groupVorSums[vor.id] || 0) + amount;
            } else {
              rowData.push(qty);
              totalQty += qty;
            }
          });
          
          if (isFinancial) {
            rowData.push(totalQty, totalAmount);
            groupTotalSum += totalAmount;
          } else {
            rowData.push(totalQty);
          }

          const newRow = worksheet.addRow(rowData);
          newRow.font = defaultFont;
          
          for (let i = 1; i <= totalCols; i++) {
            const cell = newRow.getCell(i);
            cell.border = { top: { style: 'thin' }, left: { style: 'thin' }, bottom: { style: 'thin' }, right: { style: 'thin' } };
            cell.alignment = { vertical: 'middle', horizontal: i === 4 ? 'left' : 'center', wrapText: true };
            
            // Форматирование чисел
            if (isFinancial) {
              if (i === 7 || i === 8 || (i >= 9 && (i - 9) % 2 !== 0)) { // Финансы (Цена, Суммы)
                cell.numFmt = '#,##0.00';
              } else if (i === 6 || (i >= 9 && (i - 9) % 2 === 0)) { // Объемы (Кол-во смет., ВОР-объем, ИТОГО-объем)
                cell.numFmt = '#,##0';
              }
            } else {
              if (i >= 6) cell.numFmt = '#,##0';
            }
          }

          // Подсветка перерасхода
          if (totalQty > (item.quantity || 0) + 0.0001) {
            newRow.eachCell((cell) => {
              cell.font = { ...defaultFont, color: { argb: 'FFFF0000' } };
            });
          }
        });

        // Строка ИТОГО по сметной группе (только для финансового листа)
        if (isFinancial) {
          const footerRowData = [systemName, "", "", `ИТОГО по: ${estimateTitle}`, "", "", ""];
          footerRowData.push(groupEstimateSum); // 8: Сумма по смете

          vors.forEach((vor: any) => {
            footerRowData.push(""); // объем (пусто)
            footerRowData.push(groupVorSums[vor.id] || 0); // сумма
          });
          footerRowData.push(""); // ИТОГО объем (пусто)
          footerRowData.push(groupTotalSum); // ИТОГО сумма

          const footerRow = worksheet.addRow(footerRowData);
          footerRow.height = 25;
          footerRow.font = footerFont;

          for (let i = 1; i <= totalCols; i++) {
            const cell = footerRow.getCell(i);
            cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF2F2F2' } };
            cell.border = { top: { style: 'thin' }, left: { style: 'thin' }, bottom: { style: 'thin' }, right: { style: 'thin' } };
            cell.alignment = { vertical: 'middle', horizontal: (i === 1 || i === 4) ? (i === 1 ? 'left' : 'right') : 'center' };
            
            if (i === 8 || (i >= 9 && (i - 9) % 2 !== 0)) {
              cell.numFmt = '#,##0.00';
            }
          }
        }
      });

      // Ширина колонок
      const colWidths = [
        { width: 10 }, // Система
        { width: 10 }, // Подсистема
        { width: 10 }, // №
        { width: 115 }, // Наименование
        { width: 10 }, // Ед. изм.
      ];
      
      if (isFinancial) {
        colWidths.push({ width: 12 }, { width: 12 }, { width: 15 }); // Кол-во смет., Цена, Сумма смет.
        vors.forEach(() => colWidths.push({ width: 10 }, { width: 15 })); // Объем ВОР, Сумма ВОР
        colWidths.push({ width: 10 }, { width: 15 }); // ИТОГО объем, ИТОГО сумма
      } else {
        colWidths.push({ width: 10 }); // Кол-во смет.
        vors.forEach(() => colWidths.push({ width: 10 }));
        colWidths.push({ width: 10 }); // ИТОГО
      }

      worksheet.columns = colWidths;

      headerRow.eachCell((cell) => {
        cell.border = { top: { style: 'thin' }, left: { style: 'thin' }, bottom: { style: 'thin' }, right: { style: 'thin' } };
      });
    };

    fillSheet("Накопительная ВОР (объемы)", false);
    fillSheet("Накопительная ВОР (финансы)", true);

    const buffer = await workbook.xlsx.writeBuffer();
    const base64File = encode(new Uint8Array(buffer));

    const objectName = contract.objects?.name || "Объект";
    const contractNum = contract.number || "бн";
    const filename = `Накопительная_ВОР_${objectName}_${contractNum}.xlsx`;

    return new Response(JSON.stringify({ 
      file: base64File,
      filename: filename
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("Error in cumulative vor export:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
