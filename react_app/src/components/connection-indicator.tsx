"use client";

import { SettingsIcon } from "lucide-react";

import { useConnectionStatus } from "@/hooks/use-connection-status";
import { cn } from "@/lib/utils";

type ConnectionIndicatorProps = {
  className?: string;
  /** Показывать подпись «Нет соединения» рядом со значком в офлайне. */
  showLabel?: boolean;
};

/**
 * Компактный индикатор состояния соединения.
 *
 * ONLINE — зелёная шестерёнка, плавно вращается.
 * OFFLINE — красная неподвижная шестерёнка и подпись «Нет соединения».
 *
 * Один и тот же компонент используется в desktop-шапке, mobile-шапке и
 * на экранах входа, поэтому выглядит и ведёт себя одинаково везде,
 * включая установленное PWA.
 */
export function ConnectionIndicator({
  className,
  showLabel = true,
}: ConnectionIndicatorProps) {
  const { isOnline } = useConnectionStatus();
  const label = isOnline ? "Онлайн" : "Нет соединения";

  return (
    <div
      role="status"
      aria-live="polite"
      aria-label={`Состояние соединения: ${label}`}
      title={label}
      className={cn("flex shrink-0 items-center gap-1.5", className)}
    >
      <SettingsIcon
        aria-hidden="true"
        className={cn(
          "size-4 transition-colors",
          isOnline
            ? "animate-spin text-emerald-600 motion-reduce:animate-none dark:text-emerald-400"
            : "text-destructive"
        )}
        // Медленное плавное вращение; inline-стиль надёжнее класса
        // с произвольным значением.
        style={isOnline ? { animationDuration: "3s" } : undefined}
      />
      {!isOnline && showLabel ? (
        <span className="text-xs font-medium whitespace-nowrap text-destructive">
          Нет соединения
        </span>
      ) : null}
    </div>
  );
}
