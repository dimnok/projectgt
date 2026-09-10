"use client";

import { useMemo, useState } from "react";
import { toast } from "sonner";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import type { RolePermissionMap } from "@/config/permissions";
import {
  useAppModules,
  useCompanyRoles,
  useCreateRole,
  useDeleteRole,
  useRolePermissions,
  useSaveRolePermissions,
} from "@/features/roles/hooks/use-roles";
import { RolesAside } from "@/features/roles/ui/desktop/roles-aside";
import { RolesList } from "@/features/roles/ui/desktop/roles-list";
import { RolesMatrix } from "@/features/roles/ui/desktop/roles-matrix";
import { CreateRoleDialog } from "@/features/roles/ui/shared/create-role-dialog";
import {
  permissionMapsEqual,
  setPermissionValue,
  sortRoles,
} from "@/features/roles/utils/role.utils";
import { usePermissions } from "@/hooks/use-permissions";

export function RolesDesktop() {
  const { can } = usePermissions();
  const canRead = can("roles", "read");
  const canCreate = can("roles", "create");
  const canUpdate = can("roles", "update");
  const canDelete = can("roles", "delete");

  const rolesQuery = useCompanyRoles(canRead);
  const modulesQuery = useAppModules(canRead);
  const createRole = useCreateRole();
  const deleteRole = useDeleteRole();
  const savePermissions = useSaveRolePermissions();

  const roles = useMemo(
    () => sortRoles(rolesQuery.data ?? []),
    [rolesQuery.data]
  );

  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [draft, setDraft] = useState<RolePermissionMap | null>(null);
  const [createOpen, setCreateOpen] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);

  const selected =
    roles.find((role) => role.id === selectedId) ?? roles[0] ?? null;
  const permissionsQuery = useRolePermissions(selected?.id ?? null);
  const savedMap = permissionsQuery.data ?? {};
  const map = draft ?? savedMap;
  const hasChanges = Boolean(draft) && !permissionMapsEqual(draft ?? {}, savedMap);
  const readOnly = !selected || selected.isSystem || !canUpdate;

  function selectRole(roleId: string) {
    setSelectedId(roleId);
    setDraft(null);
  }

  function handleToggle(moduleCode: string, action: string, enabled: boolean) {
    if (readOnly) {
      return;
    }
    setDraft(setPermissionValue(map, moduleCode, action, enabled));
  }

  if (!canRead) {
    return (
      <ErrorState
        title="Нет доступа"
        message="У вашей роли нет права открывать управление ролями."
      />
    );
  }

  if (rolesQuery.isLoading || modulesQuery.isLoading) {
    return <Loading />;
  }

  if (rolesQuery.isError || modulesQuery.isError) {
    return (
      <ErrorState
        title="Не удалось загрузить роли"
        message={
          rolesQuery.error instanceof Error
            ? rolesQuery.error.message
            : modulesQuery.error instanceof Error
              ? modulesQuery.error.message
              : "Неизвестная ошибка"
        }
      />
    );
  }

  return (
    <div className="grid min-h-fit min-w-0 w-full flex-1 grid-cols-1 content-start items-start gap-3 lg:grid-cols-[minmax(0,1fr)_var(--content-aside-width)] lg:gap-6">
      <div className="flex min-w-0 flex-col gap-3">
        {roles.length === 0 ? (
          <EmptyState
            title="Ролей нет"
            description="Создайте роль, затем отметьте права."
          />
        ) : selected && permissionsQuery.isLoading ? (
          <Loading />
        ) : selected ? (
          <RolesMatrix
            modules={modulesQuery.data ?? []}
            map={map}
            readOnly={readOnly}
            onToggle={handleToggle}
          />
        ) : (
          <EmptyState title="Выберите роль" description="Список справа." />
        )}
      </div>

      <div className="flex min-w-0 flex-col gap-3 lg:sticky lg:top-0 lg:self-start">
        <RolesAside
          selected={selected}
          canCreate={canCreate}
          canUpdate={canUpdate}
          canDelete={canDelete}
          hasChanges={hasChanges}
          isSaving={savePermissions.isPending}
          isDeleting={deleteRole.isPending}
          onCreate={() => setCreateOpen(true)}
          onSave={() => {
            if (!selected) {
              return;
            }
            savePermissions.mutate(
              { roleId: selected.id, map },
              {
                onSuccess: () => {
                  setDraft(null);
                  toast.success("Права сохранены");
                },
                onError: (error) =>
                  toast.error(
                    error instanceof Error ? error.message : "Не удалось сохранить"
                  ),
              }
            );
          }}
          onDelete={() => setDeleteOpen(true)}
        />
        <RolesList
          roles={roles}
          selectedId={selected?.id ?? null}
          onSelect={selectRole}
        />
      </div>

      <CreateRoleDialog
        open={createOpen}
        isSaving={createRole.isPending}
        onOpenChange={setCreateOpen}
        onSubmit={(input) => {
          createRole.mutate(input, {
            onSuccess: (role) => {
              setCreateOpen(false);
              setSelectedId(role.id);
              setDraft(null);
              toast.success("Роль создана");
            },
            onError: (error) =>
              toast.error(
                error instanceof Error ? error.message : "Не удалось создать роль"
              ),
          });
        }}
      />

      <Dialog open={deleteOpen} onOpenChange={setDeleteOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Удалить роль?</DialogTitle>
            <DialogDescription>
              {selected
                ? `Роль «${selected.name}» будет удалена.`
                : ""}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => setDeleteOpen(false)}
            >
              Отмена
            </Button>
            <Button
              type="button"
              variant="destructive"
              disabled={deleteRole.isPending}
              onClick={() => {
                if (!selected) {
                  return;
                }
                deleteRole.mutate(selected.id, {
                  onSuccess: () => {
                    setDeleteOpen(false);
                    setSelectedId(null);
                    setDraft(null);
                    toast.success("Роль удалена");
                  },
                  onError: (error) =>
                    toast.error(
                      error instanceof Error
                        ? error.message
                        : "Не удалось удалить роль"
                    ),
                });
              }}
            >
              Удалить
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
