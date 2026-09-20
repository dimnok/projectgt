import { getAccessToken } from "@/lib/supabase/client";
import type { CompanyBankAccount, CompanyProfile } from "@/features/company/types/company.types";
import type { Contractor } from "@/features/contractors/types/contractor.types";
import type { Settlement } from "@/features/settlements/types/settlement.types";
import type { SettlementInvoicePdfInput } from "@/features/settlements/utils/settlement-invoice-pdf";

/** Проверяет, достаточно ли данных для PDF счёта. Возвращает список нехваток. */
export function validateSettlementInvoiceData(input: {
  company?: CompanyProfile | null;
  bankAccount?: CompanyBankAccount | null;
  contractor?: Contractor | null;
}): string[] {
  const missing: string[] = [];
  const { company, bankAccount, contractor } = input;

  if (!company) {
    return ["профиль компании"];
  }
  if (!company.nameFull.trim()) {
    missing.push("полное наименование компании");
  }
  if (!company.inn?.trim()) {
    missing.push("ИНН компании");
  }
  if (!bankAccount) {
    missing.push("банковский счёт компании");
  } else {
    if (!bankAccount.accountNumber.trim()) {
      missing.push("расчётный счёт");
    }
    if (!bankAccount.bankName.trim()) {
      missing.push("наименование банка");
    }
  }
  if (!contractor) {
    missing.push("контрагент");
  } else {
    if (!contractor.fullName.trim()) {
      missing.push("наименование контрагента");
    }
    if (!contractor.inn.trim()) {
      missing.push("ИНН контрагента");
    }
  }

  return missing;
}

/** Отбирает из данных веба только то, что нужно для PDF счёта. */
function toInput(
  settlement: Settlement,
  company: CompanyProfile,
  bankAccount: CompanyBankAccount,
  contractor: Contractor
): SettlementInvoicePdfInput {
  return {
    operation: {
      invoiceNumber: settlement.invoiceNumber,
      invoiceDate: settlement.invoiceDate,
      operationType: settlement.operationType,
      actNumber: settlement.actNumber,
      note: settlement.note,
      purpose: settlement.purpose,
      contractNumber: settlement.contractNumber,
      objectName: settlement.objectName,
      contractorName: settlement.contractorName,
      amount: settlement.amount,
      vatRate: settlement.vatRate,
      vatAmount: settlement.vatAmount,
      totalToPay: settlement.totalToPay,
      advanceRetention: settlement.advanceRetention,
      warrantyRetention: settlement.warrantyRetention,
    },
    company: {
      nameFull: company.nameFull,
      legalAddress: company.legalAddress,
      inn: company.inn,
      kpp: company.kpp,
      phone: company.phone,
      email: company.email,
      directorName: company.directorName,
      chiefAccountantName: company.chiefAccountantName,
    },
    bankAccount: {
      bankName: bankAccount.bankName,
      bik: bankAccount.bik,
      corrAccount: bankAccount.corrAccount,
      accountNumber: bankAccount.accountNumber,
    },
    contractor: {
      fullName: contractor.fullName,
      legalAddress: contractor.legalAddress,
      inn: contractor.inn,
      kpp: contractor.kpp,
      phone: contractor.phone,
      email: contractor.email,
    },
  };
}

/** Запрашивает PDF счёта у серверного роута и возвращает байты. */
export async function buildSettlementInvoicePdfBlob(
  settlement: Settlement,
  company: CompanyProfile,
  bankAccount: CompanyBankAccount,
  contractor: Contractor
): Promise<Blob> {
  const token = await getAccessToken();

  const response = await fetch("/api/settlements/invoice-pdf", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(toInput(settlement, company, bankAccount, contractor)),
  });

  if (!response.ok) {
    const message = await response
      .json()
      .then((data: { error?: string }) => data.error)
      .catch(() => null);
    throw new Error(message || "Не удалось сформировать счёт");
  }

  return response.blob();
}
