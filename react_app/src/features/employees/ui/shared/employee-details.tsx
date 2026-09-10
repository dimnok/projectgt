"use client";

import { useState, type ReactNode } from "react";
import {
  BriefcaseIcon,
  Building2Icon,
  CalendarDaysIcon,
  CalendarIcon,
  CheckIcon,
  CoinsIcon,
  CopyIcon,
  CreditCardIcon,
  FileTextIcon,
  GlobeIcon,
  MapPinIcon,
  PhoneIcon,
  ShieldCheckIcon,
  ShirtIcon,
  UserIcon,
  type LucideIcon,
} from "lucide-react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import type {
  Employee,
  EmployeeObjectOption,
} from "@/features/employees/types/employee.types";
import { EmployeeRateSummary } from "@/features/employees/ui/shared/employee-rate-summary";
import { EmployeeTripSummary } from "@/features/employees/ui/shared/employee-trip-summary";
import { formatRuDate } from "@/features/employees/utils/employee.utils";
import { cn } from "@/lib/utils";
import { formatPhone, normalizeRuPhoneE164 } from "@/lib/utils/phone";

type EmployeeDetailsProps = {
  employee: Employee;
  objects: EmployeeObjectOption[];
  objectNamesById: Map<string, string>;
  canUpdate: boolean;
};

function filled(value: string | null | undefined): string | null {
  const text = value?.trim() ?? "";
  return text ? text : null;
}

function formatAge(birthDateStr: string | null | undefined): string | null {
  if (!birthDateStr) return null;
  const clean = birthDateStr.split("T")[0];
  const [y, m, d] = clean.split("-").map(Number);
  if (!y || !m || !d) return null;
  const birth = new Date(y, m - 1, d);
  const now = new Date();
  let age = now.getFullYear() - birth.getFullYear();
  const mDiff = now.getMonth() - birth.getMonth();
  if (mDiff < 0 || (mDiff === 0 && now.getDate() < birth.getDate())) {
    age--;
  }
  if (age < 0 || age > 120) return null;

  const mod10 = age % 10;
  const mod100 = age % 100;
  let word = "лет";
  if (mod10 === 1 && mod100 !== 11) {
    word = "год";
  } else if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
    word = "года";
  }
  return `${age} ${word}`;
}

function formatTenure(hireDateStr: string | null | undefined): string | null {
  if (!hireDateStr) return null;
  const clean = hireDateStr.split("T")[0];
  const [y, m, d] = clean.split("-").map(Number);
  if (!y || !m || !d) return null;
  const start = new Date(y, m - 1, d);
  const now = new Date();
  if (start > now) return null;

  let years = now.getFullYear() - start.getFullYear();
  let months = now.getMonth() - start.getMonth();
  if (now.getDate() < start.getDate()) {
    months--;
  }
  if (months < 0) {
    years--;
    months += 12;
  }
  if (years === 0 && months === 0) return "меньше месяца";

  const parts: string[] = [];
  if (years > 0) {
    const mod10 = years % 10;
    const mod100 = years % 100;
    let word = "лет";
    if (mod10 === 1 && mod100 !== 11) word = "год";
    else if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) word = "года";
    parts.push(`${years} ${word}`);
  }
  if (months > 0) {
    const mod10 = months % 10;
    const mod100 = months % 100;
    let word = "месяцев";
    if (mod10 === 1 && mod100 !== 11) word = "месяц";
    else if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) word = "месяца";
    parts.push(`${months} ${word}`);
  }
  return parts.join(" ");
}

function CopyButton({
  value,
  label = "Скопировано",
  className,
}: {
  value: string;
  label?: string;
  className?: string;
}) {
  const [copied, setCopied] = useState(false);

  const handleCopy = (e: React.MouseEvent) => {
    e.stopPropagation();
    e.preventDefault();
    if (!value) return;
    navigator.clipboard.writeText(value);
    setCopied(true);
    toast.success(label);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <button
      type="button"
      onClick={handleCopy}
      className={cn(
        "inline-flex size-6 shrink-0 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-muted hover:text-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
        className
      )}
      title="Скопировать"
      aria-label="Скопировать"
    >
      {copied ? (
        <CheckIcon className="size-3.5 text-emerald-600 dark:text-emerald-400" />
      ) : (
        <CopyIcon className="size-3.5" />
      )}
    </button>
  );
}

function SectionCard({
  icon: Icon,
  title,
  badge,
  children,
  className,
}: {
  icon: LucideIcon;
  title: string;
  badge?: ReactNode;
  children: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "rounded-2xl border border-border/80 bg-card p-5 shadow-xs transition-shadow",
        className
      )}
    >
      <div className="mb-4 flex items-center justify-between gap-3 border-b border-border/50 pb-3">
        <div className="flex items-center gap-2.5">
          <div className="flex size-7 items-center justify-center rounded-lg bg-primary/5 text-primary dark:bg-primary/10">
            <Icon className="size-4" />
          </div>
          <h3 className="text-sm font-semibold tracking-tight text-foreground">
            {title}
          </h3>
        </div>
        {badge}
      </div>
      {children}
    </div>
  );
}

function DataField({
  label,
  children,
  className,
}: {
  label: string;
  children: ReactNode;
  className?: string;
}) {
  return (
    <div className={cn("flex min-w-0 flex-col gap-1", className)}>
      <p className="text-xs font-medium text-muted-foreground">{label}</p>
      <div className="text-sm font-medium text-foreground">{children}</div>
    </div>
  );
}

function CopyableIdCard({
  label,
  value,
}: {
  label: string;
  value: string;
}) {
  return (
    <div className="group/id relative flex items-center justify-between gap-2 rounded-xl border border-border/70 bg-muted/30 px-3.5 py-2.5 transition-colors hover:border-border hover:bg-muted/50">
      <div className="min-w-0">
        <p className="text-[11px] font-medium text-muted-foreground">{label}</p>
        <p className="truncate font-mono text-sm font-semibold tracking-tight text-foreground">
          {value}
        </p>
      </div>
      <CopyButton value={value} label={`${label} скопирован`} />
    </div>
  );
}

export function EmployeeDetails({
  employee,
  objects,
  objectNamesById,
  canUpdate,
}: EmployeeDetailsProps) {
  const hireDate = employee.employmentDate
    ? formatRuDate(employee.employmentDate)
    : null;
  const tenure = formatTenure(employee.employmentDate);

  const assignedObjectNames = employee.objectIds
    .map((id) => objectNamesById.get(id))
    .filter((name): name is string => Boolean(name));

  const birthDate = employee.birthDate
    ? formatRuDate(employee.birthDate)
    : null;
  const age = formatAge(employee.birthDate);
  const birthPlace = filled(employee.birthPlace);
  const citizenship = filled(employee.citizenship);

  const clothing = filled(employee.clothingSize);
  const shoe = filled(employee.shoeSize);
  const height = filled(employee.height);
  const hasWorkwear = Boolean(clothing || shoe || height);

  const passportSeries = filled(employee.passportSeries);
  const passportNumber = filled(employee.passportNumber);
  const passport = [passportSeries, passportNumber].filter(Boolean).join(" ");
  const passportIssuedBy = filled(employee.passportIssuedBy);
  const passportDate = employee.passportIssueDate
    ? formatRuDate(employee.passportIssueDate)
    : null;
  const passportCode = filled(employee.passportDepartmentCode);
  const hasPassport = Boolean(
    passport || passportIssuedBy || passportDate || passportCode
  );

  const address = filled(employee.registrationAddress);
  const inn = filled(employee.inn);
  const snils = filled(employee.snils);
  const kig = filled(employee.kig);
  const patent = filled(employee.patentNumber);
  const hasTaxOrIds = Boolean(inn || snils || kig || patent);

  const hasPersonal = Boolean(birthDate || birthPlace || citizenship || hasWorkwear);
  const hasDocuments = Boolean(hasPassport || address || hasTaxOrIds);

  return (
    <div className="flex flex-col gap-5">
      {/* 1. Работа и назначения */}
      <SectionCard icon={BriefcaseIcon} title="Работа и назначения">
        <div className="flex flex-col gap-4">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <DataField label="Дата приёма на работу">
              {hireDate ? (
                <div className="flex flex-wrap items-center gap-2">
                  <div className="flex items-center gap-1.5">
                    <CalendarIcon className="size-3.5 text-muted-foreground" />
                    <span>{hireDate}</span>
                  </div>
                  {tenure ? (
                    <Badge variant="secondary" className="font-normal text-[11px] h-4.5 px-1.5">
                      стаж {tenure}
                    </Badge>
                  ) : null}
                </div>
              ) : (
                <span className="text-muted-foreground font-normal">—</span>
              )}
            </DataField>

            <DataField label="Учёт в табеле">
              <div className="flex items-center gap-2">
                <span
                  className={cn(
                    "size-2 rounded-full",
                    employee.includeInTimesheet ? "bg-emerald-500" : "bg-muted-foreground/40"
                  )}
                />
                <span className="font-medium">
                  {employee.includeInTimesheet
                    ? "Учитывается в табеле"
                    : "Не учитывается"}
                </span>
              </div>
            </DataField>

            <DataField label="Прикреплённые объекты" className="sm:col-span-2">
              {assignedObjectNames.length > 0 ? (
                <div className="flex flex-wrap gap-2 pt-1">
                  {assignedObjectNames.map((name) => (
                    <span
                      key={name}
                      className="inline-flex items-center gap-1.5 rounded-lg border border-border/80 bg-muted/40 px-2.5 py-1 text-xs font-medium text-foreground transition-colors hover:bg-muted/70"
                    >
                      <Building2Icon className="size-3.5 text-muted-foreground" />
                      <span>{name}</span>
                    </span>
                  ))}
                </div>
              ) : (
                <p className="text-sm font-normal text-muted-foreground">
                  Объекты не закреплены
                </p>
              )}
            </DataField>
          </div>

          {/* Финансы и ставки */}
          <div className="pt-2 border-t border-border/50">
            <div className="mb-2.5 flex items-center gap-2 text-xs font-semibold text-muted-foreground">
              <CoinsIcon className="size-3.5" />
              <span>СТАВКИ И ВЫПЛАТЫ</span>
            </div>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              <EmployeeRateSummary employee={employee} canUpdate={canUpdate} />
              <EmployeeTripSummary
                employee={employee}
                objects={objects}
                objectNamesById={objectNamesById}
                canUpdate={canUpdate}
              />
            </div>
          </div>
        </div>
      </SectionCard>

      {/* 2. Личные данные */}
      {hasPersonal ? (
        <SectionCard icon={UserIcon} title="Личные данные">
          <div className="flex flex-col gap-4">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {birthDate ? (
                <DataField label="Дата рождения">
                  <div className="flex items-center gap-1.5">
                    <CalendarDaysIcon className="size-3.5 text-muted-foreground" />
                    <span>{birthDate}</span>
                    {age ? (
                      <span className="text-xs font-normal text-muted-foreground">
                        ({age})
                      </span>
                    ) : null}
                  </div>
                </DataField>
              ) : null}

              {citizenship ? (
                <DataField label="Гражданство">
                  <div className="flex items-center gap-1.5">
                    <GlobeIcon className="size-3.5 text-muted-foreground" />
                    <span>{citizenship}</span>
                  </div>
                </DataField>
              ) : null}

              {birthPlace ? (
                <DataField
                  label="Место рождения"
                  className={cn(
                    birthPlace.length > 30 && "sm:col-span-2 lg:col-span-3"
                  )}
                >
                  <div className="flex items-start gap-1.5">
                    <MapPinIcon className="size-3.5 text-muted-foreground shrink-0 mt-0.5" />
                    <span className="leading-snug">{birthPlace}</span>
                  </div>
                </DataField>
              ) : null}
            </div>

            {/* Спецодежда и антропометрия */}
            {hasWorkwear ? (
              <div className="rounded-xl border border-border/60 bg-muted/30 p-3.5">
                <div className="mb-2.5 flex items-center gap-2 text-xs font-semibold text-muted-foreground">
                  <ShirtIcon className="size-3.5" />
                  <span>СПЕЦОДЕЖДА И РАЗМЕРЫ</span>
                </div>
                <div className="grid grid-cols-3 gap-3">
                  <div className="flex flex-col gap-0.5">
                    <span className="text-[11px] text-muted-foreground">Одежда</span>
                    <span className="text-sm font-semibold text-foreground">
                      {clothing || "—"}
                    </span>
                  </div>
                  <div className="flex flex-col gap-0.5">
                    <span className="text-[11px] text-muted-foreground">Обувь</span>
                    <span className="text-sm font-semibold text-foreground">
                      {shoe || "—"}
                    </span>
                  </div>
                  <div className="flex flex-col gap-0.5">
                    <span className="text-[11px] text-muted-foreground">Рост</span>
                    <span className="text-sm font-semibold text-foreground">
                      {height ? `${height} см` : "—"}
                    </span>
                  </div>
                </div>
              </div>
            ) : null}
          </div>
        </SectionCard>
      ) : null}

      {/* 3. Документы и реквизиты */}
      {hasDocuments ? (
        <SectionCard icon={FileTextIcon} title="Документы и реквизиты">
          <div className="flex flex-col gap-4">
            {/* Паспортные данные */}
            {hasPassport ? (
              <div className="rounded-xl border border-border/60 bg-muted/20 p-3.5">
                <div className="mb-3 flex items-center gap-2 text-xs font-semibold text-muted-foreground">
                  <ShieldCheckIcon className="size-3.5" />
                  <span>ПАСПОРТНЫЕ ДАННЫЕ</span>
                </div>
                <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
                  {passport ? (
                    <DataField label="Серия и номер">
                      <div className="flex items-center gap-1.5 font-mono">
                        <span className="font-semibold">{passport}</span>
                        <CopyButton
                          value={passport}
                          label="Паспорт скопирован"
                        />
                      </div>
                    </DataField>
                  ) : null}

                  {passportDate ? (
                    <DataField label="Дата выдачи">
                      <span>{passportDate}</span>
                    </DataField>
                  ) : null}

                  {passportCode ? (
                    <DataField label="Код подразделения">
                      <span className="font-mono">{passportCode}</span>
                    </DataField>
                  ) : null}

                  {passportIssuedBy ? (
                    <DataField
                      label="Кем выдан"
                      className="sm:col-span-3"
                    >
                      <p className="text-xs font-normal leading-relaxed text-foreground">
                        {passportIssuedBy}
                      </p>
                    </DataField>
                  ) : null}
                </div>
              </div>
            ) : null}

            {/* Адрес регистрации */}
            {address ? (
              <div className="flex items-start justify-between gap-3 rounded-xl border border-border/60 bg-muted/20 p-3.5">
                <div className="min-w-0">
                  <div className="mb-1 flex items-center gap-1.5 text-xs font-semibold text-muted-foreground">
                    <MapPinIcon className="size-3.5" />
                    <span>АДРЕС РЕГИСТРАЦИИ</span>
                  </div>
                  <p className="text-xs font-normal leading-relaxed text-foreground">
                    {address}
                  </p>
                </div>
                <CopyButton value={address} label="Адрес скопирован" />
              </div>
            ) : null}

            {/* Идентификаторы и патенты */}
            {hasTaxOrIds ? (
              <div>
                <div className="mb-2.5 flex items-center gap-2 text-xs font-semibold text-muted-foreground">
                  <CreditCardIcon className="size-3.5" />
                  <span>РЕКВИЗИТЫ И НОМЕРА</span>
                </div>
                <div className="grid grid-cols-1 gap-2.5 sm:grid-cols-2 lg:grid-cols-4">
                  {inn ? <CopyableIdCard label="ИНН" value={inn} /> : null}
                  {snils ? <CopyableIdCard label="СНИЛС" value={snils} /> : null}
                  {kig ? <CopyableIdCard label="КИГ" value={kig} /> : null}
                  {patent ? (
                    <CopyableIdCard label="Номер патента" value={patent} />
                  ) : null}
                </div>
              </div>
            ) : null}
          </div>
        </SectionCard>
      ) : null}
    </div>
  );
}

export function EmployeePhoneLink({ phone }: { phone: string }) {
  const [copied, setCopied] = useState(false);
  const display = formatPhone(phone) || phone;
  const normalized = normalizeRuPhoneE164(phone);
  const href = normalized
    ? `tel:${normalized}`
    : `tel:${phone.replace(/\D/g, "")}`;

  const copyToClipboard = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    navigator.clipboard.writeText(display);
    setCopied(true);
    toast.success("Номер скопирован");
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="inline-flex items-center gap-2 rounded-full border border-border/80 bg-background px-3 py-1 text-xs shadow-2xs transition-colors hover:border-border hover:bg-muted/40">
      <a
        href={href}
        className="flex items-center gap-1.5 font-semibold text-foreground transition-colors hover:text-primary"
      >
        <PhoneIcon className="size-3.5 text-muted-foreground" />
        <span>{display}</span>
      </a>
      <span className="text-border">|</span>
      <button
        type="button"
        onClick={copyToClipboard}
        className="rounded p-0.5 text-muted-foreground transition-colors hover:text-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
        title="Скопировать номер"
        aria-label="Скопировать номер телефона"
      >
        {copied ? (
          <CheckIcon className="size-3 text-emerald-600 dark:text-emerald-400" />
        ) : (
          <CopyIcon className="size-3" />
        )}
      </button>
    </div>
  );
}
