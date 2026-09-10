"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { WorkClosePanel } from "@/features/works/ui/shared/work-close-panel";
import { WorkPhotos } from "@/features/works/ui/shared/work-photos";
import { useWorkHours, useWorkItems } from "@/features/works/hooks/use-works";
import type { Work } from "@/features/works/types/work.types";
import {
  contractorTotals,
  formatCurrency,
  ownItems,
  ownItemsTotal,
  uniqueEmployeeCount,
} from "@/features/works/utils/work.utils";

type WorkDataTabProps = {
  work: Work;
  canModify?: boolean;
  canReopen?: boolean;
};

export function WorkDataTab({
  work,
  canModify = false,
  canReopen = false,
}: WorkDataTabProps) {
  const itemsQuery = useWorkItems(work.id);
  const hoursQuery = useWorkHours(work.id);
  const items = itemsQuery.data;
  const hours = hoursQuery.data;

  const own = items ? ownItems(items) : [];
  const employeesCount = hours
    ? uniqueEmployeeCount(hours)
    : work.employeesCount;
  const worksCount = items ? own.length : work.itemsCount;
  const totalAmount = items ? ownItemsTotal(items) : work.ownTotalAmount;
  const productivity = employeesCount > 0 ? totalAmount / employeesCount : 0;
  const byContractor = items ? contractorTotals(items) : [];

  return (
    <div className="flex flex-col gap-5 pb-1">
      <WorkClosePanel
        work={work}
        items={items}
        hours={hours}
        canModify={canModify}
        canReopen={canReopen}
      />
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <StatCard label="Сотрудников" value={String(employeesCount)} />
        <StatCard label="Работ" value={String(worksCount)} />
        <StatCard label="Сумма" value={formatCurrency(totalAmount)} />
        <StatCard
          label="Выработка / чел."
          value={formatCurrency(productivity)}
        />
      </div>

      {items && (own.length > 0 || byContractor.length > 0) ? (
        <Card size="sm" className="overflow-visible">
          <CardHeader className="border-b">
            <CardTitle>Кто выполнил</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col">
            <div className="flex items-center justify-between gap-3 py-2 text-xs text-muted-foreground">
              <span>Исполнитель</span>
              <span>Сумма</span>
            </div>
            <AmountRow label="Собственное выполнение" value={ownItemsTotal(items)} />
            {byContractor.map((row) => (
              <AmountRow
                key={row.contractorId}
                label={row.name}
                value={row.total}
              />
            ))}
          </CardContent>
        </Card>
      ) : null}

      <WorkPhotos work={work} />
    </div>
  );
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <Card size="sm" className="overflow-visible">
      <CardHeader>
        <p className="text-sm text-muted-foreground">{label}</p>
        <CardTitle className="tabular-nums">{value}</CardTitle>
      </CardHeader>
    </Card>
  );
}

function AmountRow({ label, value }: { label: string; value: number }) {
  return (
    <div className="flex items-center justify-between gap-3 border-b py-2 last:border-b-0">
      <span className="min-w-0 truncate text-sm">{label}</span>
      <span className="shrink-0 tabular-nums text-sm font-medium">
        {formatCurrency(value)}
      </span>
    </div>
  );
}
