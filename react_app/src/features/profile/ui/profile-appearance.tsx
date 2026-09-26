"use client";

import { CheckIcon } from "lucide-react";
import { useTheme } from "next-themes";

import { themeOptions } from "@/config/themes";
import { useHasMounted } from "@/hooks/use-has-mounted";
import { cn } from "@/lib/utils";

/**
 * Выбор темы оформления в профиле.
 *
 * Список тем и образцы цветов — в `src/config/themes.ts`, цвета — в
 * `src/styles/globals.css`. Выбор хранится на устройстве.
 */
export function ProfileAppearance() {
  const { resolvedTheme, setTheme } = useTheme();
  const mounted = useHasMounted();

  if (!mounted) {
    return <div className="h-96" />;
  }

  return (
    <div className="grid grid-cols-2 gap-2">
      {themeOptions.map((theme) => {
        const isActive = resolvedTheme === theme.id;

        return (
          <button
            key={theme.id}
            type="button"
            aria-pressed={isActive}
            onClick={() => setTheme(theme.id)}
            className={cn(
              "flex flex-col gap-2 rounded-xl p-3 text-left ring-1 transition-colors",
              isActive
                ? "bg-foreground text-background ring-foreground"
                : "bg-muted/50 text-muted-foreground ring-foreground/10 hover:bg-muted hover:text-foreground"
            )}
          >
            <span className="flex items-center gap-1">
              {theme.swatch.map((color, index) => (
                <span
                  key={index}
                  className="size-4 rounded-full ring-1 ring-foreground/15"
                  style={{ backgroundColor: color }}
                />
              ))}
              {isActive ? <CheckIcon className="ml-auto size-4" /> : null}
            </span>
            <span className="text-sm font-medium">{theme.label}</span>
            <span className="text-xs opacity-70">{theme.description}</span>
          </button>
        );
      })}
    </div>
  );
}
