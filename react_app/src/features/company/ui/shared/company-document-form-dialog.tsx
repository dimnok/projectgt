"use client";

import { useState, type FormEvent } from "react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Field,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Spinner } from "@/components/ui/spinner";
import type { CompanyDocument, CompanyDocumentDraft } from "@/features/company/types/company.types";
import {
  toDocumentDraft,
  validateDocumentDraft,
} from "@/features/company/utils/company-document";

type CompanyDocumentFormDialogProps = {
  open: boolean;
  document?: CompanyDocument | null;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: CompanyDocumentDraft) => void;
};

export function CompanyDocumentFormDialog({
  open,
  document,
  isSaving,
  onOpenChange,
  onSubmit,
}: CompanyDocumentFormDialogProps) {
  const isNew = !document;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[min(90vh,40rem)] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>
            {isNew ? "Новый документ" : "Редактирование документа"}
          </DialogTitle>
          <DialogDescription>
            Лицензии, допуски СРО и другие документы организации.
          </DialogDescription>
        </DialogHeader>
        {open ? (
          <CompanyDocumentForm
            key={document?.id ?? "new"}
            document={document ?? null}
            isSaving={isSaving}
            onCancel={() => onOpenChange(false)}
            onSubmit={onSubmit}
          />
        ) : null}
      </DialogContent>
    </Dialog>
  );
}

type CompanyDocumentFormProps = {
  document: CompanyDocument | null;
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (draft: CompanyDocumentDraft) => void;
};

function CompanyDocumentForm({
  document,
  isSaving,
  onCancel,
  onSubmit,
}: CompanyDocumentFormProps) {
  const [draft, setDraft] = useState<CompanyDocumentDraft>(() =>
    toDocumentDraft(document)
  );
  const [errors, setErrors] = useState<Record<string, string>>({});

  function set<K extends keyof CompanyDocumentDraft>(
    key: K,
    value: CompanyDocumentDraft[K]
  ) {
    setDraft((prev) => ({ ...prev, [key]: value }));
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const found = validateDocumentDraft(draft);
    setErrors(found);
    if (Object.keys(found).length > 0) {
      return;
    }
    onSubmit(draft);
  }

  return (
    <form className="flex flex-col gap-4" onSubmit={handleSubmit}>
      <FieldGroup>
        <Field data-invalid={Boolean(errors.title)}>
          <FieldLabel htmlFor="doc-title">Название документа</FieldLabel>
          <Input
            id="doc-title"
            value={draft.title}
            disabled={isSaving}
            aria-invalid={Boolean(errors.title)}
            onChange={(event) => set("title", event.target.value)}
          />
          <FieldError>{errors.title}</FieldError>
        </Field>
        <Field data-invalid={Boolean(errors.type)}>
          <FieldLabel htmlFor="doc-type">Тип</FieldLabel>
          <Input
            id="doc-type"
            value={draft.type}
            placeholder="Лицензия, СРО и т.д."
            disabled={isSaving}
            aria-invalid={Boolean(errors.type)}
            onChange={(event) => set("type", event.target.value)}
          />
          <FieldError>{errors.type}</FieldError>
        </Field>
        <Field>
          <FieldLabel htmlFor="doc-number">Номер документа</FieldLabel>
          <Input
            id="doc-number"
            value={draft.number}
            disabled={isSaving}
            onChange={(event) => set("number", event.target.value)}
          />
        </Field>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field>
            <FieldLabel htmlFor="doc-issue">Дата выдачи</FieldLabel>
            <Input
              id="doc-issue"
              type="date"
              value={draft.issueDate}
              disabled={isSaving}
              onChange={(event) => set("issueDate", event.target.value)}
            />
          </Field>
          <Field>
            <FieldLabel htmlFor="doc-expiry">Срок действия</FieldLabel>
            <Input
              id="doc-expiry"
              type="date"
              value={draft.expiryDate}
              disabled={isSaving}
              onChange={(event) => set("expiryDate", event.target.value)}
            />
          </Field>
        </div>
        <Field>
          <FieldLabel htmlFor="doc-file">Ссылка на файл</FieldLabel>
          <Input
            id="doc-file"
            value={draft.fileUrl}
            placeholder="https://…"
            disabled={isSaving}
            onChange={(event) => set("fileUrl", event.target.value)}
          />
          <FieldDescription>
            Загрузка файлов появится позже — пока можно указать ссылку.
          </FieldDescription>
        </Field>
      </FieldGroup>
      <DialogFooter>
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
          Сохранить
        </Button>
      </DialogFooter>
    </form>
  );
}
