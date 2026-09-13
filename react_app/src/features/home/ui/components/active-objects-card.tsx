"use client";

import Link from "next/link";
import { ArrowRightIcon, Building2Icon, MapPinIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { SiteObject } from "@/features/objects/types/object.types";
import { ObjectStatusBadge } from "@/features/objects/ui/shared/object-status-badge";
import { cn } from "@/lib/utils";

type ActiveObjectsCardProps = {
  objects: SiteObject[];
  className?: string;
};

export function ActiveObjectsCard({
  objects,
  className,
}: ActiveObjectsCardProps) {
  const displayObjects = objects.slice(0, 5);

  return (
    <Card className={cn("overflow-hidden border-border/80 shadow-xs", className)}>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3 border-b border-border/50">
        <div className="flex items-center gap-2">
          <Building2Icon className="size-4 text-muted-foreground" />
          <CardTitle className="text-base font-medium">Объекты в работе</CardTitle>
          <span className="text-xs text-muted-foreground">
            ({objects.length})
          </span>
        </div>

        <Button
          variant="ghost"
          size="sm"
          className="h-8 gap-1 text-xs text-muted-foreground hover:text-foreground"
          render={<Link href="/objects" />}
          nativeButton={false}
        >
          <span>Все объекты</span>
          <ArrowRightIcon className="size-3.5" />
        </Button>
      </CardHeader>

      <CardContent className="p-3 sm:p-4">
        {displayObjects.length === 0 ? (
          <div className="py-6 text-center text-xs text-muted-foreground">
            Нет активных строительных объектов
          </div>
        ) : (
          <div className="flex flex-col gap-2.5">
            {displayObjects.map((obj) => (
              <div
                key={obj.id}
                className="flex items-center justify-between gap-3 rounded-lg border border-border/50 p-2.5 sm:p-3 transition-colors hover:border-foreground/20 hover:bg-muted/20"
              >
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <h5 className="truncate text-sm font-medium text-foreground">
                      {obj.name}
                    </h5>
                    <ObjectStatusBadge status={obj.status} />
                  </div>
                  {obj.address ? (
                    <p className="mt-0.5 flex items-center gap-1 truncate text-xs text-muted-foreground">
                      <MapPinIcon className="size-3 shrink-0" />
                      <span className="truncate">{obj.address}</span>
                    </p>
                  ) : null}
                </div>

                <Button
                  variant="outline"
                  size="sm"
                  className="h-7 text-xs px-2 shrink-0"
                  render={<Link href="/works" />}
                  nativeButton={false}
                >
                  Смены
                </Button>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
