"use client";

import { useState, type FormEvent } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { FieldError, FieldGroup } from "@/components/ui/field";
import { Spinner } from "@/components/ui/spinner";
import { useCreateCompany, useSearchCompanyByInn } from "@/features/company/hooks/use-company";
import { CompanyRequisitesFields } from "@/features/company/ui/shared/company-requisites-fields";
import {
  emptyCompanyDraft,
  type CompanyDraft,
  type CompanyInnSuggestion,
} from "@/features/company/types/company.types";
import {
  companyDraftErrors,
  companyFieldBlurError,
  isCompanyFieldKey,
  type CompanyFieldErrors,
  type CompanyFieldKey,
} from "@/features/company/utils/company.utils";

/** Заполняет только пустые поля — введённое вручную не затираем. */
function applyInnSuggestion(
  prev: CompanyDraft,
  data: CompanyInnSuggestion
): CompanyDraft {
  const pick = (current: string, next: string | null | undefined) =>
    current.trim() ? current : (next ?? current);

  return {
    ...prev,
    nameFull: pick(prev.nameFull, data.nameFull),
    nameShort: pick(prev.nameShort, data.nameShort),
    kpp: pick(prev.kpp, data.kpp),
    ogrn: pick(prev.ogrn, data.ogrn),
    okpo: pick(prev.okpo, data.okpo),
    legalAddress: pick(prev.legalAddress, data.legalAddress),
    actualAddress: pick(prev.actualAddress, data.legalAddress),
    directorName: pick(prev.directorName, data.directorName),
    directorPosition: pick(prev.directorPosition, data.directorPosition),
    activityDescription: pick(prev.activityDescription, data.activityDescription),
    email: pick(prev.email, data.email),
    phone: pick(prev.phone, data.phone),
  };
}

/**
 * Полная форма создания организации.
 *
 * Поля проверяются при уходе из них, а при создании — все: организация новая,
 * заполненных ранее значений нет.
 */
export function CompanyCreateForm() {
  const createCompany = useCreateCompany();
  const searchByInn = useSearchCompanyByInn();
  const [draft, setDraft] = useState<CompanyDraft>(emptyCompanyDraft);
  const [errors, setErrors] = useState<CompanyFieldErrors>({});
  const [submitError, setSubmitError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const disabled = isSubmitting || searchByInn.isPending;

  function set<K extends keyof CompanyDraft>(key: K, value: CompanyDraft[K]) {
    setDraft((prev) => ({ ...prev, [key]: value }));

    if (typeof value !== "string" || !isCompanyFieldKey(key)) {
      return;
    }
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
    setErrors((prev) => ({
      ...prev,
      [key]: companyFieldBlurError(key, draft[key]),
    }));
  }

  async function handleSearch() {
    try {
      const data = await searchByInn.mutateAsync(draft.inn);
      if (!data) {
        toast.warning("Организация не найдена");
        return;
      }
      setDraft((prev) => applyInnSuggestion(prev, data));
      toast.success("Пустые поля заполнены данными организации");
    } catch (caught) {
      toast.error(
        caught instanceof Error ? caught.message : "Ошибка при поиске"
      );
    }
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const found = companyDraftErrors(draft);
    setErrors(found);
    if (Object.keys(found).length > 0) {
      return;
    }

    setSubmitError("");
    setIsSubmitting(true);
    try {
      await createCompany.mutateAsync(draft);
      toast.success(`Организация «${draft.nameShort.trim()}» создана`);
    } catch (caught) {
      setSubmitError(
        caught instanceof Error
          ? caught.message
          : "Не удалось создать организацию"
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form className="flex flex-col gap-6" onSubmit={handleSubmit}>
      <FieldGroup>
        <CompanyRequisitesFields
          draft={draft}
          onChange={set}
          disabled={disabled}
          errors={errors}
          onBlurField={handleBlur}
          showInnSearch
          isSearching={searchByInn.isPending}
          onSearchInn={() => void handleSearch()}
        />
        {submitError ? <FieldError>{submitError}</FieldError> : null}
      </FieldGroup>

      <Button type="submit" size="lg" disabled={disabled}>
        {isSubmitting ? <Spinner data-icon="inline-start" /> : null}
        Создать организацию
      </Button>
    </form>
  );
}
