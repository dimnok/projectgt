import type { LucideIcon } from "lucide-react";

import type { SiteObject } from "@/features/objects/types/object.types";
import type { Work } from "@/features/works/types/work.types";

export type HomeKpiData = {
  openShiftsCount: number;
  todayWorkersCount: number;
  todayVolume: number;
  activeObjectsCount: number;
  totalObjectsCount: number;
  totalEmployeesCount: number | null;
  activeContractsCount: number | null;
};

export type HomeNavModule = {
  id: string;
  title: string;
  description: string;
  href: string;
  icon: LucideIcon;
  badgeText?: string;
  badgeVariant?: "default" | "secondary" | "success" | "warning" | "outline";
};

export type HomeDashboardState = {
  companyName: string;
  userName: string;
  roleName: string;
  isOwner: boolean;
  greeting: string;
  dateLabel: string;
  kpi: HomeKpiData;
  todayShifts: Work[];
  activeObjects: SiteObject[];
  recentWorks: Work[];
  monthWorks: Work[];
  hoursByWorkId: Record<string, number>;
  minOutputPerPersonHour: number | null;
  navModules: HomeNavModule[];
  can: (module: string, action: string) => boolean;
  isLoading: boolean;
  isRefetching: boolean;
  refetch: () => Promise<void>;
};
