import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { encode } from "https://deno.land/std@0.208.0/encoding/base64.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import ExcelJS from "npm:exceljs@4.4.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info",
};

const SHEET_NAME = "Смета";
const FONT_MAIN = { name: "Times New Roman", size: 11 } as const;
const COL_COUNT = 10;

const HEADERS = [
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
];

const borderThin = {
  top: { style: "thin" as const, color: { argb: "FF000000" } },
  left: { style: "thin" as const, color: { argb: "FF000000" } },
  bottom: { style: "thin" as const, color: { argb: "FF000000" } },
  right: { style: "thin" as const, color: { argb: "FF000000" } },
};

interface Body {
  companyId: string;
  /** Если указан — в имя файла подставляется номер договора (после проверки доступа). */
  contractId?: string | null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("Missing Supabase environment variables");
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const body = (await req.json()) as Body;
    if (!body.companyId) {
      throw new Error("Нужен companyId");
    }

    await ensureCompanyAccess(supabase, req, body.companyId);

    const contractNumber = await resolveContractNumberForFilename(
      supabase,
      body.companyId,
      body.contractId,
    );

    const workbook = new ExcelJS.Workbook();
    workbook.creator = "ProjectGT";
    workbook.created = new Date();

    const sheet = workbook.addWorksheet(SHEET_NAME, {
      views: [{ state: "frozen", ySplit: 1 }],
    });

    sheet.addRow(HEADERS);
    sheet.columns = [
      { width: 18 },
      { width: 22 },
      { width: 10 },
      { width: 70 },
      { width: 18 },
      { width: 18 },
      { width: 10 },
      { width: 12 },
      { width: 14 },
      { width: 16 },
    ];

    const headerRow = sheet.getRow(1);
    headerRow.height = 28;
    headerRow.font = { ...FONT_MAIN, bold: true };
    for (let c = 1; c <= COL_COUNT; c++) {
      const cell = headerRow.getCell(c);
      cell.alignment = {
        vertical: "middle",
        horizontal: "center",
        wrapText: true,
      };
      cell.border = borderThin;
      cell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "FFF0F0F0" },
      };
    }

    const example = sheet.addRow([
      "Система 1",
      "Подсистема 1",
      1,
      "Товар",
      "A-123",
      "ООО Рога",
      "шт",
      10,
      100,
      null,
    ]);
    const rn = example.number;
    example.getCell(10).value = {
      formula: `H${rn}*I${rn}`,
      result: 1000,
    };

    for (let c = 1; c <= COL_COUNT; c++) {
      const cell = example.getCell(c);
      cell.border = borderThin;
      cell.alignment = {
        vertical: "top",
        horizontal: c >= 8 ? "right" : "left",
        wrapText: c === 4,
      };
    }
    example.getCell(8).numFmt = "#,##0.00";
    example.getCell(9).numFmt = "#,##0.00";
    example.getCell(10).numFmt = "#,##0.00";

    applySheetFont(sheet);

    const buffer = await workbook.xlsx.writeBuffer();
    const file = encode(new Uint8Array(buffer));
    const filename = buildTemplateFilename(contractNumber);

    return new Response(JSON.stringify({ file, filename }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("[generate-estimate-import-template]", e);
    return jsonError(message, 400);
  }
});

async function resolveContractNumberForFilename(
  supabase: ReturnType<typeof createClient>,
  companyId: string,
  contractId: string | null | undefined,
): Promise<string | null> {
  const id = typeof contractId === "string" ? contractId.trim() : "";
  if (!id) return null;

  const { data, error } = await supabase
    .from("contracts")
    .select("number")
    .eq("id", id)
    .eq("company_id", companyId)
    .maybeSingle();

  if (error) throw error;
  if (!data?.number) return null;
  return String(data.number);
}

function buildTemplateFilename(contractNumber: string | null): string {
  const date = todayRu();
  if (contractNumber != null && contractNumber.trim()) {
    return `Шаблон_сметы_${sanitizeFilenamePart(contractNumber)}_${date}.xlsx`;
  }
  return `Шаблон_сметы_${date}.xlsx`;
}

function sanitizeFilenamePart(s: string): string {
  return s.replace(/[\\/:*?"<>|]/g, "_").replace(/\s+/g, "_").trim() ||
    "договор";
}

async function ensureCompanyAccess(
  supabase: ReturnType<typeof createClient>,
  req: Request,
  companyId: string,
) {
  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "")
    .trim();
  if (!token) {
    throw new Error("Нужен токен Authorization");
  }

  const { data: userData, error: userError } = await supabase.auth.getUser(
    token,
  );
  if (userError || !userData.user) {
    throw new Error("Не удалось определить пользователя");
  }

  const { data: membership, error: membershipErr } = await supabase
    .from("company_members")
    .select("id, is_active")
    .eq("company_id", companyId)
    .eq("user_id", userData.user.id)
    .eq("is_active", true)
    .maybeSingle();
  if (membershipErr || !membership) {
    throw new Error("Нет доступа к выбранной компании");
  }
}

function applySheetFont(sheet: ExcelJS.Worksheet) {
  sheet.eachRow({ includeEmpty: true }, (row) => {
    row.eachCell({ includeEmpty: true }, (cell) => {
      const f = cell.font;
      cell.font = {
        name: FONT_MAIN.name,
        size: f?.size ?? FONT_MAIN.size,
        bold: f?.bold,
        italic: f?.italic,
        color: f?.color,
      };
    });
  });
}

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function todayRu(): string {
  const d = new Date();
  const dd = String(d.getDate()).padStart(2, "0");
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  return `${dd}.${mm}.${d.getFullYear()}`;
}
