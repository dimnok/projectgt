"use client";

import { ChevronLeftIcon } from "lucide-react";
import type { ReactNode } from "react";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { MobileAppBar } from "@/layouts/mobile/mobile-app-bar";

type ProfileMobileShellProps = {
  title: string;
  children: ReactNode;
  onBack?: () => void;
  trailing?: ReactNode;
};

export function ProfileMobileShell({
  title,
  children,
  onBack,
  trailing,
}: ProfileMobileShellProps) {
  return (
    <div
      data-fill-viewport
      className="-m-4 flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-background"
    >
      <MobileAppBar
        title={title}
        leading={
          onBack ? (
            <Button
              type="button"
              variant="ghost"
              size="icon"
              className="rounded-full"
              aria-label="Назад"
              onClick={onBack}
            >
              <ChevronLeftIcon />
            </Button>
          ) : undefined
        }
        trailing={trailing}
      />
      <div
        className={cn(
          "min-h-0 min-w-0 flex-1 overflow-x-hidden overflow-y-auto overscroll-contain",
          "px-4 pt-4 pb-[calc(1.25rem+env(safe-area-inset-bottom))]"
        )}
      >
        {children}
      </div>
    </div>
  );
}
