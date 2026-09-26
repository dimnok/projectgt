"use client";

import {
  actionsForModule,
  PERMISSION_ACTION_DEFS,
  permissionActionName,
  type RolePermissionMap,
} from "@/config/permissions";
import type { AppModule } from "@/features/roles/types/role.types";
import { cn } from "@/lib/utils";

type RolesMatrixProps = {
  modules: AppModule[];
  map: RolePermissionMap;
  readOnly: boolean;
  onToggle: (moduleCode: string, action: string, enabled: boolean) => void;
};

/**
 * Столбцы матрицы — все действия, которые используют показанные модули,
 * в порядке справочника. Ячейка без действия остаётся пустой.
 */
function matrixActions(modules: AppModule[]): string[] {
  const used = new Set<string>();
  for (const appModule of modules) {
    for (const action of actionsForModule(appModule.code)) {
      used.add(action);
    }
  }
  return PERMISSION_ACTION_DEFS.filter((def) => used.has(def.code)).map(
    (def) => def.code
  );
}

export function RolesMatrix({
  modules,
  map,
  readOnly,
  onToggle,
}: RolesMatrixProps) {
  const actions = matrixActions(modules);
  const cellBorder = "border-b border-r border-border/60";

  return (
    <div className="overflow-hidden rounded-xl border bg-card shadow-float">
      <div className="border-b px-4 py-3">
        <p className="text-sm font-medium">Права роли</p>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full border-separate border-spacing-0 text-sm">
          <thead>
            <tr>
              <th className="sticky left-0 z-20 h-11 min-w-56 border-b border-r border-border/70 bg-muted px-4 text-left align-middle text-[11px] font-semibold tracking-wider text-muted-foreground uppercase">
                Модуль
              </th>
              {actions.map((action) => (
                <th
                  key={action}
                  title={permissionActionName(action)}
                  className="h-11 w-[72px] min-w-[72px] max-w-[72px] border-b border-r border-border/70 bg-muted px-1 text-center align-middle text-[11px] leading-tight font-medium text-muted-foreground"
                >
                  {permissionActionName(action)}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {modules.map((appModule) => {
              const moduleActions = actionsForModule(appModule.code);
              return (
                <tr key={appModule.id} className="group">
                  <td
                    className={cn(
                      "sticky left-0 z-10 h-10 min-w-56 border-r border-border/70 bg-card px-4 align-middle text-sm font-medium group-hover:bg-muted",
                      cellBorder
                    )}
                  >
                    {appModule.name}
                  </td>
                  {actions.map((action) => {
                    const applies = moduleActions.includes(action);
                    return (
                      <td
                        key={action}
                        className={cn(
                          "h-10 text-center align-middle",
                          cellBorder,
                          applies
                            ? "group-hover:bg-muted"
                            : "bg-muted/40 group-hover:bg-muted"
                        )}
                      >
                        {applies ? (
                          <input
                            type="checkbox"
                            checked={map[appModule.code]?.[action] === true}
                            disabled={readOnly}
                            onChange={(event) =>
                              onToggle(
                                appModule.code,
                                action,
                                event.target.checked
                              )
                            }
                            aria-label={`${appModule.name}: ${permissionActionName(action)}`}
                            className="size-4 cursor-pointer rounded border-border/80 align-middle text-primary accent-primary transition-all disabled:cursor-not-allowed disabled:opacity-50"
                          />
                        ) : null}
                      </td>
                    );
                  })}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
