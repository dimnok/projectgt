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

type TabItem = {
  value: string;
  label: string;
  icon: LucideIcon;
};

const EMPLOYEE_TABS: readonly TabItem[] = [
  { value: "overview", label: "Обзор", icon: UserCheckIcon },
  { value: "timesheet", label: "Табель", icon: CalendarCheckIcon },
  { value: "tmc", label: "ТМЦ", icon: BoxesIcon },
  { value: "applications", label: "Заявления", icon: FileTextIcon },
  { value: "finances", label: "Финансы", icon: WalletIcon },
];

type EmployeeDetailsTabsProps = {
  employee: Employee;
  objects: EmployeeObjectOption[];
  objectNamesById: Map<string, string>;
  canUpdate: boolean;
};

export function EmployeeDetailsTabs({
  employee,
  objects,
  objectNamesById,
  canUpdate,
}: EmployeeDetailsTabsProps) {
  return (
    <Tabs
      key={employee.id}
      defaultValue="overview"
      className="flex min-h-0 flex-1 flex-col gap-0"
    >
      <div className="shrink-0 border-b border-border/60 bg-muted/25 px-6 pb-5">
        <TabsList variant="pills" className="h-10">
          <TabsIndicator />
          {EMPLOYEE_TABS.map((tab) => {
            const Icon = tab.icon;
            return (
              <TabsTrigger key={tab.value} value={tab.value}>
                <Icon className="size-4" />
                <span className="truncate">{tab.label}</span>
              </TabsTrigger>
            );
          })}
        </TabsList>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto px-6 py-5">
        <TabsContent value="overview">
          <EmployeeDetails
            employee={employee}
            objects={objects}
            objectNamesById={objectNamesById}
            canUpdate={canUpdate}
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
      </div>
    </Tabs>
  );
}
