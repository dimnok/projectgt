"use client";

import { useState } from "react";
import { BellIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { Spinner } from "@/components/ui/spinner";
import { useAppUpdate } from "@/hooks/use-app-update";
import { formatAppBuildSummary } from "@/lib/app-version";

/**
 * Колокольчик с уведомлением о новой сборке приложения.
 *
 * Показываем код и дату именно новой сборки — той, что придёт после обновления.
 * Это то, что спрашивает поддержка, и то, что человек реально получает.
 */
export function AppUpdateBell() {
  const { hasUpdate, remote, applyUpdate } = useAppUpdate();
  const [isApplying, setIsApplying] = useState(false);

  if (!hasUpdate) {
    return null;
  }

  const summary = remote ? formatAppBuildSummary(remote) : null;
  const message = summary
    ? `Новая сборка ${summary}. Нажмите кнопку «Обновить».`
    : "Доступна новая версия приложения. Нажмите кнопку «Обновить».";

  function handleApply() {
    if (isApplying) {
      return;
    }
    setIsApplying(true);
    // Даём кнопке показать отклик и сразу перезагружаем приложение.
    window.setTimeout(applyUpdate, 60);
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
            aria-label="Доступно обновление"
          />
        }
      >
        <BellIcon />
        <span className="absolute top-1.5 right-1.5 size-2 rounded-full bg-destructive" />
      </PopoverTrigger>
      <PopoverContent side="bottom" align="end" className="w-72 p-3">
        <div className="flex flex-col gap-3">
          <div className="flex flex-col gap-1">
            <p className="text-sm font-medium">Доступно обновление</p>
            <p className="text-xs text-muted-foreground">{message}</p>
          </div>
          <Button
            type="button"
            size="sm"
            disabled={isApplying}
            onClick={handleApply}
          >
            {isApplying ? <Spinner data-icon="inline-start" /> : null}
            {isApplying ? "Обновляем…" : "Обновить"}
          </Button>
        </div>
      </PopoverContent>
    </Popover>
  );
}
