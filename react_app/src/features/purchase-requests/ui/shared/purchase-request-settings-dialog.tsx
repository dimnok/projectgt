"use client";

import { useMemo, useState } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Field, FieldLabel } from "@/components/ui/field";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Spinner } from "@/components/ui/spinner";
import { companyUserLabel } from "@/features/purchase-requests/api/purchase-request-settings";
import type {
  PurchaseRequestCompanyUser,
  PurchaseRequestReceiverMode,
  PurchaseRequestSettings,
} from "@/features/purchase-requests/types/purchase-request.types";
import { isPurchaseRequestSettingsConfigured } from "@/features/purchase-requests/utils/settings";
import { TimesheetMultiSelect } from "@/features/timesheet/ui/shared/timesheet-multi-select";

const RECEIVER_ITEMS = [
  { value: "initiator", label: "Инициатор заявки" },
  { value: "fixed_user", label: "Назначенные сотрудники" },
];

type SettingsDialogProps = {
  open: boolean;
  settings: PurchaseRequestSettings | null | undefined;
  users: PurchaseRequestCompanyUser[];
  companyId: string;
  isSaving: boolean;
  /** Настройки или список пользователей ещё грузятся — показываем заглушку. */
  isLoading?: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (settings: PurchaseRequestSettings) => void;
};

/**
 * Настройка маршрута согласования: кто действует на каждом этапе.
 * Доступна только владельцу компании.
 */
export function PurchaseRequestSettingsDialog({
  open,
  settings,
  users,
  companyId,
  isSaving,
  isLoading = false,
  onOpenChange,
  onSubmit,
}: SettingsDialogProps) {
  // Каждое открытие окна — новая форма: значения берём из актуальных настроек,
  // а фоновое обновление данных не затирает незаполненные правки.
  const [formKey, setFormKey] = useState(0);
  const [wasOpen, setWasOpen] = useState(open);
  if (open !== wasOpen) {
    setWasOpen(open);
    if (open) {
      setFormKey((key) => key + 1);
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[min(90vh,52rem)] overflow-y-auto sm:max-w-[880px]">
        <DialogHeader>
          <DialogTitle>Настройка согласующих</DialogTitle>
          <DialogDescription>
            На каждом этапе достаточно действия любого из выбранных. В списке
            только пользователи приложения, не карточки сотрудников.
          </DialogDescription>
        </DialogHeader>
        <SettingsRouteForm
          key={formKey}
          settings={settings}
          users={users}
          companyId={companyId}
          isSaving={isSaving}
          isLoading={isLoading}
          onSubmit={onSubmit}
          onClose={() => onOpenChange(false)}
        />
      </DialogContent>
    </Dialog>
  );
}

type SettingsRouteFormProps = {
  settings: PurchaseRequestSettings | null | undefined;
  users: PurchaseRequestCompanyUser[];
  companyId: string;
  isSaving: boolean;
  isLoading: boolean;
  onSubmit: (settings: PurchaseRequestSettings) => void;
  onClose: () => void;
};

/**
 * Форма маршрута. Собственное состояние живёт до закрытия окна: обновление
 * настроек в фоне не перезаписывает уже сделанные правки.
 */
function SettingsRouteForm({
  settings,
  users,
  companyId,
  isSaving,
  isLoading,
  onSubmit,
  onClose,
}: SettingsRouteFormProps) {
  const options = useMemo(
    () => users.map((user) => ({ key: user.id, label: companyUserLabel(user) })),
    [users]
  );
  const [firstApproverIds, setFirstApproverIds] = useState<string[]>(
    () => settings?.firstApproverIds ?? []
  );
  const [invoicePreparerIds, setInvoicePreparerIds] = useState<string[]>(
    () => settings?.invoicePreparerIds ?? []
  );
  const [invoiceApproverIds, setInvoiceApproverIds] = useState<string[]>(
    () => settings?.invoiceApproverIds ?? []
  );
  const [accountantIds, setAccountantIds] = useState<string[]>(
    () => settings?.accountantIds ?? []
  );
  const [receiverMode, setReceiverMode] = useState<PurchaseRequestReceiverMode>(
    () => settings?.receiverMode ?? "initiator"
  );
  const [fixedReceiverIds, setFixedReceiverIds] = useState<string[]>(
    () => settings?.fixedReceiverIds ?? []
  );

  function handleSubmit() {
    if (!companyId) {
      toast.error("Активная компания не выбрана");
      return;
    }
    const next: PurchaseRequestSettings = {
      companyId,
      firstApproverIds,
      invoicePreparerIds,
      invoiceApproverIds,
      accountantIds,
      receiverMode,
      fixedReceiverIds: receiverMode === "fixed_user" ? fixedReceiverIds : [],
    };
    if (!isPurchaseRequestSettingsConfigured(next)) {
      toast.error("Укажите всех участников маршрута");
      return;
    }
    onSubmit(next);
  }

  return (
    <>
      {isLoading ? (
        <div className="flex items-center justify-center py-10">
          <Spinner />
        </div>
      ) : (
        <div className="grid gap-5">
          <RouteStep
            index={1}
            title="Первый согласующий"
            hint="Проверяет заявку и может вернуть на доработку."
            options={options}
            selectedKeys={firstApproverIds}
            onChange={setFirstApproverIds}
          />
          <RouteStep
            index={2}
            title="Подготовка счетов"
            hint="Добавляет счета поставщиков и файлы."
            options={options}
            selectedKeys={invoicePreparerIds}
            onChange={setInvoicePreparerIds}
          />
          <RouteStep
            index={3}
            title="Согласование счетов"
            hint="Подтверждает счета или возвращает их на подготовку."
            options={options}
            selectedKeys={invoiceApproverIds}
            onChange={setInvoiceApproverIds}
          />
          <RouteStep
            index={4}
            title="Бухгалтер"
            hint="Ставит в очередь оплаты и отмечает оплату."
            options={options}
            selectedKeys={accountantIds}
            onChange={setAccountantIds}
          />
          <div className="grid gap-3">
            <p className="text-sm font-medium">5. Получение материала</p>
            <p className="text-sm text-muted-foreground">
              Кто подтверждает, что закупка получена.
            </p>
            <Select
              value={receiverMode}
              items={RECEIVER_ITEMS}
              onValueChange={(value) => {
                if (value === "fixed_user" || value === "initiator") {
                  setReceiverMode(value);
                }
              }}
            >
              <SelectTrigger className="w-[340px] max-w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  {RECEIVER_ITEMS.map((item) => (
                    <SelectItem key={item.value} value={item.value}>
                      {item.label}
                    </SelectItem>
                  ))}
                </SelectGroup>
              </SelectContent>
            </Select>
            {receiverMode === "fixed_user" ? (
              <Field>
                <FieldLabel>Получатели</FieldLabel>
                <TimesheetMultiSelect
                  title="Получатели"
                  options={options}
                  selectedKeys={fixedReceiverIds}
                  onChange={setFixedReceiverIds}
                />
              </Field>
            ) : null}
          </div>
        </div>
      )}
      <DialogFooter>
        <Button type="button" variant="outline" disabled={isSaving} onClick={onClose}>
          Отмена
        </Button>
        <Button
          type="button"
          disabled={isSaving || isLoading}
          onClick={handleSubmit}
        >
          {isSaving ? <Spinner data-icon="inline-start" /> : null}
          Сохранить
        </Button>
      </DialogFooter>
    </>
  );
}

type RouteStepProps = {
  index: number;
  title: string;
  hint: string;
  options: { key: string; label: string }[];
  selectedKeys: string[];
  onChange: (keys: string[]) => void;
};

function RouteStep({
  index,
  title,
  hint,
  options,
  selectedKeys,
  onChange,
}: RouteStepProps) {
  const selectedLabels = options
    .filter((option) => selectedKeys.includes(option.key))
    .map((option) => option.label);

  return (
    <div className="grid gap-2 border-b pb-4 last:border-b-0">
      <div className="flex items-start gap-3">
        <span className="flex size-7 shrink-0 items-center justify-center rounded-full bg-muted text-xs font-medium">
          {index}
        </span>
        <div className="min-w-0 flex-1">
          <p className="text-sm font-medium">{title}</p>
          <p className="text-sm text-muted-foreground">{hint}</p>
          {selectedLabels.length > 0 ? (
            <p className="mt-1 text-sm">{selectedLabels.join(", ")}</p>
          ) : null}
          <div className="mt-2">
            <TimesheetMultiSelect
              title="Участники"
              options={options}
              selectedKeys={selectedKeys}
              onChange={onChange}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
