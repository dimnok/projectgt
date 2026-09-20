import {
  BookOpenIcon,
  BoxesIcon,
  BriefcaseIcon,
  Building2Icon,
  ClockIcon,
  ContactIcon,
  CreditCardIcon,
  ClipboardListIcon,
  FileTextIcon,
  HandshakeIcon,
  HardHatIcon,
  HouseIcon,
  ListOrderedIcon,
  MessageCircleIcon,
  PackageIcon,
  RefreshCwIcon,
  ShieldIcon,
  ShoppingCartIcon,
  UserRoundIcon,
  UsersIcon,
  WalletIcon,
  WrenchIcon,
} from "lucide-react";
import type { ComponentType } from "react";

import { GtDiskIcon } from "@/components/icons/gt-disk-icon";

/** Иконка раздела: подходит и готовая из lucide, и своя SVG-иконка. */
export type AppNavIcon = ComponentType<{ className?: string }>;

export type AppNavLink = {
  href: string;
  label: string;
  icon: AppNavIcon;
  migrated?: boolean;
  /** Shown and routable on screens narrower than 768px. */
  mobile?: boolean;
  /** `app_modules.code`. Empty = always visible (home). */
  module?: string;
};

export type AppNavGroup = {
  label: string;
  icon: AppNavIcon;
  children: AppNavLink[];
};

export type AppNavItem = AppNavLink | AppNavGroup;

/**
 * Same sections as the desktop app menu. Nested groups match the
 * collapsible tree on the left.
 */
export const navigation: AppNavItem[] = [
  { href: "/", label: "Главная", icon: HouseIcon, migrated: true, mobile: true },
  {
    href: "/gt-chat",
    label: "ГТ Чат",
    icon: MessageCircleIcon,
    migrated: true,
    mobile: true,
    module: "chat",
  },
  {
    href: "/gt-disk",
    label: "ГТ Диск",
    icon: GtDiskIcon,
    migrated: true,
    mobile: true,
  },
  { href: "/cash-flow", label: "CASH FLOW", icon: WalletIcon, module: "cash_flow" },
  {
    href: "/settlements",
    label: "Взаиморасчёты",
    icon: FileTextIcon,
    migrated: true,
    mobile: true,
    module: "settlements",
  },
  {
    href: "/purchase-requests",
    label: "Заявки",
    icon: ShoppingCartIcon,
    migrated: true,
    mobile: true,
    module: "purchase_requests",
  },
  {
    href: "/works",
    label: "Работы",
    icon: WrenchIcon,
    migrated: true,
    mobile: true,
    module: "works",
  },
  { href: "/material", label: "Материал", icon: PackageIcon, module: "materials" },
  { href: "/tmc", label: "ТМЦ", icon: BoxesIcon, module: "tmc" },
  { href: "/timesheet", label: "Табель", icon: ClockIcon, migrated: true, module: "timesheet" },
  {
    href: "/employees",
    label: "Сотрудники",
    icon: UsersIcon,
    migrated: true,
    mobile: true,
    module: "employees",
  },
  { href: "/subcontractors", label: "Подрядчики", icon: HardHatIcon, module: "subcontractors" },
  {
    label: "Справочники",
    icon: BookOpenIcon,
    children: [
      {
        href: "/objects",
        label: "Объекты",
        icon: Building2Icon,
        migrated: true,
        module: "objects",
      },
      {
        href: "/contractors",
        label: "Контрагенты",
        icon: ContactIcon,
        migrated: true,
        module: "contractors",
      },
      {
        href: "/contracts",
        label: "Договоры",
        icon: HandshakeIcon,
        migrated: true,
        module: "contracts",
      },
    ],
  },
  { href: "/estimates", label: "Сметы", icon: ListOrderedIcon, migrated: true, module: "estimates" },
  {
    href: "/payrolls",
    label: "ФОТ",
    icon: CreditCardIcon,
    migrated: true,
    module: "payroll",
  },
  {
    href: "/work-journal",
    label: "Журнал работ",
    icon: ClipboardListIcon,
    migrated: true,
    module: "export",
  },
  { href: "/users", label: "Пользователи", icon: UserRoundIcon, migrated: true, module: "users" },
  {
    href: "/version-management",
    label: "Управление версиями",
    icon: RefreshCwIcon,
    module: "system",
  },
  { href: "/roles", label: "Управление ролями", icon: ShieldIcon, migrated: true, module: "roles" },
  {
    href: "/company",
    label: "Компания",
    icon: BriefcaseIcon,
    migrated: true,
    mobile: true,
    module: "company",
  },
];

const DESKTOP_POST_LOGIN: { module: string; href: string }[] = [
  { module: "objects", href: "/objects" },
  { module: "works", href: "/works" },
  { module: "employees", href: "/employees" },
  { module: "timesheet", href: "/timesheet" },
  { module: "estimates", href: "/estimates" },
  { module: "contracts", href: "/contracts" },
  { module: "contractors", href: "/contractors" },
  { module: "export", href: "/work-journal" },
  { module: "users", href: "/users" },
  { module: "roles", href: "/roles" },
];

export function isNavGroup(item: AppNavItem): item is AppNavGroup {
  return "children" in item;
}

export function isActivePath(pathname: string, href: string) {
  if (href === "/") {
    return pathname === "/";
  }

  return pathname === href || pathname.startsWith(`${href}/`);
}

export function filterNavigationByAccess(
  items: AppNavItem[],
  can: (module: string, action: string) => boolean
): AppNavItem[] {
  const visible: AppNavItem[] = [];

  for (const item of items) {
    if (isNavGroup(item)) {
      const children = item.children.filter(
        (child) => !child.module || can(child.module, "read")
      );
      if (children.length > 0) {
        visible.push({ ...item, children });
      }
      continue;
    }

    if (!item.module || can(item.module, "read")) {
      visible.push(item);
    }
  }

  return visible;
}

export function filterNavigationForViewport(
  items: AppNavItem[],
  isMobile: boolean
): AppNavItem[] {
  if (!isMobile) {
    return items;
  }

  const visible: AppNavItem[] = [];

  for (const item of items) {
    if (isNavGroup(item)) {
      const children = item.children.filter((child) => child.mobile);
      if (children.length > 0) {
        visible.push({ ...item, children });
      }
      continue;
    }

    if (item.mobile) {
      visible.push(item);
    }
  }

  return visible;
}

export function isMobileAllowedPath(pathname: string) {
  return (
    pathname === "/login" ||
    pathname === "/complete-profile" ||
    pathname === "/onboarding" ||
    pathname === "/access-disabled" ||
    pathname === "/" ||
    isActivePath(pathname, "/gt-chat") ||
    isActivePath(pathname, "/works") ||
    isActivePath(pathname, "/company") ||
    isActivePath(pathname, "/profile") ||
    isActivePath(pathname, "/gt-disk") ||
    isActivePath(pathname, "/employees") ||
    isActivePath(pathname, "/purchase-requests") ||
    isActivePath(pathname, "/settlements")
  );
}

export function getPostLoginPath(
  isMobile: boolean,
  can?: (module: string, action: string) => boolean
) {
  return "/";
}

export function getModuleForPath(pathname: string): string | null {
  if (
    pathname === "/login" ||
    pathname === "/complete-profile" ||
    pathname === "/onboarding" ||
    pathname === "/access-disabled" ||
    pathname === "/" ||
    isActivePath(pathname, "/profile")
  ) {
    return null;
  }

  for (const item of navigation) {
    if (isNavGroup(item)) {
      const child = item.children.find((entry) => isActivePath(pathname, entry.href));
      if (child?.module) {
        return child.module;
      }
      continue;
    }

    if (isActivePath(pathname, item.href) && item.module) {
      return item.module;
    }
  }

  return null;
}

export function getPageTitle(pathname: string) {
  if (isActivePath(pathname, "/profile")) {
    return "Профиль";
  }

  for (const item of navigation) {
    if (isNavGroup(item)) {
      const child = item.children.find((entry) =>
        isActivePath(pathname, entry.href)
      );
      if (child) {
        return child.label;
      }
    } else if (isActivePath(pathname, item.href)) {
      return item.label;
    }
  }

  return "Стройка PRO";
}
