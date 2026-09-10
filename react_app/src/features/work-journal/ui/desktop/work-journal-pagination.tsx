"use client";

import { ChevronLeftIcon, ChevronRightIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { formatQuantity } from "@/features/work-journal/utils/work-journal.utils";

type WorkJournalPaginationProps = {
  currentPage: number;
  totalPages: number;
  totalCount: number;
  isBusy?: boolean;
  onPageChange: (page: number) => void;
};

export function WorkJournalPagination({
  currentPage,
  totalPages,
  totalCount,
  isBusy = false,
  onPageChange,
}: WorkJournalPaginationProps) {
  if (totalPages <= 1) {
    return null;
  }

  return (
    <div className="flex shrink-0 items-center justify-center gap-2 border-t border-border/80 bg-background px-4 py-1.5 sm:px-5">
      <Button
        type="button"
        variant="ghost"
        size="icon-sm"
        aria-label="Предыдущая страница"
        disabled={currentPage <= 1 || isBusy}
        onClick={() => onPageChange(currentPage - 1)}
      >
        <ChevronLeftIcon />
      </Button>
      <p className="text-xs sm:text-sm font-medium">
        Страница {currentPage} из {totalPages}
      </p>
      <p className="text-xs text-muted-foreground">
        ({formatQuantity(totalCount)} записей)
      </p>
      <Button
        type="button"
        variant="ghost"
        size="icon-sm"
        aria-label="Следующая страница"
        disabled={currentPage >= totalPages || isBusy}
        onClick={() => onPageChange(currentPage + 1)}
      >
        <ChevronRightIcon />
      </Button>
    </div>
  );
}
