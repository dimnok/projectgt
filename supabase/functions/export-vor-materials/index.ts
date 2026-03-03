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

    const { vorId, companyId } = await req.json();

    if (!vorId || !companyId) {
      throw new Error("Не указаны vorId или companyId");
    }

    // 1. Получаем данные отчета из нашей новой SQL функции
    const { data: reportRows, error: reportError } = await supabase
      .rpc("get_vor_material_report", {
        p_company_id: companyId,
        p_vor_id: vorId
      });

    if (reportError) {
      console.error("SQL Error:", reportError);
      throw reportError;
    }

    // 2. Получаем инфо о ВОР для названия файла
    const { data: vor } = await supabase
      .from("vors")
      .select("number")
      .eq("id", vorId)
      .single();

    // 3. Генерация Excel
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet("Списание материалов");

    // Настройка колонок (Добавлен № п/п)
    worksheet.columns = [
      { header: "№ п/п", key: "index", width: 7 },
      { header: "Материал (из накладной)", key: "material_name", width: 40 },
      { header: "Связанные работы", key: "related_works", width: 50 },
      { header: "Ед. изм.", key: "unit", width: 10 },
      { header: "Кол-во по накладной", key: "batch_quantity", width: 18 },
      { header: "Цена", key: "price", width: 12 },
      { header: "Стоимость", key: "total", width: 15 },
      { header: "№ накладной", key: "receipt_number", width: 15 },
      { header: "Дата накладной", key: "receipt_date", width: 15 },
      { header: "Использовано в ВОР (смета)", key: "used_in_vor", width: 18 },
      { header: "Остаток", key: "remaining_after_vor", width: 12 },
    ];

    // Стилизация шапки
    worksheet.getRow(1).font = { bold: true };
    worksheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center', wrapText: true };
    worksheet.getRow(1).height = 30;

    // Добавление данных с порядковым номером
    reportRows.forEach((row: any, idx: number) => {
      worksheet.addRow({
        ...row,
        index: idx + 1,
        receipt_date: row.receipt_date ? new Date(row.receipt_date).toLocaleDateString("ru-RU") : ""
      });
    });

    // Границы и выравнивание для всех строк
    worksheet.eachRow((row, rowNumber) => {
      row.eachCell((cell) => {
        cell.border = {
          top: { style: 'thin' },
          left: { style: 'thin' },
          bottom: { style: 'thin' },
          right: { style: 'thin' }
        };
        if (rowNumber > 1) {
          cell.alignment = { vertical: 'top', wrapText: true };
        }
      });
      if (rowNumber > 1) {
        row.getCell(1).alignment = { horizontal: 'center', vertical: 'top' };
      }
    });

    // Числовые форматы (Сдвинуты на 1 колонку вправо из-за новой колонки № п/п)
    worksheet.eachRow((row, rowNumber) => {
      if (rowNumber > 1) {
        row.getCell(5).numFmt = '#,##0.000'; // E: batch_quantity
        row.getCell(6).numFmt = '#,##0.00';  // F: price
        row.getCell(7).numFmt = '#,##0.00';  // G: total
        row.getCell(10).numFmt = '#,##0.000'; // J: used_in_vor
        row.getCell(11).numFmt = '#,##0.000'; // K: remaining_after_vor
      }
    });

    const buffer = await workbook.xlsx.writeBuffer();
    const base64File = encode(new Uint8Array(buffer));

    return new Response(JSON.stringify({ 
      file: base64File,
      filename: `Отчет_по_материалам_${vor?.number || "ВОР"}.xlsx`
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
