"use client";

import type { LucideIcon } from "lucide-react";
import {
  BoxesIcon,
  CalendarCheckIcon,
  FileTextIcon,
  UserCheckIcon,
  WalletIcon,
} from "lucide-react";

import {
  Tabs,
  TabsContent,
  TabsIndicator,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import type {
  Employee,
  EmployeeObjectOption,
} from "@/features/employees/types/employee.types";
import { EmployeeApplicationsTab } from "@/features/employees/ui/shared/employee-applications-tab";
import { EmployeeDetails } from "@/features/employees/ui/shared/employee-details";
import { EmployeeTimesheetTab } from "@/features/employees/ui/shared/employee-timesheet-tab";
import { EmployeeTmcTab } from "@/features/employees/ui/shared/employee-tmc-tab";
import { usePermissions } from "@/hooks/use-permissions";

type TabItem = {
  value: string;
  label: string;
  shortLabel: string;
  icon: LucideIcon;
};

const BASE_EMPLOYEE_TABS: readonly TabItem[] = [
  { value: "overview", label: "Обзор", shortLabel: "Обзор", icon: UserCheckIcon },
  {
    value: "timesheet",
    label: "Табель",
    shortLabel: "Табель",
    icon: CalendarCheckIcon,
  },
  { value: "tmc", label: "ТМЦ", shortLabel: "ТМЦ", icon: BoxesIcon },
  {
    value: "applications",
    label: "Заявления",
    shortLabel: "Заяв.",
    icon: FileTextIcon,
  },
];

const FINANCES_TAB: TabItem = {
  value: "finances",
  label: "Финансы",
  shortLabel: "₽",
  icon: WalletIcon,
};

type EmployeeDetailsTabsProps = {
  employee: Employee;
  objects: EmployeeObjectOption[];
  objectNamesById: Map<string, string>;
  canUpdate: boolean;
  layout?: "dialog" | "page";
};

export function EmployeeDetailsTabs({
  employee,
  objects,
  objectNamesById,
  canUpdate,
  layout = "dialog",
}: EmployeeDetailsTabsProps) {
  const { isOwner, can } = usePermissions();
  const canViewFinances = isOwner || can("payroll", "read") || can("employees", "update");
  const isPage = layout === "page";

  const tabs = canViewFinances
    ? [...BASE_EMPLOYEE_TABS, FINANCES_TAB]
    : BASE_EMPLOYEE_TABS;

  return (
    <Tabs
      key={employee.id}
      defaultValue="overview"
      className="flex min-h-0 flex-1 flex-col gap-0"
    >
      <div
        className={
          isPage
            ? "shrink-0 bg-background px-4 pt-3 pb-3"
            : "shrink-0 border-b border-border/60 bg-muted/25 px-6 pb-5"
        }
      >
        <TabsList variant="pills" className={isPage ? "h-10 w-full" : "h-10"}>
          <TabsIndicator />
          {tabs.map((tab) => {
            const Icon = tab.icon;
            return (
              <TabsTrigger
                key={tab.value}
                value={tab.value}
                aria-label={tab.label}
                className={
                  isPage
                    ? "group/tab gap-1 px-2"
                    : undefined
                }
              >
                <Icon />
                <span
                  className={
                    isPage
                      ? "hidden min-w-0 truncate group-data-active/tab:inline"
                      : "truncate"
                  }
                >
                  {isPage ? tab.shortLabel : tab.label}
                </span>
              </TabsTrigger>
            );
          })}
        </TabsList>
      </div>

      <div
        className={
          isPage
            ? "min-h-0 flex-1 overflow-y-auto overscroll-contain px-4 py-4"
            : "min-h-0 flex-1 overflow-y-auto px-6 py-5"
        }
      >
        <TabsContent value="overview">
          <EmployeeDetails
            employee={employee}
            objects={objects}
            objectNamesById={objectNamesById}
            canUpdate={canUpdate}
            canViewFinances={canViewFinances}
          />
        </TabsContent>

        <TabsContent value="timesheet">
          <EmployeeTimesheetTab
            employee={employee}
            objectNamesById={objectNamesById}
          />
        </TabsContent>

        <TabsContent value="tmc">
          <EmployeeTmcTab
            employee={employee}
            objectNamesById={objectNamesById}
          />
        </TabsContent>

        <TabsContent value="applications">
          <EmployeeApplicationsTab
            employee={employee}
            canManage={canUpdate}
          />
        </TabsContent>

        {canViewFinances ? (
          <TabsContent value="finances">
            <div className="flex min-h-60 flex-col items-center justify-center gap-2 rounded-2xl border border-dashed border-border p-8 text-center">
              <div className="flex size-12 items-center justify-center rounded-2xl bg-muted text-muted-foreground">
                <WalletIcon className="size-6" />
              </div>
              <h4 className="text-base font-semibold text-foreground">
                Финансы и взаиморасчёты
              </h4>
              <p className="max-w-md text-xs text-muted-foreground">
                Раздел финансовой аналитики, начислений, выплат заработной платы и
                авансов сотрудника находится в разработке.
              </p>
            </div>
          </TabsContent>
        ) : null}
      </div>
    </Tabs>
  );
}
