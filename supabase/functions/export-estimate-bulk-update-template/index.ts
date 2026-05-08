import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { encode } from "https://deno.land/std@0.208.0/encoding/base64.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import ExcelJS from "npm:exceljs@4.4.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info",
};

const SHEET_NAME = "Обновление сметы";
const FONT_MAIN = { name: "Times New Roman", size: 11 } as const;
const COL_COUNT = 13;

const HEADERS = [
  "ID строки",
  "ID позиции",
  "updated_at",
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
  contractId: string;
  estimateTitle: string;
  objectId?: string | null;
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
    if (!body.companyId || !body.contractId || !body.estimateTitle) {
      throw new Error("Нужны companyId, contractId и estimateTitle");
    }

    await ensureEstimateAccess(supabase, req, body);

    let query = supabase
      .from("estimates")
      .select(
        "id, position_id, updated_at, system, subsystem, number, name, article, manufacturer, unit, quantity, price, total",
      )
      .eq("company_id", body.companyId)
      .eq("contract_id", body.contractId)
      .eq("estimate_title", body.estimateTitle);

    if (body.objectId) {
      query = query.eq("object_id", body.objectId);
    } else {
      query = query.is("object_id", null);
    }

    const { data: rawRows, error } = await query
      .order("system", { ascending: true })
      .order("number", { ascending: true });

    if (error) throw error;

    const rows = (rawRows ?? []) as Record<string, unknown>[];
    if (rows.length === 0) {
      throw new Error("В выбранной смете нет строк для выгрузки");
    }

    const workbook = new ExcelJS.Workbook();
    workbook.creator = "ProjectGT";
    workbook.created = new Date();

    const sheet = workbook.addWorksheet(SHEET_NAME, {
      views: [{ state: "frozen", ySplit: 1, xSplit: 3 }],
    });

    sheet.addRow(HEADERS);
    sheet.columns = [
      { width: 38 },
      { width: 38 },
      { width: 30 },
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

    for (const e of rows) {
      const row = sheet.addRow([
        String(e["id"] ?? ""),
        String(e["position_id"] ?? ""),
        String(e["updated_at"] ?? ""),
        String(e["system"] ?? ""),
        String(e["subsystem"] ?? ""),
        String(e["number"] ?? ""),
        String(e["name"] ?? ""),
        String(e["article"] ?? ""),
        String(e["manufacturer"] ?? ""),
        String(e["unit"] ?? ""),
        toNum(e["quantity"]),
        toNum(e["price"]),
        null,
      ]);

      const rn = row.number;
      row.getCell(13).value = {
        formula: `K${rn}*L${rn}`,
        result: toNum(e["total"]),
      };

      for (let c = 1; c <= COL_COUNT; c++) {
        const cell = row.getCell(c);
        cell.border = borderThin;
        cell.alignment = {
          vertical: "top",
          horizontal: c >= 11 ? "right" : "left",
          wrapText: c === 7,
        };
      }
      row.getCell(11).numFmt = "#,##0.00";
      row.getCell(12).numFmt = "#,##0.00";
      row.getCell(13).numFmt = "#,##0.00";
    }

    applySheetFont(sheet);

    const buffer = await workbook.xlsx.writeBuffer();
    const file = encode(new Uint8Array(buffer));
    const filename = `Обновление_сметы_${sanitizeFilenamePart(body.estimateTitle)}_${todayRu()}.xlsx`;

    return new Response(JSON.stringify({ file, filename }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("[export-estimate-bulk-update-template]", e);
    return jsonError(message, 400);
  }
});

async function ensureEstimateAccess(
  supabase: ReturnType<typeof createClient>,
  req: Request,
  body: Body,
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

  const { data: contract, error: contractErr } = await supabase
    .from("contracts")
    .select("id, company_id, object_id")
    .eq("id", body.contractId)
    .eq("company_id", body.companyId)
    .maybeSingle();
  if (contractErr || !contract) {
    throw new Error("Договор не найден или нет доступа");
  }
  if (body.objectId && contract.object_id !== body.objectId) {
    throw new Error("Договор не относится к выбранному объекту");
  }

  const { data: membership, error: membershipErr } = await supabase
    .from("company_members")
    .select("id, is_owner, is_active")
    .eq("company_id", body.companyId)
    .eq("user_id", userData.user.id)
    .eq("is_active", true)
    .maybeSingle();
  if (membershipErr || !membership) {
    throw new Error("Нет доступа к выбранной компании");
  }

  if (membership.is_owner) return;

  const { data: profile, error: profileErr } = await supabase
    .from("profiles")
    .select("object_ids")
    .eq("id", userData.user.id)
    .maybeSingle();
  if (profileErr) throw profileErr;

  const allowedObjects = Array.isArray(profile?.object_ids)
    ? profile.object_ids
    : [];
  const objectId = body.objectId ?? contract.object_id;
  if (!objectId || !allowedObjects.includes(objectId)) {
    throw new Error("Нет доступа к объекту выбранной сметы");
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

function toNum(v: unknown): number {
  if (v == null) return 0;
  if (typeof v === "number" && !Number.isNaN(v)) return v;
  const n = parseFloat(String(v).replace(",", "."));
  return Number.isNaN(n) ? 0 : n;
}

function sanitizeFilenamePart(s: string): string {
  return s.replace(/[\\/:*?"<>|]/g, "_").replace(/\s+/g, "_").trim() ||
    "смета";
}

function todayRu(): string {
  const d = new Date();
  const dd = String(d.getDate()).padStart(2, "0");
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  return `${dd}.${mm}.${d.getFullYear()}`;
}
