"use client";

import { Button } from "@/components/ui/button";
import { Field, FieldLabel } from "@/components/ui/field";
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
};

/** Поля реквизитов компании. Используются при создании и редактировании. */
export function CompanyRequisitesFields({
  draft,
  onChange,
  disabled,
  showInnSearch,
  isSearching,
  onSearchInn,
}: CompanyRequisitesFieldsProps) {
  const taxItems = taxationSystems.map((item) => ({ value: item, label: item }));

  return (
    <>
      <SectionTitle>Основная информация</SectionTitle>
      <TextField
        id="company-name-full"
        label="Полное наименование"
        value={draft.nameFull}
        disabled={disabled}
        onChange={(value) => onChange("nameFull", value)}
      />
      <TextField
        id="company-name-short"
        label="Краткое наименование"
        value={draft.nameShort}
        disabled={disabled}
        onChange={(value) => onChange("nameShort", value)}
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
            id="company-inn"
            label="ИНН"
            value={draft.inn}
            placeholder="10 или 12 цифр"
            inputMode="numeric"
            disabled={disabled}
            onChange={(value) => onChange("inn", value)}
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
          id="company-kpp"
          label="КПП"
          value={draft.kpp}
          inputMode="numeric"
          disabled={disabled}
          onChange={(value) => onChange("kpp", value)}
        />
        <TextField
          id="company-ogrn"
          label="ОГРН"
          value={draft.ogrn}
          inputMode="numeric"
          disabled={disabled}
          onChange={(value) => onChange("ogrn", value)}
        />
      </div>
      <TextField
        id="company-okpo"
        label="ОКПО"
        value={draft.okpo}
        inputMode="numeric"
        disabled={disabled}
        onChange={(value) => onChange("okpo", value)}
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
};

function TextField({
  id,
  label,
  value,
  onChange,
  placeholder,
  disabled,
  inputMode,
}: TextFieldProps) {
  return (
    <Field>
      <FieldLabel htmlFor={id}>{label}</FieldLabel>
      <Input
        id={id}
        value={value}
        placeholder={placeholder}
        inputMode={inputMode}
        disabled={disabled}
        onChange={(event) => onChange(event.target.value)}
      />
    </Field>
  );
}

function TextareaField({
  id,
  label,
  value,
  onChange,
  disabled,
}: TextFieldProps) {
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
