"use client";

import {
  actionsForModule,
  permissionActionName,
  type RolePermissionMap,
} from "@/config/permissions";
import { Switch } from "@/components/ui/switch";
import { Field, FieldLabel } from "@/components/ui/field";
import type { AppModule } from "@/features/roles/types/role.types";
import { cn } from "@/lib/utils";

type RolesMatrixProps = {
  modules: AppModule[];
  map: RolePermissionMap;
  readOnly: boolean;
  onToggle: (moduleCode: string, action: string, enabled: boolean) => void;
};

export function RolesMatrix({
  modules,
  map,
  readOnly,
  onToggle,
}: RolesMatrixProps) {
  return (
    <div className="overflow-hidden rounded-xl border bg-card shadow-float">
      <div className="border-b px-4 py-3">
        <p className="text-sm font-medium">Права роли</p>
      </div>
      <div className="divide-y">
        {modules.map((module) => {
          const actions = actionsForModule(module.code);
          return (
            <div
              key={module.id}
              className="grid gap-3 px-4 py-3 sm:grid-cols-[minmax(0,12rem)_minmax(0,1fr)] sm:items-start"
            >
              <p className="pt-1 text-sm font-medium">{module.name}</p>
              <div className="flex min-w-0 flex-wrap gap-x-4 gap-y-2">
                {actions.map((action) => {
                  const checked = map[module.code]?.[action] === true;
                  return (
                    <Field
                      key={action}
                      orientation="horizontal"
                      className="w-auto"
                    >
                      <Switch
                        checked={checked}
                        disabled={readOnly}
                        onCheckedChange={(value) =>
                          onToggle(module.code, action, value)
                        }
                        size="sm"
                      />
                      <FieldLabel
                        className={cn(
                          "text-xs font-normal",
                          readOnly && "text-muted-foreground"
                        )}
                      >
                        {permissionActionName(action)}
                      </FieldLabel>
                    </Field>
                  );
                })}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
