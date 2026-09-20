"use client";

import { usePathname } from "next/navigation";
import { Building2Icon } from "lucide-react";

import { AppUpdateBell } from "@/components/app-update-bell";
import { SidebarTrigger } from "@/components/ui/sidebar";
import { getPageTitle, isMobileAllowedPath } from "@/config/navigation";
import { UserMenu } from "@/layouts/user-menu";
import { cn } from "@/lib/utils";

export function Header() {
  const pathname = usePathname();
  const title = getPageTitle(pathname);

  return (
    <header
      className={cn(
        "flex h-16 shrink-0 items-center gap-4 px-4 pr-8 text-sidebar-foreground md:px-6 md:pr-8",
        // Мобильные экраны рисуют свою шапку — общая на телефоне скрывается.
        isMobileAllowedPath(pathname) ? "max-md:hidden" : undefined
      )}
    >
      <div className="flex min-w-0 items-center gap-3">
        <SidebarTrigger className="rounded-full text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground" />
        <div className="flex size-9 shrink-0 items-center justify-center rounded-full bg-sidebar-foreground text-sidebar [&_svg]:size-4">
          <Building2Icon />
        </div>
        <h1 className="font-heading truncate text-xl font-medium">{title}</h1>
      </div>
      <div className="ml-auto flex min-w-0 items-center gap-2">
        <AppUpdateBell />
        <div className="hidden md:block">
          <UserMenu />
        </div>
      </div>
    </header>
  );
}
