"use client";

import { PencilIcon, Trash2Icon, type LucideIcon } from "lucide-react";
import type { ReactNode } from "react";

import { Button, buttonVariants } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { ContractorBankAccounts } from "@/features/contractors/ui/shared/contractor-bank-accounts";
import type { Contractor } from "@/features/contractors/types/contractor.types";
import { formatVatRate } from "@/features/contractors/utils/contractor.utils";
import { formatOkvedLabel } from "@/lib/okved/okved";
import { cn } from "@/lib/utils";
import { formatPhone, normalizeRuPhoneE164 } from "@/lib/utils/phone";

type ContractorDetailsProps = {
  contractor: Contractor;
  isExpanded: boolean;
  canUpdate: boolean;
  canDelete: boolean;
  onEdit: () => void;
  onDelete: () => void;
};

function filled(value: string | null | undefined): string | null {
  const text = value?.trim() ?? "";
  return text ? text : null;
}

function websiteHref(value: string): string {
  if (/^https?:\/\//i.test(value)) {
    return value;
  }
  return `https://${value}`;
}

function Field({
  label,
  children,
}: {
  label: string;
  children: ReactNode;
}) {
  return (
    <div className="flex min-w-0 flex-col gap-1">
      <p className="text-xs text-muted-foreground">{label}</p>
      <div className="flex flex-col items-start gap-1 text-sm">{children}</div>
    </div>
  );
}

function TextValue({ value }: { value: string }) {
  return <p className="text-sm">{value}</p>;
}

function LinkValue({
  href,
  children,
  external,
}: {
  href: string;
  children: string;
  external?: boolean;
}) {
  return (
    <a
      href={href}
      className={cn(
        buttonVariants({ variant: "link" }),
        "h-auto w-fit justify-start self-start px-0",
      )}
      {...(external
        ? { target: "_blank", rel: "noreferrer" }
        : undefined)}
    >
      {children}
    </a>
  );
}

function PhoneValue({ value }: { value: string }) {
  const display = formatPhone(value) || value;
  const normalized = normalizeRuPhoneE164(value);
  const href = normalized
    ? `tel:${normalized}`
    : `tel:${value.replace(/\D/g, "")}`;
  return <LinkValue href={href}>{display}</LinkValue>;
}

function ActionButton({
  label,
  variant,
  icon: Icon,
  onClick,
}: {
  label: string;
  variant: "outline" | "destructive";
  icon: LucideIcon;
  onClick: () => void;
}) {
  return (
    <Tooltip>
      <TooltipTrigger
        render={
          <Button
            type="button"
            variant={variant}
            size="icon"
            className="@4xl:h-8 @4xl:w-auto @4xl:gap-1.5 @4xl:px-2.5"
            aria-label={label}
            onClick={onClick}
          />
        }
      >
        <Icon data-icon="inline-start" />
        <span className="hidden @4xl:inline">{label}</span>
      </TooltipTrigger>
      <TooltipContent>{label}</TooltipContent>
    </Tooltip>
  );
}

export function ContractorDetails({
  contractor,
  isExpanded,
  canUpdate,
  canDelete,
  onEdit,
  onDelete,
}: ContractorDetailsProps) {
  const fullName = filled(contractor.fullName);
  const activity = formatOkvedLabel(contractor.activityDescription);
  const inn = filled(contractor.inn);
  const kpp = filled(contractor.kpp);
  const ogrn = filled(contractor.ogrn);
  const okpo = filled(contractor.okpo);
  const tax = filled(contractor.taxationSystem);
  const legalAddress = filled(contractor.legalAddress);
  const actualAddress = filled(contractor.actualAddress);
  const director = filled(contractor.director);
  const directorPhone = filled(contractor.directorPhone);
  const directorBasis = filled(contractor.directorBasis);
  const accountant = filled(contractor.chiefAccountantName);
  const accountantPhone = filled(contractor.chiefAccountantPhone);
  const phone = filled(contractor.phone);
  const email = filled(contractor.email);
  const website = filled(contractor.website);
  const contactPerson = filled(contractor.contactPerson);

  const codes = [
    inn ? { label: "ИНН", value: inn } : null,
    kpp ? { label: "КПП", value: kpp } : null,
    ogrn ? { label: "ОГРН", value: ogrn } : null,
    okpo ? { label: "ОКПО", value: okpo } : null,
    tax ? { label: "Налог", value: tax } : null,
    {
      label: "НДС",
      value: contractor.isVatPayer
        ? `Да (${formatVatRate(contractor.vatRate)}%)`
        : "Нет",
    },
  ].filter((item): item is { label: string; value: string } => item !== null);

  const hasAddresses = Boolean(legalAddress || actualAddress);
  const hasDirector = Boolean(director || directorPhone || directorBasis);
  const hasAccountant = Boolean(accountant || accountantPhone);
  const hasPeople = hasDirector || hasAccountant;
  const hasContacts = Boolean(phone || email || website || contactPerson);
  const hasActions = canUpdate || canDelete;

  return (
    <div className="@container flex flex-col gap-5 border-t px-(--card-spacing) py-(--card-spacing)">
      <div className="flex flex-wrap items-start justify-between gap-3">
        {fullName || activity ? (
          <div className="flex min-w-0 flex-1 flex-col gap-1">
            {fullName ? (
              <p className="text-sm font-medium">{fullName}</p>
            ) : null}
            {activity ? (
              <p className="text-sm text-muted-foreground">{activity}</p>
            ) : null}
          </div>
        ) : (
          <div className="min-w-0 flex-1" />
        )}

        {hasActions ? (
          <div className="flex shrink-0 items-center gap-2">
            {canUpdate ? (
              <ActionButton
                label="Изменить"
                variant="outline"
                icon={PencilIcon}
                onClick={onEdit}
              />
            ) : null}
            {canDelete ? (
              <ActionButton
                label="Удалить"
                variant="destructive"
                icon={Trash2Icon}
                onClick={onDelete}
              />
            ) : null}
          </div>
        ) : null}
      </div>

      <div className="flex flex-wrap gap-x-6 gap-y-3">
        {codes.map((item) => (
          <Field key={item.label} label={item.label}>
            <TextValue value={item.value} />
          </Field>
        ))}
      </div>

      {hasAddresses ? (
        <>
          <Separator />
          <div className="grid gap-4 @2xl:grid-cols-2">
            {legalAddress ? (
              <Field label="Юридический адрес">
                <TextValue value={legalAddress} />
              </Field>
            ) : null}
            {actualAddress ? (
              <Field label="Фактический адрес">
                <TextValue value={actualAddress} />
              </Field>
            ) : null}
          </div>
        </>
      ) : null}

      {hasPeople ? (
        <>
          <Separator />
          <div className="grid gap-4 @2xl:grid-cols-2">
            {hasDirector ? (
              <div className="flex min-w-0 flex-col gap-3">
                <Field label="Генеральный директор">
                  {director ? <TextValue value={director} /> : null}
                  {directorPhone ? (
                    <PhoneValue value={directorPhone} />
                  ) : null}
                </Field>
                {directorBasis ? (
                  <Field label="Действует на основании">
                    <TextValue value={directorBasis} />
                  </Field>
                ) : null}
              </div>
            ) : null}
            {hasAccountant ? (
              <Field label="Главный бухгалтер">
                {accountant ? <TextValue value={accountant} /> : null}
                {accountantPhone ? (
                  <PhoneValue value={accountantPhone} />
                ) : null}
              </Field>
            ) : null}
          </div>
        </>
      ) : null}

      {hasContacts ? (
        <>
          <Separator />
          <div className="flex flex-wrap gap-x-6 gap-y-3">
            {phone ? (
              <Field label="Телефон">
                <PhoneValue value={phone} />
              </Field>
            ) : null}
            {email ? (
              <Field label="Email">
                <LinkValue href={`mailto:${email}`}>{email}</LinkValue>
              </Field>
            ) : null}
            {website ? (
              <Field label="Сайт">
                <LinkValue href={websiteHref(website)} external>
                  {website}
                </LinkValue>
              </Field>
            ) : null}
            {contactPerson ? (
              <Field label="Контактное лицо">
                <TextValue value={contactPerson} />
              </Field>
            ) : null}
          </div>
        </>
      ) : null}

      <ContractorBankAccounts
        contractorId={contractor.id}
        enabled={isExpanded}
      />
    </div>
  );
}
