import { Skeleton } from "@/components/ui/skeleton";

/** Скелетон полосы показателей сверху. */
export function SettlementsKpiSkeleton() {
  return (
    <div className="grid grid-cols-2 divide-y divide-border/60 border-b border-border/80 bg-card sm:divide-y-0 sm:divide-x lg:grid-cols-4">
      {Array.from({ length: 4 }).map((_, index) => (
        <div key={index} className="flex items-center justify-between gap-3 px-5 py-3">
          <div className="flex flex-col gap-2">
            <Skeleton className="h-3 w-20" />
            <Skeleton className="h-5 w-28" />
            <Skeleton className="h-2.5 w-24" />
          </div>
          <Skeleton className="size-6 rounded-md" />
        </div>
      ))}
    </div>
  );
}

/** Скелетон строк таблицы счетов (компьютер). */
export function SettlementsTableSkeleton({ rows = 8 }: { rows?: number }) {
  return (
    <div className="min-h-0 flex-1 overflow-hidden rounded-b-xl">
      <div className="flex items-center gap-3 border-b border-border/80 bg-muted px-4 py-2.5 sm:px-5">
        {[56, 44, 64, 56, 96, 80, 72, 64].map((width, index) => (
          <Skeleton key={index} className="h-3.5" style={{ width }} />
        ))}
      </div>
      {Array.from({ length: rows }).map((_, index) => (
        <div
          key={index}
          className="flex items-center gap-3 border-b border-border/50 px-4 py-3 sm:px-5"
        >
          <Skeleton className="h-4 w-16" />
          <Skeleton className="h-5 w-14 rounded-full" />
          <Skeleton className="h-4 w-16" />
          <Skeleton className="h-4 w-14" />
          <Skeleton className="h-4 w-20" />
          <Skeleton className="h-4 w-28" />
          <Skeleton className="h-4 w-24" />
          <Skeleton className="ml-auto h-4 w-24" />
        </div>
      ))}
    </div>
  );
}

/** Скелетон ленты карточек счетов (телефон). */
export function SettlementCardsSkeleton({ cards = 6 }: { cards?: number }) {
  return (
    <ul className="flex flex-col gap-2">
      {Array.from({ length: cards }).map((_, index) => (
        <li
          key={index}
          className="bg-card flex flex-col gap-2 rounded-xl p-3 ring-1 ring-foreground/10"
        >
          <div className="flex items-center gap-2">
            <Skeleton className="h-4 w-24" />
            <Skeleton className="ml-auto h-5 w-20 rounded-full" />
          </div>
          <Skeleton className="h-3.5 w-40" />
          <div className="flex items-center gap-2">
            <Skeleton className="h-5 w-16 rounded-full" />
            <Skeleton className="ml-auto h-4 w-24" />
          </div>
        </li>
      ))}
    </ul>
  );
}

/** Скелетон списка оплат по счёту. */
export function SettlementPaymentsSkeleton({ rows = 3 }: { rows?: number }) {
  return (
    <div className="flex flex-col gap-2">
      {Array.from({ length: rows }).map((_, index) => (
        <div
          key={index}
          className="flex items-center gap-3 rounded-lg border px-3 py-2.5"
        >
          <Skeleton className="h-4 w-20" />
          <Skeleton className="ml-auto h-4 w-24" />
          <Skeleton className="h-3.5 w-32" />
        </div>
      ))}
    </div>
  );
}

/** Скелетон списка документов счёта. */
export function SettlementFilesSkeleton({ rows = 2 }: { rows?: number }) {
  return (
    <ul className="flex flex-col gap-2">
      {Array.from({ length: rows }).map((_, index) => (
        <li
          key={index}
          className="flex items-center gap-3 rounded-lg border px-3 py-2.5"
        >
          <div className="flex min-w-0 flex-1 flex-col gap-1.5">
            <Skeleton className="h-4 w-48" />
            <Skeleton className="h-3 w-32" />
          </div>
          <Skeleton className="size-7 rounded-md" />
        </li>
      ))}
    </ul>
  );
}

/** Скелетон карточки счёта на весь экран (телефон). */
export function SettlementDetailsMobileSkeleton() {
  return (
    <div className="flex flex-col gap-4 px-4 pt-3">
      <div className="flex items-center gap-2">
        <Skeleton className="h-5 w-16 rounded-full" />
        <Skeleton className="h-5 w-20 rounded-full" />
        <Skeleton className="h-4 w-24" />
      </div>
      <div className="grid grid-cols-2 gap-3 rounded-lg border p-3">
        {Array.from({ length: 4 }).map((_, index) => (
          <div key={index} className="flex flex-col gap-1.5">
            <Skeleton className="h-3 w-20" />
            <Skeleton className="h-4 w-24" />
          </div>
        ))}
      </div>
      <Skeleton className="h-32 w-full rounded-lg" />
      <Skeleton className="h-20 w-full rounded-lg" />
    </div>
  );
}
