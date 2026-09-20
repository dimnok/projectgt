"use client";

import type { PurchaseRequestHistoryEntry } from "@/features/purchase-requests/types/purchase-request.types";
import { formatRuDateTime } from "@/features/purchase-requests/utils/format";
import { historyActionPhrase } from "@/features/purchase-requests/utils/labels";
import { formatUserDisplayLabel } from "@/features/purchase-requests/utils/names";
import {
  EmptySection,
  SectionTitle,
} from "@/features/purchase-requests/ui/mobile/purchase-request-section";

type PurchaseRequestHistorySectionProps = {
  history: PurchaseRequestHistoryEntry[];
};

/**
 * История заявки: кто, что и когда сделал.
 *
 * Текст компактнее остальных разделов, но контрастнее — история читается
 * как журнал и не спорит с содержимым карточки.
 */
export function PurchaseRequestHistorySection({
  history,
}: PurchaseRequestHistorySectionProps) {
  return (
    <section className="flex flex-col gap-2">
      <SectionTitle title="История" />
      {history.length === 0 ? (
        <EmptySection text="История пока пуста" />
      ) : (
        <ol className="flex flex-col gap-2.5 border-l border-border/70 pl-4">
          {history.map((entry) => (
            <li key={entry.id} className="relative">
              <span className="absolute top-1 -left-[19px] size-1.5 rounded-full bg-foreground ring-4 ring-background" />
              <div className="flex items-start justify-between gap-3">
                <p className="min-w-0 text-xs leading-snug text-foreground/90">
                  <span className="font-semibold text-foreground">
                    {formatUserDisplayLabel(entry.userName)}
                  </span>{" "}
                  {historyActionPhrase(entry.action)}
                </p>
                <span className="shrink-0 text-[11px] font-medium tabular-nums text-muted-foreground">
                  {formatRuDateTime(entry.createdAt)}
                </span>
              </div>
              {entry.comment?.trim() ? (
                <p className="mt-0.5 text-xs text-foreground/70">
                  {entry.comment}
                </p>
              ) : null}
            </li>
          ))}
        </ol>
      )}
    </section>
  );
}
