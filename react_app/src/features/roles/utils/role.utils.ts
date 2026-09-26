import type { RolePermissionMap } from "@/config/permissions";
import type { AppModule, CompanyRole } from "@/features/roles/types/role.types";

/**
 * Модули, скрытые в матрице прав: реализация ещё правится, права настроим позже.
 * Права таких модулей в базе не трогаем — они сохраняются как есть.
 */
export const HIDDEN_MATRIX_MODULE_CODES: readonly string[] = ["tmc"];

/** Модули для матрицы: без временно скрытых. */
export function matrixModules(modules: AppModule[]): AppModule[] {
  return modules.filter(
    (appModule) => !HIDDEN_MATRIX_MODULE_CODES.includes(appModule.code)
  );
}

export function sortRoles(roles: CompanyRole[]): CompanyRole[] {
  return [...roles].sort((left, right) => {
    if (left.isSystem !== right.isSystem) {
      return left.isSystem ? -1 : 1;
    }
    return left.name.localeCompare(right.name, "ru");
  });
}

export function clonePermissionMap(map: RolePermissionMap): RolePermissionMap {
  const next: RolePermissionMap = {};
  for (const [moduleCode, actions] of Object.entries(map)) {
    next[moduleCode] = { ...actions };
  }
  return next;
}

export function setPermissionValue(
  map: RolePermissionMap,
  moduleCode: string,
  action: string,
  enabled: boolean
): RolePermissionMap {
  const next = clonePermissionMap(map);
  next[moduleCode] = { ...(next[moduleCode] ?? {}), [action]: enabled };
  return next;
}

export function permissionMapsEqual(
  left: RolePermissionMap,
  right: RolePermissionMap
): boolean {
  return JSON.stringify(left) === JSON.stringify(right);
}

export function roleDbErrorMessage(error: unknown): string {
  const text = error instanceof Error ? error.message : String(error);

  if (/duplicate|idx_roles_name|already exists/i.test(text)) {
    return "Роль с таким названием уже существует";
  }
  if (/23503|foreign key/i.test(text)) {
    return "Роль назначена пользователям. Сначала снимите её.";
  }
  if (/row-level security|RLS|42501/i.test(text)) {
    return "Недостаточно прав для этого действия";
  }

  return text.trim() || "Не удалось выполнить действие";
}
