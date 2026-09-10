"use client";

import { useEffect, useRef, useState, type FormEvent } from "react";
import { SearchIcon } from "lucide-react";
import { toast } from "sonner";

import { PhoneInput } from "@/components/shared/phone-input";
import { Button } from "@/components/ui/button";
import {
  Field,
  FieldContent,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
  FieldLegend,
  FieldSet,
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
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { lookupContractorByInn } from "@/features/contractors/api/lookup-contractor-by-inn";
import type {
  Contractor,
  ContractorDraft,
} from "@/features/contractors/types/contractor.types";
import { ContractorTypeBadge } from "@/features/contractors/ui/shared/contractor-type-badge";
import { applyInnLookupToDraft } from "@/features/contractors/utils/contractor-inn-lookup";
import {
  CONTRACTOR_TYPE_OPTIONS,
  isContractorType,
} from "@/features/contractors/utils/contractor-type";
import {
  TAXATION_NONE_VALUE,
  taxationSelectItems,
} from "@/features/contractors/utils/contractor-taxation";
import {
  digitsInn,
  duplicateInnMessage,
  findContractorByInn,
  formatVatRate,
  isValidInn,
} from "@/features/contractors/utils/contractor.utils";
import {
  okvedFieldHint,
  okvedInputValue,
  onOkvedInputChange,
} from "@/lib/okved/okved";

type ContractorFormProps = {
  contractor?: Contractor | null;
  existingContractors: Contractor[];
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (draft: ContractorDraft) => void;
};

type FormErrors = Partial<
  Record<"fullName" | "shortName" | "inn" | "director" | "vatRate", string>
>;

function toDraft(contractor?: Contractor | null): ContractorDraft {
  return {
    fullName: contractor?.fullName ?? "",
    shortName: contractor?.shortName ?? "",
    inn: digitsInn(contractor?.inn ?? ""),
    type: contractor?.type ?? "customer",
    director: contractor?.director ?? "",
    legalAddress: contractor?.legalAddress ?? "",
    actualAddress: contractor?.actualAddress ?? "",
    phone: contractor?.phone ?? "",
    email: contractor?.email ?? "",
    website: contractor?.website ?? "",
    activityDescription: okvedInputValue(contractor?.activityDescription),
    kpp: contractor?.kpp ?? "",
    ogrn: contractor?.ogrn ?? "",
    okpo: contractor?.okpo ?? "",
    directorBasis: contractor?.directorBasis ?? "",
    directorPhone: contractor?.directorPhone ?? "",
    chiefAccountantName: contractor?.chiefAccountantName ?? "",
    chiefAccountantPhone: contractor?.chiefAccountantPhone ?? "",
    contactPerson: contractor?.contactPerson ?? "",
    taxationSystem: contractor?.taxationSystem ?? "",
    isVatPayer: contractor?.isVatPayer ?? false,
    vatRate: formatVatRate(contractor?.vatRate ?? 0),
  };
}

function isAbortError(error: unknown) {
  return (
    (error instanceof DOMException && error.name === "AbortError") ||
    (error instanceof Error && error.name === "AbortError")
  );
}

export function ContractorForm({
  contractor,
  existingContractors,
  isSaving,
  onCancel,
  onSubmit,
}: ContractorFormProps) {
  const [draft, setDraft] = useState<ContractorDraft>(() => toDraft(contractor));
  const [errors, setErrors] = useState<FormErrors>({});
  const [isLookingUp, setIsLookingUp] = useState(false);
  const lookupAbortRef = useRef<AbortController | null>(null);
  const isNew = !contractor;
  const isBusy = isSaving || isLookingUp;
  const taxItems = taxationSelectItems(draft.taxationSystem);
  const activityHint = okvedFieldHint(draft.activityDescription);

  useEffect(() => {
    return () => {
      lookupAbortRef.current?.abort();
    };
  }, []);

  function update<K extends keyof ContractorDraft>(
    key: K,
    value: ContractorDraft[K]
  ) {
    setDraft((current) => ({ ...current, [key]: value }));
  }

  function validate(): FormErrors {
    const nextErrors: FormErrors = {};
    if (!draft.fullName.trim()) {
      nextErrors.fullName = "Введите полное наименование";
    }
    if (!draft.shortName.trim()) {
      nextErrors.shortName = "Введите сокращённое наименование";
    }
    if (!draft.inn.trim()) {
      nextErrors.inn = "Введите ИНН";
    } else if (!isValidInn(draft.inn.trim())) {
      nextErrors.inn = "ИНН должен содержать 10 или 12 цифр";
    } else {
      const duplicate = findContractorByInn(
        existingContractors,
        draft.inn,
        contractor?.id
      );
      if (duplicate) {
        nextErrors.inn = duplicateInnMessage(duplicate);
      }
    }
    if (!draft.director.trim()) {
      nextErrors.director = "Введите ФИО директора";
    }
    if (draft.isVatPayer) {
      const vatRate = Number(draft.vatRate.replace(",", "."));
      if (!Number.isFinite(vatRate) || vatRate < 0) {
        nextErrors.vatRate = "Введите ставку НДС";
      }
    }
    return nextErrors;
  }

  async function handleLookup() {
    const inn = digitsInn(draft.inn);
    if (!isValidInn(inn)) {
      setErrors((current) => ({
        ...current,
        inn: inn ? "ИНН должен содержать 10 или 12 цифр" : "Введите ИНН",
      }));
      return;
    }

    lookupAbortRef.current?.abort();
    const controller = new AbortController();
    lookupAbortRef.current = controller;
    setIsLookingUp(true);
    setErrors((current) => ({ ...current, inn: undefined }));

    try {
      const lookup = await lookupContractorByInn(inn, controller.signal);
      if (controller.signal.aborted) {
        return;
      }
      setDraft((current) => applyInnLookupToDraft(current, lookup));
      const duplicate = findContractorByInn(
        existingContractors,
        inn,
        contractor?.id
      );
      setErrors((current) => ({
        ...current,
        fullName: undefined,
        shortName: undefined,
        inn: duplicate ? duplicateInnMessage(duplicate) : undefined,
        director: undefined,
      }));
      if (duplicate) {
        toast.error(duplicateInnMessage(duplicate));
      } else {
        toast.success("Данные загружены по ИНН");
      }
    } catch (error) {
      if (controller.signal.aborted || isAbortError(error)) {
        return;
      }
      toast.error(
        error instanceof Error
          ? error.message
          : "Не удалось загрузить данные по ИНН"
      );
    } finally {
      if (!controller.signal.aborted) {
        setIsLookingUp(false);
      }
    }
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (isLookingUp) {
      return;
    }
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
        <FieldSet>
          <FieldLegend>Основная информация</FieldLegend>
          <Field data-invalid={Boolean(errors.inn)}>
            <FieldLabel htmlFor="contractor-inn">ИНН</FieldLabel>
            <FieldGroup className="grid grid-cols-[minmax(0,1fr)_auto] items-center gap-2">
              <Input
                id="contractor-inn"
                value={draft.inn}
                disabled={isBusy}
                autoFocus={isNew}
                inputMode="numeric"
                autoComplete="off"
                aria-invalid={Boolean(errors.inn)}
                placeholder="10 или 12 цифр"
                onChange={(event) =>
                  update("inn", digitsInn(event.target.value))
                }
                onKeyDown={(event) => {
                  if (event.key !== "Enter") {
                    return;
                  }
                  event.preventDefault();
                  void handleLookup();
                }}
              />
              <Button
                type="button"
                variant="outline"
                disabled={isBusy}
                onClick={() => {
                  void handleLookup();
                }}
              >
                {isLookingUp ? (
                  <Spinner data-icon="inline-start" />
                ) : (
                  <SearchIcon data-icon="inline-start" />
                )}
                Поиск по ИНН
              </Button>
            </FieldGroup>
            <FieldError>{errors.inn}</FieldError>
          </Field>
          <Field data-invalid={Boolean(errors.fullName)}>
            <FieldLabel htmlFor="contractor-full-name">
              Полное наименование
            </FieldLabel>
            <Input
              id="contractor-full-name"
              value={draft.fullName}
              disabled={isBusy}
              aria-invalid={Boolean(errors.fullName)}
              placeholder="ООО «Компания»"
              onChange={(event) => update("fullName", event.target.value)}
            />
            <FieldError>{errors.fullName}</FieldError>
          </Field>
          <FieldGroup className="grid sm:grid-cols-2">
            <Field data-invalid={Boolean(errors.shortName)}>
              <FieldLabel htmlFor="contractor-short-name">
                Краткое наименование
              </FieldLabel>
              <Input
                id="contractor-short-name"
                value={draft.shortName}
                disabled={isBusy}
                aria-invalid={Boolean(errors.shortName)}
                placeholder="Компания"
                onChange={(event) => update("shortName", event.target.value)}
              />
              <FieldError>{errors.shortName}</FieldError>
            </Field>
            <Field>
              <FieldLabel htmlFor="contractor-type">Тип контрагента</FieldLabel>
              <Select
                value={draft.type}
                items={CONTRACTOR_TYPE_OPTIONS}
                disabled={isBusy}
                onValueChange={(value) => {
                  if (!isContractorType(value)) {
                    return;
                  }
                  update("type", value);
                }}
              >
                <SelectTrigger id="contractor-type" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectGroup>
                    {CONTRACTOR_TYPE_OPTIONS.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        <ContractorTypeBadge type={option.value} />
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            </Field>
          </FieldGroup>
          <Field>
            <FieldLabel htmlFor="contractor-activity">Код ОКВЭД</FieldLabel>
            <Input
              id="contractor-activity"
              value={draft.activityDescription}
              disabled={isBusy}
              inputMode="decimal"
              autoComplete="off"
              placeholder="43.29"
              onChange={(event) =>
                update(
                  "activityDescription",
                  onOkvedInputChange(event.target.value)
                )
              }
            />
            {activityHint ? (
              <FieldDescription>{activityHint}</FieldDescription>
            ) : (
              <FieldDescription>
                Название подставится само. Вводить его не нужно.
              </FieldDescription>
            )}
          </Field>
        </FieldSet>

        <FieldSet>
          <FieldLegend>Юридические данные</FieldLegend>
          <FieldGroup className="grid sm:grid-cols-3">
            <Field>
              <FieldLabel htmlFor="contractor-kpp">КПП</FieldLabel>
              <Input
                id="contractor-kpp"
                value={draft.kpp}
                disabled={isBusy}
                inputMode="numeric"
                onChange={(event) => update("kpp", event.target.value)}
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="contractor-ogrn">ОГРН</FieldLabel>
              <Input
                id="contractor-ogrn"
                value={draft.ogrn}
                disabled={isBusy}
                inputMode="numeric"
                onChange={(event) => update("ogrn", event.target.value)}
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="contractor-okpo">ОКПО</FieldLabel>
              <Input
                id="contractor-okpo"
                value={draft.okpo}
                disabled={isBusy}
                inputMode="numeric"
                onChange={(event) => update("okpo", event.target.value)}
              />
            </Field>
          </FieldGroup>
        </FieldSet>

        <FieldSet>
          <FieldLegend>Налогообложение</FieldLegend>
          <FieldGroup className="grid sm:grid-cols-2">
            <Field>
              <FieldLabel htmlFor="contractor-tax">
                Система налогообложения
              </FieldLabel>
              <Select
                value={draft.taxationSystem || TAXATION_NONE_VALUE}
                items={taxItems}
                disabled={isBusy}
                onValueChange={(value) => {
                  if (value === null || value === TAXATION_NONE_VALUE) {
                    update("taxationSystem", "");
                    return;
                  }
                  update("taxationSystem", value);
                }}
              >
                <SelectTrigger id="contractor-tax" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectGroup>
                    {taxItems.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        {option.label}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            </Field>
            <Field orientation="horizontal">
              <FieldContent>
                <FieldLabel htmlFor="contractor-vat">НДС</FieldLabel>
                <FieldDescription>Плательщик НДС</FieldDescription>
              </FieldContent>
              <Switch
                id="contractor-vat"
                checked={draft.isVatPayer}
                disabled={isBusy}
                onCheckedChange={(checked) => update("isVatPayer", checked)}
              />
            </Field>
          </FieldGroup>
          {draft.isVatPayer ? (
            <Field data-invalid={Boolean(errors.vatRate)}>
              <FieldLabel htmlFor="contractor-vat-rate">
                Ставка НДС (%)
              </FieldLabel>
              <Input
                id="contractor-vat-rate"
                value={draft.vatRate}
                disabled={isBusy}
                inputMode="decimal"
                aria-invalid={Boolean(errors.vatRate)}
                onChange={(event) => update("vatRate", event.target.value)}
              />
              <FieldError>{errors.vatRate}</FieldError>
            </Field>
          ) : null}
        </FieldSet>

        <FieldSet>
          <FieldLegend>Контакты</FieldLegend>
          <FieldGroup className="grid sm:grid-cols-2">
            <Field>
              <FieldLabel htmlFor="contractor-phone">Телефон компании</FieldLabel>
              <PhoneInput
                id="contractor-phone"
                value={draft.phone}
                disabled={isBusy}
                onValueChange={(value) => update("phone", value)}
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="contractor-email">Email</FieldLabel>
              <Input
                id="contractor-email"
                value={draft.email}
                disabled={isBusy}
                type="email"
                onChange={(event) => update("email", event.target.value)}
              />
            </Field>
          </FieldGroup>
          <Field>
            <FieldLabel htmlFor="contractor-website">Сайт</FieldLabel>
            <Input
              id="contractor-website"
              value={draft.website}
              disabled={isBusy}
              placeholder="https://"
              onChange={(event) => update("website", event.target.value)}
            />
          </Field>
          <Field>
            <FieldLabel htmlFor="contractor-contact">
              Контактное лицо
            </FieldLabel>
            <Input
              id="contractor-contact"
              value={draft.contactPerson}
              disabled={isBusy}
              onChange={(event) => update("contactPerson", event.target.value)}
            />
          </Field>
        </FieldSet>

        <FieldSet>
          <FieldLegend>Адреса</FieldLegend>
          <Field>
            <FieldLabel htmlFor="contractor-legal-address">
              Юридический адрес
            </FieldLabel>
            <Textarea
              id="contractor-legal-address"
              value={draft.legalAddress}
              disabled={isBusy}
              onChange={(event) => update("legalAddress", event.target.value)}
            />
          </Field>
          <Field>
            <FieldLabel htmlFor="contractor-actual-address">
              Фактический адрес
            </FieldLabel>
            <Textarea
              id="contractor-actual-address"
              value={draft.actualAddress}
              disabled={isBusy}
              onChange={(event) => update("actualAddress", event.target.value)}
            />
          </Field>
        </FieldSet>

        <FieldSet>
          <FieldLegend>Руководство и бухгалтерия</FieldLegend>
          <FieldGroup className="grid sm:grid-cols-2">
            <Field data-invalid={Boolean(errors.director)}>
              <FieldLabel htmlFor="contractor-director">
                Генеральный директор
              </FieldLabel>
              <Input
                id="contractor-director"
                value={draft.director}
                disabled={isBusy}
                aria-invalid={Boolean(errors.director)}
                onChange={(event) => update("director", event.target.value)}
              />
              <FieldError>{errors.director}</FieldError>
            </Field>
            <Field>
              <FieldLabel htmlFor="contractor-director-phone">
                Телефон руководителя
              </FieldLabel>
              <PhoneInput
                id="contractor-director-phone"
                value={draft.directorPhone}
                disabled={isBusy}
                onValueChange={(value) => update("directorPhone", value)}
              />
            </Field>
          </FieldGroup>
          <Field>
            <FieldLabel htmlFor="contractor-director-basis">
              Действует на основании
            </FieldLabel>
            <Input
              id="contractor-director-basis"
              value={draft.directorBasis}
              disabled={isBusy}
              placeholder="Устава, доверенности"
              onChange={(event) => update("directorBasis", event.target.value)}
            />
          </Field>
          <FieldGroup className="grid sm:grid-cols-2">
            <Field>
              <FieldLabel htmlFor="contractor-accountant">
                Главный бухгалтер
              </FieldLabel>
              <Input
                id="contractor-accountant"
                value={draft.chiefAccountantName}
                disabled={isBusy}
                onChange={(event) =>
                  update("chiefAccountantName", event.target.value)
                }
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="contractor-accountant-phone">
                Телефон бухгалтера
              </FieldLabel>
              <PhoneInput
                id="contractor-accountant-phone"
                value={draft.chiefAccountantPhone}
                disabled={isBusy}
                onValueChange={(value) =>
                  update("chiefAccountantPhone", value)
                }
              />
            </Field>
          </FieldGroup>
        </FieldSet>
      </FieldGroup>

      <div className="flex justify-end gap-2">
        <Button type="button" variant="outline" disabled={isSaving} onClick={onCancel}>
          Отмена
        </Button>
        <Button type="submit" disabled={isBusy}>
          {isSaving ? <Spinner data-icon="inline-start" /> : null}
          {isNew ? "Создать" : "Сохранить"}
        </Button>
      </div>
    </form>
  );
}
