"use client";

import { useMemo, useState, type FormEvent } from "react";

import {
  MobileSheetBody,
  MobileSheetChrome,
} from "@/components/shared/mobile-sheet-chrome";
import { PhoneInput } from "@/components/shared/phone-input";
import { Button } from "@/components/ui/button";
import {
  Field,
  FieldContent,
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
import { EmployeeObjectsField } from "@/features/employees/ui/shared/employee-objects-field";
import type {
  Employee,
  EmployeeDraft,
  EmployeeObjectOption,
} from "@/features/employees/types/employee.types";
import {
  EMPLOYEE_EMPLOYMENT_OPTIONS,
  isEmployeeEmploymentType,
} from "@/features/employees/utils/employee-employment";
import {
  EMPLOYEE_STATUS_OPTIONS,
  isEmployeeStatus,
} from "@/features/employees/utils/employee-status";
import {
  CLOTHING_SIZE_OPTIONS,
  HEIGHT_OPTIONS,
  SHOE_SIZE_OPTIONS,
  fromOptionalSelectValue,
  optionalSelectValue,
  sizeSelectItems,
  toDraft,
} from "@/features/employees/utils/employee.utils";

type EmployeeFormProps = {
  employee: Employee;
  objects: EmployeeObjectOption[];
  positions: string[];
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (draft: EmployeeDraft) => void;
  layout?: "dialog" | "sheet";
};

type FormErrors = Partial<Record<"lastName" | "firstName", string>>;

export function EmployeeForm({
  employee,
  objects,
  positions,
  isSaving,
  onCancel,
  onSubmit,
  layout = "dialog",
}: EmployeeFormProps) {
  const [draft, setDraft] = useState<EmployeeDraft>(() => toDraft(employee));
  const [errors, setErrors] = useState<FormErrors>({});
  const clothingItems = useMemo(
    () => sizeSelectItems(CLOTHING_SIZE_OPTIONS),
    []
  );
  const shoeItems = useMemo(() => sizeSelectItems(SHOE_SIZE_OPTIONS), []);
  const heightItems = useMemo(() => sizeSelectItems(HEIGHT_OPTIONS), []);
  const positionOptions = useMemo(() => {
    const names = new Set(positions);
    if (draft.position) {
      names.add(draft.position);
    }
    return [...names].sort((a, b) =>
      a.localeCompare(b, "ru", { sensitivity: "base" })
    );
  }, [draft.position, positions]);

  function update<K extends keyof EmployeeDraft>(
    key: K,
    value: EmployeeDraft[K]
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

  function submitDraft() {
    const nextErrors = validate();
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length > 0) {
      return;
    }
    onSubmit(draft);
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    submitDraft();
  }

  const isSheet = layout === "sheet";
  const row2 = isSheet ? undefined : "grid sm:grid-cols-2";
  const row3 = isSheet ? undefined : "grid sm:grid-cols-3";

  const fields = (
      <>
      <FieldSet>
        <FieldLegend>Личные данные</FieldLegend>
        <FieldGroup>
          <FieldGroup className={row3}>
            <Field data-invalid={Boolean(errors.lastName)}>
              <FieldLabel htmlFor="employee-edit-last-name">Фамилия</FieldLabel>
              <Input
                id="employee-edit-last-name"
                value={draft.lastName}
                disabled={isSaving}
                aria-invalid={Boolean(errors.lastName)}
                onChange={(event) => update("lastName", event.target.value)}
              />
              <FieldError>{errors.lastName}</FieldError>
            </Field>
            <Field data-invalid={Boolean(errors.firstName)}>
              <FieldLabel htmlFor="employee-edit-first-name">Имя</FieldLabel>
              <Input
                id="employee-edit-first-name"
                value={draft.firstName}
                disabled={isSaving}
                aria-invalid={Boolean(errors.firstName)}
                onChange={(event) => update("firstName", event.target.value)}
              />
              <FieldError>{errors.firstName}</FieldError>
            </Field>
            <Field>
              <FieldLabel htmlFor="employee-edit-middle-name">
                Отчество
              </FieldLabel>
              <Input
                id="employee-edit-middle-name"
                value={draft.middleName}
                disabled={isSaving}
                onChange={(event) => update("middleName", event.target.value)}
              />
            </Field>
          </FieldGroup>
          <FieldGroup className={row2}>
            <Field>
              <FieldLabel htmlFor="employee-birth-date">
                Дата рождения
              </FieldLabel>
              <Input
                id="employee-birth-date"
                type="date"
                value={draft.birthDate}
                disabled={isSaving}
                onChange={(event) => update("birthDate", event.target.value)}
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="employee-birth-place">
                Место рождения
              </FieldLabel>
              <Input
                id="employee-birth-place"
                value={draft.birthPlace}
                disabled={isSaving}
                onChange={(event) => update("birthPlace", event.target.value)}
              />
            </Field>
          </FieldGroup>
          <Field>
            <FieldLabel htmlFor="employee-citizenship">Гражданство</FieldLabel>
            <Input
              id="employee-citizenship"
              value={draft.citizenship}
              disabled={isSaving}
              onChange={(event) => update("citizenship", event.target.value)}
            />
          </Field>
          <FieldGroup className={row3}>
            <Field>
              <FieldLabel htmlFor="employee-clothing">Размер одежды</FieldLabel>
              <Select
                value={optionalSelectValue(draft.clothingSize)}
                items={clothingItems}
                disabled={isSaving}
                onValueChange={(value) => {
                  if (value === null) {
                    return;
                  }
                  update("clothingSize", fromOptionalSelectValue(value));
                }}
              >
                <SelectTrigger id="employee-clothing" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectGroup>
                    {clothingItems.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        {option.label}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            </Field>
            <Field>
              <FieldLabel htmlFor="employee-shoe">Размер обуви</FieldLabel>
              <Select
                value={optionalSelectValue(draft.shoeSize)}
                items={shoeItems}
                disabled={isSaving}
                onValueChange={(value) => {
                  if (value === null) {
                    return;
                  }
                  update("shoeSize", fromOptionalSelectValue(value));
                }}
              >
                <SelectTrigger id="employee-shoe" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectGroup>
                    {shoeItems.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        {option.label}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            </Field>
            <Field>
              <FieldLabel htmlFor="employee-height">Рост</FieldLabel>
              <Select
                value={optionalSelectValue(draft.height)}
                items={heightItems}
                disabled={isSaving}
                onValueChange={(value) => {
                  if (value === null) {
                    return;
                  }
                  update("height", fromOptionalSelectValue(value));
                }}
              >
                <SelectTrigger id="employee-height" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectGroup>
                    {heightItems.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        {option.label}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            </Field>
          </FieldGroup>
        </FieldGroup>
      </FieldSet>

      <FieldSet>
        <FieldLegend>Работа</FieldLegend>
        <FieldGroup>
          <FieldGroup className={row2}>
            <Field>
              <FieldLabel htmlFor="employee-status">Статус</FieldLabel>
              <Select
                value={draft.status}
                items={EMPLOYEE_STATUS_OPTIONS}
                disabled={isSaving}
                onValueChange={(value) => {
                  if (value && isEmployeeStatus(value)) {
                    update("status", value);
                  }
                }}
              >
                <SelectTrigger id="employee-status" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectGroup>
                    {EMPLOYEE_STATUS_OPTIONS.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        {option.label}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            </Field>
            <Field>
              <FieldLabel htmlFor="employee-employment-type">
                Вид трудоустройства
              </FieldLabel>
              <Select
                value={draft.employmentType}
                items={EMPLOYEE_EMPLOYMENT_OPTIONS}
                disabled={isSaving}
                onValueChange={(value) => {
                  if (value && isEmployeeEmploymentType(value)) {
                    update("employmentType", value);
                  }
                }}
              >
                <SelectTrigger id="employee-employment-type" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectGroup>
                    {EMPLOYEE_EMPLOYMENT_OPTIONS.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        {option.label}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            </Field>
          </FieldGroup>
          <FieldGroup className={row2}>
            <Field>
              <FieldLabel htmlFor="employee-position">Должность</FieldLabel>
              <Input
                id="employee-position"
                value={draft.position}
                disabled={isSaving}
                list="employee-positions"
                onChange={(event) => update("position", event.target.value)}
              />
              <datalist id="employee-positions">
                {positionOptions.map((position) => (
                  <option key={position} value={position} />
                ))}
              </datalist>
            </Field>
            <Field>
              <FieldLabel htmlFor="employee-hire-date">Дата приёма</FieldLabel>
              <Input
                id="employee-hire-date"
                type="date"
                value={draft.employmentDate}
                disabled={isSaving}
                onChange={(event) =>
                  update("employmentDate", event.target.value)
                }
              />
            </Field>
          </FieldGroup>
          <Field>
            <FieldLabel htmlFor="employee-edit-phone">Телефон</FieldLabel>
            <PhoneInput
              id="employee-edit-phone"
              value={draft.phone}
              disabled={isSaving}
              onValueChange={(value) => update("phone", value)}
            />
          </Field>
          <Field orientation="horizontal">
            <FieldContent>
              <FieldLabel htmlFor="employee-timesheet">
                Учитывать в табеле
              </FieldLabel>
            </FieldContent>
            <Switch
              id="employee-timesheet"
              checked={draft.includeInTimesheet}
              disabled={isSaving}
              onCheckedChange={(checked) =>
                update("includeInTimesheet", checked)
              }
            />
          </Field>
          <EmployeeObjectsField
            objects={objects}
            value={draft.objectIds}
            disabled={isSaving}
            onChange={(objectIds) => update("objectIds", objectIds)}
          />
        </FieldGroup>
      </FieldSet>

      <FieldSet>
        <FieldLegend>Документы</FieldLegend>
        <FieldGroup>
          <FieldGroup className={row2}>
            <Field>
              <FieldLabel htmlFor="employee-passport-series">
                Серия паспорта
              </FieldLabel>
              <Input
                id="employee-passport-series"
                value={draft.passportSeries}
                disabled={isSaving}
                onChange={(event) =>
                  update("passportSeries", event.target.value)
                }
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="employee-passport-number">
                Номер паспорта
              </FieldLabel>
              <Input
                id="employee-passport-number"
                value={draft.passportNumber}
                disabled={isSaving}
                onChange={(event) =>
                  update("passportNumber", event.target.value)
                }
              />
            </Field>
          </FieldGroup>
          <Field>
            <FieldLabel htmlFor="employee-passport-issued">
              Кем выдан
            </FieldLabel>
            <Input
              id="employee-passport-issued"
              value={draft.passportIssuedBy}
              disabled={isSaving}
              onChange={(event) =>
                update("passportIssuedBy", event.target.value)
              }
            />
          </Field>
          <FieldGroup className={row2}>
            <Field>
              <FieldLabel htmlFor="employee-passport-date">
                Дата выдачи
              </FieldLabel>
              <Input
                id="employee-passport-date"
                type="date"
                value={draft.passportIssueDate}
                disabled={isSaving}
                onChange={(event) =>
                  update("passportIssueDate", event.target.value)
                }
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="employee-passport-code">
                Код подразделения
              </FieldLabel>
              <Input
                id="employee-passport-code"
                value={draft.passportDepartmentCode}
                disabled={isSaving}
                onChange={(event) =>
                  update("passportDepartmentCode", event.target.value)
                }
              />
            </Field>
          </FieldGroup>
          <Field>
            <FieldLabel htmlFor="employee-address">
              Адрес регистрации
            </FieldLabel>
            <Input
              id="employee-address"
              value={draft.registrationAddress}
              disabled={isSaving}
              onChange={(event) =>
                update("registrationAddress", event.target.value)
              }
            />
          </Field>
          <FieldGroup className={row2}>
            <Field>
              <FieldLabel htmlFor="employee-inn">ИНН</FieldLabel>
              <Input
                id="employee-inn"
                value={draft.inn}
                disabled={isSaving}
                inputMode="numeric"
                onChange={(event) => update("inn", event.target.value)}
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="employee-snils">СНИЛС</FieldLabel>
              <Input
                id="employee-snils"
                value={draft.snils}
                disabled={isSaving}
                onChange={(event) => update("snils", event.target.value)}
              />
            </Field>
          </FieldGroup>
          <FieldGroup className={row2}>
            <Field>
              <FieldLabel htmlFor="employee-kig">КИГ</FieldLabel>
              <Input
                id="employee-kig"
                value={draft.kig}
                disabled={isSaving}
                onChange={(event) => update("kig", event.target.value)}
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="employee-patent">Номер патента</FieldLabel>
              <Input
                id="employee-patent"
                value={draft.patentNumber}
                disabled={isSaving}
                onChange={(event) => update("patentNumber", event.target.value)}
              />
            </Field>
          </FieldGroup>
        </FieldGroup>
      </FieldSet>
      </>
  );

  if (layout === "sheet") {
    return (
      <>
        <MobileSheetChrome
          title="Редактирование"
          description={`Карточка: ${employee.lastName} ${employee.firstName}`}
          confirmLabel="Сохранить"
          confirmDisabled={isSaving}
          confirmPending={isSaving}
          confirmShowLabelWhenEnabled
          onConfirm={submitDraft}
        />
        <MobileSheetBody>{fields}</MobileSheetBody>
      </>
    );
  }

  return (
    <form className="flex flex-col gap-6" onSubmit={handleSubmit}>
      {fields}
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
          Сохранить
        </Button>
      </div>
    </form>
  );
}
