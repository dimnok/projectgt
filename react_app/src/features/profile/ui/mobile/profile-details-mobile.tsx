"use client";

import { InfoIcon, LockIcon, PhoneIcon } from "lucide-react";
import { useState, type FormEvent } from "react";
import { toast } from "sonner";

import { PhoneInput } from "@/components/shared/phone-input";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Spinner } from "@/components/ui/spinner";
import { EmployeeStatusBadge } from "@/features/employees/ui/shared/employee-status-badge";
import {
  employeeEmploymentLabel,
  isEmployeeEmploymentType,
} from "@/features/employees/utils/employee-employment";
import { isEmployeeStatus } from "@/features/employees/utils/employee-status";
import { useUpdateCurrentProfile } from "@/features/profile/hooks/use-current-profile";
import type { CurrentProfile } from "@/features/profile/types/profile.types";
import { ProfileMobileShell } from "@/features/profile/ui/mobile/profile-mobile-shell";
import {
  profileInitials,
  validateProfileDraft,
} from "@/features/profile/utils/profile.utils";

type ProfileDetailsMobileProps = {
  profile: CurrentProfile;
  onBack: () => void;
};

export function ProfileDetailsMobile({
  profile,
  onBack,
}: ProfileDetailsMobileProps) {
  const updateProfile = useUpdateCurrentProfile();
  const [fullName, setFullName] = useState(profile.fullName);
  const [phone, setPhone] = useState(profile.phone);
  const [errors, setErrors] = useState<{ fullName?: string; phone?: string }>(
    {}
  );
  const linked = profile.linkedEmployee;
  const companyName =
    profile.activeMembership?.companyName || "активная организация";

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

  return (
    <ProfileMobileShell title="Личные данные" onBack={onBack}>
      <form className="flex flex-col gap-5" onSubmit={handleSubmit}>
        <FieldGroup>
          <Field data-invalid={Boolean(errors.fullName) || undefined}>
            <FieldLabel htmlFor="profile-mobile-full-name">ФИО</FieldLabel>
            <Input
              id="profile-mobile-full-name"
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
            <FieldLabel htmlFor="profile-mobile-phone">Телефон</FieldLabel>
            <PhoneInput
              id="profile-mobile-phone"
              value={phone}
              onValueChange={setPhone}
              disabled={updateProfile.isPending}
              aria-invalid={Boolean(errors.phone)}
            />
            <FieldError>{errors.phone}</FieldError>
          </Field>

          <Field>
            <div className="flex items-center justify-between gap-2">
              <FieldLabel htmlFor="profile-mobile-email">Почта</FieldLabel>
              <span className="flex items-center gap-1 text-xs text-muted-foreground">
                <LockIcon className="size-3.5" />
                Только для входа
              </span>
            </div>
            <Input
              id="profile-mobile-email"
              value={profile.email || "Не указана"}
              readOnly
              disabled
            />
          </Field>
        </FieldGroup>

        <Button
          type="submit"
          size="lg"
          className="w-full"
          disabled={!isDirty || updateProfile.isPending}
        >
          {updateProfile.isPending ? <Spinner data-icon="inline-start" /> : null}
          Сохранить
        </Button>

        {linked ? (
          <div className="flex flex-col gap-3 rounded-2xl bg-card p-4 ring-1 ring-foreground/10">
            <p className="text-sm font-medium">Карточка сотрудника</p>
            <div className="flex items-center gap-3">
              <Avatar className="size-12">
                {linked.photoUrl ? (
                  <AvatarImage src={linked.photoUrl} alt={linked.fullName} />
                ) : null}
                <AvatarFallback>
                  {profileInitials(linked.fullName)}
                </AvatarFallback>
              </Avatar>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium">{linked.fullName}</p>
                <div className="mt-1 flex flex-wrap items-center gap-1.5">
                  {linked.position ? (
                    <Badge variant="outline">{linked.position}</Badge>
                  ) : null}
                  {isEmployeeStatus(linked.status) ? (
                    <EmployeeStatusBadge status={linked.status} />
                  ) : null}
                  {isEmployeeEmploymentType(linked.employmentType) ? (
                    <Badge variant="secondary">
                      {employeeEmploymentLabel(linked.employmentType)}
                    </Badge>
                  ) : null}
                </div>
                {linked.phone ? (
                  <a
                    href={`tel:${linked.phone}`}
                    className="mt-1.5 inline-flex min-h-11 items-center gap-1 text-xs text-muted-foreground"
                  >
                    <PhoneIcon className="size-3.5" />
                    {linked.phone}
                  </a>
                ) : null}
              </div>
            </div>
          </div>
        ) : (
          <Alert>
            <InfoIcon />
            <AlertTitle>Карточка сотрудника не назначена</AlertTitle>
            <AlertDescription>
              Связь с сотрудником в «{companyName}» может назначить только
              руководитель.
            </AlertDescription>
          </Alert>
        )}
      </form>
    </ProfileMobileShell>
  );
}
