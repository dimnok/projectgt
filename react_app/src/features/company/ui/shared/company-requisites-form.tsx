"use client";

import { useRef, useState, type FormEvent } from "react";

import {
  MobileSheetBody,
  MobileSheetChrome,
} from "@/components/shared/mobile-sheet-chrome";
import { Button } from "@/components/ui/button";
import { DialogFooter } from "@/components/ui/dialog";
import { FieldGroup } from "@/components/ui/field";
import { Spinner } from "@/components/ui/spinner";
import {
  CompanyRequisitesFields,
  companyFieldElementIds,
} from "@/features/company/ui/shared/company-requisites-fields";
import type {
  CompanyDraft,
  CompanyProfile,
} from "@/features/company/types/company.types";
import {
  companyDraftErrors,
  companyFieldBlurError,
  companyToDraft,
  isCompanyFieldKey,
  type CompanyFieldErrors,
  type CompanyFieldKey,
} from "@/features/company/utils/company.utils";

type CompanyRequisitesFormProps = {
  layout: "dialog" | "sheet";
  company: CompanyProfile;
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (draft: CompanyDraft) => void;
};

/**
 * Реквизиты компании: общая форма для настольного окна и мобильного окна снизу.
 *
 * Поля проверяются при уходе из них, а при сохранении — наименования и те поля,
 * которые пользователь заполнял.
 */
export function CompanyRequisitesForm({
  layout,
  company,
  isSaving,
  onCancel,
  onSubmit,
}: CompanyRequisitesFormProps) {
  const [draft, setDraft] = useState<CompanyDraft>(() =>
    companyToDraft(company)
  );
  const [errors, setErrors] = useState<CompanyFieldErrors>({});
  const touched = useRef(new Set<CompanyFieldKey>());

  function set<K extends keyof CompanyDraft>(key: K, value: CompanyDraft[K]) {
    setDraft((prev) => ({ ...prev, [key]: value }));

    if (typeof value !== "string" || !isCompanyFieldKey(key)) {
      return;
    }
    touched.current.add(key);
    // Пока ошибка не исправлена, проверяем поле на каждый ввод: сообщение
    // исчезает сразу, как только значение стало верным.
    if (errors[key]) {
      setErrors((prev) => ({
        ...prev,
        [key]: companyFieldBlurError(key, value),
      }));
    }
  }

  function handleBlur(key: CompanyFieldKey) {
    touched.current.add(key);
    setErrors((prev) => ({
      ...prev,
      [key]: companyFieldBlurError(key, draft[key]),
    }));
  }

  function submitDraft() {
    const found = companyDraftErrors(draft, touched.current);
    setErrors(found);

    const firstError = Object.keys(found)[0] as CompanyFieldKey | undefined;
    if (firstError) {
      // Ошибка может быть за пределами экрана — показываем её пользователю.
      document
        .getElementById(companyFieldElementIds[firstError])
        ?.scrollIntoView({ block: "center", behavior: "smooth" });
      return;
    }

    onSubmit(draft);
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    submitDraft();
  }

  const fields = (
    <CompanyRequisitesFields
      draft={draft}
      onChange={set}
      disabled={isSaving}
      errors={errors}
      onBlurField={handleBlur}
    />
  );

  if (layout === "sheet") {
    return (
      <>
        <MobileSheetChrome
          title="Реквизиты компании"
          description="Изменения сохраняются в карточку организации."
          confirmLabel="Сохранить"
          confirmPending={isSaving}
          onConfirm={submitDraft}
        />
        <MobileSheetBody>
          <FieldGroup>{fields}</FieldGroup>
        </MobileSheetBody>
      </>
    );
  }

  return (
    <form className="flex flex-col gap-6" onSubmit={handleSubmit}>
      <FieldGroup>{fields}</FieldGroup>
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
