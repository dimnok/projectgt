"use client";

import Link from "next/link";
import { LayoutGridIcon } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { HomeNavModule } from "@/features/home/types/home.types";
import { cn } from "@/lib/utils";

type ModulesHubCardProps = {
  modules: HomeNavModule[];
  className?: string;
};

export function ModulesHubCard({ modules, className }: ModulesHubCardProps) {
  return (
    <Card className={cn("overflow-hidden border-border/80 shadow-xs", className)}>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3 border-b border-border/50">
        <div className="flex items-center gap-2">
          <LayoutGridIcon className="size-4 text-muted-foreground" />
          <CardTitle className="text-base font-medium">Разделы системы</CardTitle>
        </div>
        <span className="text-xs text-muted-foreground">
          {modules.length} доступно
        </span>
      </CardHeader>

      <CardContent className="p-3 sm:p-4">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
          {modules.map((item) => {
            const Icon = item.icon;

            return (
              <Link
                key={item.id}
                href={item.href}
                className="group relative flex items-start gap-3 rounded-lg border border-border/60 bg-card p-3 transition-all hover:border-foreground/20 hover:bg-muted/40 hover:shadow-xs"
              >
                <div className="flex size-9 shrink-0 items-center justify-center rounded-md bg-muted text-foreground transition-colors group-hover:bg-primary/10 group-hover:text-primary">
                  <Icon className="size-4" />
                </div>

                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-1.5">
                    <span className="truncate text-sm font-medium text-foreground group-hover:text-primary">
                      {item.title}
                    </span>
                    {item.badgeText && (
                      <Badge
                        variant={item.badgeVariant ?? "secondary"}
                        className="text-[10px] h-4.5 px-1.5 shrink-0"
                      >
                        {item.badgeText}
                      </Badge>
                    )}
                  </div>
                  <p className="mt-0.5 line-clamp-1 text-xs text-muted-foreground">
                    {item.description}
                  </p>
                </div>
              </Link>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}
