"use client";

import { useState, type FormEvent } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Spinner } from "@/components/ui/spinner";
import { useUpdateCurrentProfile } from "@/features/profile/hooks/use-current-profile";

type CompleteProfileFormProps = {
  phone: string;
};

/**
 * Завершение регистрации: обязательный ввод ФИО после первого входа.
 * Как `ProfileCompletionForm` в приложении — фамилия и имя минимум.
 */
export function CompleteProfileForm({ phone }: CompleteProfileFormProps) {
  const updateProfile = useUpdateCurrentProfile();
  const [fullName, setFullName] = useState("");
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const value = fullName.trim();
    const parts = value.split(/\s+/).filter(Boolean);
    if (parts.length < 2) {
      setError("Введите фамилию и имя");
      return;
    }

    setError("");
    setIsSubmitting(true);
    try {
      await updateProfile.mutateAsync({ fullName: value, phone });
      toast.success("Профиль сохранён");
    } catch (caught) {
      setError(
        caught instanceof Error ? caught.message : "Не удалось сохранить профиль"
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form className="flex flex-col gap-4" onSubmit={handleSubmit}>
      <FieldGroup>
        <Field data-invalid={Boolean(error)}>
          <FieldLabel htmlFor="complete-profile-name">Фамилия Имя</FieldLabel>
          <Input
            id="complete-profile-name"
            value={fullName}
            placeholder="Иванов Иван"
            autoComplete="name"
            disabled={isSubmitting}
            aria-invalid={Boolean(error)}
            onChange={(event) => setFullName(event.target.value)}
          />
          <FieldError>{error}</FieldError>
        </Field>
      </FieldGroup>
      <Button type="submit" size="lg" disabled={isSubmitting}>
        {isSubmitting ? <Spinner data-icon="inline-start" /> : null}
        Завершить регистрацию
      </Button>
    </form>
  );
}
