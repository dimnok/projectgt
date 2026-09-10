"use client";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Skeleton } from "@/components/ui/skeleton";
import type { Work } from "@/features/works/types/work.types";
import { WorkStatusBadge } from "@/features/works/ui/shared/work-status-badge";
import { formatCurrency, formatRuDate } from "@/features/works/utils/work.utils";
import { cn } from "@/lib/utils";
import { WrenchIcon } from "lucide-react";

type WorksListProps = {
  works: Work[];
  selectedWork: Work | null;
  isLoading: boolean;
  errorMessage?: string;
  emptyTitle: string;
  emptyDescription: string;
  onSelectWork: (work: Work) => void;
};

export function WorksList({
  works,
  selectedWork,
  isLoading,
  errorMessage,
  emptyTitle,
  emptyDescription,
  onSelectWork,
}: WorksListProps) {
  if (isLoading) {
    return (
      <div className="flex flex-col gap-2">
        <Skeleton className="h-14 w-full" />
        <Skeleton className="h-14 w-full" />
        <Skeleton className="h-14 w-full" />
      </div>
    );
  }

  if (errorMessage) {
    return <ErrorState message={errorMessage} />;
  }

  if (works.length === 0) {
    return (
      <EmptyState
        title={emptyTitle}
        description={emptyDescription}
        icon={WrenchIcon}
      />
    );
  }

  return (
    <div className="flex flex-col gap-2">
      {works.map((work) => (
        <WorkRow
          key={work.id}
          work={work}
          selected={selectedWork?.id === work.id}
          onSelect={() => onSelectWork(work)}
        />
      ))}
    </div>
  );
}

type WorkRowProps = {
  work: Work;
  selected: boolean;
  onSelect: () => void;
};

function WorkRow({ work, selected, onSelect }: WorkRowProps) {
  return (
    <button
      type="button"
      onClick={onSelect}
      className={cn(
        "group flex w-full cursor-pointer items-center gap-2.5 rounded-xl border bg-card px-3 py-2.5 text-left outline-none ring-1 ring-foreground/10 transition-all focus-visible:ring-2 focus-visible:ring-ring",
        selected
          ? "border-primary/50 bg-muted/80 ring-primary/40 shadow-xs"
          : "border-transparent hover:bg-muted/40"
      )}
    >
      <span className="min-w-0 flex-1">
        <span className="block truncate text-xs font-semibold text-foreground">
          {formatRuDate(work.date)} · {work.objectName}
        </span>
        <span className="block truncate text-[11px] text-muted-foreground">
          {work.openedByName} · {formatCurrency(work.totalAmount)}
        </span>
      </span>
      <WorkStatusBadge status={work.status} />
    </button>
  );
}
