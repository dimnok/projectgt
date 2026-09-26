"use client";

import { Skeleton } from "@/components/ui/skeleton";
import { companyListIconButtonMobileClass } from "@/features/company/ui/shared/company-list-icon-button";
import { useIsMobile } from "@/hooks/use-mobile";
import { cn } from "@/lib/utils";

/** Скелетон строк списка с ведущей иконкой: банковские счета, документы. */
export function CompanyListSkeleton({ rows = 2 }: { rows?: number }) {
  const actionClass = useActionPlaceholderClass();

  return (
    <div className="flex flex-col gap-2">
      {Array.from({ length: rows }).map((_, index) => (
        <div
          key={index}
          className="flex items-center justify-between gap-3 rounded-lg border bg-card p-3"
        >
          <div className="flex min-w-0 items-center gap-3">
            <Skeleton className="size-9 shrink-0 rounded-md" />
            <div className="flex flex-col gap-1.5">
              <Skeleton className="h-4 w-32" />
              <Skeleton className="h-3 w-44" />
            </div>
          </div>
          <div className="flex shrink-0 items-center gap-1">
            <Skeleton className={actionClass} />
            <Skeleton className={actionClass} />
          </div>
        </div>
      ))}
    </div>
  );
}

/** Скелетон строк списка приглашений: код, срок действия, статус. */
export function CompanyInvitationsSkeleton({ rows = 2 }: { rows?: number }) {
  const actionClass = useActionPlaceholderClass();

  return (
    <div className="flex flex-col gap-2">
      {Array.from({ length: rows }).map((_, index) => (
        <div
          key={index}
          className="flex items-center justify-between gap-3 rounded-lg border bg-card p-3"
        >
          <div className="flex flex-col gap-1.5">
            <Skeleton className="h-4 w-24" />
            <Skeleton className="h-3 w-20" />
          </div>
          <div className="flex shrink-0 items-center gap-1">
            <Skeleton className="h-5 w-20 rounded-full" />
            <Skeleton className={actionClass} />
            <Skeleton className={actionClass} />
          </div>
        </div>
      ))}
    </div>
  );
}

/** Размер заглушки кнопки-иконки — совпадает с кнопкой на этой платформе. */
function useActionPlaceholderClass(): string {
  const isMobile = useIsMobile();
  return cn(
    "rounded-md",
    isMobile ? companyListIconButtonMobileClass : "size-7"
  );
}
