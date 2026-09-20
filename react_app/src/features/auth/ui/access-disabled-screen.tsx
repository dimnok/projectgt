"use client";

import { LockIcon } from "lucide-react";
import { useState } from "react";

import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import { useCurrentProfile } from "@/features/profile/hooks/use-current-profile";
import { signOut } from "@/lib/supabase/auth";

/**
 * Экран блокировки доступа (`profiles.status = false`).
 * Как `AccessDisabledScreen` в приложении: повторная проверка доступа.
 */
export function AccessDisabledScreen() {
  const { refetch } = useCurrentProfile();
  const [isChecking, setIsChecking] = useState(false);

  async function checkAccess() {
    if (isChecking) {
      return;
    }
    setIsChecking(true);
    try {
      await refetch();
    } finally {
      setIsChecking(false);
    }
  }

  return (
    <div className="flex flex-col items-center gap-5 text-center">
      <div className="flex size-14 items-center justify-center rounded-full bg-destructive/10 text-destructive">
        <LockIcon className="size-6" />
      </div>
      <div className="flex flex-col gap-2">
        <h1 className="font-heading text-xl font-medium">
          Доступ временно отключён
        </h1>
        <p className="text-sm text-muted-foreground">
          Обратитесь к администратору, чтобы восстановить доступ.
        </p>
      </div>
      <div className="flex w-full flex-col gap-2">
        <Button
          type="button"
          variant="outline"
          size="lg"
          disabled={isChecking}
          onClick={() => void checkAccess()}
        >
          {isChecking ? <Spinner data-icon="inline-start" /> : null}
          Проверить доступ
        </Button>
        <Button
          type="button"
          variant="ghost"
          disabled={isChecking}
          onClick={() => void signOut()}
        >
          Выйти
        </Button>
      </div>
    </div>
  );
}
