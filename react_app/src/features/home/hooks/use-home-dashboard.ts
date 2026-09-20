"use client";

import { useCallback, useMemo } from "react";
import { useQueryClient } from "@tanstack/react-query";
import {
  Building2Icon,
  ClipboardListIcon,
  ClockIcon,
  ContactIcon,
  HandshakeIcon,
  HardDriveIcon,
  ListOrderedIcon,
  UsersIcon,
  WrenchIcon,
} from "lucide-react";

import { useContracts } from "@/features/contracts/hooks/use-contracts";
import { useEmployees } from "@/features/employees/hooks/use-employees";
import { useObjects } from "@/features/objects/hooks/use-objects";
import { useCurrentProfile } from "@/features/profile/hooks/use-current-profile";
import { profileDisplayName } from "@/features/profile/utils/profile.utils";
import { scopeHomeObjects } from "@/features/home/utils/scope-home-objects";
import {
  monthWorkHoursQueryKey,
  monthWorksQueryKey,
  useMonthWorkHourTotals,
  useMonthWorks,
  useWorkAccessScope,
  workAccessScopeQueryKey,
} from "@/features/works/hooks/use-works";
import {
  currentMonthKey,
  toDateKey,
} from "@/features/works/utils/work.utils";
import { usePermissions } from "@/hooks/use-permissions";
import type {
  HomeDashboardState,
  HomeKpiData,
  HomeNavModule,
} from "@/features/home/types/home.types";

function formatFullDateRu(date: Date): string {
  const formatted = new Intl.DateTimeFormat("ru-RU", {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(date);

  return formatted.charAt(0).toUpperCase() + formatted.slice(1);
}

function getGreeting(name: string): string {
  const hour = new Date().getHours();
  let prefix = "Добрый день";
  if (hour >= 5 && hour < 12) {
    prefix = "Доброе утро";
  } else if (hour >= 18 && hour < 23) {
    prefix = "Добрый вечер";
  } else if (hour >= 23 || hour < 5) {
    prefix = "Доброй ночи";
  }

  return name ? `${prefix}, ${name}` : prefix;
}

export function useHomeDashboard(): HomeDashboardState {
  const queryClient = useQueryClient();
  const { data: profile, isLoading: isProfileLoading } = useCurrentProfile();
  const { can, isOwner, isLoading: isPermLoading } = usePermissions();

  const today = useMemo(() => new Date(), []);
  const todayKey = useMemo(() => toDateKey(today), [today]);
  const monthKey = useMemo(() => currentMonthKey(), []);

  const canReadWorks = isOwner || can("works", "read");
  const canReadObjects = isOwner || can("objects", "read");
  const canReadEmployees = isOwner || can("employees", "read");
  const canReadContracts = isOwner || can("contracts", "read");

  // Works query for current month
  const worksQuery = useMonthWorks(monthKey, undefined, canReadWorks);
  const monthWorks = useMemo(() => worksQuery.data ?? [], [worksQuery.data]);
  const monthWorkIds = useMemo(
    () => monthWorks.map((work) => work.id),
    [monthWorks]
  );
  const hoursQuery = useMonthWorkHourTotals(
    monthKey,
    monthWorkIds,
    canReadWorks && monthWorkIds.length > 0
  );
  const hoursByWorkId = hoursQuery.data ?? {};
  const minOutputPerPersonHour =
    profile?.activeMembership?.minOutputPerPersonHour ?? null;

  // Objects query — same scope as chart shifts (profile objects, unless owner/super-admin)
  const objectsQuery = useObjects();
  const accessScopeQuery = useWorkAccessScope();
  const allObjects = useMemo(
    () => scopeHomeObjects(objectsQuery.data ?? [], accessScopeQuery.data),
    [objectsQuery.data, accessScopeQuery.data]
  );
  const activeObjects = useMemo(
    () => allObjects.filter((o) => o.status === "active"),
    [allObjects]
  );

  // Employees query
  const employeesQuery = useEmployees();
  const allEmployees = useMemo(
    () => (canReadEmployees ? (employeesQuery.data ?? []) : []),
    [canReadEmployees, employeesQuery.data]
  );
  const activeEmployees = useMemo(
    () => allEmployees.filter((e) => e.status === "working"),
    [allEmployees]
  );

  // Contracts query
  const contractsQuery = useContracts();
  const allContracts = useMemo(
    () => (canReadContracts ? (contractsQuery.data ?? []) : []),
    [canReadContracts, contractsQuery.data]
  );
  const activeContracts = useMemo(
    () => allContracts.filter((c) => c.status === "active"),
    [allContracts]
  );

  // Today shifts
  const todayShifts = useMemo(
    () => monthWorks.filter((w) => w.date.slice(0, 10) === todayKey),
    [monthWorks, todayKey]
  );

  const openShiftsCount = useMemo(
    () => todayShifts.filter((w) => w.status === "open").length,
    [todayShifts]
  );

  const todayWorkersCount = useMemo(
    () => todayShifts.reduce((acc, w) => acc + (w.employeesCount || 0), 0),
    [todayShifts]
  );

  const todayVolume = useMemo(
    () => todayShifts.reduce((acc, w) => acc + (w.totalAmount || 0), 0),
    [todayShifts]
  );

  // Recent 6 shifts from current month
  const recentWorks = useMemo(() => monthWorks.slice(0, 6), [monthWorks]);

  // KPIs
  const kpi: HomeKpiData = useMemo(
    () => ({
      openShiftsCount,
      todayWorkersCount,
      todayVolume,
      activeObjectsCount: activeObjects.length,
      totalObjectsCount: allObjects.length,
      totalEmployeesCount: canReadEmployees ? activeEmployees.length : null,
      activeContractsCount: canReadContracts ? activeContracts.length : null,
    }),
    [
      openShiftsCount,
      todayWorkersCount,
      todayVolume,
      activeObjects.length,
      allObjects.length,
      canReadEmployees,
      activeEmployees.length,
      canReadContracts,
      activeContracts.length,
    ]
  );

  // User & Company info
  const companyName =
    profile?.activeMembership?.companyName || "Строительная компания";
  const userDisplayName = profile ? profileDisplayName(profile) : "Специалист";
  const roleName = isOwner
    ? "Владелец"
    : profile?.activeMembership?.roleName || "Сотрудник";

  const greeting = useMemo(
    () => getGreeting(profile?.shortName || userDisplayName.split(" ")[0] || ""),
    [profile?.shortName, userDisplayName]
  );

  const dateLabel = useMemo(() => formatFullDateRu(today), [today]);

  // Nav modules according to permissions
  const navModules: HomeNavModule[] = useMemo(() => {
    const list: HomeNavModule[] = [
      {
        id: "gt-disk",
        title: "ГТ Диск",
        description: "Файлы компании по объектам: положить, найти, открыть",
        href: "/gt-disk",
        icon: HardDriveIcon,
        badgeText: "макет",
        badgeVariant: "outline",
      },
    ];

    if (canReadWorks) {
      list.push({
        id: "works",
        title: "Работы",
        description: "Учет рабочих смен, фотофиксация и объемы выработки",
        href: "/works",
        icon: WrenchIcon,
        badgeText:
          openShiftsCount > 0 ? `${openShiftsCount} открыто` : undefined,
        badgeVariant: openShiftsCount > 0 ? "success" : undefined,
      });
    }

    if (isOwner || can("timesheet", "read")) {
      list.push({
        id: "timesheet",
        title: "Табель",
        description: "График выходов и рабочие часы сотрудников по объектам",
        href: "/timesheet",
        icon: ClockIcon,
      });
    }

    if (canReadObjects) {
      list.push({
        id: "objects",
        title: "Объекты",
        description: "Строительные площадки, адреса и привязанные бригады",
        href: "/objects",
        icon: Building2Icon,
        badgeText: `${activeObjects.length} в работе`,
        badgeVariant: "secondary",
      });
    }

    if (isOwner || can("estimates", "read")) {
      list.push({
        id: "estimates",
        title: "Сметы",
        description: "Сметные расценки, нормативные объемы и материалы",
        href: "/estimates",
        icon: ListOrderedIcon,
      });
    }

    if (canReadContracts) {
      list.push({
        id: "contracts",
        title: "Договоры",
        description: "Реестр договоров, заказчики и контрактные суммы",
        href: "/contracts",
        icon: HandshakeIcon,
      });
    }

    if (canReadEmployees) {
      list.push({
        id: "employees",
        title: "Сотрудники",
        description: "Кадровый состав, часовые ставки и командировочные",
        href: "/employees",
        icon: UsersIcon,
        badgeText: `${activeEmployees.length} чел.`,
        badgeVariant: "secondary",
      });
    }

    if (isOwner || can("contractors", "read")) {
      list.push({
        id: "contractors",
        title: "Контрагенты",
        description: "Заказчики, подрядные организации и поставщики",
        href: "/contractors",
        icon: ContactIcon,
      });
    }

    if (isOwner || can("export", "read")) {
      list.push({
        id: "work-journal",
        title: "Журнал работ",
        description: "Сводный журнал выполненных работ и аналитика",
        href: "/work-journal",
        icon: ClipboardListIcon,
      });
    }

    return list;
  }, [
    canReadWorks,
    isOwner,
    can,
    canReadObjects,
    canReadContracts,
    canReadEmployees,
    openShiftsCount,
    activeObjects.length,
    activeEmployees.length,
  ]);

  const isLoading =
    isProfileLoading ||
    isPermLoading ||
    (canReadWorks && worksQuery.isLoading) ||
    (canReadWorks && monthWorkIds.length > 0 && hoursQuery.isLoading) ||
    objectsQuery.isLoading ||
    accessScopeQuery.isLoading;

  const isRefetching =
    worksQuery.isRefetching ||
    hoursQuery.isRefetching ||
    objectsQuery.isRefetching ||
    accessScopeQuery.isRefetching ||
    employeesQuery.isRefetching ||
    contractsQuery.isRefetching;

  const refetch = useCallback(async () => {
    await Promise.allSettled([
      queryClient.invalidateQueries({
        queryKey: monthWorksQueryKey(monthKey, undefined),
      }),
      queryClient.invalidateQueries({
        queryKey: monthWorkHoursQueryKey(monthKey),
      }),
      queryClient.invalidateQueries({ queryKey: ["objects"] }),
      queryClient.invalidateQueries({ queryKey: workAccessScopeQueryKey }),
      queryClient.invalidateQueries({ queryKey: ["employees"] }),
      queryClient.invalidateQueries({ queryKey: ["contracts"] }),
    ]);
  }, [queryClient, monthKey]);

  return {
    companyName,
    userName: userDisplayName,
    roleName,
    isOwner,
    greeting,
    dateLabel,
    kpi,
    todayShifts,
    activeObjects,
    recentWorks,
    monthWorks,
    hoursByWorkId,
    minOutputPerPersonHour,
    navModules,
    can,
    isLoading,
    isRefetching,
    refetch,
  };
}
