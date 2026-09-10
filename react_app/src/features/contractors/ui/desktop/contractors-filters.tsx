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
import { ContractorTypeBadge } from "@/features/contractors/ui/shared/contractor-type-badge";
import type { ContractorFilters } from "@/features/contractors/types/contractor.types";
import {
  CONTRACTOR_TYPE_OPTIONS,
  isContractorType,
} from "@/features/contractors/utils/contractor-type";

const TYPE_FILTER_ITEMS = [
  { value: "all", label: "Все" },
  ...CONTRACTOR_TYPE_OPTIONS,
];

type ContractorsFiltersProps = {
  type: ContractorFilters["type"];
  onTypeChange: (value: ContractorFilters["type"]) => void;
  canCreate: boolean;
  onCreate: () => void;
};

export function ContractorsFilters({
  type,
  onTypeChange,
  canCreate,
  onCreate,
}: ContractorsFiltersProps) {
  return (
    <Card className="shadow-float max-lg:[--card-spacing:--spacing(3)]">
      <CardHeader className="border-b max-lg:hidden">
        <CardTitle>Фильтры</CardTitle>
        {canCreate ? (
          <CardAction>
            <Button
              type="button"
              size="icon"
              aria-label="Добавить контрагента"
              onClick={onCreate}
            >
              <PlusIcon />
            </Button>
          </CardAction>
        ) : null}
      </CardHeader>
      <CardContent className="flex items-center gap-3">
        <div className="flex min-w-0 flex-1 items-center gap-2">
          <FieldLabel htmlFor="contractors-type" className="shrink-0">
            Тип
          </FieldLabel>
          <div className="min-w-0 flex-1">
            <Select
              value={type}
              items={TYPE_FILTER_ITEMS}
              onValueChange={(value) => {
                if (value === "all" || isContractorType(value)) {
                  onTypeChange(value);
                }
              }}
            >
              <SelectTrigger id="contractors-type" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent align="start">
                <SelectGroup>
                  <SelectItem value="all">Все</SelectItem>
                  {CONTRACTOR_TYPE_OPTIONS.map((option) => (
                    <SelectItem key={option.value} value={option.value}>
                      <ContractorTypeBadge type={option.value} />
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
            aria-label="Добавить контрагента"
            onClick={onCreate}
          >
            <PlusIcon />
          </Button>
        ) : null}
      </CardContent>
    </Card>
  );
}
