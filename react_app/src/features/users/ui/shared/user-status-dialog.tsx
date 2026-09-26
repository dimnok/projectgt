"use client";

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
import { useUpdateUserStatus } from "@/features/users/hooks/use-company-users";
import type { CompanyUser } from "@/features/users/types/user.types";
import { userDisplayName } from "@/features/users/utils/user.utils";

type UserStatusDialogProps = {
  user: CompanyUser | null;
  onOpenChange: (open: boolean) => void;
};

/**
 * Confirms switching company access on or off. Only the company owner
 * may change it — the database enforces the same rule.
 */
export function UserStatusDialog({ user, onOpenChange }: UserStatusDialogProps) {
  const updateStatus = useUpdateUserStatus();
  const nextActive = !(user?.isActive ?? true);
  const name = user ? userDisplayName(user) : "";

  function handleConfirm() {
    if (!user) {
      return;
    }

    updateStatus.mutate(
      { userId: user.id, isActive: nextActive },
      {
        onSuccess: () => {
          onOpenChange(false);
          toast.success(
            nextActive ? "Доступ включён" : "Доступ отключён"
          );
        },
        onError: (error) =>
          toast.error(
            error instanceof Error
              ? error.message
              : "Не удалось изменить статус"
          ),
      }
    );
  }

  return (
    <Dialog
      open={Boolean(user)}
      onOpenChange={(open) => {
        if (!open && !updateStatus.isPending) {
          onOpenChange(false);
        }
      }}
    >
      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            {nextActive ? "Включить доступ?" : "Отключить доступ?"}
          </DialogTitle>
          <DialogDescription>
            {name}.{" "}
            {nextActive
              ? "Человек снова сможет входить в приложение и работать в компании."
              : "Человек не сможет войти в приложение: при входе появится экран «Доступ отключён». Данные и роль сохранятся."}
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            disabled={updateStatus.isPending}
            onClick={() => onOpenChange(false)}
          >
            Отмена
          </Button>
          <Button
            type="button"
            variant={nextActive ? "default" : "destructive"}
            disabled={updateStatus.isPending}
            onClick={handleConfirm}
          >
            {updateStatus.isPending ? <Spinner data-icon="inline-start" /> : null}
            {nextActive ? "Включить доступ" : "Отключить доступ"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
