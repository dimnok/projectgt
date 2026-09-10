import type {
  EstimateFile,
  EstimateFileQuery,
  EstimateItem,
  EstimateObjectGroup,
} from "@/features/estimates/types/estimate.types";
import type {
  EstimateGroupRow,
  EstimateItemRow,
} from "@/types/database.types";
import { compareEstimateItems } from "@/features/estimates/utils/estimate-sort";

export const EMPTY_OBJECT_NAME = "Без объекта";
export const EMPTY_CONTRACT_NUMBER = "Без договора";

export const ESTIMATE_ITEM_SELECT = [
  "id",
  "company_id",
  "system",
  "subsystem",
  "number",
  "name",
  "article",
  "manufacturer",
  "unit",
  "quantity",
  "price",
  "total",
  "created_at",
  "created_by_name",
  "estimate_title",
  "object_id",
  "contract_id",
].join(", ");

export const ESTIMATE_ITEMS_PAGE_SIZE = 1000;

export function toNumber(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", "."));
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

function text(value: string | null | undefined): string {
  return value?.trim() ?? "";
}

export function estimateFileKey(file: EstimateFileQuery): string {
  return `${file.estimateTitle ?? ""}\u001f${file.objectId ?? ""}\u001f${file.contractId ?? ""}`;
}

export const EMPTY_FILTER_VALUE = "__empty__";

export function toFilterValue(key: string | null | undefined): string {
  return key && key.length > 0 ? key : "all";
}

export function resolveEstimateSelection(
  groups: EstimateObjectGroup[],
  objectKey: string | null,
  contractKey: string | null,
  fileKey: string | null
) {
  const objectGroup =
    objectKey && objectKey !== "all"
      ? (groups.find((group) => group.key === objectKey) ?? null)
      : null;
  const contractGroup =
    objectGroup && contractKey && contractKey !== "all"
      ? (objectGroup.contracts.find((contract) => contract.key === contractKey) ?? null)
      : null;
  const file =
    contractGroup && fileKey && fileKey !== "all"
      ? (contractGroup.files.find((entry) => entry.key === fileKey) ?? null)
      : null;

  return {
    objectGroup,
    contractGroup,
    file,
  };
}

export function mapEstimateGroupRow(
  row: EstimateGroupRow,
  objectNameById: Map<string, string>
): EstimateFile {
  const objectId = row.object_id;
  const contractNumber =
    text(row.contract_number) || EMPTY_CONTRACT_NUMBER;

  return {
    key: estimateFileKey({
      estimateTitle: text(row.estimate_title),
      objectId,
      contractId: row.contract_id,
    }),
    estimateTitle: text(row.estimate_title),
    objectId,
    objectName: objectId
      ? (objectNameById.get(objectId) ?? EMPTY_OBJECT_NAME)
      : EMPTY_OBJECT_NAME,
    contractId: row.contract_id,
    contractNumber,
    itemsCount: Math.round(toNumber(row.items_count)),
    total: toNumber(row.total_amount),
    completionPercent: toNumber(row.completion_percent),
  };
}

export function mapEstimateItemRow(row: EstimateItemRow): EstimateItem {
  return {
    id: row.id,
    companyId: row.company_id,
    system: text(row.system),
    subsystem: text(row.subsystem),
    number: String(row.number ?? "").trim(),
    name: text(row.name),
    article: text(row.article),
    manufacturer: text(row.manufacturer),
    unit: text(row.unit),
    quantity: toNumber(row.quantity),
    price: toNumber(row.price),
    total: toNumber(row.total),
    createdAt: row.created_at ?? null,
    createdByName: text(row.created_by_name) || null,
    estimateTitle: text(row.estimate_title),
    objectId: row.object_id ?? null,
    contractId: row.contract_id ?? null,
  };
}

export function sortEstimateItems(items: EstimateItem[]): EstimateItem[] {
  return [...items].sort(compareEstimateItems);
}

export function groupEstimateFiles(files: EstimateFile[]): EstimateObjectGroup[] {
  const objects = new Map<string, EstimateObjectGroup>();

  for (const file of files) {
    const objectKey = file.objectId ?? "";
    let objectGroup = objects.get(objectKey);
    if (!objectGroup) {
      objectGroup = {
        key: objectKey,
        objectId: file.objectId,
        objectName: file.objectName,
        total: 0,
        contracts: [],
      };
      objects.set(objectKey, objectGroup);
    }

    const contractKey = file.contractId ?? file.contractNumber;
    let contractGroup = objectGroup.contracts.find(
      (entry) => entry.key === contractKey
    );
    if (!contractGroup) {
      contractGroup = {
        key: contractKey,
        contractId: file.contractId,
        contractNumber: file.contractNumber,
        total: 0,
        files: [],
      };
      objectGroup.contracts.push(contractGroup);
    }

    contractGroup.files.push(file);
    contractGroup.total += file.total;
    objectGroup.total += file.total;
  }

  const groups = [...objects.values()].sort((a, b) =>
    a.objectName.localeCompare(b.objectName, "ru", { sensitivity: "base" })
  );

  for (const group of groups) {
    group.contracts.sort((a, b) =>
      a.contractNumber.localeCompare(b.contractNumber, "ru", {
        sensitivity: "base",
      })
    );
    for (const contract of group.contracts) {
      contract.files.sort((a, b) =>
        a.estimateTitle.localeCompare(b.estimateTitle, "ru", {
          sensitivity: "base",
        })
      );
    }
  }

  return groups;
}

export function filterEstimateFiles(
  files: EstimateFile[],
  search: string
): EstimateFile[] {
  const query = search.trim().toLowerCase();
  if (!query) {
    return files;
  }

  return files.filter((file) => {
    const haystack =
      `${file.estimateTitle} ${file.objectName} ${file.contractNumber}`.toLowerCase();
    return haystack.includes(query);
  });
}

export function filterEstimateItems(
  items: EstimateItem[],
  search: string
): EstimateItem[] {
  const query = search.trim().toLowerCase();
  if (!query) {
    return items;
  }

  return items.filter((item) => {
    const name = (item.name || "").toLowerCase();
    const article = (item.article || "").toLowerCase();
    return name.includes(query) || article.includes(query);
  });
}

export function formatCurrency(value: number): string {
  return new Intl.NumberFormat("ru-RU", {
    style: "currency",
    currency: "RUB",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
}

export function formatQuantity(value: number): string {
  return new Intl.NumberFormat("ru-RU", {
    maximumFractionDigits: 3,
  }).format(value);
}

export function formatRuDate(value: string | null | undefined): string {
  if (!value) {
    return "—";
  }
  const clean = value.split("T")[0];
  const [year, month, day] = clean.split("-");
  if (!year || !month || !day) {
    return value;
  }
  return `${day}.${month}.${year}`;
}

export function formatRuDateTime(value: string | Date | null | undefined): string {
  if (!value) {
    return "—";
  }
  const d = typeof value === "string" ? new Date(value) : value;
  if (isNaN(d.getTime())) {
    return String(value);
  }
  const day = String(d.getDate()).padStart(2, "0");
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const year = d.getFullYear();
  const hours = String(d.getHours()).padStart(2, "0");
  const minutes = String(d.getMinutes()).padStart(2, "0");
  return `${day}.${month}.${year} ${hours}:${minutes}`;
}

export function formatPlural(
  count: number,
  one: string,
  few: string,
  many: string
): string {
  const abs = Math.abs(count);
  const mod10 = abs % 10;
  const mod100 = abs % 100;

  if (mod100 >= 11 && mod100 <= 19) {
    return `${count} ${many}`;
  }
  if (mod10 === 1) {
    return `${count} ${one}`;
  }
  if (mod10 >= 2 && mod10 <= 4) {
    return `${count} ${few}`;
  }
  return `${count} ${many}`;
}


