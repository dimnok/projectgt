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
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Spinner } from "@/components/ui/spinner";
import { Textarea } from "@/components/ui/textarea";
import type { ObjectDraft, SiteObject } from "@/features/objects/types/object.types";
import {
  isObjectStatus,
  OBJECT_STATUS_OPTIONS,
} from "@/features/objects/utils/object-status";

type ObjectFormProps = {
  object?: SiteObject | null;
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (draft: ObjectDraft) => void;
};

type FormErrors = Partial<Record<"name" | "address", string>>;

function toDraft(object?: SiteObject | null): ObjectDraft {
  return {
    name: object?.name ?? "",
    address: object?.address ?? "",
    description: object?.description ?? "",
    status: object?.status ?? "active",
  };
}

export function ObjectForm({
  object,
  isSaving,
  onCancel,
  onSubmit,
}: ObjectFormProps) {
  const [draft, setDraft] = useState<ObjectDraft>(() => toDraft(object));
  const [errors, setErrors] = useState<FormErrors>({});
  const isNew = !object;

  function validate(): FormErrors {
    const nextErrors: FormErrors = {};
    if (!draft.name.trim()) {
      nextErrors.name = "Введите наименование";
    }
    if (!draft.address.trim()) {
      nextErrors.address = "Введите адрес";
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
        <Field data-invalid={Boolean(errors.name)}>
          <FieldLabel htmlFor="object-name">Наименование</FieldLabel>
          <Input
            id="object-name"
            value={draft.name}
            disabled={isSaving}
            aria-invalid={Boolean(errors.name)}
            placeholder="Введите наименование"
            onChange={(event) =>
              setDraft((current) => ({ ...current, name: event.target.value }))
            }
          />
          <FieldError>{errors.name}</FieldError>
        </Field>
        <Field data-invalid={Boolean(errors.address)}>
          <FieldLabel htmlFor="object-address">Адрес</FieldLabel>
          <Input
            id="object-address"
            value={draft.address}
            disabled={isSaving}
            aria-invalid={Boolean(errors.address)}
            placeholder="Введите адрес"
            onChange={(event) =>
              setDraft((current) => ({
                ...current,
                address: event.target.value,
              }))
            }
          />
          <FieldError>{errors.address}</FieldError>
        </Field>
        <Field>
          <FieldLabel htmlFor="object-status">Статус</FieldLabel>
          <Select
            value={draft.status}
            items={OBJECT_STATUS_OPTIONS}
            disabled={isSaving}
            onValueChange={(value) => {
              if (!isObjectStatus(value)) {
                return;
              }
              setDraft((current) => ({ ...current, status: value }));
            }}
          >
            <SelectTrigger id="object-status" className="w-full">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectGroup>
                {OBJECT_STATUS_OPTIONS.map((option) => (
                  <SelectItem key={option.value} value={option.value}>
                    {option.label}
                  </SelectItem>
                ))}
              </SelectGroup>
            </SelectContent>
          </Select>
        </Field>
        <Field>
          <FieldLabel htmlFor="object-description">Описание</FieldLabel>
          <Textarea
            id="object-description"
            value={draft.description}
            disabled={isSaving}
            placeholder="Введите описание"
            onChange={(event) =>
              setDraft((current) => ({
                ...current,
                description: event.target.value,
              }))
            }
          />
        </Field>
      </FieldGroup>
      <div className="flex justify-end gap-2">
        <Button type="button" variant="outline" disabled={isSaving} onClick={onCancel}>
          Отмена
        </Button>
        <Button type="submit" disabled={isSaving}>
          {isSaving ? <Spinner data-icon="inline-start" /> : null}
          {isNew ? "Создать" : "Сохранить"}
        </Button>
      </div>
    </form>
  );
}
