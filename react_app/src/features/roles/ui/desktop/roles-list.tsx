"use client";

import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import type { CompanyRole } from "@/features/roles/types/role.types";
import { cn } from "@/lib/utils";

type RolesListProps = {
  roles: CompanyRole[];
  selectedId: string | null;
  onSelect: (roleId: string) => void;
};

export function RolesList({ roles, selectedId, onSelect }: RolesListProps) {
  return (
    <div className="flex min-w-0 flex-col gap-2">
      {roles.map((role) => {
        const selected = role.id === selectedId;
        return (
          <Card
            key={role.id}
            size="sm"
            className={cn(
              "cursor-pointer overflow-visible py-3 shadow-float",
              selected && "ring-2 ring-inset ring-primary"
            )}
            onClick={() => onSelect(role.id)}
          >
            <div className="flex min-w-0 items-start justify-between gap-2 px-4">
              <div className="min-w-0">
                <p className="truncate font-medium">{role.name}</p>
                {role.description ? (
                  <p className="mt-1 line-clamp-2 text-xs text-muted-foreground">
                    {role.description}
                  </p>
                ) : null}
              </div>
              {role.isSystem ? <Badge variant="secondary">Система</Badge> : null}
            </div>
          </Card>
        );
      })}
    </div>
  );
}
