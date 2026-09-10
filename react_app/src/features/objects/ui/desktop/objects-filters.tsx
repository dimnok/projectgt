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
import { ObjectStatusBadge } from "@/features/objects/ui/shared/object-status-badge";
import type { ObjectFilters } from "@/features/objects/types/object.types";
import {
  isObjectStatus,
  OBJECT_STATUS_OPTIONS,
} from "@/features/objects/utils/object-status";

const STATUS_FILTER_ITEMS = [
  { value: "all", label: "Все" },
  ...OBJECT_STATUS_OPTIONS,
];

type ObjectsFiltersProps = {
  status: ObjectFilters["status"];
  onStatusChange: (value: ObjectFilters["status"]) => void;
  canCreate: boolean;
  onCreate: () => void;
};

export function ObjectsFilters({
  status,
  onStatusChange,
  canCreate,
  onCreate,
}: ObjectsFiltersProps) {
  return (
    <Card className="shadow-float max-lg:[--card-spacing:--spacing(3)]">
      <CardHeader className="border-b max-lg:hidden">
        <CardTitle>Фильтры</CardTitle>
        {canCreate ? (
          <CardAction>
            <Button
              type="button"
              size="icon"
              aria-label="Добавить объект"
              onClick={onCreate}
            >
              <PlusIcon />
            </Button>
          </CardAction>
        ) : null}
      </CardHeader>
      <CardContent className="flex items-center gap-3">
        <div className="flex min-w-0 flex-1 items-center gap-2">
          <FieldLabel htmlFor="objects-status" className="shrink-0">
            Статус
          </FieldLabel>
          <div className="min-w-0 flex-1">
            <Select
              value={status}
              items={STATUS_FILTER_ITEMS}
              onValueChange={(value) => {
                if (value === "all" || isObjectStatus(value)) {
                  onStatusChange(value);
                }
              }}
            >
              <SelectTrigger id="objects-status" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent align="start">
                <SelectGroup>
                  <SelectItem value="all">Все</SelectItem>
                  {OBJECT_STATUS_OPTIONS.map((option) => (
                    <SelectItem key={option.value} value={option.value}>
                      <ObjectStatusBadge status={option.value} />
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
            aria-label="Добавить объект"
            onClick={onCreate}
          >
            <PlusIcon />
          </Button>
        ) : null}
      </CardContent>
    </Card>
  );
}
