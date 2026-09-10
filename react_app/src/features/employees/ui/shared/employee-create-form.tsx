"use client";

import { useState, type FormEvent } from "react";

import { Button } from "@/components/ui/button";
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { PhoneInput } from "@/components/shared/phone-input";
import { Spinner } from "@/components/ui/spinner";
import { EmployeeObjectsField } from "@/features/employees/ui/shared/employee-objects-field";
import type {
  EmployeeCreateDraft,
  EmployeeObjectOption,
} from "@/features/employees/types/employee.types";
import { toCreateDraft } from "@/features/employees/utils/employee.utils";

type EmployeeCreateFormProps = {
  objects: EmployeeObjectOption[];
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (draft: EmployeeCreateDraft) => void;
};

type FormErrors = Partial<Record<"lastName" | "firstName", string>>;

export function EmployeeCreateForm({
  objects,
  isSaving,
  onCancel,
  onSubmit,
}: EmployeeCreateFormProps) {
  const [draft, setDraft] = useState<EmployeeCreateDraft>(toCreateDraft);
  const [errors, setErrors] = useState<FormErrors>({});

  function update<K extends keyof EmployeeCreateDraft>(
    key: K,
    value: EmployeeCreateDraft[K]
  ) {
    setDraft((current) => ({ ...current, [key]: value }));
  }

  function validate(): FormErrors {
    const nextErrors: FormErrors = {};
    if (!draft.lastName.trim()) {
      nextErrors.lastName = "Введите фамилию";
    }
    if (!draft.firstName.trim()) {
      nextErrors.firstName = "Введите имя";
    }
    return nextErrors;
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const nextErrors = validate();
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length > 0) {
      return;
    }
    onSubmit(draft);
  }

  return (
    <form className="flex flex-col gap-4" onSubmit={handleSubmit}>
      <FieldGroup>
        <Field data-invalid={Boolean(errors.lastName)}>
          <FieldLabel htmlFor="employee-last-name">Фамилия</FieldLabel>
          <Input
            id="employee-last-name"
            value={draft.lastName}
            disabled={isSaving}
            aria-invalid={Boolean(errors.lastName)}
            placeholder="Иванов"
            autoComplete="family-name"
            onChange={(event) => update("lastName", event.target.value)}
          />
          <FieldError>{errors.lastName}</FieldError>
        </Field>
        <Field data-invalid={Boolean(errors.firstName)}>
          <FieldLabel htmlFor="employee-first-name">Имя</FieldLabel>
          <Input
            id="employee-first-name"
            value={draft.firstName}
            disabled={isSaving}
            aria-invalid={Boolean(errors.firstName)}
            placeholder="Иван"
            autoComplete="given-name"
            onChange={(event) => update("firstName", event.target.value)}
          />
          <FieldError>{errors.firstName}</FieldError>
        </Field>
        <Field>
          <FieldLabel htmlFor="employee-middle-name">Отчество</FieldLabel>
          <Input
            id="employee-middle-name"
            value={draft.middleName}
            disabled={isSaving}
            placeholder="Иванович"
            autoComplete="additional-name"
            onChange={(event) => update("middleName", event.target.value)}
          />
        </Field>
        <Field>
          <FieldLabel htmlFor="employee-phone">Телефон</FieldLabel>
          <PhoneInput
            id="employee-phone"
            value={draft.phone}
            disabled={isSaving}
            onValueChange={(value) => update("phone", value)}
          />
        </Field>
        <EmployeeObjectsField
          objects={objects}
          value={draft.objectIds}
          disabled={isSaving}
          onChange={(objectIds) => update("objectIds", objectIds)}
        />
      </FieldGroup>
      <div className="flex justify-end gap-2">
        <Button
          type="button"
          variant="outline"
          disabled={isSaving}
          onClick={onCancel}
        >
          Отмена
        </Button>
        <Button type="submit" disabled={isSaving}>
          {isSaving ? <Spinner data-icon="inline-start" /> : null}
          Добавить
        </Button>
      </div>
    </form>
  );
}
