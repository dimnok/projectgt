"use client";

import { useState } from "react";
import type { LucideIcon } from "lucide-react";
import {
  CalculatorIcon,
  ClipboardCheckIcon,
  FilePlus2Icon,
  FileTextIcon,
  FolderArchiveIcon,
  WalletIcon,
} from "lucide-react";

import { EmptyState } from "@/components/shared/empty-state";
import type { Contract } from "@/features/contracts/types/contract.types";
import { ContractDetails } from "@/features/contracts/ui/shared/contract-details";
import { ContractEstimatesTab } from "@/features/contracts/ui/shared/contract-estimates-tab";
import { ContractSettlementsTab } from "@/features/settlements/ui/shared/contract-settlements-tab";
import { cn } from "@/lib/utils";

type TabItem = {
  value: string;
  label: string;
  icon: LucideIcon;
  description: string;
};

const CONTRACT_DETAIL_TABS: readonly TabItem[] = [
  {
    value: "general",
    label: "Общие данные",
    icon: FileTextIcon,
    description: "Основные реквизиты, суммы и подписанты договора",
  },
  {
    value: "estimates",
    label: "Сметы",
    icon: CalculatorIcon,
    description: "Сметные расчеты, разделы и статьи затрат",
  },
  {
    value: "addenda",
    label: "ДС",
    icon: FilePlus2Icon,
    description: "Дополнительные соглашения к договору",
  },
  {
    value: "acts",
    label: "Акты",
    icon: ClipboardCheckIcon,
    description: "Акты выполненных работ и формы КС-2",
  },
  {
    value: "documents",
    label: "Документы",
    icon: FolderArchiveIcon,
    description: "Файлы, сканы и прикрепленные документы",
  },
  {
    value: "finances",
    label: "Финансы",
    icon: WalletIcon,
    description: "Платежи, взаиморасчеты и аналитика расходов",
  },
];

type ContractDetailsTabsProps = {
  contract: Contract;
  canUpdate?: boolean;
  canDelete?: boolean;
  onEdit?: () => void;
  onDelete?: () => void;
};

export function ContractDetailsTabs({
  contract,
  canUpdate = false,
  canDelete = false,
  onEdit,
  onDelete,
}: ContractDetailsTabsProps) {
  const [activeTab, setActiveTab] = useState<string>("general");

  return (
    <div key={contract.id} className="flex min-h-0 flex-1 flex-col">
      <div
        role="tablist"
        aria-label="Вкладки договора"
        className="relative z-10 flex h-11 w-full items-end rounded-t-xl border-t border-x border-border/70 bg-muted/80 px-4 pt-1.5 shadow-[inset_0_1px_2px_rgba(0,0,0,0.05)] dark:bg-muted/40 dark:shadow-[inset_0_1px_2px_rgba(0,0,0,0.2)]"
      >
        {CONTRACT_DETAIL_TABS.map((tab, index) => {
          const Icon = tab.icon;
          const isActive = tab.value === activeTab;

          return (
            <div key={tab.value} className="relative flex flex-1 min-w-0 items-end">
              <button
                type="button"
                role="tab"
                id={`contract-tab-${tab.value}`}
                aria-selected={isActive}
                aria-controls={`contract-panel-${tab.value}`}
                tabIndex={isActive ? 0 : -1}
                onClick={() => setActiveTab(tab.value)}
                onKeyDown={(e) => {
                  if (e.key === "ArrowRight") {
                    const next = (index + 1) % CONTRACT_DETAIL_TABS.length;
                    setActiveTab(CONTRACT_DETAIL_TABS[next].value);
                  } else if (e.key === "ArrowLeft") {
                    const prev =
                      (index - 1 + CONTRACT_DETAIL_TABS.length) %
                      CONTRACT_DETAIL_TABS.length;
                    setActiveTab(CONTRACT_DETAIL_TABS[prev].value);
                  }
                }}
                className={cn(
                  "relative flex w-full flex-1 items-center justify-center gap-2 whitespace-nowrap text-sm outline-none transition-colors select-none",
                  isActive
                    ? "z-20 -mb-[2px] h-[calc(2.5rem+2px)] rounded-t-xl bg-popover px-2 font-semibold text-popover-foreground sm:px-4"
                    : "z-10 h-8 px-2 font-medium text-muted-foreground hover:text-foreground sm:px-3"
                )}
              >
                {isActive ? (
                  <svg
                    aria-hidden="true"
                    className="pointer-events-none absolute -left-3.5 -bottom-[2px] h-4 w-3.5 fill-popover"
                    viewBox="0 0 14 16"
                    fill="none"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M14 0V16H0V14C7.73199 14 14 7.73199 14 0Z" />
                  </svg>
                ) : null}

                {isActive ? (
                  <div
                    aria-hidden="true"
                    className="pointer-events-none absolute inset-x-2 top-0 h-px bg-gradient-to-r from-transparent via-white/30 to-transparent dark:via-white/20"
                  />
                ) : null}

                <Icon
                  className={cn(
                    "size-4 shrink-0 transition-opacity",
                    isActive ? "opacity-100" : "opacity-60"
                  )}
                />
                <span className="truncate">{tab.label}</span>

                {isActive ? (
                  <svg
                    aria-hidden="true"
                    className="pointer-events-none absolute -right-3.5 -bottom-[2px] h-4 w-3.5 fill-popover"
                    viewBox="0 0 14 16"
                    fill="none"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M0 0V16H14V14C6.26801 14 0 7.73199 0 0Z" />
                  </svg>
                ) : null}

                {isActive ? (
                  <div
                    aria-hidden="true"
                    className="pointer-events-none absolute inset-x-0 -bottom-[2px] h-2 bg-popover"
                  />
                ) : null}
              </button>
            </div>
          );
        })}
      </div>

      <div
        className={cn(
          "relative min-h-0 flex-1 rounded-b-xl border border-border/70 bg-popover",
          activeTab === "estimates" || activeTab === "finances"
            ? "p-0 flex flex-col overflow-hidden"
            : "p-5 overflow-y-auto"
        )}
      >
        {CONTRACT_DETAIL_TABS.map((tab) => {
          if (tab.value !== activeTab) return null;

          return (
            <div
              key={tab.value}
              role="tabpanel"
              id={`contract-panel-${tab.value}`}
              aria-labelledby={`contract-tab-${tab.value}`}
              className={cn(
                "outline-none",
                (tab.value === "estimates" || tab.value === "finances") &&
                  "flex min-h-0 flex-1 flex-col h-full overflow-hidden"
              )}
            >
              {tab.value === "general" ? (
                <ContractDetails
                  contract={contract}
                  canUpdate={canUpdate}
                  canDelete={canDelete}
                  onEdit={onEdit}
                  onDelete={onDelete}
                />
              ) : tab.value === "estimates" ? (
                <ContractEstimatesTab contract={contract} />
              ) : tab.value === "finances" ? (
                <ContractSettlementsTab contract={contract} />
              ) : (
                <EmptyState
                  title={tab.label}
                  description={tab.description}
                  icon={tab.icon}
                />
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
