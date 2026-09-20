import type { CompanyDocument, CompanyDocumentDraft } from "@/features/company/types/company.types";

type DocumentRow = {
  id: string;
  company_id: string;
  type: string | null;
  title: string | null;
  number: string | null;
  issue_date: string | null;
  expiry_date: string | null;
  file_url: string | null;
};

export const DOCUMENT_SELECT =
  "id, company_id, type, title, number, issue_date, expiry_date, file_url";

function asString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed ? trimmed : null;
}

export function mapDocumentRow(row: DocumentRow): CompanyDocument {
  return {
    id: row.id,
    companyId: row.company_id,
    type: asString(row.type) ?? "",
    title: asString(row.title) ?? "",
    number: asString(row.number),
    issueDate: row.issue_date,
    expiryDate: row.expiry_date,
    fileUrl: asString(row.file_url),
  };
}

export function toDocumentPayload(
  companyId: string,
  draft: CompanyDocumentDraft
) {
  return {
    company_id: companyId,
    type: draft.type.trim(),
    title: draft.title.trim(),
    number: draft.number.trim() || null,
    issue_date: draft.issueDate || null,
    expiry_date: draft.expiryDate || null,
    file_url: draft.fileUrl.trim() || null,
  };
}

export function toDocumentDraft(
  document?: CompanyDocument | null
): CompanyDocumentDraft {
  return {
    type: document?.type ?? "",
    title: document?.title ?? "",
    number: document?.number ?? "",
    issueDate: document?.issueDate ?? "",
    expiryDate: document?.expiryDate ?? "",
    fileUrl: document?.fileUrl ?? "",
  };
}

export function validateDocumentDraft(
  draft: CompanyDocumentDraft
): Record<string, string> {
  const errors: Record<string, string> = {};
  if (!draft.title.trim()) {
    errors.title = "Введите название документа";
  }
  if (!draft.type.trim()) {
    errors.type = "Введите тип (Лицензия, СРО и т.д.)";
  }
  return errors;
}

/** Отображает дату документа как `дд.мм.гггг`. */
export function formatDocumentDate(value: string | null): string {
  if (!value) {
    return "—";
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "—";
  }
  return date.toLocaleDateString("ru-RU");
}
