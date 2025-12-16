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

    const { 
      objectId, 
      dateFrom, 
      dateTo,
      systemFilters,
      sectionFilters,
      floorFilters,
      searchQuery
    } = await req.json();

    if (!objectId || !dateFrom || !dateTo) {
      throw new Error("Не указаны обязательные параметры (objectId, dateFrom, dateTo)");
    }

    // 1. Получаем информацию об объекте
    const { data: objectData, error: objectError } = await supabase
      .from("objects")
      .select("name, address")
      .eq("id", objectId)
      .single();

    if (objectError) throw objectError;

    // 2. Получаем работы за период с учетом фильтров (с пагинацией)
    let query = supabase
      .from("work_items")
      .select(`
        system,
        section,
        floor,
        name,
        unit,
        quantity,
        estimates (
          number,
          contracts (
            id,
            number,
            date
          )
        ),
        works!inner (
          object_id,
          date
        )
      `)
      .eq("works.object_id", objectId)
      .gte("works.date", dateFrom)
      .lte("works.date", dateTo);

    // Применяем фильтры
    if (systemFilters && Array.isArray(systemFilters) && systemFilters.length > 0) {
      query = query.in('system', systemFilters);
    }
    if (sectionFilters && Array.isArray(sectionFilters) && sectionFilters.length > 0) {
      query = query.in('section', sectionFilters);
    }
    if (floorFilters && Array.isArray(floorFilters) && floorFilters.length > 0) {
      query = query.in('floor', floorFilters);
    }
    if (searchQuery && typeof searchQuery === 'string' && searchQuery.trim().length > 0) {
      query = query.ilike('name', `%${searchQuery.trim()}%`);
    }

    // Реализация пагинации для обхода лимита в 1000 записей
    const allItems: any[] = [];
    let offset = 0;
    const limit = 1000;
    let hasMore = true;

    while (hasMore) {
      // Используем range для получения порции данных
      // Важно: в supabase-js query builder иммутабелен при вызове range, возвращает новый Promise
      const { data, error } = await query.range(offset, offset + limit - 1);
      
      if (error) throw error;

      if (data && data.length > 0) {
        allItems.push(...data);
        
        // Если получили меньше лимита, значит данных больше нет
        if (data.length < limit) {
          hasMore = false;
        }
      } else {
        hasMore = false;
      }
      
      offset += limit;
    }

    const items = allItems;

    // 3. Группировка по Договорам
    // Map<ContractKey, { contractInfo: string, items: any[] }>
    const contractsMap = new Map();

    if (items && items.length > 0) {
      items.forEach((item: any) => {
        const contract = item.estimates?.contracts;
        
        // Формируем уникальный ключ и название договора
        let contractKey = "no_contract";
        let contractLabel = "Без договора";
        let contractDateStr = "";

        if (contract) {
          contractKey = contract.id || `${contract.number}_${contract.date}`;
          const cDate = contract.date ? new Date(contract.date).toLocaleDateString("ru-RU") : "";
          contractLabel = `№ ${contract.number || "б/н"} от ${cDate}`;
          contractDateStr = contract.date || "";
        }

        if (!contractsMap.has(contractKey)) {
          contractsMap.set(contractKey, {
            label: contractLabel,
            rawDate: contractDateStr,
            items: []
          });
        }
        contractsMap.get(contractKey).items.push(item);
      });
    } else {
      // Если данных нет вообще, создадим пустую группу, чтобы сгенерировать пустой отчет
      contractsMap.set("empty", { label: "—", items: [] });
    }

    // 4. Генерация Excel
    const workbook = new ExcelJS.Workbook();

    // Перебираем каждый договор и создаем лист
    const sortedContractKeys = Array.from(contractsMap.keys()); 

    for (const key of sortedContractKeys) {
      const contractGroup = contractsMap.get(key);
      const groupItems = contractGroup.items;
      const contractInfo = contractGroup.label;

      // Формируем имя листа (Excel ограничение 31 символ, запрещенные знаки)
      let sheetName = contractInfo.replace(/[:\/\?\*\[\]\\]/g, " ").trim();
      if (sheetName.length > 30) {
        sheetName = sheetName.substring(0, 30);
      }
      
      let uniqueSheetName = sheetName;
      let counter = 1;
      while (workbook.getWorksheet(uniqueSheetName)) {
        uniqueSheetName = `${sheetName.substring(0, 25)} (${counter})`;
        counter++;
      }

      const worksheet = workbook.addWorksheet(uniqueSheetName, {
        pageSetup: {
          paperSize: 9, // A4
          orientation: 'portrait',
          fitToPage: true,
          fitToWidth: 1,
          fitToHeight: 0, 
          printTitlesRow: '11:11',
          margins: {
            left: 0.5, right: 0.5,
            top: 0.5, bottom: 0.5,
            header: 0.3, footer: 0.3
          }
        }
      });

      // --- Внутренняя группировка данных (Суммирование quantity) для текущего договора ---
      const groupedData = new Map();
      groupItems.forEach((item: any) => {
        const lsrNumber = item.estimates?.number || "—";
        const itemKey = `${item.system}_${item.name}_${item.unit}_${lsrNumber}`;
        
        if (!groupedData.has(itemKey)) {
          groupedData.set(itemKey, {
            lsrNumber: lsrNumber,
            section: item.system, // Раздел = Система
            name: item.name,
            unit: item.unit,
            quantity: 0,
          });
        }
        
        const qty = Number(item.quantity);
        if (!isNaN(qty)) {
           groupedData.get(itemKey).quantity += qty;
        }
      });

      const reportRows = Array.from(groupedData.values()).sort((a, b) => {
        const sectionCompare = a.section.localeCompare(b.section);
        if (sectionCompare !== 0) return sectionCompare;
        
        // Numeric sort for LSR
        const lsrCompare = String(a.lsrNumber).localeCompare(String(b.lsrNumber), 'ru', { numeric: true });
        if (lsrCompare !== 0) return lsrCompare;
        
        return a.name.localeCompare(b.name);
      });

      // --- Настройка колонок и стилей (повтoряем для каждого листа) ---
      worksheet.getColumn(1).width = 10; // A
      worksheet.getColumn(2).width = 10; // B
      worksheet.getColumn(3).width = 10; // C
      worksheet.getColumn(4).width = 75; // D
      worksheet.getColumn(5).width = 10; // E
      worksheet.getColumn(6).width = 10; // F

      // --- Шапка ---
      const titleRow = worksheet.getRow(9);
      worksheet.mergeCells('A9:F9');
      const titleCell = worksheet.getCell('A9');
      titleCell.value = "ВЕДОМОСТЬ ОБЪЁМОВ РАБОТ";
      titleCell.font = { name: 'Times New Roman', size: 14, bold: true };
      titleCell.alignment = { horizontal: 'center', vertical: 'middle' };
      titleRow.height = 30;

      const headerInfoFont = { name: 'Times New Roman', size: 12, bold: true };
      const headerInfoAlignmentLeft = { horizontal: "left" as const, vertical: "middle" as const, wrapText: true };
      const headerInfoAlignmentRight = { horizontal: "right" as const, vertical: "middle" as const };

      const setRowHeight = (rowIdx: number, text: string) => {
        const row = worksheet.getRow(rowIdx);
        if (!text) {
          row.height = 20;
          return;
        }
        const charsPerLine = 100;
        const lines = Math.ceil(text.length / charsPerLine);
        if (lines > 1) {
          row.height = lines * 15 + 5; 
        } else {
          row.height = 20;
        }
      };

      // B1: Объект
      const objName = objectData.name || "";
      worksheet.mergeCells('B1:F1');
      worksheet.getCell("B1").value = objName;
      worksheet.getCell("A1").value = "Объект:";
      setRowHeight(1, objName);
      
      // B3: Адрес
      const objAddress = objectData.address || "—";
      worksheet.mergeCells('B3:F3');
      worksheet.getCell("B3").value = objAddress;
      worksheet.getCell("A3").value = "Адрес:";
      setRowHeight(3, objAddress);

      // B5: Договор (ТЕПЕРЬ УНИКАЛЬНЫЙ ДЛЯ ЛИСТА)
      worksheet.mergeCells('B5:F5');
      worksheet.getCell("B5").value = contractInfo;
      worksheet.getCell("A5").value = "Договор:";
      setRowHeight(5, contractInfo);

      // B7: Период
      const formatDate = (dateStr: string) => {
        try {
          const date = new Date(dateStr);
          return date.toLocaleDateString("ru-RU");
        } catch {
          return dateStr;
        }
      };
      const formattedFrom = formatDate(dateFrom);
      const formattedTo = formatDate(dateTo);
      const periodText = `${formattedFrom} - ${formattedTo}`;
      worksheet.mergeCells('B7:F7');
      worksheet.getCell("B7").value = periodText;
      worksheet.getCell("A7").value = "Период:";
      setRowHeight(7, periodText);

      // Spacing
      [2, 4, 6, 8, 10].forEach(rowIdx => {
        worksheet.getRow(rowIdx).height = 10;
      });

      // Styles
      ["A1", "A3", "A5", "A7"].forEach(cell => {
        const c = worksheet.getCell(cell);
        c.font = headerInfoFont;
        c.alignment = headerInfoAlignmentRight;
      });
      ["B1", "B3", "B5", "B7"].forEach(cell => {
        const c = worksheet.getCell(cell);
        c.font = headerInfoFont;
        c.alignment = headerInfoAlignmentLeft;
      });

      // --- Таблица ---
      const headerRowIdx = 11;
      const headers = ["№ п/п", "№ по ЛСР", "Раздел", "Наименование работ", "Ед. изм.", "Кол-во"];
      const headerRow = worksheet.getRow(headerRowIdx);
      headerRow.height = 40;
      
      for(let i=0; i<headers.length; i++) {
        headerRow.getCell(i+1).value = headers[i];
      }
      
      headerRow.eachCell((cell) => {
        cell.font = { name: 'Times New Roman', size: 11, bold: true };
        cell.alignment = { horizontal: "center", vertical: "middle", wrapText: true };
        cell.border = { top: { style: "thin" }, left: { style: "thin" }, bottom: { style: "thin" }, right: { style: "thin" } };
      });

      let currentRowIdx = 12;
      const dataFont = { name: 'Times New Roman', size: 12 };

      if (reportRows.length > 0) {
        reportRows.forEach((row: any, index: number) => {
          const excelRow = worksheet.getRow(currentRowIdx);
          
          excelRow.getCell(1).value = index + 1;
          excelRow.getCell(2).value = row.lsrNumber;
          excelRow.getCell(3).value = row.section;
          excelRow.getCell(4).value = row.name;
          excelRow.getCell(5).value = row.unit;
          excelRow.getCell(6).value = row.quantity;

          for (let i = 1; i <= 6; i++) {
             excelRow.getCell(i).font = dataFont;
             excelRow.getCell(i).border = { top: { style: "thin" }, left: { style: "thin" }, bottom: { style: "thin" }, right: { style: "thin" } };
          }
          excelRow.getCell(1).alignment = { horizontal: "center", vertical: 'top' };
          excelRow.getCell(2).alignment = { horizontal: "center", vertical: 'top' };
          excelRow.getCell(3).alignment = { horizontal: "left", vertical: 'top', wrapText: true };
          excelRow.getCell(4).alignment = { horizontal: "left", vertical: 'top', wrapText: true };
          excelRow.getCell(5).alignment = { horizontal: "center", vertical: 'top' };
          excelRow.getCell(6).alignment = { horizontal: "right", vertical: 'top' };
          
          currentRowIdx++;
        });
      } else {
          const excelRow = worksheet.getRow(currentRowIdx);
          excelRow.height = 20;
          const cell = excelRow.getCell(1);
          cell.value = "Нет данных";
          cell.font = dataFont;
          worksheet.mergeCells(`A${currentRowIdx}:F${currentRowIdx}`);
          cell.alignment = { horizontal: "center", vertical: "middle" };
          currentRowIdx++;
      }

      const lastRow = currentRowIdx - 1;

      // --- Подписи ---
      const footerStartRow = lastRow + 3;
      const footerFont = { name: 'Times New Roman', size: 12 };

      const compiledCell = worksheet.getCell(`D${footerStartRow}`);
      compiledCell.value = "Составил: _______________ /____________/";
      compiledCell.font = footerFont;

      const agreedCell = worksheet.getCell(`D${footerStartRow + 2}`);
      agreedCell.value = "Согласовал: _______________ /____________/";
      agreedCell.font = footerFont;

      const endRow = footerStartRow + 2;
      worksheet.pageSetup.printArea = `A1:F${endRow}`;
    } // Конец цикла по договорам

    const buffer = await workbook.xlsx.writeBuffer();
    const base64File = encode(buffer);

    return new Response(JSON.stringify({ 
      file: base64File,
      filename: `vor_${objectId}.xlsx`
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
