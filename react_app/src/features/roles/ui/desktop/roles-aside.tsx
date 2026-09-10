"use client";

import { PlusIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Spinner } from "@/components/ui/spinner";
import type { CompanyRole } from "@/features/roles/types/role.types";

type RolesAsideProps = {
  selected: CompanyRole | null;
  canCreate: boolean;
  canUpdate: boolean;
  canDelete: boolean;
  hasChanges: boolean;
  isSaving: boolean;
  isDeleting: boolean;
  onCreate: () => void;
  onSave: () => void;
  onDelete: () => void;
};

export function RolesAside({
  selected,
  canCreate,
  canUpdate,
  canDelete,
  hasChanges,
  isSaving,
  isDeleting,
  onCreate,
  onSave,
  onDelete,
}: RolesAsideProps) {
  const systemLocked = selected?.isSystem === true;

  return (
    <Card className="shadow-float max-lg:[--card-spacing:--spacing(3)]">
      <CardHeader className="border-b">
        <CardTitle>Роли</CardTitle>
        {canCreate ? (
          <CardAction>
            <Button
              type="button"
              size="icon"
              aria-label="Добавить роль"
              onClick={onCreate}
            >
              <PlusIcon />
            </Button>
          </CardAction>
        ) : null}
      </CardHeader>
      <CardContent className="flex flex-col gap-3">
        {selected ? (
          <>
            <div>
              <p className="font-medium">{selected.name}</p>
              <CardDescription>
                {systemLocked
                  ? "Системную роль смотрят, но не меняют."
                  : selected.description || "Настройте права слева и сохраните."}
              </CardDescription>
            </div>
            {canUpdate && !systemLocked ? (
              <Button
                type="button"
                disabled={!hasChanges || isSaving}
                onClick={onSave}
              >
                {isSaving ? <Spinner data-icon="inline-start" /> : null}
                Сохранить права
              </Button>
            ) : null}
            {canDelete && !systemLocked ? (
              <Button
                type="button"
                variant="destructive"
                disabled={isDeleting || isSaving}
                onClick={onDelete}
              >
                {isDeleting ? <Spinner data-icon="inline-start" /> : null}
                Удалить роль
              </Button>
            ) : null}
          </>
        ) : (
          <CardDescription>Выберите роль в списке.</CardDescription>
        )}
        {canCreate ? (
          <Button
            type="button"
            variant="outline"
            className="lg:hidden"
            onClick={onCreate}
          >
            <PlusIcon data-icon="inline-start" />
            Новая роль
          </Button>
        ) : null}
      </CardContent>
    </Card>
  );
}
