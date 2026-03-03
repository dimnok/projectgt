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

    const { vorId } = await req.json();

    if (!vorId) {
      throw new Error("Не указан vorId");
    }

    // 1. Получаем заголовок ВОР и данные контракта/объекта
    const { data: vor, error: vorError } = await supabase
      .from("vors")
      .select(`
        *,
        excel_url,
        contracts (
          *,
          objects (*)
        )
      `)
      .eq("id", vorId)
      .single();

    if (vorError) throw vorError;
    if (!vor) throw new Error("Ведомость не найдена");

    // Если файл уже сгенерирован, возвращаем его путь
    if (vor.excel_url) {
      const { data: fileData, error: downloadError } = await supabase.storage
        .from("vor_documents")
        .download(vor.excel_url);

      if (!downloadError && fileData) {
        const buffer = await fileData.arrayBuffer();
        const base64File = encode(new Uint8Array(buffer));
        return new Response(JSON.stringify({ 
          file: base64File,
          filename: `ВОР_${vor.number}.xlsx`,
          url: vor.excel_url
        }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    const contract = vor.contracts;
    const object = contract?.objects;

    // 2. Получаем позиции ВОР
    const { data: items, error: itemsError } = await supabase
      .from("vor_items")
      .select(`
        *,
        estimates (
          number,
          system,
          material_aliases (
            alias_raw
          )
        )
      `)
      .eq("vor_id", vorId)
      .order("sort_order", { ascending: true });

    if (itemsError) throw itemsError;

    // 3. Генерация Excel
    const workbook = new ExcelJS.Workbook();
    
    // Получаем уникальные системы из позиций
    const systems = [...new Set(items.map(item => item.estimates?.system || "Без системы"))];

    for (const systemName of systems) {
      const sheetTitle = systemName.substring(0, 31);
      const worksheet = workbook.addWorksheet(sheetTitle, {
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

      // Настройка колонок
      worksheet.getColumn(1).width = 7;   // № п/п
      worksheet.getColumn(2).width = 10;  // № по ЛСР
      worksheet.getColumn(3).width = 45;  // Наименование работ
      worksheet.getColumn(4).width = 45;  // Материал (накладная)
      worksheet.getColumn(5).width = 10;  // Ед. изм.
      worksheet.getColumn(6).width = 10;  // Кол-во

      const mainFont = { name: 'PT Serif', size: 10 };
      const boldFont = { name: 'PT Serif', size: 10, bold: true };

      // Шапка документа
      const headerInfoFont = { name: 'PT Serif', size: 11, bold: true };
      const headerInfoAlignmentLeft = { horizontal: "left" as const, vertical: "middle" as const, wrapText: true };
      const headerInfoAlignmentRight = { horizontal: "right" as const, vertical: "middle" as const };

      // Объект
      worksheet.mergeCells('B1:F1');
      worksheet.getCell("B1").value = object?.name || "—";
      worksheet.getCell("A1").value = "Объект:";
      
      // Адрес
      worksheet.mergeCells('B3:F3');
      worksheet.getCell("B3").value = object?.address || "—";
      worksheet.getCell("A3").value = "Адрес:";

      // Договор
      worksheet.mergeCells('B5:F5');
      const contractInfo = `№ ${contract?.number || "б/н"} от ${contract?.date ? new Date(contract.date).toLocaleDateString("ru-RU") : "—"}`;
      worksheet.getCell("B5").value = contractInfo;
      worksheet.getCell("A5").value = "Договор:";

      // Период
      worksheet.mergeCells('B7:F7');
      const periodText = `${new Date(vor.start_date).toLocaleDateString("ru-RU")} - ${new Date(vor.end_date).toLocaleDateString("ru-RU")}`;
      worksheet.getCell("B7").value = periodText;
      worksheet.getCell("A7").value = "Период:";

      // Стилизация шапки
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

      // Заголовок таблицы
      const titleCell = worksheet.getCell('A9');
      worksheet.mergeCells('A9:F9');
      titleCell.value = `ВЕДОМОСТЬ ОБЪЁМОВ РАБОТ (${systemName.toUpperCase()})`;
      titleCell.font = { name: 'PT Serif', size: 14, bold: true };
      titleCell.alignment = { horizontal: 'center', vertical: 'middle' };

      // Заголовки колонок
      const headers = ["№ п/п", "№ по ЛСР", "Наименование работ", "Материал (накладная)", "Ед. изм.", "Кол-во"];
      const headerRow = worksheet.getRow(11);
      headerRow.height = 30;
      headers.forEach((h, i) => {
        const cell = headerRow.getCell(i + 1);
        cell.value = h;
        cell.font = boldFont;
        cell.alignment = { horizontal: "center", vertical: "middle", wrapText: true };
        cell.border = { top: { style: "thin" }, left: { style: "thin" }, bottom: { style: "thin" }, right: { style: "thin" } };
      });

      // Рендеринг строк для текущей системы
      let currentRowIdx = 12;
      let rowCounter = 1;

      const systemItems = items.filter(i => (i.estimates?.system || "Без системы") === systemName);
      const normalItems = systemItems.filter(i => !i.is_extra);
      const extraItems = systemItems.filter(i => i.is_extra);

      const sortFn = (a: any, b: any) => {
        const lsrA = a.estimates?.number || "";
        const lsrB = b.estimates?.number || "";
        const lsrCompare = lsrA.localeCompare(lsrB, 'ru', { numeric: true });
        if (lsrCompare !== 0) return lsrCompare;
        return a.name.localeCompare(b.name);
      };

      const renderRows = (rowList: any[]) => {
        rowList.sort(sortFn).forEach((item) => {
          const row = worksheet.getRow(currentRowIdx);
          row.getCell(1).value = rowCounter++;
          row.getCell(2).value = item.estimates?.number || "—";
          row.getCell(3).value = item.name;
          
          // Материалы
          const aliases = item.estimates?.material_aliases || [];
          row.getCell(4).value = [...new Set(aliases.map((a: any) => a.alias_raw))].join(', ');
          
          row.getCell(5).value = item.unit;
          row.getCell(6).value = item.quantity;

          for (let i = 1; i <= 6; i++) {
            const cell = row.getCell(i);
            cell.font = mainFont;
            cell.border = { top: { style: "thin" }, left: { style: "thin" }, bottom: { style: "thin" }, right: { style: "thin" } };
            cell.alignment = { vertical: 'top', wrapText: true };
          }
          row.getCell(1).alignment = { horizontal: 'center', vertical: 'top' };
          row.getCell(2).alignment = { horizontal: 'center', vertical: 'top' };
          row.getCell(5).alignment = { horizontal: 'center', vertical: 'top' };
          row.getCell(6).alignment = { horizontal: 'right', vertical: 'top' };
          
          currentRowIdx++;
        });
      };

      if (normalItems.length > 0) {
        renderRows(normalItems);
      }

      if (extraItems.length > 0) {
        // Разделитель для превышений
        const sepRow = worksheet.getRow(currentRowIdx);
        worksheet.mergeCells(`A${currentRowIdx}:F${currentRowIdx}`);
        sepRow.getCell(1).value = "ПРЕВЫШЕНИЕ ОБЪЕМОВ И ДОПОЛНИТЕЛЬНЫЕ РАБОТЫ";
        sepRow.getCell(1).font = boldFont;
        sepRow.getCell(1).alignment = { horizontal: "center", vertical: "middle" };
        sepRow.getCell(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFEEEEEE' } };
        sepRow.height = 25;
        currentRowIdx++;
        
        renderRows(extraItems);
      }

      // Подписи
      const footerStartRow = currentRowIdx + 2;
      const sigs = {
        contractor: {
          name: contract?.contractor_legal_name || '—',
          position: contract?.contractor_position || 'Подрядчик',
          signer: contract?.contractor_signer || '________________'
        },
        customer: {
          name: contract?.customer_legal_name || '—',
          position: contract?.customer_position || 'Заказчик',
          signer: contract?.customer_signer || '________________'
        }
      };

      const contractorRow = worksheet.getRow(footerStartRow);
      contractorRow.getCell(1).value = "Подготовил:";
      contractorRow.getCell(1).font = boldFont;
      worksheet.getRow(footerStartRow + 1).getCell(1).value = sigs.contractor.name;
      worksheet.getRow(footerStartRow + 2).getCell(1).value = `${sigs.contractor.position}: ${sigs.contractor.signer}`;

      const customerRow = worksheet.getRow(footerStartRow);
      customerRow.getCell(4).value = "Согласовал:";
      customerRow.getCell(4).font = boldFont;
      worksheet.getRow(footerStartRow + 1).getCell(4).value = sigs.customer.name;
      worksheet.getRow(footerStartRow + 2).getCell(4).value = `${sigs.customer.position}: ${sigs.customer.signer}`;
    }

    const buffer = await workbook.xlsx.writeBuffer();
    
    // Функция для транслитерации и очистки имен для путей в Storage
    const slugify = (text: string) => {
      const map: Record<string, string> = {
        'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo', 'ж': 'zh',
        'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n', 'о': 'o',
        'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u', 'ф': 'f', 'х': 'kh', 'ц': 'ts',
        'ч': 'ch', 'ш': 'sh', 'щ': 'shch', 'ъ': '', 'ы': 'y', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya'
      };
      return text.toLowerCase().split('').map(char => map[char] || char).join('')
        .replace(/[^a-z0-9]/g, '_')
        .replace(/_+/g, '_')
        .trim();
    };

    const objectSlug = slugify(object?.name || "object");
    const vorNumberSlug = slugify(vor.number).replace(/^vor_/, ''); // Убираем префикс vor_, если он есть
    const fileName = `${vorNumberSlug}_${Date.now()}.xlsx`;
    const filePath = `${objectSlug}/${fileName}`;

    // Загружаем файл в Storage
    const { error: uploadError } = await supabase.storage
      .from("vor_documents")
      .upload(filePath, buffer, {
        contentType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        upsert: true
      });

    if (uploadError) {
      console.error("Ошибка загрузки в Storage:", uploadError);
    } else {
      // Обновляем запись в БД
      await supabase
        .from("vors")
        .update({ excel_url: filePath })
        .eq("id", vorId);
    }

    const base64File = encode(new Uint8Array(buffer));

    return new Response(JSON.stringify({ 
      file: base64File,
      filename: `ВОР_${vor.number}_${object?.name || ""}.xlsx`,
      url: filePath
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
