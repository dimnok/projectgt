import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { encode } from "https://deno.land/std@0.208.0/encoding/base64.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import ExcelJS from "npm:exceljs@4.4.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info",
};

const borderStyle = {
  top: { style: "thin" as const, color: { argb: "FF000000" } },
  left: { style: "thin" as const, color: { argb: "FF000000" } },
  bottom: { style: "thin" as const, color: { argb: "FF000000" } },
  right: { style: "thin" as const, color: { argb: "FF000000" } },
};

const STATUS_LABELS: Record<string, string> = {
  working: "Работает",
  vacation: "Отпуск",
  sickLeave: "Больничный",
  unpaidLeave: "Без содержания",
  fired: "Уволен",
};

const EMPLOYMENT_LABELS: Record<string, string> = {
  official: "Официально",
  unofficial: "Неофициально",
  contractor: "Подрядчик",
};

interface ObjectFilterBody {
  kind?: string;
  objectId?: string;
}

interface ExportEmployeesRequest {
  companyId: string;
  /** Совпадает с JSON enum EmployeeStatus в приложении (`sickLeave` и т.д.). Пусто/null — все статусы. */
  status?: string | null;
  objectFilter?: ObjectFilterBody;
  searchQuery?: string | null;
}

interface EmployeeRow {
  id: string;
  last_name: string;
  first_name: string;
  middle_name: string | null;
  birth_date: string | null;
  birth_place: string | null;
  citizenship: string | null;
  phone: string | null;
  clothing_size: string | null;
  shoe_size: string | null;
  height: string | null;
  employment_date: string | null;
  employment_type: string;
  position: string | null;
  status: string;
  object_ids: string[] | null;
  passport_series: string | null;
  passport_number: string | null;
  passport_issued_by: string | null;
  passport_issue_date: string | null;
  passport_department_code: string | null;
  registration_address: string | null;
  inn: string | null;
  snils: string | null;
  current_hourly_rate?: number | null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ success: false, message: "Method not allowed" }, 405);
  }

  try {
    const request = (await req.json()) as ExportEmployeesRequest;
    if (!request.companyId) {
      throw new Error("companyId is required");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("Missing Supabase environment variables");
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });
    await ensureCompanyAccess(supabase, req, request.companyId);

    const rawEmployees = await loadEmployees(supabase, request.companyId);
    const ratesMap = await loadCurrentRatesMap(supabase, request.companyId);
    const objects = await loadObjects(supabase, request.companyId);
    const objectNameById = new Map(objects.map((o: { id: string; name: string }) => [o.id, o.name]));

    let employees: EmployeeRow[] = rawEmployees.map((row) => ({
      ...row,
      object_ids: Array.isArray(row.object_ids) ? row.object_ids as string[] : [],
      current_hourly_rate: ratesMap.get(String(row.id)) ?? null,
    }));

    const search = (request.searchQuery ?? "").trim().toLowerCase();
    if (search.length > 0) {
      employees = employees.filter((e) => matchesSearch(e, search));
    }

    const statusFilter = request.status?.trim();
    if (statusFilter) {
      employees = employees.filter((e) => e.status === statusFilter);
    }

    const objFilter = request.objectFilter ?? { kind: "all" };
    employees = employees.filter((e) => applyObjectFilter(e, objFilter));

    employees.sort((a, b) =>
      (a.last_name || "").localeCompare(b.last_name || "", "ru", { sensitivity: "base" })
    );

    if (employees.length === 0) {
      return jsonResponse({
        success: false,
        message: "Нет данных для экспорта по выбранным фильтрам",
      });
    }

    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet("Сотрудники", {
      views: [{ state: "frozen", ySplit: 1 }],
    });

    const headers = [
      "ФИО",
      "Должность",
      "Статус",
      "Тип занятости",
      "Дата приема",
      "Объекты",
      "Текущая ставка",
      "Телефон",
      "Дата рождения",
      "Место рождения",
      "Гражданство",
      "Размер одежды",
      "Размер обуви",
      "Рост",
      "Паспорт (Серия и номер)",
      "Кем выдан",
      "Дата выдачи",
      "Код подразделения",
      "Адрес регистрации",
      "ИНН",
      "СНИЛС",
    ];

    const headerRow = sheet.addRow(headers);
    headerRow.font = { bold: true, size: 11 };
    headerRow.alignment = { horizontal: "center", vertical: "middle", wrapText: true };
    headerRow.height = 28;
    headerRow.eachCell((cell) => {
      cell.border = borderStyle;
      cell.fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "FFF2F2F2" },
      };
    });

    for (const emp of employees) {
      const fullName = buildFullName(emp);
      const statusText = STATUS_LABELS[emp.status] ?? emp.status;
      const employmentText = EMPLOYMENT_LABELS[emp.employment_type] ?? emp.employment_type;
      const objectNames = (emp.object_ids ?? [])
        .map((id) => objectNameById.get(id))
        .filter((n): n is string => Boolean(n))
        .join(", ");

      const passportCombined = `${emp.passport_series ?? ""} ${emp.passport_number ?? ""}`.trim();

      const row = sheet.addRow([
        fullName,
        emp.position ?? "",
        statusText,
        employmentText,
        formatRuDateOnly(emp.employment_date),
        objectNames,
        emp.current_hourly_rate != null ? formatCurrency(emp.current_hourly_rate) : "",
        emp.phone ?? "",
        formatRuDateOnly(emp.birth_date),
        emp.birth_place ?? "",
        emp.citizenship ?? "",
        emp.clothing_size ?? "",
        emp.shoe_size ?? "",
        emp.height ?? "",
        passportCombined,
        emp.passport_issued_by ?? "",
        formatRuDateOnly(emp.passport_issue_date),
        emp.passport_department_code ?? "",
        emp.registration_address ?? "",
        emp.inn ?? "",
        emp.snils ?? "",
      ]);

      row.eachCell((cell) => {
        cell.border = borderStyle;
        cell.alignment = { vertical: "middle", wrapText: true };
      });
      row.getCell(7).alignment = { horizontal: "right", vertical: "middle", wrapText: true };
    }

    sheet.columns = [
      { width: 28 },
      { width: 18 },
      { width: 14 },
      { width: 14 },
      { width: 12 },
      { width: 32 },
      { width: 16 },
      { width: 18 },
      { width: 12 },
      { width: 20 },
      { width: 14 },
      { width: 12 },
      { width: 10 },
      { width: 8 },
      { width: 18 },
      { width: 28 },
      { width: 12 },
      { width: 12 },
      { width: 36 },
      { width: 14 },
      { width: 16 },
    ];

    const buffer = await workbook.xlsx.writeBuffer();
    const base64 = encode(new Uint8Array(buffer));
    const filename = `Сотрудники_${todayRuForFilename()}.xlsx`;

    return jsonResponse({
      success: true,
      filename,
      base64,
      rows: employees.length,
      message: "Excel-файл успешно сформирован",
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse({ success: false, message }, 500);
  }
});

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function ensureCompanyAccess(
  supabase: ReturnType<typeof createClient>,
  req: Request,
  companyId: string,
) {
  const authHeader = req.headers.get("Authorization");
  const token = authHeader?.replace(/^Bearer\s+/i, "").trim();

  if (!token) {
    throw new Error("Authorization token is required");
  }

  const { data: userData, error: userError } = await supabase.auth.getUser(token);
  if (userError || !userData.user) {
    throw new Error("Не удалось определить пользователя");
  }

  const { data: membership, error: membershipError } = await supabase
    .from("company_members")
    .select("id")
    .eq("company_id", companyId)
    .eq("user_id", userData.user.id)
    .eq("is_active", true)
    .maybeSingle();

  if (membershipError || !membership) {
    throw new Error("Нет доступа к выбранной компании");
  }
}

async function loadEmployees(
  supabase: ReturnType<typeof createClient>,
  companyId: string,
): Promise<EmployeeRow[]> {
  const { data, error } = await supabase
    .from("employees")
    .select(
      "id, last_name, first_name, middle_name, birth_date, birth_place, citizenship, phone, clothing_size, shoe_size, height, employment_date, employment_type, position, status, object_ids, passport_series, passport_number, passport_issued_by, passport_issue_date, passport_department_code, registration_address, inn, snils",
    )
    .eq("company_id", companyId);

  if (error) throw error;
  return (data ?? []) as EmployeeRow[];
}

async function loadCurrentRatesMap(
  supabase: ReturnType<typeof createClient>,
  companyId: string,
): Promise<Map<string, number>> {
  const map = new Map<string, number>();
  const { data, error } = await supabase
    .from("employee_rates")
    .select("employee_id, hourly_rate")
    .eq("company_id", companyId)
    .is("valid_to", null);

  if (error) {
    console.error("employee_rates load:", error);
    return map;
  }

  for (const row of data ?? []) {
    const id = row.employee_id as string;
    const rate = row.hourly_rate as number | null;
    if (rate != null) {
      map.set(id, Number(rate));
    }
  }
  return map;
}

async function loadObjects(supabase: ReturnType<typeof createClient>, companyId: string) {
  const { data, error } = await supabase.from("objects").select("id, name").eq("company_id", companyId);
  if (error) throw error;
  return data ?? [];
}

function buildFullName(emp: EmployeeRow): string {
  return [emp.last_name, emp.first_name, emp.middle_name]
    .filter((v) => v && String(v).trim().length > 0)
    .join(" ");
}

function matchesSearch(emp: EmployeeRow, query: string): boolean {
  const fullName = `${emp.last_name} ${emp.first_name} ${emp.middle_name ?? ""}`.toLowerCase();
  const position = (emp.position ?? "").toLowerCase();
  const phone = (emp.phone ?? "").toLowerCase();
  return fullName.includes(query) || position.includes(query) || phone.includes(query);
}

function applyObjectFilter(emp: EmployeeRow, filter: ObjectFilterBody): boolean {
  const kind = filter.kind ?? "all";
  const ids = emp.object_ids ?? [];
  switch (kind) {
    case "unassigned":
      return ids.length === 0;
    case "object": {
      const oid = filter.objectId;
      return Boolean(oid && ids.includes(oid));
    }
    case "all":
    default:
      return true;
  }
}

function formatRuDateOnly(iso: string | undefined | null): string {
  if (!iso) return "";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  return d.toLocaleDateString("ru-RU", { day: "2-digit", month: "2-digit", year: "numeric" });
}

function formatCurrency(value: number): string {
  return new Intl.NumberFormat("ru-RU", {
    style: "currency",
    currency: "RUB",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
}

/** Дата формирования файла в формате `dd.MM.yyyy` (как `formatRuDate` на клиенте). */
function todayRuForFilename(): string {
  const d = new Date();
  const dd = String(d.getDate()).padStart(2, "0");
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const yyyy = d.getFullYear();
  return `${dd}.${mm}.${yyyy}`;
}
