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
          id,
          number,
          quantity,
          material_aliases (
            alias_raw
          ),
          contracts (
            id,
            number,
            date,
            contractor_legal_name,
            contractor_position,
            contractor_signer,
            customer_legal_name,
            customer_position,
            customer_signer
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
      const { data, error } = await query.range(offset, offset + limit - 1);
      
      if (error) throw error;

      if (data && data.length > 0) {
        allItems.push(...data);
        if (data.length < limit) {
          hasMore = false;
        }
      } else {
        hasMore = false;
      }
      
      offset += limit;
    }

    // 2.1 Получение исторического использования (объемы ДО этого периода)
    const estimateIds = [...new Set(allItems.map(i => i.estimates?.id).filter(id => !!id))];
    const historicalUsageMap = new Map();
    
    if (estimateIds.length > 0) {
        const chunkSize = 100;
        for (let i = 0; i < estimateIds.length; i += chunkSize) {
             const chunk = estimateIds.slice(i, i + chunkSize);
             const { data: historyData, error: historyError } = await supabase
                .from("work_items")
                .select(`estimate_id, quantity, works!inner(date)`)
                .in("estimate_id", chunk)
                .lt("works.date", dateFrom);
             
             if (historyError) throw historyError;
             
             historyData?.forEach((hItem: any) => {
                 const eid = hItem.estimate_id;
                 const qty = Number(hItem.quantity) || 0;
                 historicalUsageMap.set(eid, (historicalUsageMap.get(eid) || 0) + qty);
             });
        }
    }

    const items = allItems;

    // 3. Группировка по Договорам
    const contractsMap = new Map();

    if (items && items.length > 0) {
      items.forEach((item: any) => {
        const contract = item.estimates?.contracts;
        
        let contractKey = "no_contract";
        let contractLabel = "Без договора";
        let contractDateStr = "";
        let contractSignatories = null;

        if (contract) {
          contractKey = contract.id || `${contract.number}_${contract.date}`;
          const cDate = contract.date ? new Date(contract.date).toLocaleDateString("ru-RU") : "";
          contractLabel = `№ ${contract.number || "б/н"} от ${cDate}`;
          contractDateStr = contract.date || "";
          
          contractSignatories = {
            contractor: {
              name: contract.contractor_legal_name || '—',
              position: contract.contractor_position || 'Должность',
              signer: contract.contractor_signer || '/___________/'
            },
            customer: {
              name: contract.customer_legal_name || '—',
              position: contract.customer_position || 'Должность',
              signer: contract.customer_signer || '/___________/'
            }
          };
        }

        if (!contractsMap.has(contractKey)) {
          contractsMap.set(contractKey, {
            label: contractLabel,
            rawDate: contractDateStr,
            signatories: contractSignatories,
            items: []
          });
        }
        contractsMap.get(contractKey).items.push(item);
      });
    } else {
      contractsMap.set("empty", { label: "—", items: [] });
    }

    // 4. Генерация Excel
    const workbook = new ExcelJS.Workbook();
    const sortedContractKeys = Array.from(contractsMap.keys()); 

    for (const key of sortedContractKeys) {
      const contractGroup = contractsMap.get(key);
      const groupItems = contractGroup.items;
      const contractInfo = contractGroup.label;
      const sigs = contractGroup.signatories;

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

      // --- Группировка и разделение на Норму и Превышение ---
      const groupedData = new Map();
      groupItems.forEach((item: any) => {
        const lsrNumber = item.estimates?.number || "—";
        const estimateId = item.estimates?.id;
        const itemKey = `${item.system}_${item.name}_${item.unit}_${lsrNumber}`;
        
        if (!groupedData.has(itemKey)) {
          // Собираем уникальные алиасы материалов из накладных
          const rawAliases = item.estimates?.material_aliases || [];
          const aliases = [...new Set(rawAliases.map((a: any) => a.alias_raw))].join(', ');

          groupedData.set(itemKey, {
            lsrNumber: lsrNumber,
            section: item.system,
            name: item.name,
            relatedMaterials: aliases, // Новое поле
            unit: item.unit,
            estimateId: estimateId,
            limit: Number(item.estimates?.quantity) || 0,
            usedBefore: historicalUsageMap.get(estimateId) || 0,
            currentTotal: 0,
          });
        }
        
        const qty = Number(item.quantity);
        if (!isNaN(qty)) {
           groupedData.get(itemKey).currentTotal += qty;
        }
      });

      const normalRows: any[] = [];
      const overrunRows: any[] = [];

      groupedData.forEach((data) => {
          const limit = data.limit;
          const usedBefore = data.usedBefore;
          const remaining = Math.max(0, limit - usedBefore);
          const current = data.currentTotal;

          if (current <= 0) return;

          if (data.estimateId && limit > 0) {
              if (current <= remaining) {
                  normalRows.push({ ...data, displayQuantity: current });
              } else {
                  if (remaining > 0) {
                      normalRows.push({ ...data, displayQuantity: remaining });
                  }
                  const overrun = current - remaining;
                  overrunRows.push({ ...data, displayQuantity: overrun });
              }
          } else {
              overrunRows.push({ ...data, displayQuantity: current });
          }
      });

      const sortFn = (a: any, b: any) => {
          const sectionCompare = a.section.localeCompare(b.section);
          if (sectionCompare !== 0) return sectionCompare;
          const lsrCompare = String(a.lsrNumber).localeCompare(String(b.lsrNumber), 'ru', { numeric: true });
          if (lsrCompare !== 0) return lsrCompare;
          return a.name.localeCompare(b.name);
      };

      normalRows.sort(sortFn);
      overrunRows.sort(sortFn);

      // --- Настройка колонок и стилей ---
      worksheet.getColumn(1).width = 7;   // № п/п
      worksheet.getColumn(2).width = 10;  // № по ЛСР
      worksheet.getColumn(3).width = 12;  // Раздел
      worksheet.getColumn(4).width = 45;  // Наименование работ
      worksheet.getColumn(5).width = 45;  // Материал (накладная) - НОВАЯ КОЛОНКА
      worksheet.getColumn(6).width = 10;  // Ед. изм.
      worksheet.getColumn(7).width = 10;  // Кол-во

      const mainFont = { name: 'PT Serif', size: 10 };
      const boldFont = { name: 'PT Serif', size: 10, bold: true };

      // --- Шапка ---
      const titleRow = worksheet.getRow(9);
      worksheet.mergeCells('A9:G9'); // Увеличено до G
      const titleCell = worksheet.getCell('A9');
      titleCell.value = "ВЕДОМОСТЬ ОБЪЁМОВ РАБОТ";
      titleCell.font = { name: 'PT Serif', size: 14, bold: true };
      titleCell.alignment = { horizontal: 'center', vertical: 'middle' };
      titleRow.height = 30;

      const headerInfoFont = { name: 'PT Serif', size: 11, bold: true };
      const headerInfoAlignmentLeft = { horizontal: "left" as const, vertical: "middle" as const, wrapText: true };
      const headerInfoAlignmentRight = { horizontal: "right" as const, vertical: "middle" as const };

      const setRowHeight = (rowIdx: number, text: string) => {
        const row = worksheet.getRow(rowIdx);
        if (!text) {
          row.height = 20;
          return;
        }
        const charsPerLine = 120;
        const lines = Math.ceil(text.length / charsPerLine);
        row.height = lines > 1 ? lines * 14 + 5 : 20;
      };

      // B1: Объект
      const objName = objectData.name || "";
      worksheet.mergeCells('B1:G1'); // Увеличено до G
      worksheet.getCell("B1").value = objName;
      worksheet.getCell("A1").value = "Объект:";
      setRowHeight(1, objName);
      
      // B3: Адрес
      const objAddress = objectData.address || "—";
      worksheet.mergeCells('B3:G3'); // Увеличено до G
      worksheet.getCell("B3").value = objAddress;
      worksheet.getCell("A3").value = "Адрес:";
      setRowHeight(3, objAddress);

      // B5: Договор
      worksheet.mergeCells('B5:G5'); // Увеличено до G
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
      const periodText = `${formatDate(dateFrom)} - ${formatDate(dateTo)}`;
      worksheet.mergeCells('B7:G7'); // Увеличено до G
      worksheet.getCell("B7").value = periodText;
      worksheet.getCell("A7").value = "Период:";
      setRowHeight(7, periodText);

      [2, 4, 6, 8, 10].forEach(rowIdx => { worksheet.getRow(rowIdx).height = 10; });

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
      const headers = ["№ п/п", "№ по ЛСР", "Раздел", "Наименование работ", "Материал (накладная)", "Ед. изм.", "Кол-во"];
      const headerRow = worksheet.getRow(headerRowIdx);
      headerRow.height = 40;
      
      for(let i=0; i<headers.length; i++) {
        headerRow.getCell(i+1).value = headers[i];
      }
      
      headerRow.eachCell((cell) => {
        cell.font = { name: 'PT Serif', size: 10, bold: true };
        cell.alignment = { horizontal: "center", vertical: "middle", wrapText: true };
        cell.border = { top: { style: "thin" }, left: { style: "thin" }, bottom: { style: "thin" }, right: { style: "thin" } };
      });

      let currentRowIdx = 12;
      let rowCounter = 1;

      const renderRows = (rows: any[]) => {
        rows.forEach((row: any) => {
          const excelRow = worksheet.getRow(currentRowIdx);
          excelRow.getCell(1).value = rowCounter++;
          excelRow.getCell(2).value = row.lsrNumber;
          excelRow.getCell(3).value = row.section;
          excelRow.getCell(4).value = row.name;
          excelRow.getCell(5).value = row.relatedMaterials; // Новая колонка
          excelRow.getCell(6).value = row.unit;
          excelRow.getCell(7).value = row.displayQuantity;

          for (let i = 1; i <= 7; i++) { // Увеличено до 7
             const cell = excelRow.getCell(i);
             cell.font = mainFont;
             cell.border = { top: { style: "thin" }, left: { style: "thin" }, bottom: { style: "thin" }, right: { style: "thin" } };
          }
          excelRow.getCell(1).alignment = { horizontal: "center", vertical: 'top' };
          excelRow.getCell(2).alignment = { horizontal: "center", vertical: 'top' };
          excelRow.getCell(3).alignment = { horizontal: "left", vertical: 'top', wrapText: true };
          excelRow.getCell(4).alignment = { horizontal: "left", vertical: 'top', wrapText: true };
          excelRow.getCell(5).alignment = { horizontal: "left", vertical: 'top', wrapText: true }; // Новая колонка
          excelRow.getCell(6).alignment = { horizontal: "center", vertical: 'top' };
          excelRow.getCell(7).alignment = { horizontal: "right", vertical: 'top' };
          currentRowIdx++;
        });
      };

      if (normalRows.length > 0) {
        renderRows(normalRows);
      } else if (overrunRows.length === 0) {
        const excelRow = worksheet.getRow(currentRowIdx);
        excelRow.getCell(1).value = "Нет данных";
        worksheet.mergeCells(`A${currentRowIdx}:G${currentRowIdx}`); // Увеличено до G
        excelRow.getCell(1).alignment = { horizontal: "center", vertical: "middle" };
        excelRow.getCell(1).font = mainFont;
        currentRowIdx++;
      }

      if (overrunRows.length > 0) {
        // Разделитель
        const separatorRow = worksheet.getRow(currentRowIdx);
        worksheet.mergeCells(`A${currentRowIdx}:G${currentRowIdx}`); // Увеличено до G
        const separatorCell = separatorRow.getCell(1);
        separatorCell.value = "ПРЕВЫШЕНИЕ ОБЪЕМОВ И ДОПОЛНИТЕЛЬНЫЕ РАБОТЫ, ТРЕБУЮЩИЕ ДОП. СОГЛАШЕНИЯ";
        separatorCell.font = boldFont;
        separatorCell.alignment = { horizontal: "center", vertical: "middle" };
        separatorCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFEEEEEE' } };
        separatorCell.border = { top: { style: "thin" }, left: { style: "thin" }, bottom: { style: "thin" }, right: { style: "thin" } };
        separatorRow.height = 25;
        currentRowIdx++;

        renderRows(overrunRows);
      }

      // --- Подписи ---
      const footerStartRow = currentRowIdx + 2;
      const formatSigner = (signer: string) => {
          if (signer.startsWith('/')) return `____________________ ${signer}`;
          return `____________________ /${signer}/`;
      };

      if (sigs) {
        // Подрядчик
        const contractorRow = worksheet.getRow(footerStartRow);
        contractorRow.getCell(1).value = "Подготовил";
        contractorRow.getCell(1).font = boldFont;
        
        const contractorNameRow = worksheet.getRow(footerStartRow + 1);
        contractorNameRow.getCell(1).value = `Подрядчик: ${sigs.contractor.name}`;
        contractorNameRow.getCell(1).font = boldFont;
        
        const contractorSignerRow = worksheet.getRow(footerStartRow + 3);
        contractorSignerRow.getCell(1).value = `${sigs.contractor.position} ${formatSigner(sigs.contractor.signer)}`;
        contractorSignerRow.getCell(1).font = mainFont;

        // Заказчик
        const customerRow = worksheet.getRow(footerStartRow);
        customerRow.getCell(5).value = "Согласовал"; // Перенесено на 5-ю колонку
        customerRow.getCell(5).font = boldFont;
        customerRow.getCell(5).alignment = { horizontal: 'right' };
        
        const customerNameRow = worksheet.getRow(footerStartRow + 1);
        customerNameRow.getCell(5).value = `Заказчик: ${sigs.customer.name}`; // Перенесено на 5-ю колонку
        customerNameRow.getCell(5).font = boldFont;
        customerNameRow.getCell(5).alignment = { horizontal: 'right' };
        
        const customerSignerRow = worksheet.getRow(footerStartRow + 3);
        customerSignerRow.getCell(5).value = `${sigs.customer.position} ${formatSigner(sigs.customer.signer)}`; // Перенесено на 5-ю колонку
        customerSignerRow.getCell(5).font = mainFont;
        customerSignerRow.getCell(5).alignment = { horizontal: 'right' };

        worksheet.pageSetup.printArea = `A1:G${footerStartRow + 4}`;
      } else {
        const compiledCell = worksheet.getCell(`D${footerStartRow}`);
        compiledCell.value = "Составил: _______________ /____________/";
        compiledCell.font = mainFont;

        const agreedCell = worksheet.getCell(`D${footerStartRow + 2}`);
        agreedCell.value = "Согласовал: _______________ /____________/";
        agreedCell.font = mainFont;

        worksheet.pageSetup.printArea = `A1:G${footerStartRow + 3}`;
      }
    }

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
