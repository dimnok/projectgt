"use client";

import { LockIcon } from "lucide-react";
import { useState, type FormEvent } from "react";
import { toast } from "sonner";

import { PhoneInput } from "@/components/shared/phone-input";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Spinner } from "@/components/ui/spinner";
import { useUpdateCurrentProfile } from "@/features/profile/hooks/use-current-profile";
import type { CurrentProfile } from "@/features/profile/types/profile.types";
import { ProfileEmployeeCard } from "@/features/profile/ui/profile-employee-card";
import { validateProfileDraft } from "@/features/profile/utils/profile.utils";

type ProfileDetailsTabProps = {
  profile: CurrentProfile;
};

export function ProfileDetailsTab({ profile }: ProfileDetailsTabProps) {
  const updateProfile = useUpdateCurrentProfile();
  const [fullName, setFullName] = useState(profile.fullName);
  const [phone, setPhone] = useState(profile.phone);
  const [errors, setErrors] = useState<{ fullName?: string; phone?: string }>(
    {}
  );

  const isDirty =
    fullName.trim() !== profile.fullName.trim() ||
    phone.trim() !== profile.phone.trim();

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const nextErrors = validateProfileDraft({ fullName, phone });
    setErrors(nextErrors);
    if (nextErrors.fullName || nextErrors.phone) {
      return;
    }

    updateProfile.mutate(
      { fullName, phone },
      {
        onSuccess: () => toast.success("Личные данные сохранены"),
        onError: (error) =>
          toast.error(
            error instanceof Error ? error.message : "Не удалось сохранить данные"
          ),
      }
    );
  }

  function handleReset() {
    setFullName(profile.fullName);
    setPhone(profile.phone);
    setErrors({});
  }

  return (
    <div className="flex flex-col gap-6">
      <Card>
        <CardHeader>
          <CardTitle>Основные данные</CardTitle>
          <CardDescription>
            Ваше имя и рабочий номер телефона, отображаемые в системе и сменах.
          </CardDescription>
        </CardHeader>
        <form onSubmit={handleSubmit}>
          <CardContent className="flex flex-col gap-5">
            <FieldGroup>
              <Field data-invalid={Boolean(errors.fullName) || undefined}>
                <FieldLabel htmlFor="profile-full-name">
                  Фамилия, Имя и Отчество
                </FieldLabel>
                <Input
                  id="profile-full-name"
                  placeholder="Иванов Иван Иванович"
                  autoComplete="name"
                  value={fullName}
                  onChange={(event) => setFullName(event.target.value)}
                  disabled={updateProfile.isPending}
                  aria-invalid={Boolean(errors.fullName)}
                />
                <FieldError>{errors.fullName}</FieldError>
              </Field>

              <Field data-invalid={Boolean(errors.phone) || undefined}>
                <FieldLabel htmlFor="profile-phone">Номер телефона</FieldLabel>
                <PhoneInput
                  id="profile-phone"
                  value={phone}
                  onValueChange={setPhone}
                  disabled={updateProfile.isPending}
                  aria-invalid={Boolean(errors.phone)}
                />
                <FieldError>{errors.phone}</FieldError>
              </Field>

              <Field>
                <div className="flex items-center justify-between">
                  <FieldLabel htmlFor="profile-email">
                    Электронная почта
                  </FieldLabel>
                  <span className="flex items-center gap-1 text-xs text-muted-foreground">
                    <LockIcon className="size-3" />
                    Только для входа
                  </span>
                </div>
                <Input
                  id="profile-email"
                  value={profile.email || "Не указана"}
                  readOnly
                  disabled
                  className="bg-muted/50 cursor-not-allowed"
                />
                <p className="text-xs text-muted-foreground">
                  Используется в качестве логина учетной записи.
                </p>
              </Field>
            </FieldGroup>
          </CardContent>

          <CardFooter className="justify-between gap-3">
            <Button
              type="button"
              variant="ghost"
              size="sm"
              disabled={!isDirty || updateProfile.isPending}
              onClick={handleReset}
            >
              Сбросить
            </Button>
            <Button
              type="submit"
              size="sm"
              disabled={!isDirty || updateProfile.isPending}
            >
              {updateProfile.isPending ? <Spinner className="size-3.5" /> : null}
              Сохранить изменения
            </Button>
          </CardFooter>
        </form>
      </Card>

      <ProfileEmployeeCard profile={profile} />
    </div>
  );
}
