"use client";

import { WrenchIcon } from "lucide-react";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import type { Work } from "@/features/works/types/work.types";
import { WorkStatusBadge } from "@/features/works/ui/shared/work-status-badge";
import { formatCurrency } from "@/features/works/utils/work.utils";

type WorksMobileListProps = {
  works: Work[];
  isLoading: boolean;
  errorMessage?: string;
  emptyDescription: string;
  onSelectWork: (work: Work) => void;
};

export function WorksMobileList({
  works,
  isLoading,
  errorMessage,
  emptyDescription,
  onSelectWork,
}: WorksMobileListProps) {
  if (isLoading) {
    return (
      <div className="flex flex-col gap-2">
        <Skeleton className="h-20 w-full" />
        <Skeleton className="h-20 w-full" />
        <Skeleton className="h-20 w-full" />
      </div>
    );
  }

  if (errorMessage) {
    return <ErrorState message={errorMessage} />;
  }

  if (works.length === 0) {
    return (
      <EmptyState
        title="Смен нет"
        description={emptyDescription}
        icon={WrenchIcon}
      />
    );
  }

  return (
    <div className="flex flex-col gap-2">
      {works.map((work) => (
        <WorkMobileCard
          key={work.id}
          work={work}
          onSelect={() => onSelectWork(work)}
        />
      ))}
    </div>
  );
}

function WorkMobileCard({
  work,
  onSelect,
}: {
  work: Work;
  onSelect: () => void;
}) {
  return (
    <button type="button" className="w-full text-left" onClick={onSelect}>
      <Card size="sm" className="overflow-visible shadow-float">
        <CardContent className="flex items-start gap-3">
          <div className="min-w-0 flex-1">
            <p className="truncate font-heading text-sm font-medium">
              {work.objectName}
            </p>
            <p className="truncate text-xs text-muted-foreground">
              {work.openedByName}
              {work.employeesCount > 0 ? ` · ${work.employeesCount} чел.` : ""}
            </p>
            <p className="mt-1 text-sm font-medium tabular-nums">
              {formatCurrency(work.totalAmount)}
            </p>
          </div>
          <WorkStatusBadge status={work.status} />
        </CardContent>
      </Card>
    </button>
  );
}
