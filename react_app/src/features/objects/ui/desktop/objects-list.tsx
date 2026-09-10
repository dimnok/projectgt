"use client";

import { ChevronDownIcon } from "lucide-react";

import { Card } from "@/components/ui/card";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import { ObjectDetails } from "@/features/objects/ui/shared/object-details";
import { ObjectStatusBadge } from "@/features/objects/ui/shared/object-status-badge";
import type { SiteObject } from "@/features/objects/types/object.types";
import {
  OBJECT_STATUS_HEADER_CLASS,
  OBJECT_STATUS_RING_CLASS,
} from "@/features/objects/utils/object-status";
import { cn } from "@/lib/utils";

type ObjectsListProps = {
  objects: SiteObject[];
  expandedId: string | null;
  canUpdate: boolean;
  canDelete: boolean;
  onExpandedChange: (id: string, open: boolean) => void;
  onEdit: (object: SiteObject) => void;
  onDelete: (object: SiteObject) => void;
};

export function ObjectsList({
  objects,
  expandedId,
  canUpdate,
  canDelete,
  onExpandedChange,
  onEdit,
  onDelete,
}: ObjectsListProps) {
  return (
    <div className="flex flex-col gap-2">
      {objects.map((object) => {
        const isOpen = expandedId === object.id;

        return (
          <Collapsible
            key={object.id}
            open={isOpen}
            onOpenChange={(open) => onExpandedChange(object.id, open)}
          >
            <Card
              size="sm"
              className={cn(
                "relative gap-0 overflow-visible py-0 transition-[box-shadow,transform] duration-200 motion-safe:hover:-translate-y-px motion-safe:hover:z-10 motion-safe:hover:shadow-float-hover",
                isOpen && OBJECT_STATUS_RING_CLASS[object.status]
              )}
            >
              <CollapsibleTrigger
                className={cn(
                  "flex w-full cursor-pointer items-center gap-3 rounded-xl border-0 bg-transparent px-(--card-spacing) py-3 text-left outline-none hover:bg-muted/50 focus-visible:ring-3 focus-visible:ring-ring/50",
                  isOpen && "rounded-b-none",
                  isOpen && OBJECT_STATUS_HEADER_CLASS[object.status]
                )}
              >
                <span className="min-w-0 flex-1">
                  <span className="block truncate font-heading text-sm font-medium">
                    {object.name}
                  </span>
                  <span className="block truncate text-sm text-muted-foreground">
                    {object.address.trim()
                      ? object.address
                      : "Адрес не указан"}
                  </span>
                </span>
                <ObjectStatusBadge status={object.status} />
                <ChevronDownIcon
                  className={cn(
                    "size-4 shrink-0 text-muted-foreground transition-transform",
                    isOpen && "rotate-180"
                  )}
                />
              </CollapsibleTrigger>
              <CollapsibleContent className="h-[var(--collapsible-panel-height)] overflow-hidden transition-[height] duration-150 ease-out data-ending-style:h-0 data-starting-style:h-0">
                <ObjectDetails
                  object={object}
                  canUpdate={canUpdate}
                  canDelete={canDelete}
                  onEdit={() => onEdit(object)}
                  onDelete={() => onDelete(object)}
                />
              </CollapsibleContent>
            </Card>
          </Collapsible>
        );
      })}
    </div>
  );
}
