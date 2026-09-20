"use client";

import { useState } from "react";
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
import { Label } from "@/components/ui/label";
import { Spinner } from "@/components/ui/spinner";
import { Switch } from "@/components/ui/switch";
import { useUpdateUserPreferWebApp } from "@/features/users/hooks/use-company-users";
import type { CompanyUser } from "@/features/users/types/user.types";
import { userDisplayName } from "@/features/users/utils/user.utils";

type UserPreferWebSwitchProps = {
  user: CompanyUser;
  canToggle: boolean;
};

export function UserPreferWebSwitch({
  user,
  canToggle,
}: UserPreferWebSwitchProps) {
  const updatePreferWeb = useUpdateUserPreferWebApp();
  const [confirmOpen, setConfirmOpen] = useState(false);
  const busy = updatePreferWeb.isPending;

  async function save(preferWebApp: boolean) {
    try {
      await updatePreferWeb.mutateAsync({
        userId: user.id,
        preferWebApp,
      });
      toast.success(
        preferWebApp
          ? `${userDisplayName(user)} переведён на новую версию`
          : `${userDisplayName(user)} снова может работать в старом приложении`
      );
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось сохранить"
      );
    }
  }

  return (
    <>
      <div className="flex items-center justify-end gap-2">
        <Label
          htmlFor={`prefer-web-${user.id}`}
          className="text-muted-foreground font-normal"
        >
          {user.preferWebApp ? "Сайт" : "Приложение"}
        </Label>
        <Switch
          id={`prefer-web-${user.id}`}
          checked={user.preferWebApp}
          disabled={!canToggle || busy}
          onCheckedChange={(checked) => {
            if (checked) {
              setConfirmOpen(true);
              return;
            }
            void save(false);
          }}
        />
      </div>

      <Dialog open={confirmOpen} onOpenChange={setConfirmOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Перевести на новую версию?</DialogTitle>
            <DialogDescription>
              У {userDisplayName(user)} в старом приложении сразу появится
              экран перехода. Работать можно будет только на сайте
              app.progt.ru — с телефона и с компьютера.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              disabled={busy}
              onClick={() => setConfirmOpen(false)}
            >
              Отмена
            </Button>
            <Button
              type="button"
              disabled={busy}
              onClick={() => {
                void (async () => {
                  await save(true);
                  setConfirmOpen(false);
                })();
              }}
            >
              {busy ? <Spinner data-icon="inline-start" /> : null}
              Перевести
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
