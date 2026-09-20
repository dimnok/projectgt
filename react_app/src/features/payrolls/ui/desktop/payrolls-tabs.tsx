"use client";

import { TabsIndicator, TabsList, TabsTrigger } from "@/components/ui/tabs";

const PAYROLL_TABS = [
  { value: "fot", label: "ФОТ" },
  { value: "bonuses", label: "Премии" },
  { value: "penalties", label: "Удержания" },
  { value: "payouts", label: "Выплаты" },
] as const;

export type PayrollTabValue = (typeof PAYROLL_TABS)[number]["value"];

/** Переключатель вкладок модуля ФОТ. */
export function PayrollsTabList() {
  return (
    <div className="flex shrink-0 justify-center border-b border-border/80 px-4 py-2 sm:px-5">
      <TabsList variant="pills" className="h-9 w-full max-w-2xl">
        <TabsIndicator />
        {PAYROLL_TABS.map((tab) => (
          <TabsTrigger key={tab.value} value={tab.value}>
            {tab.label}
          </TabsTrigger>
        ))}
      </TabsList>
    </div>
  );
}
