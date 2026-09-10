"use client";

import { useEffect, useMemo, useState } from "react";
import type { LucideIcon } from "lucide-react";
import {
  BarChart3Icon,
  ClipboardListIcon,
  HammerIcon,
  MapPinIcon,
  PlusIcon,
  SearchIcon,
  Trash2Icon,
  UsersIcon,
  XIcon,
} from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
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
import { toast } from "sonner";
import { useDeleteWork } from "@/features/works/hooks/use-open-work";
import { useWorkHours, useWorkItems } from "@/features/works/hooks/use-works";
import { useWorkMembership } from "@/features/works/hooks/use-work-item-mutations";
import { WorkDataTab } from "@/features/works/ui/shared/work-data-tab";
import { WorkDeleteDialog } from "@/features/works/ui/shared/work-delete-dialog";
import { WorkHourFormDialog } from "@/features/works/ui/shared/work-hour-form-dialog";
import { WorkHoursTab } from "@/features/works/ui/shared/work-hours-tab";
import { WorkItemAddDialog } from "@/features/works/ui/shared/work-item-add-dialog";
import { WorkItemPlaceFilters } from "@/features/works/ui/shared/work-item-place-filters";
import { WorkItemsTab } from "@/features/works/ui/shared/work-items-tab";
import { WorkStatusBadge } from "@/features/works/ui/shared/work-status-badge";
import type { Work } from "@/features/works/types/work.types";
import {
  canModifyWorkItems,
  formatMonthYear,
  formatRuDate,
  uniqueWorkItemFloors,
  uniqueWorkItemSections,
  uniqueWorkItemSystems,
  type WorkItemPlaceFilter,
} from "@/features/works/utils/work.utils";

type WorkDetailsProps = {
  work: Work;
  headerMonth?: string;
  onSwitchToSummary?: () => void;
  onClose?: () => void;
  onDeleted?: () => void;
};

export function WorkDetails({
  work,
  headerMonth,
  onSwitchToSummary,
  onClose,
  onDeleted,
}: WorkDetailsProps) {
  const monthKey = headerMonth ?? work.date.slice(0, 7);
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
  const items = itemsQuery.data ?? [];
  const hours = hoursQuery.data ?? [];
  const systems = useMemo(() => uniqueWorkItemSystems(items), [items]);
  const sections = useMemo(
    () => uniqueWorkItemSections(items, placeFilter.system),
    [items, placeFilter.system]
  );
  const floors = useMemo(
    () =>
      uniqueWorkItemFloors(items, placeFilter.system, placeFilter.section),
    [items, placeFilter.system, placeFilter.section]
  );
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

  useEffect(() => {
    setTab("data");
    setSearch("");
    setPlaceFilter({ system: null, section: null, floor: null });
    setAddOpen(false);
    setAddHourOpen(false);
    setDeleteOpen(false);
  }, [work.id]);

  useEffect(() => {
    if (tab !== "items") {
      setAddOpen(false);
    }
    if (tab !== "hours") {
      setAddHourOpen(false);
    }
  }, [tab]);

  useEffect(() => {
    setPlaceFilter((current) => {
      const nextSystem =
        current.system && systems.includes(current.system)
          ? current.system
          : null;
      const nextSection =
        current.section && sections.includes(current.section)
          ? current.section
          : null;
      const nextFloor =
        current.floor && floors.includes(current.floor) ? current.floor : null;
      if (
        nextSystem === current.system &&
        nextSection === current.section &&
        nextFloor === current.floor
      ) {
        return current;
      }
      return { system: nextSystem, section: nextSection, floor: nextFloor };
    });
  }, [systems, sections, floors]);

  const tabs: {
    value: string;
    label: string;
    icon: LucideIcon;
    badge?: number;
  }[] = [
    { value: "data", label: "Обзор и фото", icon: ClipboardListIcon },
    {
      value: "items",
      label: "Работы",
      icon: HammerIcon,
      badge: work.itemsCount,
    },
    {
      value: "hours",
      label: "Сотрудники",
      icon: UsersIcon,
      badge: work.employeesCount,
    },
  ];

  return (
    <Tabs
      key={work.id}
      value={tab}
      onValueChange={(value) => setTab(String(value))}
      className="flex h-full min-h-0 min-w-0 flex-1 flex-col"
    >
      <Card className="flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden shadow-float">
        <CardHeader className="relative z-10 shrink-0 gap-3 border-b bg-card">
          <div className="flex flex-wrap items-center justify-between gap-x-3 gap-y-2">
            <div className="flex min-w-0 flex-wrap items-center gap-x-2 gap-y-1">
              <CardTitle>Смена</CardTitle>
              <span className="font-medium">{formatRuDate(work.date)}</span>
              <WorkStatusBadge status={work.status} />
              <span className="inline-flex min-w-0 items-center gap-1 text-sm text-muted-foreground">
                <MapPinIcon className="size-3.5 shrink-0" />
                <span className="truncate">{work.objectName}</span>
              </span>
            </div>
            <div className="flex flex-wrap items-center gap-1.5">
              {canDeleteShift ? (
                <Button
                  type="button"
                  variant="ghost"
                  size="xs"
                  onClick={() => setDeleteOpen(true)}
                  className="gap-1 text-xs text-destructive hover:text-destructive"
                >
                  <Trash2Icon />
                  <span>Удалить</span>
                </Button>
              ) : null}
              {onSwitchToSummary ? (
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  onClick={onSwitchToSummary}
                  className="gap-1.5 text-xs font-medium text-muted-foreground hover:text-foreground"
                >
                  <BarChart3Icon />
                  <span>Сводка за {formatMonthYear(monthKey)}</span>
                </Button>
              ) : null}
              {onClose ? (
                <Button
                  type="button"
                  variant="ghost"
                  size="xs"
                  onClick={onClose}
                  className="gap-1 text-xs text-muted-foreground hover:text-foreground"
                >
                  <span>Скрыть</span>
                  <XIcon />
                </Button>
              ) : null}
            </div>
          </div>

          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <TabsList variant="pills" className="h-10 w-full sm:w-fit">
              <TabsIndicator />
              {tabs.map((tab) => {
                const Icon = tab.icon;
                return (
                  <TabsTrigger
                    key={tab.value}
                    value={tab.value}
                    className="gap-1.5 text-xs"
                  >
                    <Icon className="size-3.5" />
                    <span>{tab.label}</span>
                    {typeof tab.badge === "number" && tab.badge > 0 ? (
                      <span className="ml-0.5 rounded-full bg-muted-foreground/20 px-1.5 py-0.2 text-[10px] font-medium tabular-nums">
                        {tab.badge}
                      </span>
                    ) : null}
                  </TabsTrigger>
                );
              })}
            </TabsList>

            {showSearch ? (
              <div className="flex min-w-0 flex-1 flex-wrap items-center justify-end gap-2">
                {tab === "items" ? (
                  <WorkItemPlaceFilters
                    system={placeFilter.system}
                    section={placeFilter.section}
                    floor={placeFilter.floor}
                    systems={systems}
                    sections={sections}
                    floors={floors}
                    disabled={itemsQuery.isLoading}
                    onChange={setPlaceFilter}
                  />
                ) : null}
                {tab === "items" && canModify ? (
                  <Button
                    type="button"
                    size="icon-sm"
                    aria-label="Добавить работы"
                    onClick={() => setAddOpen(true)}
                  >
                    <PlusIcon />
                  </Button>
                ) : null}
                {tab === "hours" && canModify ? (
                  <Button
                    type="button"
                    size="icon-sm"
                    aria-label="Добавить сотрудника"
                    onClick={() => setAddHourOpen(true)}
                  >
                    <PlusIcon />
                  </Button>
                ) : null}
                <InputGroup className="w-full bg-background sm:max-w-72">
                  <InputGroupAddon>
                    <SearchIcon />
                  </InputGroupAddon>
                  <InputGroupInput
                    type="search"
                    value={search}
                    placeholder="Поиск по работам и сотрудникам"
                    aria-label="Поиск по работам и сотрудникам"
                    onChange={(event) => setSearch(event.target.value)}
                  />
                </InputGroup>
              </div>
            ) : null}
          </div>
        </CardHeader>

        <CardContent className="flex min-h-0 flex-1 flex-col overflow-hidden px-(--card-spacing) pb-(--card-spacing) pt-(--card-spacing)">
          <TabsContent
            value="data"
            className="mt-0 min-h-0 flex-1 overflow-y-auto overflow-x-hidden p-px outline-none"
          >
            <WorkDataTab
              work={work}
              canModify={canModify}
              canReopen={canReopen}
            />
          </TabsContent>
          <TabsContent
            value="items"
            className="mt-0 flex min-h-0 flex-1 flex-col overflow-hidden outline-none"
          >
            <WorkItemsTab
              workId={work.id}
              objectId={work.objectId}
              search={search}
              placeFilter={placeFilter}
              canModify={canModify}
            />
          </TabsContent>
          <TabsContent
            value="hours"
            className="mt-0 min-h-0 flex-1 overflow-y-auto overflow-x-hidden p-px outline-none"
          >
            <WorkHoursTab
              workId={work.id}
              objectId={work.objectId}
              search={search}
              canModify={canModify}
            />
          </TabsContent>
        </CardContent>
      </Card>
      <WorkItemAddDialog
        open={addOpen}
        workId={work.id}
        objectId={work.objectId}
        existingItems={items}
        onOpenChange={setAddOpen}
      />
      <WorkHourFormDialog
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
              onDeleted?.();
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
    </Tabs>
  );
}
