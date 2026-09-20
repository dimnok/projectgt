"use client";

import { AuthFlowShell } from "@/features/auth/ui/auth-flow-shell";
import { CompleteProfileForm } from "@/features/auth/ui/complete-profile-form";
import { useCurrentProfile } from "@/features/profile/hooks/use-current-profile";

/** Экран обязательного заполнения ФИО после первого входа. */
export function CompleteProfileScreen() {
  const { data: profile } = useCurrentProfile();

  return (
    <AuthFlowShell className="max-w-sm">
      <div className="flex flex-col gap-6">
        <div className="flex flex-col gap-2 text-center">
          <h1 className="font-heading text-2xl font-medium">
            Завершение регистрации
          </h1>
          <p className="text-sm text-muted-foreground">
            Введите ваше имя для начала работы
          </p>
        </div>
        <CompleteProfileForm phone={profile?.phone ?? ""} />
        <p className="text-center text-xs text-muted-foreground">
          Вы сможете изменить эти данные позже в профиле
        </p>
      </div>
    </AuthFlowShell>
  );
}
