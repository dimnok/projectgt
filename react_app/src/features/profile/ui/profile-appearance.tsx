"use client";

import { MoonIcon, SunIcon, ZapIcon } from "lucide-react";
import { useTheme } from "next-themes";

import { useHasMounted } from "@/hooks/use-has-mounted";
import { cn } from "@/lib/utils";

const options = [
  { id: "light", label: "Светлая", icon: SunIcon },
  { id: "dark", label: "Тёмная", icon: MoonIcon },
  { id: "brand", label: "Фирменная", icon: ZapIcon },
] as const;

export function ProfileAppearance() {
  const { resolvedTheme, setTheme } = useTheme();
  const mounted = useHasMounted();

  if (!mounted) {
    return <div className="h-11" />;
  }

  return (
    <div className="grid grid-cols-3 gap-2">
      {options.map((option) => {
        const Icon = option.icon;
        const isActive = resolvedTheme === option.id;

        return (
          <button
            key={option.id}
            type="button"
            onClick={() => setTheme(option.id)}
            className={cn(
              "flex flex-col items-center gap-1.5 rounded-xl px-2 py-3 text-xs font-medium ring-1 transition-colors",
              isActive
                ? "bg-foreground text-background ring-foreground"
                : "bg-muted/50 text-muted-foreground ring-foreground/10 hover:bg-muted hover:text-foreground"
            )}
          >
            <Icon className="size-4" />
            {option.label}
          </button>
        );
      })}
    </div>
  );
}
