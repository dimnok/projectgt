"use client";

import { MobileSheet } from "@/components/shared/mobile-sheet-chrome";
import { SettlementForm } from "@/features/settlements/ui/shared/settlement-form";
import type { Contract } from "@/features/contracts/types/contract.types";
import type {
  Settlement,
  SettlementDraft,
  SettlementPickItem,
} from "@/features/settlements/types/settlement.types";

type SettlementFormSheetProps = {
  open: boolean;
  settlement?: Settlement | null;
  presetContract?: Contract | null;
  contractors: SettlementPickItem[];
  objects: SettlementPickItem[];
  contracts: Contract[];
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: SettlementDraft) => void;
};

/**
 * Создание и правка счёта на телефоне: окно снизу.
 *
 * Форма общая с настольным окном; здесь — только мобильное окно.
 */
export function SettlementFormSheet({
  open,
  settlement,
  presetContract,
  contractors,
  objects,
  contracts,
  isSaving,
  onOpenChange,
  onSubmit,
}: SettlementFormSheetProps) {
  return (
    <MobileSheet open={open} onOpenChange={onOpenChange}>
      {open ? (
        <SettlementForm
          key={settlement?.id ?? presetContract?.id ?? "new"}
          layout="sheet"
          settlement={settlement}
          presetContract={presetContract}
          contractors={contractors}
          objects={objects}
          contracts={contracts}
          isSaving={isSaving}
          onCancel={() => onOpenChange(false)}
          onSubmit={onSubmit}
        />
      ) : null}
    </MobileSheet>
  );
}
