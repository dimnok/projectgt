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
import { Spinner } from "@/components/ui/spinner";
import { EmployeeObjectsField } from "@/features/employees/ui/shared/employee-objects-field";
import type { SiteObject } from "@/features/objects/types/object.types";
import { objectStatusLabel } from "@/features/objects/utils/object-status";
import { sortObjectsByName } from "@/features/objects/utils/object.utils";
import { useUpdateUserObjects } from "@/features/users/hooks/use-company-users";
import type { CompanyUser } from "@/features/users/types/user.types";
import {
  companyObjectIdsOfUser,
  sameIdSet,
  userDisplayName,
} from "@/features/users/utils/user.utils";

type UserObjectsDialogProps = {
  user: CompanyUser | null;
  objects: SiteObject[];
  onOpenChange: (open: boolean) => void;
};

export function UserObjectsDialog({
  user,
  objects,
  onOpenChange,
}: UserObjectsDialogProps) {
  return (
    <Dialog
      open={Boolean(user)}
      onOpenChange={(open) => {
        if (!open) {
          onOpenChange(false);
        }
      }}
    >
      {user ? (
        <UserObjectsForm
          key={`${user.id}:${[...objects].map((object) => object.id).sort().join(",")}`}
          user={user}
          objects={objects}
          onClose={() => onOpenChange(false)}
        />
      ) : null}
    </Dialog>
  );
}

function UserObjectsForm({
  user,
  objects,
  onClose,
}: {
  user: CompanyUser;
  objects: SiteObject[];
  onClose: () => void;
}) {
  const updateObjects = useUpdateUserObjects();
  const sorted = useMemo(() => sortObjectsByName(objects), [objects]);
  const companyIds = useMemo(
    () => new Set(sorted.map((object) => object.id)),
    [sorted]
  );
  const initialIds = useMemo(
    () => companyObjectIdsOfUser(user.objectIds, companyIds),
    [companyIds, user.objectIds]
  );
  const [value, setValue] = useState(initialIds);

  const options = useMemo(
    () =>
      sorted.map((object) => ({
        id: object.id,
        name:
          object.status === "active"
            ? object.name
            : `${object.name} (${objectStatusLabel(object.status)})`,
      })),
    [sorted]
  );

  const isDirty = !sameIdSet(value, initialIds);
  const otherCompanyCount = Math.max(0, user.objectIds.length - initialIds.length);

  return (
    <DialogContent>
      <DialogHeader>
        <DialogTitle>Объекты пользователя</DialogTitle>
        <DialogDescription>
          {userDisplayName(user)}. От этих объектов зависит, какие смены можно
          открывать.
        </DialogDescription>
      </DialogHeader>
      <EmployeeObjectsField
        objects={options}
        value={value}
        disabled={updateObjects.isPending}
        onChange={setValue}
      />
      {otherCompanyCount > 0 ? (
        <p className="text-xs text-muted-foreground">
          Ещё {otherCompanyCount} из других компаний останутся без изменений.
        </p>
      ) : null}
      <DialogFooter>
        <Button
          type="button"
          variant="outline"
          disabled={updateObjects.isPending}
          onClick={onClose}
        >
          Отмена
        </Button>
        <Button
          type="button"
          disabled={!isDirty || updateObjects.isPending}
          onClick={() => {
            updateObjects.mutate(
              { userId: user.id, objectIds: value },
              {
                onSuccess: () => {
                  onClose();
                  toast.success("Объекты сохранены");
                },
                onError: (error) =>
                  toast.error(
                    error instanceof Error
                      ? error.message
                      : "Не удалось сохранить объекты"
                  ),
              }
            );
          }}
        >
          {updateObjects.isPending ? <Spinner data-icon="inline-start" /> : null}
          Сохранить
        </Button>
      </DialogFooter>
    </DialogContent>
  );
}
