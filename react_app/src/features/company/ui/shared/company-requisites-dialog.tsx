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
import { FieldError, FieldGroup } from "@/components/ui/field";
import { Spinner } from "@/components/ui/spinner";
import { CompanyRequisitesFields } from "@/features/company/ui/shared/company-requisites-fields";
import type { CompanyDraft, CompanyProfile } from "@/features/company/types/company.types";
import { companyToDraft } from "@/features/company/utils/company.utils";

type CompanyRequisitesDialogProps = {
  open: boolean;
  company: CompanyProfile;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: CompanyDraft) => void;
};

/** Редактирование реквизитов компании (только владелец). */
export function CompanyRequisitesDialog({
  open,
  company,
  isSaving,
  onOpenChange,
  onSubmit,
}: CompanyRequisitesDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[min(92vh,52rem)] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>Реквизиты компании</DialogTitle>
          <DialogDescription>
            Изменения сохраняются в карточку организации.
          </DialogDescription>
        </DialogHeader>
        {open ? (
          <CompanyRequisitesForm
            key={company.id}
            company={company}
            isSaving={isSaving}
            onCancel={() => onOpenChange(false)}
            onSubmit={onSubmit}
          />
        ) : null}
      </DialogContent>
    </Dialog>
  );
}

type CompanyRequisitesFormProps = {
  company: CompanyProfile;
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (draft: CompanyDraft) => void;
};

function CompanyRequisitesForm({
  company,
  isSaving,
  onCancel,
  onSubmit,
}: CompanyRequisitesFormProps) {
  const [draft, setDraft] = useState<CompanyDraft>(() =>
    companyToDraft(company)
  );
  const [error, setError] = useState("");

  function set<K extends keyof CompanyDraft>(key: K, value: CompanyDraft[K]) {
    setDraft((prev) => ({ ...prev, [key]: value }));
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!draft.nameFull.trim()) {
      setError("Введите полное наименование");
      return;
    }
    if (!draft.nameShort.trim()) {
      setError("Введите краткое наименование");
      return;
    }
    setError("");
    onSubmit(draft);
  }

  return (
    <form className="flex flex-col gap-6" onSubmit={handleSubmit}>
      <FieldGroup>
        <CompanyRequisitesFields
          draft={draft}
          onChange={set}
          disabled={isSaving}
        />
        {error ? <FieldError>{error}</FieldError> : null}
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
