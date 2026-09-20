"use client";

import { SettlementStatusBadge } from "@/features/settlements/ui/shared/settlement-status-badge";
import { SettlementTypeBadge } from "@/features/settlements/ui/shared/settlement-type-badge";
import type { Settlement } from "@/features/settlements/types/settlement.types";
import {
  formatCurrency,
  formatRuDate,
  settlementRemaining,
} from "@/features/settlements/utils/settlement.utils";

type SettlementsMobileListProps = {
  settlements: Settlement[];
  onSelect: (settlement: Settlement) => void;
};

/** Лента карточек счетов на телефоне: номер, статус, контрагент, сумма и остаток. */
export function SettlementsMobileList({
  settlements,
  onSelect,
}: SettlementsMobileListProps) {
  return (
    <ul className="flex flex-col gap-2">
      {settlements.map((settlement) => {
        const remaining = settlementRemaining(settlement);
        const subtitle = [settlement.contractorName, settlement.objectName]
          .filter(Boolean)
          .join(" · ");

        return (
          <li key={settlement.id}>
            <button
              type="button"
              className="bg-card w-full rounded-xl p-3 text-left ring-1 ring-foreground/10 active:scale-[0.99]"
              onClick={() => onSelect(settlement)}
            >
              <div className="flex items-center gap-2">
                <span className="min-w-0 flex-1 truncate font-semibold">
                  {settlement.invoiceNumber}
                  <span className="text-muted-foreground ml-1 text-xs font-normal">
                    · {formatRuDate(settlement.invoiceDate)}
                  </span>
                </span>
                <SettlementStatusBadge status={settlement.paymentStatus} />
              </div>
              <p className="text-muted-foreground mt-1 truncate text-sm">
                {subtitle || "—"}
              </p>
              <div className="mt-2 flex items-center gap-2">
                <SettlementTypeBadge type={settlement.operationType} />
                <span className="ml-auto font-semibold tabular-nums">
                  {formatCurrency(settlement.totalToPay)}
                </span>
              </div>
              {remaining !== 0 ? (
                <p
                  className={
                    remaining > 0
                      ? "text-destructive mt-1 text-right text-xs"
                      : "text-muted-foreground mt-1 text-right text-xs"
                  }
                >
                  {remaining > 0 ? "Остаток" : "Переплата"}{" "}
                  {formatCurrency(remaining)}
                </p>
              ) : null}
            </button>
          </li>
        );
      })}
    </ul>
  );
}
