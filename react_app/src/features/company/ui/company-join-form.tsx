"use client";

import { useState, type FormEvent } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  Field,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Spinner } from "@/components/ui/spinner";
import { useJoinCompany } from "@/features/company/hooks/use-company";

/** Вступление в существующую организацию по коду приглашения. */
export function CompanyJoinForm() {
  const joinCompany = useJoinCompany();
  const [code, setCode] = useState("");
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!code.trim()) {
      setError("Введите код приглашения");
      return;
    }

    setError("");
    setIsSubmitting(true);
    try {
      await joinCompany.mutateAsync(code);
      toast.success("Вы присоединились к организации");
    } catch (caught) {
      setError(
        caught instanceof Error ? caught.message : "Не удалось присоединиться"
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form className="flex flex-col gap-4" onSubmit={handleSubmit}>
      <FieldGroup>
        <Field data-invalid={Boolean(error)}>
          <FieldLabel htmlFor="join-code">Код приглашения</FieldLabel>
          <Input
            id="join-code"
            value={code}
            placeholder="XXXXXXXX"
            autoCapitalize="characters"
            disabled={isSubmitting}
            aria-invalid={Boolean(error)}
            onChange={(event) => setCode(event.target.value.toUpperCase())}
          />
          <FieldDescription>
            Код выдаёт руководитель организации. 8 символов.
          </FieldDescription>
          <FieldError>{error}</FieldError>
        </Field>
      </FieldGroup>
      <Button type="submit" size="lg" disabled={isSubmitting}>
        {isSubmitting ? <Spinner data-icon="inline-start" /> : null}
        Вступить в организацию
      </Button>
    </form>
  );
}
