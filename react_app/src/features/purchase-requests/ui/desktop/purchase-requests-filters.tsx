"use client";

import { PlusIcon, SettingsIcon } from "lucide-react";

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
import type {
  PurchaseRequestCounts,
  PurchaseRequestListFilter,
} from "@/features/purchase-requests/types/purchase-request.types";
import {
  isPurchaseRequestListFilter,
  PURCHASE_REQUEST_FILTER_OPTIONS,
} from "@/features/purchase-requests/utils/status";

type PurchaseRequestsFiltersProps = {
  filter: PurchaseRequestListFilter;
  counts?: PurchaseRequestCounts;
  canCreate: boolean;
  canOpenSettings: boolean;
  onFilterChange: (value: PurchaseRequestListFilter) => void;
  onCreate: () => void;
  onSettings: () => void;
};

export function PurchaseRequestsFilters({
  filter,
  counts,
  canCreate,
  canOpenSettings,
  onFilterChange,
  onCreate,
  onSettings,
}: PurchaseRequestsFiltersProps) {
  return (
    <Card className="shadow-float max-lg:[--card-spacing:--spacing(3)]">
      <CardHeader className="border-b max-lg:hidden">
        <CardTitle>Фильтры</CardTitle>
        <CardAction className="flex items-center gap-2">
          {canOpenSettings ? (
            <Button
              type="button"
              size="icon"
              variant="outline"
              aria-label="Настройка согласующих"
              onClick={onSettings}
            >
              <SettingsIcon />
            </Button>
          ) : null}
          {canCreate ? (
            <Button
              type="button"
              size="icon"
              aria-label="Новая заявка"
              onClick={onCreate}
            >
              <PlusIcon />
            </Button>
          ) : null}
        </CardAction>
      </CardHeader>
      <CardContent className="flex items-center gap-3">
        <div className="flex min-w-0 flex-1 items-center gap-2">
          <FieldLabel htmlFor="purchase-requests-filter" className="shrink-0">
            Статус
          </FieldLabel>
          <div className="min-w-0 flex-1">
            <Select
              value={filter}
              items={PURCHASE_REQUEST_FILTER_OPTIONS}
              onValueChange={(value) => {
                if (value && isPurchaseRequestListFilter(value)) {
                  onFilterChange(value);
                }
              }}
            >
              <SelectTrigger id="purchase-requests-filter" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent align="start">
                <SelectGroup>
                  {PURCHASE_REQUEST_FILTER_OPTIONS.map((item) => {
                    const count = counts?.[item.value];
                    const label =
                      typeof count === "number"
                        ? `${item.label} (${count})`
                        : item.label;
                    return (
                      <SelectItem key={item.value} value={item.value}>
                        {label}
                      </SelectItem>
                    );
                  })}
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
            aria-label="Новая заявка"
            onClick={onCreate}
          >
            <PlusIcon />
          </Button>
        ) : null}
      </CardContent>
    </Card>
  );
}
