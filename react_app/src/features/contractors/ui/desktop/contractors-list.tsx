"use client";

import { ChevronDownIcon } from "lucide-react";

import { Card } from "@/components/ui/card";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import { ContractorDetails } from "@/features/contractors/ui/shared/contractor-details";
import { ContractorTypeBadge } from "@/features/contractors/ui/shared/contractor-type-badge";
import type { Contractor } from "@/features/contractors/types/contractor.types";
import {
  CONTRACTOR_TYPE_HEADER_CLASS,
  CONTRACTOR_TYPE_RING_CLASS,
} from "@/features/contractors/utils/contractor-type";
import { cn } from "@/lib/utils";

type ContractorsListProps = {
  contractors: Contractor[];
  expandedId: string | null;
  canUpdate: boolean;
  canDelete: boolean;
  onExpandedChange: (id: string, open: boolean) => void;
  onEdit: (contractor: Contractor) => void;
  onDelete: (contractor: Contractor) => void;
};

export function ContractorsList({
  contractors,
  expandedId,
  canUpdate,
  canDelete,
  onExpandedChange,
  onEdit,
  onDelete,
}: ContractorsListProps) {
  return (
    <div className="flex flex-col gap-2">
      {contractors.map((contractor) => {
        const isOpen = expandedId === contractor.id;

        return (
          <Collapsible
            key={contractor.id}
            open={isOpen}
            onOpenChange={(open) => onExpandedChange(contractor.id, open)}
          >
            <Card
              size="sm"
              className={cn(
                "relative gap-0 overflow-visible py-0 transition-[box-shadow,transform] duration-200 motion-safe:hover:-translate-y-px motion-safe:hover:z-10 motion-safe:hover:shadow-float-hover",
                isOpen && CONTRACTOR_TYPE_RING_CLASS[contractor.type]
              )}
            >
              <CollapsibleTrigger
                className={cn(
                  "flex w-full cursor-pointer items-center gap-3 rounded-xl border-0 bg-transparent px-(--card-spacing) py-3 text-left outline-none hover:bg-muted/50 focus-visible:ring-3 focus-visible:ring-ring/50",
                  isOpen && "rounded-b-none",
                  isOpen && CONTRACTOR_TYPE_HEADER_CLASS[contractor.type]
                )}
              >
                <span className="min-w-0 flex-1">
                  <span className="block truncate font-heading text-sm font-medium">
                    {contractor.shortName}
                  </span>
                  <span className="block truncate text-sm text-muted-foreground">
                    {contractor.inn.trim()
                      ? `ИНН ${contractor.inn}`
                      : "ИНН не указан"}
                  </span>
                </span>
                <ContractorTypeBadge type={contractor.type} />
                <ChevronDownIcon
                  className={cn(
                    "size-4 shrink-0 text-muted-foreground transition-transform",
                    isOpen && "rotate-180"
                  )}
                />
              </CollapsibleTrigger>
              <CollapsibleContent className="h-[var(--collapsible-panel-height)] overflow-hidden transition-[height] duration-150 ease-out data-ending-style:h-0 data-starting-style:h-0">
                <ContractorDetails
                  contractor={contractor}
                  isExpanded={isOpen}
                  canUpdate={canUpdate}
                  canDelete={canDelete}
                  onEdit={() => onEdit(contractor)}
                  onDelete={() => onDelete(contractor)}
                />
              </CollapsibleContent>
            </Card>
          </Collapsible>
        );
      })}
    </div>
  );
}
