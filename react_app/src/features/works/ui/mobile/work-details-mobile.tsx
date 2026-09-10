"use client";

import { useMemo, useState } from "react";
import type { LucideIcon } from "lucide-react";
import {
  ChevronLeftIcon,
  ClipboardListIcon,
  HammerIcon,
  PlusIcon,
  SearchIcon,
  Trash2Icon,
  UsersIcon,
} from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  InputGroup,
  InputGroupAddon,
  InputGroupInput,
} from "@/components/ui/input-group";
import {
  Tabs,
  TabsContent,
  TabsIndicator,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import { usePermissions } from "@/hooks/use-permissions";
import { useDeleteWork } from "@/features/works/hooks/use-open-work";
import { useWorkHours, useWorkItems } from "@/features/works/hooks/use-works";
import { useWorkMembership } from "@/features/works/hooks/use-work-item-mutations";
import { WorkHoursMobile } from "@/features/works/ui/mobile/work-hours-mobile";
import { WorkItemsMobile } from "@/features/works/ui/mobile/work-items-mobile";
import { WorkDataTab } from "@/features/works/ui/shared/work-data-tab";
import { WorkDeleteDialog } from "@/features/works/ui/shared/work-delete-dialog";
import { WorkHourFormSheet } from "@/features/works/ui/mobile/work-hour-form-sheet";
import { WorkItemAddSheet } from "@/features/works/ui/mobile/work-item-add-sheet";
import { WorkItemPlaceFilters } from "@/features/works/ui/shared/work-item-place-filters";
import { WorkStatusBadge } from "@/features/works/ui/shared/work-status-badge";
import type { Work } from "@/features/works/types/work.types";
import {
  canModifyWorkItems,
  formatRuDate,
  uniqueWorkItemFloors,
  uniqueWorkItemSections,
  uniqueWorkItemSystems,
  type WorkItemPlaceFilter,
} from "@/features/works/utils/work.utils";
import { MobileAppBar } from "@/layouts/mobile/mobile-app-bar";

type WorkDetailsMobileProps = {
  work: Work;
  onBack: () => void;
  onDeleted: () => void;
};

export function WorkDetailsMobile({
  work,
  onBack,
  onDeleted,
}: WorkDetailsMobileProps) {
  const [search, setSearch] = useState("");
  const [tab, setTab] = useState("data");
  const [placeFilter, setPlaceFilter] = useState<WorkItemPlaceFilter>({
    system: null,
    section: null,
    floor: null,
  });
  const [addOpen, setAddOpen] = useState(false);
  const [addHourOpen, setAddHourOpen] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const showSearch = tab === "items" || tab === "hours";
  const { can } = usePermissions();
  const membershipQuery = useWorkMembership();
  const itemsQuery = useWorkItems(work.id);
  const hoursQuery = useWorkHours(work.id);
  const items = useMemo(() => itemsQuery.data ?? [], [itemsQuery.data]);
  const hours = useMemo(() => hoursQuery.data ?? [], [hoursQuery.data]);
  const systems = useMemo(() => uniqueWorkItemSystems(items), [items]);
  const activeSystem =
    placeFilter.system && systems.includes(placeFilter.system)
      ? placeFilter.system
      : null;
  const sections = useMemo(
    () => uniqueWorkItemSections(items, activeSystem),
    [items, activeSystem]
  );
  const activeSection =
    placeFilter.section && sections.includes(placeFilter.section)
      ? placeFilter.section
      : null;
  const floors = useMemo(
    () => uniqueWorkItemFloors(items, activeSystem, activeSection),
    [items, activeSystem, activeSection]
  );
  const activeFloor =
    placeFilter.floor && floors.includes(placeFilter.floor)
      ? placeFilter.floor
      : null;
  const activePlaceFilter: WorkItemPlaceFilter = {
    system: activeSystem,
    section: activeSection,
    floor: activeFloor,
  };
  const canModify = canModifyWorkItems({
    canUpdate: can("works", "update"),
    userId: membershipQuery.data?.userId ?? null,
    openedBy: work.openedBy,
    status: work.status,
    isSuperAdmin: membershipQuery.data?.isSuperAdmin ?? false,
  });
  const isSuperAdmin = membershipQuery.data?.isSuperAdmin ?? false;
  const canReopen = isSuperAdmin && can("works", "update");
  const canDeleteShift = isSuperAdmin && can("works", "delete");
  const deleteWorkMutation = useDeleteWork();

  function handleTabChange(value: string) {
    setTab(value);
    if (value !== "items") {
      setAddOpen(false);
    }
    if (value !== "hours") {
      setAddHourOpen(false);
    }
  }

  const tabs: {
    value: string;
    label: string;
    icon: LucideIcon;
    badge?: number;
  }[] = [
    { value: "data", label: "Обзор", icon: ClipboardListIcon },
    {
      value: "items",
      label: "Работы",
      icon: HammerIcon,
      badge: work.itemsCount,
    },
    {
      value: "hours",
      label: "Люди",
      icon: UsersIcon,
      badge: work.employeesCount,
    },
  ];

  return (
    <div
      data-fill-viewport
      className="-m-4 flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-background"
    >
      <Tabs
        value={tab}
        onValueChange={(value) => handleTabChange(String(value))}
        className="flex h-full min-h-0 min-w-0 flex-1 flex-col gap-0"
      >
        <header className="shrink-0 border-b bg-background">
          <MobileAppBar
            title={`Смена ${formatRuDate(work.date)}`}
            className="border-b-0"
            leading={
              <Button
                type="button"
                variant="ghost"
                size="icon"
                className="rounded-full"
                aria-label="Назад к списку смен"
                onClick={onBack}
              >
                <ChevronLeftIcon />
              </Button>
            }
            trailing={
              canDeleteShift ? (
                <Button
                  type="button"
                  variant="ghost"
                  size="icon"
                  className="rounded-full text-destructive hover:text-destructive"
                  aria-label="Удалить смену"
                  onClick={() => setDeleteOpen(true)}
                >
                  <Trash2Icon />
                </Button>
              ) : undefined
            }
          />
          <div className="flex items-center gap-2 px-4 pb-2">
            <WorkStatusBadge status={work.status} />
            <p className="min-w-0 truncate text-sm text-muted-foreground">
              {work.objectName}
            </p>
          </div>
          <div className="flex flex-col gap-2 px-4 pb-3">
            <TabsList variant="pills" className="h-10 w-full">
              <TabsIndicator />
              {tabs.map((item) => {
                const Icon = item.icon;
                return (
                  <TabsTrigger
                    key={item.value}
                    value={item.value}
                    className="gap-1 px-2 text-[11px]"
                  >
                    <Icon className="size-3.5" />
                    <span>{item.label}</span>
                    {typeof item.badge === "number" && item.badge > 0 ? (
                      <span className="rounded-full bg-muted-foreground/20 px-1.5 py-0.2 text-[10px] font-medium tabular-nums">
                        {item.badge}
                      </span>
                    ) : null}
                  </TabsTrigger>
                );
              })}
            </TabsList>
            {showSearch ? (
              <div className="flex flex-col gap-2">
                {tab === "items" ? (
                  <WorkItemPlaceFilters
                    system={activePlaceFilter.system}
                    section={activePlaceFilter.section}
                    floor={activePlaceFilter.floor}
                    systems={systems}
                    sections={sections}
                    floors={floors}
                    disabled={itemsQuery.isLoading}
                    onChange={setPlaceFilter}
                  />
                ) : null}
                <div className="flex items-center gap-2">
                  <InputGroup className="min-w-0 flex-1 bg-background">
                    <InputGroupAddon>
                      <SearchIcon />
                    </InputGroupAddon>
                    <InputGroupInput
                      type="search"
                      value={search}
                      placeholder={
                        tab === "items"
                          ? "Поиск по работам"
                          : "Поиск по сотрудникам"
                      }
                      aria-label={
                        tab === "items"
                          ? "Поиск по работам"
                          : "Поиск по сотрудникам"
                      }
                      onChange={(event) => setSearch(event.target.value)}
                    />
                  </InputGroup>
                  {tab === "items" && canModify ? (
                    <Button
                      type="button"
                      size="icon"
                      aria-label="Добавить работы"
                      onClick={() => setAddOpen(true)}
                    >
                      <PlusIcon />
                    </Button>
                  ) : null}
                  {tab === "hours" && canModify ? (
                    <Button
                      type="button"
                      size="icon"
                      aria-label="Добавить сотрудника"
                      onClick={() => setAddHourOpen(true)}
                    >
                      <PlusIcon />
                    </Button>
                  ) : null}
                </div>
              </div>
            ) : null}
          </div>
        </header>

        <div className="flex min-h-0 flex-1 flex-col overflow-hidden">
          <TabsContent
            value="data"
            className="mt-0 min-h-0 flex-1 overflow-y-auto overflow-x-hidden overscroll-y-contain px-4 pt-3 pb-[max(0.75rem,env(safe-area-inset-bottom))] outline-none"
          >
            <WorkDataTab
              work={work}
              canModify={canModify}
              canReopen={canReopen}
            />
          </TabsContent>
          <TabsContent
            value="items"
            className="mt-0 min-h-0 flex-1 overflow-y-auto overflow-x-hidden overscroll-y-contain px-4 pt-3 pb-[max(0.75rem,env(safe-area-inset-bottom))] outline-none"
          >
            <WorkItemsMobile
              workId={work.id}
              objectId={work.objectId}
              search={search}
              placeFilter={activePlaceFilter}
              canModify={canModify}
            />
          </TabsContent>
          <TabsContent
            value="hours"
            className="mt-0 flex min-h-0 flex-1 flex-col overflow-hidden outline-none"
          >
            <WorkHoursMobile
              workId={work.id}
              objectId={work.objectId}
              search={search}
              canModify={canModify}
            />
          </TabsContent>
        </div>
      </Tabs>
      <WorkItemAddSheet
        open={addOpen}
        workId={work.id}
        objectId={work.objectId}
        existingItems={items}
        onOpenChange={setAddOpen}
      />
      <WorkHourFormSheet
        open={addHourOpen}
        workId={work.id}
        objectId={work.objectId}
        existingHours={hours}
        onOpenChange={setAddHourOpen}
      />
      <WorkDeleteDialog
        workDate={deleteOpen ? work.date : null}
        isDeleting={deleteWorkMutation.isPending}
        onOpenChange={setDeleteOpen}
        onConfirm={() => {
          void (async () => {
            try {
              await deleteWorkMutation.mutateAsync(work.id);
              toast.success("Смена удалена");
              setDeleteOpen(false);
              onDeleted();
            } catch (error) {
              toast.error(
                error instanceof Error
                  ? error.message
                  : "Не удалось удалить смену"
              );
            }
          })();
        }}
      />
    </div>
  );
}
