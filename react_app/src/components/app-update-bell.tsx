"use client";

import { BellIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { useAppUpdate } from "@/hooks/use-app-update";
import { formatAppVersionLabel } from "@/lib/app-version";

export function AppUpdateBell() {
  const { hasUpdate, current, applyUpdate } = useAppUpdate();

  if (!hasUpdate) {
    return null;
  }

  return (
    <Popover>
      <PopoverTrigger
        render={
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="relative rounded-full"
            aria-label="Доступна новая версия"
          />
        }
      >
        <BellIcon />
        <span className="absolute top-1.5 right-1.5 size-2 rounded-full bg-destructive" />
      </PopoverTrigger>
      <PopoverContent side="bottom" align="end" className="w-72 p-3">
        <div className="flex flex-col gap-3">
          <div className="flex flex-col gap-1">
            <p className="text-sm font-medium">Доступна новая версия</p>
            <p className="text-xs text-muted-foreground">
              Сейчас установлена {formatAppVersionLabel(current.version)}.
              Обновите страницу, чтобы получить изменения.
            </p>
          </div>
          <Button type="button" size="sm" onClick={applyUpdate}>
            Обновить
          </Button>
        </div>
      </PopoverContent>
    </Popover>
  );
}
