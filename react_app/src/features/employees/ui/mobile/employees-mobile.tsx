"use client";

import { PlusIcon } from "lucide-react";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { Button } from "@/components/ui/button";
import { FieldLabel } from "@/components/ui/field";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useEmployeesScreen } from "@/features/employees/hooks/use-employees-screen";
import { EmployeeCreateSheet } from "@/features/employees/ui/mobile/employee-create-sheet";
import { EmployeeDetailsMobile } from "@/features/employees/ui/mobile/employee-details-mobile";
import { EmployeeFormSheet } from "@/features/employees/ui/mobile/employee-form-sheet";
import { EmployeesMobileList } from "@/features/employees/ui/mobile/employees-mobile-list";
import {
  EMPLOYEE_STATUS_OPTIONS,
  employeeStatusLabel,
  isEmployeeStatus,
} from "@/features/employees/utils/employee-status";
import {
  countEmployeesByStatus,
  formatEmployeeCount,
} from "@/features/employees/utils/employee.utils";
import { AppSearchField } from "@/layouts/desktop/app-search";
import { MobileAppBar } from "@/layouts/mobile/mobile-app-bar";

const STATUS_FILTER_ITEMS = [
  { value: "all", label: "Все" },
  ...EMPLOYEE_STATUS_OPTIONS,
];

export function EmployeesMobile() {
  const screen = useEmployeesScreen();
  const { total, byStatus } = countEmployeesByStatus(screen.allEmployees);
  const workingCount = byStatus.working;

  if (screen.isLoading) {
    return <Loading />;
  }

  if (screen.isError) {
    return (
      <ErrorState
        message={
          screen.error instanceof Error
            ? screen.error.message
            : "Неизвестная ошибка"
        }
      />
    );
  }

  const objectItems = [
    { value: "all", label: "Все объекты" },
    ...screen.objects.map((object) => ({
      value: object.id,
      label: object.name,
    })),
  ];

  const sheets = (
    <>
      <EmployeeCreateSheet
        open={screen.isCreateOpen}
        objects={screen.objects}
        isSaving={screen.isCreating}
        onOpenChange={screen.setIsCreateOpen}
        onSubmit={screen.handleCreate}
      />
      <EmployeeFormSheet
        employee={screen.editorEmployee}
        objects={screen.objects}
        positions={screen.positions}
        isSaving={screen.isUpdating}
        onOpenChange={(open) => {
          if (!open) {
            screen.setEditorEmployee(null);
          }
        }}
        onSubmit={screen.handleUpdate}
      />
    </>
  );

  if (screen.selectedEmployee) {
    return (
      <>
        <EmployeeDetailsMobile
          employee={screen.selectedEmployee}
          objects={screen.objects}
          objectNamesById={screen.objectNamesById}
          canUpdate={screen.canUpdate}
          onBack={() => {
            screen.setEditorEmployee(null);
            screen.selectEmployee(null);
          }}
          onEdit={screen.openEditor}
          onEmployeeUpdated={screen.setSelectedDraft}
        />
        {sheets}
      </>
    );
  }

  return (
    <div
      data-fill-viewport
      className="-m-4 flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-background"
    >
      <header className="shrink-0 border-b bg-background">
        <MobileAppBar
          title="Сотрудники"
          className="border-b-0"
          trailing={
            screen.canCreate ? (
              <Button
                type="button"
                size="icon"
                className="rounded-full"
                aria-label="Добавить сотрудника"
                onClick={() => screen.setIsCreateOpen(true)}
              >
                <PlusIcon />
              </Button>
            ) : undefined
          }
        />
        <div className="flex flex-col gap-3 px-4 pb-3">
          <AppSearchField
            placeholder="ФИО, должность, телефон"
            aria-label="Поиск по сотрудникам"
          />
          <div className="flex min-w-0 flex-wrap gap-1.5">
              {STATUS_FILTER_ITEMS.map((item) => {
                const isActive = screen.status === item.value;
                return (
                  <Button
                    key={item.value}
                    type="button"
                    size="sm"
                    variant={isActive ? "default" : "outline"}
                    className="rounded-full"
                    onClick={() => {
                      if (item.value === "all" || isEmployeeStatus(item.value)) {
                        screen.setStatus(item.value);
                      }
                    }}
                  >
                    {item.value === "all"
                      ? "Все"
                      : isEmployeeStatus(item.value)
                        ? employeeStatusLabel(item.value, "short")
                        : item.label}
                  </Button>
                );
              })}
          </div>
          {screen.objects.length > 0 ? (
            <div className="flex min-w-0 items-center gap-2">
              <FieldLabel htmlFor="employees-mobile-object" className="shrink-0">
                Объект
              </FieldLabel>
              <div className="min-w-0 flex-1">
                <Select
                  value={screen.objectId}
                  items={objectItems}
                  onValueChange={(value) => {
                    if (!value) {
                      return;
                    }
                    if (
                      value === "all" ||
                      screen.objects.some((item) => item.id === value)
                    ) {
                      screen.setObjectId(value);
                    }
                  }}
                >
                  <SelectTrigger id="employees-mobile-object" className="w-full">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent align="start">
                    <SelectGroup>
                      <SelectItem value="all">Все объекты</SelectItem>
                      {screen.objects.map((object) => (
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
          <p className="text-xs text-muted-foreground">
            В списке {formatEmployeeCount(screen.employees.length)}. В штате{" "}
            {workingCount}, всего {total}.
          </p>
        </div>
      </header>

      <div className="min-h-0 min-w-0 flex-1 overflow-y-auto overscroll-contain pb-6">
        {screen.employees.length === 0 ? (
          <div className="px-4 pt-6">
            <EmptyState
              title="Сотрудников нет"
              description="Добавьте сотрудника или измените фильтры."
            />
          </div>
        ) : (
          <EmployeesMobileList
            employees={screen.employees}
            onSelect={screen.selectEmployee}
          />
        )}
      </div>

      {sheets}
    </div>
  );
}
