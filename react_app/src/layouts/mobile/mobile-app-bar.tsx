"use client";

import type { ReactNode } from "react";

import { AppUpdateBell } from "@/components/app-update-bell";
import { SidebarTrigger } from "@/components/ui/sidebar";
import { cn } from "@/lib/utils";

type MobileAppBarProps = {
  title: string;
  /** Label centered in the bar (does not replace `title`). */
  center?: string;
  className?: string;
  leading?: ReactNode;
  trailing?: ReactNode;
};

export function MobileAppBar({
  title,
  center,
  className,
  leading,
  trailing,
}: MobileAppBarProps) {
  return (
    <header
      className={cn(
        "relative flex h-[calc(3.5rem+env(safe-area-inset-top))] shrink-0 items-center gap-3 border-b bg-background px-4 pt-[env(safe-area-inset-top)]",
        className
      )}
    >
      {leading ?? (
        <SidebarTrigger className="rounded-full" aria-label="Открыть меню" />
      )}
      <h1 className="min-w-0 flex-1 truncate font-heading text-lg font-medium">
        {title}
      </h1>
      {center ? (
        <p className="pointer-events-none absolute inset-x-0 top-[env(safe-area-inset-top)] bottom-0 flex items-center justify-center font-heading text-lg font-medium">
          {center}
        </p>
      ) : null}
      <div className="flex shrink-0 items-center gap-1">
        {trailing}
        <AppUpdateBell />
      </div>
    </header>
  );
}
