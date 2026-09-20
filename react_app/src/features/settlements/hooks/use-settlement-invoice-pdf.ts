"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";

import { buildSettlementInvoicePdfBlob } from "@/features/settlements/api/settlement-invoice-pdf";
import {
  deleteSettlementFile,
  getSettlementFiles,
  uploadSettlementFile,
} from "@/features/settlements/api/settlement-files";
import { settlementFilesQueryKey } from "@/features/settlements/hooks/use-settlement-files";
import type {
  Settlement,
  SettlementFile,
} from "@/features/settlements/types/settlement.types";
import type {
  CompanyBankAccount,
  CompanyProfile,
} from "@/features/company/types/company.types";
import type { Contractor } from "@/features/contractors/types/contractor.types";
import { formatRuDate } from "@/features/settlements/utils/settlement.utils";

/** Описание автосгенерированного PDF: по нему находим и перезаписываем версию. */
export const SETTLEMENT_INVOICE_PDF_DESCRIPTION =
  "Счёт на оплату (сформирован автоматически)";

/** Убирает из имени файла символы, недопустимые в путях и именах. */
function sanitizeSegment(value: string): string {
  return value.replace(/[\\/:*?"<>|]/g, "_").trim();
}

/** Базовое имя PDF без расширения. */
export function settlementInvoicePdfBaseName(settlement: Settlement): string {
  return `Счёт на оплату № ${sanitizeSegment(
    settlement.invoiceNumber
  )} от ${formatRuDate(settlement.invoiceDate)}`;
}

/** Имя PDF-файла счёта с расширением. */
export function settlementInvoicePdfFileName(settlement: Settlement): string {
  return `${settlementInvoicePdfBaseName(settlement)}.pdf`;
}

/**
 * Убирает старую автоверсию PDF.
 *
 * Ошибку не пробрасываем: новый PDF уже сохранён, и уборка не должна лишать
 * пользователя готового счёта. Одну повторную попытку делаем — сбой хранилища
 * обычно кратковременный; если и она не прошла, лишняя версия останется
 * в документах и её видно в списке.
 */
async function removeStaleInvoiceFile(file: SettlementFile): Promise<void> {
  try {
    await deleteSettlementFile(file.id, file.filePath);
  } catch {
    try {
      await deleteSettlementFile(file.id, file.filePath);
    } catch {
      // Уборку не удалось завершить — показ счёта важнее.
    }
  }
}

type GenerateInput = {
  settlement: Settlement;
  company: CompanyProfile | null | undefined;
  bankAccount: CompanyBankAccount | null | undefined;
  contractor: Contractor | null | undefined;
  /** Сохранить PDF в файлы счёта (перезаписав предыдущую автоверсию). */
  persist?: boolean;
};

/**
 * Формирует PDF счёта на сервере. По умолчанию сохраняет его в файлы счёта
 * (перезаписывая предыдущую автоверсию).
 */
export function useSettlementInvoicePdf() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: GenerateInput): Promise<Blob> => {
      const { settlement, company, bankAccount, contractor } = input;
      if (!company || !bankAccount || !contractor) {
        throw new Error("Недостаточно данных для счёта");
      }

      const blob = await buildSettlementInvoicePdfBlob(
        settlement,
        company,
        bankAccount,
        contractor
      );

      if (input.persist) {
        const stale = (await getSettlementFiles(settlement.id)).filter(
          (file) => file.description === SETTLEMENT_INVOICE_PDF_DESCRIPTION
        );

        // Сначала сохраняем новую версию и только потом убираем старую:
        // в обратном порядке сбой загрузки оставил бы счёт без документа.
        await uploadSettlementFile({
          settlementOperationId: settlement.id,
          file: new File([blob], settlementInvoicePdfFileName(settlement), {
            type: "application/pdf",
          }),
          name: settlementInvoicePdfFileName(settlement),
          description: SETTLEMENT_INVOICE_PDF_DESCRIPTION,
        });

        for (const old of stale) {
          await removeStaleInvoiceFile(old);
        }

        await queryClient.invalidateQueries({
          queryKey: settlementFilesQueryKey(settlement.id),
        });
      }

      return blob;
    },
  });
}
