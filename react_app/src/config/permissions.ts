export type ModulePermissions = Record<string, boolean>;

export type RolePermissionMap = Record<string, ModulePermissions>;

export type PermissionActionDef = {
  code: string;
  name: string;
};

export const PERMISSION_ACTION_DEFS: readonly PermissionActionDef[] = [
  { code: "read", name: "Просмотр" },
  { code: "create", name: "Создание" },
  { code: "update", name: "Изменение" },
  { code: "delete", name: "Удаление" },
  { code: "export", name: "Экспорт" },
  { code: "import", name: "Импорт" },
  { code: "issue", name: "Выдача" },
  { code: "move", name: "Перемещение" },
  { code: "repair", name: "Ремонт" },
  { code: "write_off", name: "Списание" },
  { code: "inventory", name: "Инвентаризация" },
  { code: "view_cost", name: "Стоимость" },
  { code: "manage_catalogs", name: "Справочники" },
];

const CRUD = ["read", "create", "update", "delete"] as const;

/**
 * Actions shown in the roles matrix. Only actions the module actually uses.
 * Source: app_modules + Flutter matrix, without unused grey cells.
 */
export const MODULE_PERMISSION_ACTIONS: Record<string, readonly string[]> = {
  chat: ["read", "create", "delete"],
  company: ["read", "update"],
  employees: ["read", "create", "update", "delete", "export"],
  materials: ["read", "update", "export", "import"],
  work_plans: ["read", "create", "update", "delete"],
  works: ["read", "create", "update", "delete"],
  objects: ["read", "create", "update", "delete"],
  tmc: [
    "read",
    "create",
    "update",
    "delete",
    "export",
    "issue",
    "move",
    "repair",
    "write_off",
    "inventory",
    "view_cost",
    "manage_catalogs",
  ],
  // Этапы заявок (согласование, счета, оплата, получение) задаёт маршрут
  // в самом модуле — в матрице остаются доступ к разделу и создание заявки.
  purchase_requests: ["read", "create"],
  payroll: ["read", "create", "update", "delete", "export"],
  timesheet: ["read", "create", "update", "delete", "export"],
  estimates: ["read", "create", "update", "delete", "export", "import"],
  subcontractors: ["read", "create", "update", "delete"],
  contractors: ["read", "create", "update", "delete"],
  users: ["read", "create", "update", "delete"],
  settlements: ["read", "create", "update", "delete", "export"],
  cash_flow: ["read", "create", "update", "delete", "export", "import"],
  system: ["read", "update"],
  contracts: ["read", "create", "update", "delete"],
  roles: ["read", "create", "update", "delete"],
  export: ["read", "export"],
};

export function actionsForModule(moduleCode: string): readonly string[] {
  return MODULE_PERMISSION_ACTIONS[moduleCode] ?? CRUD;
}

export function permissionActionName(code: string): string {
  return PERMISSION_ACTION_DEFS.find((item) => item.code === code)?.name ?? code;
}

export function isPermissionEnabled(
  map: RolePermissionMap | undefined,
  module: string,
  action: string
): boolean {
  return map?.[module]?.[action] === true;
}
