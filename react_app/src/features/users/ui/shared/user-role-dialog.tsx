"use client";

import { useMemo, useState } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Field, FieldLabel } from "@/components/ui/field";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Spinner } from "@/components/ui/spinner";
import { useCompanyRoles, useUpdateMemberRole } from "@/features/roles/hooks/use-roles";
import { sortRoles } from "@/features/roles/utils/role.utils";
import type { CompanyUser } from "@/features/users/types/user.types";
import { userDisplayName } from "@/features/users/utils/user.utils";

const NONE_VALUE = "none";

type UserRoleDialogProps = {
  user: CompanyUser | null;
  onOpenChange: (open: boolean) => void;
};

export function UserRoleDialog({ user, onOpenChange }: UserRoleDialogProps) {
  return (
    <Dialog
      open={Boolean(user)}
      onOpenChange={(open) => {
        if (!open) {
          onOpenChange(false);
        }
      }}
    >
      {user ? <UserRoleForm key={user.id} user={user} onClose={() => onOpenChange(false)} /> : null}
    </Dialog>
  );
}

function UserRoleForm({
  user,
  onClose,
}: {
  user: CompanyUser;
  onClose: () => void;
}) {
  const rolesQuery = useCompanyRoles(true);
  const updateRole = useUpdateMemberRole();
  const roles = useMemo(() => sortRoles(rolesQuery.data ?? []), [rolesQuery.data]);
  const [value, setValue] = useState(user.roleId ?? NONE_VALUE);

  const items = useMemo(() => {
    const list = [
      { value: NONE_VALUE, label: "Без роли" },
      ...roles.map((role) => ({ value: role.id, label: role.name })),
    ];
    if (user.roleId && !list.some((item) => item.value === user.roleId)) {
      list.splice(1, 0, { value: user.roleId, label: user.roleName });
    }
    return list;
  }, [roles, user.roleId, user.roleName]);

  return (
    <DialogContent>
      <DialogHeader>
        <DialogTitle>Роль пользователя</DialogTitle>
        <DialogDescription>{userDisplayName(user)}</DialogDescription>
      </DialogHeader>
      <Field>
        <FieldLabel htmlFor="user-role">Роль</FieldLabel>
        <Select
          value={value}
          items={items}
          onValueChange={(next) => {
            if (next) {
              setValue(next);
            }
          }}
        >
          <SelectTrigger id="user-role" className="w-full">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectGroup>
              {items.map((item) => (
                <SelectItem key={item.value} value={item.value}>
                  {item.label}
                </SelectItem>
              ))}
            </SelectGroup>
          </SelectContent>
        </Select>
      </Field>
      <DialogFooter>
        <Button type="button" variant="outline" onClick={onClose}>
          Отмена
        </Button>
        <Button
          type="button"
          disabled={updateRole.isPending}
          onClick={() => {
            updateRole.mutate(
              {
                userId: user.id,
                roleId: value === NONE_VALUE ? null : value,
              },
              {
                onSuccess: () => {
                  onClose();
                  toast.success("Роль сохранена");
                },
                onError: (error) =>
                  toast.error(
                    error instanceof Error ? error.message : "Не удалось сохранить роль"
                  ),
              }
            );
          }}
        >
          {updateRole.isPending ? <Spinner data-icon="inline-start" /> : null}
          Сохранить
        </Button>
      </DialogFooter>
    </DialogContent>
  );
}
