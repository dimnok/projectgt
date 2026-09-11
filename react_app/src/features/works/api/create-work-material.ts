import { createEstimateItem } from "@/features/estimates/api/create-estimate-item";
import type { WorkEstimateOption } from "@/features/works/api/get-work-item-catalog";
import { nextWorkMaterialNumber } from "@/features/works/utils/work-material-number";
import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";

const PAGE_SIZE = 1000;

export type WorkMaterialTitleOption = {
  title: string;
  contractId: string | null;
};

export type WorkMaterialContext = {
  titles: WorkMaterialTitleOption[];
  fallbackTitle: string | null;
  fallbackContractId: string | null;
};

export type CreateWorkMaterialInput = {
  objectId: string;
  system: string;
  subsystem: string;
  estimateTitle: string | null;
  name: string;
  article: string;
  manufacturer: string;
  unit: string;
};

type EstimateMetaRow = {
  estimate_title: string | null;
  contract_id: string | null;
  number: string | number | null;
  system: string | null;
  subsystem: string | null;
};

function uniqueTitles(rows: EstimateMetaRow[]): WorkMaterialTitleOption[] {
  const byTitle = new Map<string, string | null>();
  for (const row of rows) {
    const title = row.estimate_title?.trim() ?? "";
    if (!title || byTitle.has(title)) {
      continue;
    }
    byTitle.set(title, row.contract_id);
  }
  return [...byTitle.entries()]
    .map(([title, contractId]) => ({ title, contractId }))
    .sort((a, b) => a.title.localeCompare(b.title, "ru"));
}

async function loadObjectEstimateMeta(
  objectId: string
): Promise<EstimateMetaRow[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const all: EstimateMetaRow[] = [];
  let offset = 0;

  while (true) {
    const { data, error } = await client
      .from("estimates")
      .select("estimate_title, contract_id, number, system, subsystem")
      .eq("company_id", companyId)
      .eq("object_id", objectId)
      .order("id")
      .range(offset, offset + PAGE_SIZE - 1);

    if (error) {
      throw new Error(error.message);
    }

    const chunk = (data ?? []) as EstimateMetaRow[];
    all.push(...chunk);
    if (chunk.length < PAGE_SIZE) {
      break;
    }
    offset += PAGE_SIZE;
  }

  return all;
}

function matchesPlace(
  row: EstimateMetaRow,
  system: string,
  subsystem: string
): boolean {
  return (
    (row.system?.trim() ?? "") === system &&
    (row.subsystem?.trim() ?? "") === subsystem
  );
}

/**
 * Estimate files that already have this system/subsystem on the object.
 * Fallback title/contract come from any line of the object.
 */
export async function getWorkMaterialContext(
  objectId: string,
  system: string,
  subsystem: string
): Promise<WorkMaterialContext> {
  const rows = await loadObjectEstimateMeta(objectId);
  const titles = uniqueTitles(rows.filter((row) => matchesPlace(row, system, subsystem)));
  const objectTitles = uniqueTitles(rows);
  const fallback = titles[0] ?? objectTitles[0] ?? null;

  return {
    titles,
    fallbackTitle: fallback?.title ?? null,
    fallbackContractId: fallback?.contractId ?? null,
  };
}

/**
 * Inserts an estimate line for the current object/system/subsystem
 * (qty and price 0, number `д-N`) and returns it for the shift catalog.
 * Allowed with estimates.create or works.create / works.update on own objects.
 */
export async function createWorkMaterial(
  input: CreateWorkMaterialInput
): Promise<WorkEstimateOption> {
  const system = input.system.trim();
  const subsystem = input.subsystem.trim();
  const name = input.name.trim();
  const unit = input.unit.trim();

  if (!system || !subsystem) {
    throw new Error("Сначала выберите систему и подсистему");
  }
  if (!name) {
    throw new Error("Наименование обязательно для заполнения");
  }
  if (!unit) {
    throw new Error("Выберите единицу измерения");
  }

  const rows = await loadObjectEstimateMeta(input.objectId);
  if (rows.length === 0) {
    throw new Error(
      "На объекте нет сметы. Сначала загрузите смету в разделе «Сметы»."
    );
  }

  const placeRows = rows.filter((row) => matchesPlace(row, system, subsystem));
  const placeTitles = uniqueTitles(placeRows);
  const objectTitles = uniqueTitles(rows);
  const requested = input.estimateTitle?.trim() || null;
  const chosenTitle =
    requested ??
    placeTitles[0]?.title ??
    objectTitles[0]?.title ??
    null;

  if (!chosenTitle) {
    throw new Error(
      "На объекте нет сметы. Сначала загрузите смету в разделе «Сметы»."
    );
  }

  const titleRows = rows.filter(
    (row) => (row.estimate_title?.trim() ?? "") === chosenTitle
  );
  const sample =
    titleRows.find((row) => matchesPlace(row, system, subsystem)) ??
    titleRows[0] ??
    placeRows[0] ??
    rows[0];

  const numbers = titleRows.map((row) =>
    row.number == null ? "" : String(row.number)
  );
  const number = nextWorkMaterialNumber(numbers);
  const id = await createEstimateItem({
    objectId: input.objectId,
    contractId: sample?.contract_id ?? null,
    estimateTitle: chosenTitle,
    system,
    subsystem,
    number,
    name,
    article: input.article,
    manufacturer: input.manufacturer,
    unit,
    quantity: 0,
    price: 0,
  });

  return {
    id,
    system,
    subsystem,
    number,
    name,
    unit,
    price: 0,
  };
}
