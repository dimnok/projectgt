import { Skeleton } from "@/components/ui/skeleton";

/** Скелетон полосы показателей сверху. */
export function CashFlowKpiSkeleton() {
  return (
    <div className="grid grid-cols-2 divide-y divide-border/60 border-b border-border/80 bg-card sm:divide-y-0 sm:divide-x lg:grid-cols-4">
      {Array.from({ length: 4 }).map((_, index) => (
        <div
          key={index}
          className="flex items-center justify-between gap-3 px-5 py-3"
        >
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

/** Скелетон строк таблицы операций. */
export function CashFlowTableSkeleton({ rows = 8 }: { rows?: number }) {
  return (
    <div className="min-h-0 flex-1 overflow-hidden">
      <div className="flex items-center gap-3 border-b border-border/80 bg-muted px-4 py-2.5 sm:px-5">
        {[56, 48, 80, 88, 96, 56, 72].map((width, index) => (
          <Skeleton key={index} className="h-3.5" style={{ width }} />
        ))}
      </div>
      {Array.from({ length: rows }).map((_, index) => (
        <div
          key={index}
          className="flex items-center gap-3 border-b border-border/50 px-4 py-3 sm:px-5"
        >
          <Skeleton className="h-4 w-16" />
          <Skeleton className="h-5 w-16 rounded-full" />
          <Skeleton className="h-4 w-20" />
          <Skeleton className="h-4 w-24" />
          <Skeleton className="h-4 w-28" />
          <Skeleton className="h-4 w-16" />
          <Skeleton className="ml-auto h-4 w-24" />
        </div>
      ))}
    </div>
  );
}

/** Скелетон отчёта по месяцам: столбец подписей, столбцы месяцев и итог. */
export function CashFlowAnalyticsSkeleton({ columns = 6 }: { columns?: number }) {
  const gridTemplateColumns = `11rem repeat(${columns}, minmax(0, 1fr)) 8rem`;

  return (
    <div className="flex flex-col">
      <div
        className="grid items-center gap-3 border-b border-border/60 bg-muted px-4 py-2 sm:px-5"
        style={{ gridTemplateColumns }}
      >
        <Skeleton className="h-3.5 w-20" />
        {Array.from({ length: columns }).map((_, index) => (
          <Skeleton key={index} className="ml-auto h-3.5 w-20" />
        ))}
        <Skeleton className="ml-auto h-3.5 w-24" />
      </div>
      {Array.from({ length: 3 }).map((_, row) => (
        <div
          key={row}
          className="grid items-center gap-3 border-b border-border/50 px-4 py-2.5 sm:px-5"
          style={{ gridTemplateColumns }}
        >
          <Skeleton className="h-3.5 w-24" />
          {Array.from({ length: columns }).map((_, index) => (
            <Skeleton key={index} className="ml-auto h-3.5 w-20" />
          ))}
          <Skeleton className="ml-auto h-3.5 w-24" />
        </div>
      ))}
    </div>
  );
}
