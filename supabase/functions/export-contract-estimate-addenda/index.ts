import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { encode } from "https://deno.land/std@0.208.0/encoding/base64.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import ExcelJS from "npm:exceljs@4.4.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, content-type, apikey, x-client-info",
};

const VIEW = "estimates_with_contracts";
const PAGE_SIZE = 1000;
const SHEET_NAME = "Смета";
const FONT_MAIN = { name: "Times New Roman", size: 11 } as const;

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

interface ContractRow {
  positionId: string;
  system: string;
  subsystem: string;
  number: string;
  name: string;
  article: string;
  manufacturer: string;
  unit: string;
  contractQuantity: number | null;
  contractPrice: number | null;
  contractTotal: number | null;
}

interface RevisionMeta {
  revisionId: string;
  revisionLabel: string;
}

function str(v: unknown): string {
  return v == null ? "" : String(v);
}

/** Как `_toDouble` во Flutter: null и ошибки парсинга → 0. */
function toNum(v: unknown): number {
  if (v == null) return 0;
  if (typeof v === "number" && !Number.isNaN(v)) return v;
  const s = String(v).replace(/,/g, ".");
  const n = parseFloat(s);
  return Number.isNaN(n) ? 0 : n;
}

function sanitizeFileNameComponent(name: string): string {
  return name.replace(/[\\/:*?"<>|]/g, "_").replace(/\s+/g, " ").trim();
}

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
  const { data: membership, error: mErr } = await supabase
    .from("company_members")
    .select("id")
    .eq("company_id", companyId)
    .eq("user_id", userData.user.id)
    .eq("is_active", true)
    .maybeSingle();
  if (mErr || !membership) {
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

function columnWidthForIndex(c1Based: number, revisionCount: number): number {
  const base = [38, 18, 22, 10, 52, 16, 16, 8, 14, 12, 16];
  if (c1Based <= base.length) {
    return base[c1Based - 1]!;
  }
  if (c1Based <= 11 + revisionCount * 2) {
    return c1Based % 2 === 0 ? 14 : 16;
  }
  return 12;
}

/** Буква столбца Excel (1 = A). */
function colLetter(col1Based: number): string {
  let n = col1Based;
  let s = "";
  while (n > 0) {
    const r = (n - 1) % 26;
    s = String.fromCharCode(65 + r) + s;
    n = Math.floor((n - 1) / 26);
  }
  return s;
}

function setNumOrEmpty(cell: ExcelJS.Cell, v: number | null) {
  if (v == null || Number.isNaN(v)) {
    cell.value = "";
  } else {
    cell.value = v;
  }
}

function appendDataRow(
  sheet: ExcelJS.Worksheet,
  row: ContractRow,
  revisions: RevisionMeta[],
  cellsByRevisionId: Map<string, Map<string, { quantity: number; total: number }>>,
) {
  const r = sheet.addRow([]);
  let c = 1;
  const setText = (v: string) => {
    r.getCell(c++).value = v;
  };
  setText(row.positionId);
  setText(row.system);
  setText(row.subsystem);
  setText(row.number);
  setText(row.name);
  setText(row.article);
  setText(row.manufacturer);
  setText(row.unit);
  setNumOrEmpty(r.getCell(c++), row.contractQuantity);
  setNumOrEmpty(r.getCell(c++), row.contractPrice);
  setNumOrEmpty(r.getCell(c++), row.contractTotal);

  for (const rev of revisions) {
    const cell = cellsByRevisionId.get(rev.revisionId)?.get(row.positionId);
    if (!cell) {
      r.getCell(c++).value = "";
      r.getCell(c++).value = "";
    } else {
      r.getCell(c++).value = cell.quantity;
      r.getCell(c++).value = cell.total;
    }
  }

  const totalCols = 11 + revisions.length * 2;
  const rn = r.number;
  for (let col = 1; col <= totalCols; col++) {
    const cell = sheet.getRow(rn).getCell(col);
    cell.border = borderThin;
    const isNum = col >= 9;
    cell.alignment = {
      vertical: "top",
      horizontal: isNum ? "right" : "left",
      wrapText: col === 5,
    };
    if (isNum && typeof cell.value === "number") {
      cell.numFmt = "#,##0.00";
    }
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ success: false, message: "Method not allowed" }, 405);
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
    const companyId = str(body.companyId).trim();
    const contractId = str(body.contractId).trim();
    const trimmedTitle = str(body.estimateTitle).trim();
    const objectIdRaw = body.objectId;
    const objectId = objectIdRaw != null && str(objectIdRaw).trim() !== ""
      ? str(objectIdRaw).trim()
      : null;

    if (!companyId) {
      throw new Error("Не задан companyId");
    }
    if (!contractId) {
      throw new Error("Не задан contractId");
    }
    if (!trimmedTitle) {
      throw new Error("Не задан заголовок сметы для выгрузки");
    }

    await ensureCompanyAccess(supabase, req, companyId);

    const { data: contractRow, error: contractErr } = await supabase
      .from("contracts")
      .select("number")
      .eq("id", contractId)
      .eq("company_id", companyId)
      .maybeSingle();

    if (contractErr) {
      throw contractErr;
    }
    const contractNoRaw = str(contractRow?.number).trim();
    const contractNo = contractNoRaw.length > 0 ? contractNoRaw : contractId;

    const contractMaps: Record<string, unknown>[] = [];
    let estOffset = 0;
    while (true) {
      let q = supabase
        .from(VIEW)
        .select(
          "position_id, system, subsystem, number, name, article, manufacturer, unit, quantity, price, total",
        )
        .eq("company_id", companyId)
        .eq("contract_id", contractId)
        .eq("estimate_title", trimmedTitle)
        .order("system", { ascending: true })
        .order("number", { ascending: true })
        .range(estOffset, estOffset + PAGE_SIZE - 1);

      if (objectId == null) {
        q = q.is("object_id", null);
      } else {
        q = q.eq("object_id", objectId);
      }

      const { data: chunk, error: estErr } = await q;
      if (estErr) {
        throw estErr;
      }
      const rows = chunk ?? [];
      if (rows.length === 0) {
        break;
      }
      contractMaps.push(...rows);
      if (rows.length < PAGE_SIZE) {
        break;
      }
      estOffset += PAGE_SIZE;
    }

    const { data: revAll, error: revErr } = await supabase
      .from("estimate_revisions")
      .select("id, revision_label, revision_type, revision_no, created_at")
      .eq("company_id", companyId)
      .eq("contract_id", contractId)
      .eq("estimate_title", trimmedTitle)
      .order("revision_no", { ascending: true });

    if (revErr) {
      throw revErr;
    }

    const allRevs = (revAll ?? []) as Record<string, unknown>[];
    let originalRevisionId: string | null = null;
    const revListAddenda: Record<string, unknown>[] = [];
    for (const r of allRevs) {
      const t = str(r.revision_type).trim();
      if (t === "original") {
        const oid = str(r.id).trim();
        if (oid) {
          originalRevisionId = oid;
        }
      } else if (t === "addendum") {
        revListAddenda.push(r);
      }
    }

    const revisionMetas: RevisionMeta[] = [];
    const addendumRevIds: string[] = [];
    for (const r of revListAddenda) {
      const id = str(r.id).trim();
      if (!id) {
        continue;
      }
      addendumRevIds.push(id);
      const labelRaw = str(r.revision_label).trim();
      revisionMetas.push({
        revisionId: id,
        revisionLabel: labelRaw.length > 0 ? labelRaw : "ДС",
      });
    }

    const revisionIdsForItems: string[] = [
      ...(originalRevisionId ? [originalRevisionId] : []),
      ...addendumRevIds,
    ];

    const itemsByRevision: Record<string, Record<string, unknown>[]> = {};
    for (const id of revisionIdsForItems) {
      itemsByRevision[id] = [];
    }

    if (revisionIdsForItems.length > 0) {
      const chunkSize = 40;
      for (let i = 0; i < revisionIdsForItems.length; i += chunkSize) {
        const slice = revisionIdsForItems.slice(
          i,
          i + chunkSize,
        );
        const { data: itemsResponse, error: itemsErr } = await supabase
          .from("estimate_revision_items")
          .select(
            "revision_id, position_id, quantity, total, change_type, system, subsystem, number, name, article, manufacturer, unit, price, row_no",
          )
          .eq("company_id", companyId)
          .in("revision_id", slice)
          .order("row_no", { ascending: true });

        if (itemsErr) {
          throw itemsErr;
        }
        for (const row of itemsResponse ?? []) {
          const m = row as Record<string, unknown>;
          const rid = str(m.revision_id).trim();
          if (!rid) {
            continue;
          }
          if (itemsByRevision[rid]) {
            itemsByRevision[rid].push(m);
          }
        }
      }
    }

    const baselineByPosition = new Map<string, Record<string, unknown>>();
    if (originalRevisionId) {
      for (const it of itemsByRevision[originalRevisionId] ?? []) {
        const pid = str(it.position_id).trim();
        if (pid) {
          baselineByPosition.set(pid, it);
        }
      }
    }

    const cellsByRevisionId = new Map<
      string,
      Map<string, { quantity: number; total: number }>
    >();
    for (const rid of addendumRevIds) {
      const inner = new Map<string, { quantity: number; total: number }>();
      cellsByRevisionId.set(rid, inner);
      for (const it of itemsByRevision[rid] ?? []) {
        const ct = str(it.change_type).trim();
        if (ct === "removed") {
          continue;
        }
        const pid = str(it.position_id).trim();
        if (!pid) {
          continue;
        }
        inner.set(pid, {
          quantity: toNum(it.quantity),
          total: toNum(it.total),
        });
      }
    }

    // Колонки «Договор»: из снимка ревизии «Основная». Если ревизия есть, а позиции в ней
    // не было (появилась только в позднем ДС), qty/total пустые — не брать из текущей сметы
    // (там уже пересчёт после ДС). Если ревизии «Основная» ещё нет — вся тройка из сметы.
    const hasOriginalRevision = Boolean(originalRevisionId);
    const contractRows: ContractRow[] = contractMaps.map((row) => {
      const pid = str(row.position_id);
      const base = baselineByPosition.get(pid);
      const contractQuantity =
        base != null
          ? toNum(base.quantity)
          : hasOriginalRevision
            ? null
            : toNum(row.quantity);
      const contractTotal =
        base != null
          ? toNum(base.total)
          : hasOriginalRevision
            ? null
            : toNum(row.total);
      return {
        positionId: pid,
        system: str(row.system),
        subsystem: str(row.subsystem),
        number: str(row.number),
        name: str(row.name),
        article: str(row.article),
        manufacturer: str(row.manufacturer),
        unit: str(row.unit),
        contractQuantity,
        contractPrice: base != null
          ? toNum(base.price)
          : hasOriginalRevision
            ? null
            : toNum(row.price),
        contractTotal,
      };
    });

    const inContract = new Set<string>();
    for (const r of contractRows) {
      if (r.positionId) {
        inContract.add(r.positionId);
      }
    }

    const allNonRemovedPositions = new Set<string>();
    for (const rid of addendumRevIds) {
      for (const it of itemsByRevision[rid] ?? []) {
        const ct = str(it.change_type).trim();
        if (ct === "removed") {
          continue;
        }
        const pid = str(it.position_id).trim();
        if (pid) {
          allNonRemovedPositions.add(pid);
        }
      }
    }

    const orphanIds = [...allNonRemovedPositions].filter((id) =>
      !inContract.has(id)
    );
    const revisionOnlyRows: ContractRow[] = [];

    function rowFromRevisionItem(
      it: Record<string, unknown>,
    ): ContractRow | null {
      const pid = str(it.position_id).trim();
      if (!pid) {
        return null;
      }
      const base = baselineByPosition.get(pid);
      return {
        positionId: pid,
        system: str(it.system),
        subsystem: str(it.subsystem),
        number: str(it.number),
        name: str(it.name),
        article: str(it.article),
        manufacturer: str(it.manufacturer),
        unit: str(it.unit),
        contractQuantity: base != null ? toNum(base.quantity) : null,
        contractPrice: base != null ? toNum(base.price) : toNum(it.price),
        contractTotal: base != null ? toNum(base.total) : null,
      };
    }

    for (const pid of orphanIds) {
      let picked: Record<string, unknown> | null = null;
      for (let ri = addendumRevIds.length - 1; ri >= 0; ri--) {
        const rid = addendumRevIds[ri];
        for (const it of itemsByRevision[rid] ?? []) {
          if (str(it.position_id) !== pid) {
            continue;
          }
          const ct = str(it.change_type).trim();
          if (ct === "removed") {
            continue;
          }
          picked = it;
          break;
        }
        if (picked != null) {
          break;
        }
      }
      if (picked != null) {
        const built = rowFromRevisionItem(picked);
        if (built != null) {
          revisionOnlyRows.push(built);
        }
      }
    }

    revisionOnlyRows.sort((a, b) => {
      const s = a.system.localeCompare(b.system, "ru");
      if (s !== 0) {
        return s;
      }
      return a.number.localeCompare(b.number, "ru");
    });

    if (contractRows.length === 0 && revisionOnlyRows.length === 0) {
      throw new Error("Нет строк сметы для выгрузки");
    }

    const header: string[] = [
      "ID позиции",
      "Система",
      "Подсистема",
      "№",
      "Наименование",
      "Артикул",
      "Производитель",
      "Ед. изм.",
      "Кол-во (договор)",
      "Цена",
      "Сумма (договор)",
    ];
    for (const _ of revisionMetas) {
      header.push("Кол-во", "Сумма");
    }
    const colCount = header.length;
    const revisionCount = revisionMetas.length;

    const workbook = new ExcelJS.Workbook();
    workbook.creator = "ProjectGT";
    workbook.created = new Date();

    const sheet = workbook.addWorksheet(SHEET_NAME, {
      views: [
        {
          state: "frozen",
          xSplit: 0,
          ySplit: 2,
          activeCell: "A3",
        },
      ],
    });

    sheet.columns = Array.from({ length: colCount }, (_, i) => ({
      width: columnWidthForIndex(i + 1, revisionCount),
    }));

    sheet.addRow([]);
    const top = sheet.getRow(1);
    top.getCell(1).value = "Позиция";
    sheet.mergeCells("A1:H1");
    top.getCell(9).value = "Договор";
    sheet.mergeCells("I1:K1");
    let dsCol = 12;
    for (const rev of revisionMetas) {
      const label = rev.revisionLabel.trim() === ""
        ? "ДС"
        : rev.revisionLabel.trim();
      top.getCell(dsCol).value = label;
      const c1 = colLetter(dsCol);
      const c2 = colLetter(dsCol + 1);
      sheet.mergeCells(`${c1}1:${c2}1`);
      dsCol += 2;
    }

    sheet.addRow(header);

    for (let hr = 1; hr <= 2; hr++) {
      const row = sheet.getRow(hr);
      row.height = hr === 1 ? 22 : 26;
      row.font = { ...FONT_MAIN, bold: true };
      for (let hc = 1; hc <= colCount; hc++) {
        const cell = row.getCell(hc);
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
    }
    for (const row of contractRows) {
      appendDataRow(sheet, row, revisionMetas, cellsByRevisionId);
    }
    for (const row of revisionOnlyRows) {
      appendDataRow(sheet, row, revisionMetas, cellsByRevisionId);
    }

    applySheetFont(sheet);
    const buffer = await workbook.xlsx.writeBuffer();
    const base64 = encode(new Uint8Array(buffer));
    const safeNo = sanitizeFileNameComponent(contractNo);
    const safeTitle = sanitizeFileNameComponent(trimmedTitle);
    const filename = `Смета_${safeNo}_${safeTitle}.xlsx`;

    return jsonResponse({
      success: true,
      filename,
      base64,
      rows: contractRows.length + revisionOnlyRows.length,
      message: "Excel со сметой и ДС сформирован",
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse({ success: false, message }, 500);
  }
});
