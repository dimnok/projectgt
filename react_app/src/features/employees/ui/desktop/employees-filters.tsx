"use client";

import { DownloadIcon, PlusIcon } from "lucide-react";

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
import { Spinner } from "@/components/ui/spinner";
import { EmployeeStatusBadge } from "@/features/employees/ui/shared/employee-status-badge";
import type {
  EmployeeFilters,
  EmployeeObjectOption,
} from "@/features/employees/types/employee.types";
import {
  EMPLOYEE_STATUS_OPTIONS,
  isEmployeeStatus,
} from "@/features/employees/utils/employee-status";

const STATUS_FILTER_ITEMS = [
  { value: "all", label: "Все" },
  ...EMPLOYEE_STATUS_OPTIONS,
];

type EmployeesFiltersProps = {
  status: EmployeeFilters["status"];
  objectId: EmployeeFilters["objectId"];
  objects: EmployeeObjectOption[];
  onStatusChange: (value: EmployeeFilters["status"]) => void;
  onObjectChange: (value: EmployeeFilters["objectId"]) => void;
  canCreate: boolean;
  onCreate: () => void;
  canExport: boolean;
  isExporting: boolean;
  onExport: () => void;
};

export function EmployeesFilters({
  status,
  objectId,
  objects,
  onStatusChange,
  onObjectChange,
  canCreate,
  onCreate,
  canExport,
  isExporting,
  onExport,
}: EmployeesFiltersProps) {
  const objectItems = [
    { value: "all", label: "Все объекты" },
    ...objects.map((object) => ({ value: object.id, label: object.name })),
  ];

  const exportButton = canExport ? (
    <Button
      type="button"
      variant="outline"
      disabled={isExporting}
      aria-label="Выгрузить в Excel"
      onClick={onExport}
    >
      {isExporting ? (
        <Spinner data-icon="inline-start" />
      ) : (
        <DownloadIcon data-icon="inline-start" />
      )}
      Excel
    </Button>
  ) : null;

  const exportIconButton = canExport ? (
    <Button
      type="button"
      variant="outline"
      size="icon"
      className="lg:hidden"
      disabled={isExporting}
      aria-label="Выгрузить в Excel"
      onClick={onExport}
    >
      {isExporting ? <Spinner /> : <DownloadIcon />}
    </Button>
  ) : null;

  return (
    <Card className="shadow-float max-lg:[--card-spacing:--spacing(3)]">
      <CardHeader className="border-b max-lg:hidden">
        <CardTitle>Фильтры</CardTitle>
        {canCreate || canExport ? (
          <CardAction className="flex items-center gap-2">
            {exportButton}
            {canCreate ? (
              <Button
                type="button"
                size="icon"
                aria-label="Добавить сотрудника"
                onClick={onCreate}
              >
                <PlusIcon />
              </Button>
            ) : null}
          </CardAction>
        ) : null}
      </CardHeader>
      <CardContent className="flex flex-col gap-3">
        <div className="flex items-center gap-3">
          <div className="flex min-w-0 flex-1 items-center gap-2">
            <FieldLabel htmlFor="employees-status" className="shrink-0">
              Статус
            </FieldLabel>
            <div className="min-w-0 flex-1">
              <Select
                value={status}
                items={STATUS_FILTER_ITEMS}
                onValueChange={(value) => {
                  if (value === "all" || (value && isEmployeeStatus(value))) {
                    onStatusChange(value);
                  }
                }}
              >
                <SelectTrigger id="employees-status" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent align="start">
                  <SelectGroup>
                    <SelectItem value="all">Все</SelectItem>
                    {EMPLOYEE_STATUS_OPTIONS.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        <EmployeeStatusBadge status={option.value} />
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            </div>
          </div>
          {exportIconButton}
          {canCreate ? (
            <Button
              type="button"
              size="icon"
              className="lg:hidden"
              aria-label="Добавить сотрудника"
              onClick={onCreate}
            >
              <PlusIcon />
            </Button>
          ) : null}
        </div>
        {objects.length > 0 ? (
          <div className="flex min-w-0 items-center gap-2">
            <FieldLabel htmlFor="employees-object" className="shrink-0">
              Объект
            </FieldLabel>
            <div className="min-w-0 flex-1">
              <Select
                value={objectId}
                items={objectItems}
                onValueChange={(value) => {
                  if (!value) {
                    return;
                  }
                  if (value === "all" || objects.some((item) => item.id === value)) {
                    onObjectChange(value);
                  }
                }}
              >
                <SelectTrigger id="employees-object" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent align="start">
                  <SelectGroup>
                    <SelectItem value="all">Все объекты</SelectItem>
                    {objects.map((object) => (
                      <SelectItem key={object.id} value={object.id}>
                        {object.name}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            </div>
          </div>
        ) : null}
      </CardContent>
    </Card>
  );
}
