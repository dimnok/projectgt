"use client";

import { PlusIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Card,
  CardAction,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { FieldLabel } from "@/components/ui/field";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { ContractKindBadge } from "@/features/contracts/ui/shared/contract-kind-badge";
import { ContractStatusBadge } from "@/features/contracts/ui/shared/contract-status-badge";
import type { ContractFilters } from "@/features/contracts/types/contract.types";
import {
  CONTRACT_KIND_OPTIONS,
  isContractKind,
} from "@/features/contracts/utils/contract-kind";
import {
  CONTRACT_STATUS_OPTIONS,
  isContractStatus,
} from "@/features/contracts/utils/contract-status";

const KIND_FILTER_ITEMS = [
  { value: "all", label: "Все" },
  ...CONTRACT_KIND_OPTIONS,
];

const STATUS_FILTER_ITEMS = [
  { value: "all", label: "Все" },
  ...CONTRACT_STATUS_OPTIONS,
];

type ContractsFiltersProps = {
  kind: ContractFilters["kind"];
  status: ContractFilters["status"];
  onKindChange: (value: ContractFilters["kind"]) => void;
  onStatusChange: (value: ContractFilters["status"]) => void;
  canCreate: boolean;
  onCreate: () => void;
};

export function ContractsFilters({
  kind,
  status,
  onKindChange,
  onStatusChange,
  canCreate,
  onCreate,
}: ContractsFiltersProps) {
  return (
    <Card className="shadow-float max-lg:[--card-spacing:--spacing(3)]">
      <CardHeader className="border-b max-lg:hidden">
        <CardTitle>Фильтры</CardTitle>
        {canCreate ? (
          <CardAction>
            <Button
              type="button"
              size="icon"
              aria-label="Добавить договор"
              onClick={onCreate}
            >
              <PlusIcon />
            </Button>
          </CardAction>
        ) : null}
      </CardHeader>
      <CardContent className="flex flex-col gap-3">
        <div className="flex items-center gap-3">
          <div className="flex min-w-0 flex-1 items-center gap-2">
            <FieldLabel htmlFor="contracts-kind" className="shrink-0">
              Тип
            </FieldLabel>
            <div className="min-w-0 flex-1">
              <Select
                value={kind}
                items={KIND_FILTER_ITEMS}
                onValueChange={(value) => {
                  if (value === "all" || isContractKind(value)) {
                    onKindChange(value);
                  }
                }}
              >
                <SelectTrigger id="contracts-kind" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent align="start">
                  <SelectGroup>
                    <SelectItem value="all">Все</SelectItem>
                    {CONTRACT_KIND_OPTIONS.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        <ContractKindBadge kind={option.value} />
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            </div>
          </div>
          {canCreate ? (
            <Button
              type="button"
              size="icon"
              className="lg:hidden"
              aria-label="Добавить договор"
              onClick={onCreate}
            >
              <PlusIcon />
            </Button>
          ) : null}
        </div>
        <div className="flex min-w-0 items-center gap-2">
          <FieldLabel htmlFor="contracts-status" className="shrink-0">
            Статус
          </FieldLabel>
          <div className="min-w-0 flex-1">
            <Select
              value={status}
              items={STATUS_FILTER_ITEMS}
              onValueChange={(value) => {
                if (value === "all" || isContractStatus(value)) {
                  onStatusChange(value);
                }
              }}
            >
              <SelectTrigger id="contracts-status" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent align="start">
                <SelectGroup>
                  <SelectItem value="all">Все</SelectItem>
                  {CONTRACT_STATUS_OPTIONS.map((option) => (
                    <SelectItem key={option.value} value={option.value}>
                      <ContractStatusBadge status={option.value} />
                    </SelectItem>
                  ))}
                </SelectGroup>
              </SelectContent>
            </Select>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
