"use client";

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { ContractKindBadge } from "@/features/contracts/ui/shared/contract-kind-badge";
import { ContractStatusBadge } from "@/features/contracts/ui/shared/contract-status-badge";
import type { Contract } from "@/features/contracts/types/contract.types";
import {
  daysUntilEnd,
  formatCurrency,
  formatRuDate,
} from "@/features/contracts/utils/contract.utils";
import { cn } from "@/lib/utils";

type ContractsListProps = {
  contracts: Contract[];
  selectedId: string | null;
  onSelect: (contract: Contract) => void;
};

function periodClass(contract: Contract) {
  const days = daysUntilEnd(contract.endDate);
  if (days === null) {
    return "text-muted-foreground";
  }
  if (days < 0) {
    return "text-destructive";
  }
  if (days <= 30) {
    return "text-warning";
  }
  return "text-muted-foreground";
}

export function ContractsList({
  contracts,
  selectedId,
  onSelect,
}: ContractsListProps) {
  return (
    <div className="overflow-hidden rounded-xl bg-card ring-1 ring-foreground/10">
      <Table>
        <TableHeader>
          <TableRow className="hover:bg-transparent">
            <TableHead>Номер</TableHead>
            <TableHead>Объект</TableHead>
            <TableHead>Контрагент</TableHead>
            <TableHead>Период</TableHead>
            <TableHead className="text-right">Сумма</TableHead>
            <TableHead>Статус</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {contracts.map((contract) => {
            const isSelected = selectedId === contract.id;

            return (
              <TableRow
                key={contract.id}
                data-state={isSelected ? "selected" : undefined}
                className="cursor-pointer focus-visible:bg-muted/50 focus-visible:outline-none"
                onClick={() => onSelect(contract)}
                onKeyDown={(event) => {
                  if (event.key === "Enter" || event.key === " ") {
                    event.preventDefault();
                    onSelect(contract);
                  }
                }}
                tabIndex={0}
              >
                <TableCell className="max-w-48 font-medium">
                  <span className="block truncate">№ {contract.number}</span>
                </TableCell>
                <TableCell className="max-w-56">
                  <span className="block truncate">
                    {contract.objectName || "—"}
                  </span>
                </TableCell>
                <TableCell className="max-w-64 whitespace-normal">
                  <span className="flex min-w-0 flex-col items-start gap-1">
                    <span className="w-full truncate">
                      {contract.contractorName || "—"}
                    </span>
                    <ContractKindBadge kind={contract.kind} compact />
                  </span>
                </TableCell>
                <TableCell className="whitespace-normal">
                  <span className="flex flex-col leading-tight">
                    <span>{formatRuDate(contract.date)}</span>
                    <span className={cn("text-xs", periodClass(contract))}>
                      {contract.endDate
                        ? formatRuDate(contract.endDate)
                        : "—"}
                    </span>
                  </span>
                </TableCell>
                <TableCell className="text-right font-medium tabular-nums">
                  {formatCurrency(contract.amount)}
                </TableCell>
                <TableCell>
                  <ContractStatusBadge status={contract.status} />
                </TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    </div>
  );
}
