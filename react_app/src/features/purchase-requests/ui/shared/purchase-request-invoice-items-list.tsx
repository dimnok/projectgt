"use client";

import type { PurchaseRequestInvoiceItem } from "@/features/purchase-requests/types/purchase-request.types";
import { formatInvoiceItemAmounts } from "@/features/purchase-requests/utils/format";
import { cn } from "@/lib/utils";

type PurchaseRequestInvoiceItemsListProps = {
  items: PurchaseRequestInvoiceItem[];
  className?: string;
};

/**
 * Позиции счёта «как в счёте».
 *
 * Поставщик называет товары по-своему, поэтому строки счёта показываем рядом
 * со счётом — их можно сверить с позициями заявки. Ничего не рисуем, если
 * строк нет (старые счета).
 */
export function PurchaseRequestInvoiceItemsList({
  items,
  className,
}: PurchaseRequestInvoiceItemsListProps) {
  if (items.length === 0) {
    return null;
  }

  return (
    <ul className={cn("flex flex-col gap-1", className)}>
      {items.map((item) => (
        <li
          key={item.id}
          className="flex items-start justify-between gap-3 text-xs"
        >
          <span className="min-w-0 flex-1 break-words text-muted-foreground">
            {item.article ? `${item.article} · ` : ""}
            {item.name}
          </span>
          <span className="shrink-0 tabular-nums text-muted-foreground">
            {formatInvoiceItemAmounts(item)}
          </span>
        </li>
      ))}
    </ul>
  );
}
