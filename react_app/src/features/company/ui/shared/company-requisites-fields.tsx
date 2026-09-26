"use client";

import { Button } from "@/components/ui/button";
import { Field, FieldError, FieldLabel } from "@/components/ui/field";
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
import {
  taxationSystems,
  type CompanyDraft,
} from "@/features/company/types/company.types";
import type {
  CompanyFieldErrors,
  CompanyFieldKey,
} from "@/features/company/utils/company.utils";

/** Идентификаторы проверяемых полей — форма прокручивает окно к ошибке. */
export const companyFieldElementIds: Record<CompanyFieldKey, string> = {
  nameFull: "company-name-full",
  nameShort: "company-name-short",
  inn: "company-inn",
  kpp: "company-kpp",
  ogrn: "company-ogrn",
  okpo: "company-okpo",
};

type CompanyRequisitesFieldsProps = {
  draft: CompanyDraft;
  onChange: <K extends keyof CompanyDraft>(
    key: K,
    value: CompanyDraft[K]
  ) => void;
  disabled?: boolean;
  showInnSearch?: boolean;
  isSearching?: boolean;
  onSearchInn?: () => void;
  /** Ошибки проверяемых полей: показываются под своим полем. */
  errors?: CompanyFieldErrors;
  /** Уход из проверяемого поля — момент проверки. */
  onBlurField?: (key: CompanyFieldKey) => void;
};

/** Поля реквизитов компании. Используются при создании и редактировании. */
export function CompanyRequisitesFields({
  draft,
  onChange,
  disabled,
  showInnSearch,
  isSearching,
  onSearchInn,
  errors,
  onBlurField,
}: CompanyRequisitesFieldsProps) {
  const taxItems = taxationSystems.map((item) => ({ value: item, label: item }));

  return (
    <>
      <SectionTitle>Основная информация</SectionTitle>
      <TextField
        id={companyFieldElementIds.nameFull}
        label="Полное наименование"
        value={draft.nameFull}
        error={errors?.nameFull}
        disabled={disabled}
        onChange={(value) => onChange("nameFull", value)}
        onBlur={() => onBlurField?.("nameFull")}
      />
      <TextField
        id={companyFieldElementIds.nameShort}
        label="Краткое наименование"
        value={draft.nameShort}
        error={errors?.nameShort}
        disabled={disabled}
        onChange={(value) => onChange("nameShort", value)}
        onBlur={() => onBlurField?.("nameShort")}
      />
      <TextareaField
        id="company-activity"
        label="Сфера деятельности"
        value={draft.activityDescription}
        disabled={disabled}
        onChange={(value) => onChange("activityDescription", value)}
      />

      <SectionTitle>Юридические данные</SectionTitle>
      <div className="flex items-end gap-2">
        <div className="min-w-0 flex-1">
          <TextField
            id={companyFieldElementIds.inn}
            label="ИНН"
            value={draft.inn}
            placeholder="10 или 12 цифр"
            inputMode="numeric"
            error={errors?.inn}
            disabled={disabled}
            onChange={(value) => onChange("inn", value)}
            onBlur={() => onBlurField?.("inn")}
          />
        </div>
        {showInnSearch ? (
          <Button
            type="button"
            variant="outline"
            disabled={disabled || isSearching || !draft.inn.trim()}
            onClick={onSearchInn}
          >
            {isSearching ? <Spinner data-icon="inline-start" /> : null}
            Поиск
          </Button>
        ) : null}
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <TextField
          id={companyFieldElementIds.kpp}
          label="КПП"
          value={draft.kpp}
          inputMode="numeric"
          error={errors?.kpp}
          disabled={disabled}
          onChange={(value) => onChange("kpp", value)}
          onBlur={() => onBlurField?.("kpp")}
        />
        <TextField
          id={companyFieldElementIds.ogrn}
          label="ОГРН"
          value={draft.ogrn}
          inputMode="numeric"
          error={errors?.ogrn}
          disabled={disabled}
          onChange={(value) => onChange("ogrn", value)}
          onBlur={() => onBlurField?.("ogrn")}
        />
      </div>
      <TextField
        id={companyFieldElementIds.okpo}
        label="ОКПО"
        value={draft.okpo}
        inputMode="numeric"
        error={errors?.okpo}
        disabled={disabled}
        onChange={(value) => onChange("okpo", value)}
        onBlur={() => onBlurField?.("okpo")}
      />

      <SectionTitle>Налогообложение</SectionTitle>
      <div className="grid gap-4 sm:grid-cols-2">
        <Field>
          <FieldLabel htmlFor="company-taxation">
            Система налогообложения
          </FieldLabel>
          <Select
            value={draft.taxationSystem || null}
            items={taxItems}
            disabled={disabled}
            onValueChange={(value) =>
              onChange("taxationSystem", (value as string | null) ?? "")
            }
          >
            <SelectTrigger id="company-taxation" className="w-full">
              <SelectValue placeholder="Выберите систему" />
            </SelectTrigger>
            <SelectContent>
              <SelectGroup>
                {taxItems.map((item) => (
                  <SelectItem key={item.value} value={item.value}>
                    {item.label}
                  </SelectItem>
                ))}
              </SelectGroup>
            </SelectContent>
          </Select>
        </Field>
        <div className="flex flex-col gap-2">
          <FieldLabel htmlFor="company-vat">Плательщик НДС</FieldLabel>
          <div className="flex items-center gap-3">
            <Switch
              id="company-vat"
              checked={draft.isVatPayer}
              disabled={disabled}
              onCheckedChange={(checked) => onChange("isVatPayer", checked)}
            />
            {draft.isVatPayer ? (
              <Input
                className="max-w-28"
                value={draft.vatRate}
                inputMode="numeric"
                disabled={disabled}
                aria-label="Ставка НДС, %"
                onChange={(event) => onChange("vatRate", event.target.value)}
              />
            ) : (
              <span className="text-sm text-muted-foreground">Ставка, %</span>
            )}
          </div>
        </div>
      </div>

      <SectionTitle>Контакты</SectionTitle>
      <div className="grid gap-4 sm:grid-cols-2">
        <TextField
          id="company-website"
          label="Сайт"
          value={draft.website}
          disabled={disabled}
          onChange={(value) => onChange("website", value)}
        />
        <TextField
          id="company-email"
          label="Email"
          value={draft.email}
          inputMode="email"
          disabled={disabled}
          onChange={(value) => onChange("email", value)}
        />
        <TextField
          id="company-phone"
          label="Телефон компании"
          value={draft.phone}
          inputMode="tel"
          disabled={disabled}
          onChange={(value) => onChange("phone", value)}
        />
        <TextField
          id="company-contact"
          label="Контактное лицо"
          value={draft.contactPerson}
          disabled={disabled}
          onChange={(value) => onChange("contactPerson", value)}
        />
      </div>

      <SectionTitle>Адреса</SectionTitle>
      <TextareaField
        id="company-legal-address"
        label="Юридический адрес"
        value={draft.legalAddress}
        disabled={disabled}
        onChange={(value) => onChange("legalAddress", value)}
      />
      <TextareaField
        id="company-actual-address"
        label="Фактический адрес"
        value={draft.actualAddress}
        disabled={disabled}
        onChange={(value) => onChange("actualAddress", value)}
      />

      <SectionTitle>Руководство</SectionTitle>
      <TextField
        id="company-director-name"
        label="ФИО руководителя"
        value={draft.directorName}
        disabled={disabled}
        onChange={(value) => onChange("directorName", value)}
      />
      <div className="grid gap-4 sm:grid-cols-2">
        <TextField
          id="company-director-position"
          label="Должность"
          value={draft.directorPosition}
          disabled={disabled}
          onChange={(value) => onChange("directorPosition", value)}
        />
        <TextField
          id="company-director-phone"
          label="Телефон"
          value={draft.directorPhone}
          inputMode="tel"
          disabled={disabled}
          onChange={(value) => onChange("directorPhone", value)}
        />
      </div>
      <TextField
        id="company-director-basis"
        label="Основание полномочий"
        value={draft.directorBasis}
        placeholder="Устава, Доверенности…"
        disabled={disabled}
        onChange={(value) => onChange("directorBasis", value)}
      />

      <SectionTitle>Бухгалтерия</SectionTitle>
      <div className="grid gap-4 sm:grid-cols-2">
        <TextField
          id="company-accountant-name"
          label="ФИО главбуха"
          value={draft.chiefAccountantName}
          disabled={disabled}
          onChange={(value) => onChange("chiefAccountantName", value)}
        />
        <TextField
          id="company-accountant-phone"
          label="Телефон"
          value={draft.chiefAccountantPhone}
          inputMode="tel"
          disabled={disabled}
          onChange={(value) => onChange("chiefAccountantPhone", value)}
        />
      </div>
    </>
  );
}

function SectionTitle({ children }: { children: string }) {
  return (
    <p className="text-xs font-semibold uppercase tracking-wider text-primary">
      {children}
    </p>
  );
}

type TextFieldProps = {
  id: string;
  label: string;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  disabled?: boolean;
  inputMode?: "text" | "numeric" | "tel" | "email" | "url";
  /** Сообщение проверки — показывается под полем. */
  error?: string;
  /** Проверка поля выполняется, когда пользователь ушёл из него. */
  onBlur?: () => void;
};

function TextField({
  id,
  label,
  value,
  onChange,
  placeholder,
  disabled,
  inputMode,
  error,
  onBlur,
}: TextFieldProps) {
  return (
    <Field data-invalid={Boolean(error)}>
      <FieldLabel htmlFor={id}>{label}</FieldLabel>
      <Input
        id={id}
        value={value}
        placeholder={placeholder}
        inputMode={inputMode}
        disabled={disabled}
        aria-invalid={Boolean(error)}
        onChange={(event) => onChange(event.target.value)}
        onBlur={onBlur}
      />
      <FieldError>{error}</FieldError>
    </Field>
  );
}

type TextareaFieldProps = {
  id: string;
  label: string;
  value: string;
  onChange: (value: string) => void;
  disabled?: boolean;
};

function TextareaField({
  id,
  label,
  value,
  onChange,
  disabled,
}: TextareaFieldProps) {
  return (
    <Field>
      <FieldLabel htmlFor={id}>{label}</FieldLabel>
      <Textarea
        id={id}
        value={value}
        disabled={disabled}
        onChange={(event) => onChange(event.target.value)}
      />
    </Field>
  );
}
