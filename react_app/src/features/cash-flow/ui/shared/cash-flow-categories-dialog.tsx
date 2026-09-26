"use client";

import { useState, type FormEvent } from "react";
import { PencilIcon, PlusIcon, TrashIcon } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
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
import {
  useDeleteCashFlowCategory,
  useSaveCashFlowCategory,
} from "@/features/cash-flow/hooks/use-cash-flow";
import type {
  CashFlowCategory,
  CashFlowType,
} from "@/features/cash-flow/types/cash-flow.types";
import { CashFlowConfirmDialog } from "@/features/cash-flow/ui/shared/cash-flow-confirm-dialog";
import { CASH_FLOW_TYPE_OPTIONS } from "@/features/cash-flow/utils/operation-type";

type CashFlowCategoriesDialogProps = {
  open: boolean;
  categories: CashFlowCategory[];
  canCreate: boolean;
  canUpdate: boolean;
  canDelete: boolean;
  onOpenChange: (open: boolean) => void;
};

/**
 * Справочник статей ДДС: добавление, переименование и удаление.
 *
 * Статью, на которую ссылаются операции, база удалить не даёт — окно
 * показывает это понятным текстом.
 */
export function CashFlowCategoriesDialog({
  open,
  categories,
  canCreate,
  canUpdate,
  canDelete,
  onOpenChange,
}: CashFlowCategoriesDialogProps) {
  const saveCategory = useSaveCashFlowCategory();
  const deleteCategory = useDeleteCashFlowCategory();
  const [name, setName] = useState("");
  const [type, setType] = useState<CashFlowType>("expense");
  const [editingId, setEditingId] = useState<string | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<CashFlowCategory | null>(
    null
  );

  const isEditing = editingId !== null;
  const canSubmit = isEditing ? canUpdate : canCreate;
  const isBusy = saveCategory.isPending || deleteCategory.isPending;

  function resetForm() {
    setName("");
    setType("expense");
    setEditingId(null);
  }

  function startEditing(category: CashFlowCategory) {
    setEditingId(category.id);
    setName(category.name);
    setType(category.type);
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const trimmed = name.trim();
    if (!trimmed) {
      toast.error("Укажите название статьи");
      return;
    }

    saveCategory.mutate(
      { draft: { name: trimmed, type }, categoryId: editingId ?? undefined },
      {
        onSuccess: () => {
          toast.success(isEditing ? "Статья изменена" : "Статья добавлена");
          resetForm();
        },
        onError: (error) =>
          toast.error(
            error instanceof Error ? error.message : "Не удалось сохранить статью"
          ),
      }
    );
  }

  function handleDelete() {
    if (!deleteTarget) {
      return;
    }
    deleteCategory.mutate(deleteTarget.id, {
      onSuccess: () => {
        toast.success("Статья удалена");
        if (editingId === deleteTarget.id) {
          resetForm();
        }
        setDeleteTarget(null);
      },
      onError: (error) => {
        toast.error(
          error instanceof Error ? error.message : "Не удалось удалить статью"
        );
        setDeleteTarget(null);
      },
    });
  }

  const sections: { type: CashFlowType; label: string }[] = [
    { type: "income", label: "Приход" },
    { type: "expense", label: "Расход" },
  ];

  return (
    <>
      <Dialog
        open={open}
        onOpenChange={(next) => {
          if (!next) {
            resetForm();
          }
          onOpenChange(next);
        }}
      >
        <DialogContent className="max-h-[min(92vh,48rem)] overflow-y-auto sm:max-w-xl">
          <DialogHeader>
            <DialogTitle>Статьи ДДС</DialogTitle>
            <DialogDescription>
              Статьи классифицируют операции: по ним строится аналитика и
              расшифровка по месяцам.
            </DialogDescription>
          </DialogHeader>

          {canSubmit ? (
            <form
              className="flex items-end gap-2"
              onSubmit={handleSubmit}
            >
              <div className="flex min-w-0 flex-1 flex-col gap-1.5">
                <label
                  htmlFor="cash-flow-category-name"
                  className="text-xs font-medium text-muted-foreground"
                >
                  Название статьи
                </label>
                <Input
                  id="cash-flow-category-name"
                  value={name}
                  disabled={isBusy}
                  placeholder="Например: аренда"
                  onChange={(event) => setName(event.target.value)}
                />
              </div>
              <Select
                value={type}
                items={CASH_FLOW_TYPE_OPTIONS.map((option) => ({
                  value: option.value,
                  label: option.label,
                }))}
                disabled={isBusy}
                onValueChange={(value) => setType(value as CashFlowType)}
              >
                <SelectTrigger
                  aria-label="Тип статьи"
                  className="w-32 shrink-0"
                >
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectGroup>
                    {CASH_FLOW_TYPE_OPTIONS.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        {option.label}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
              <Button type="submit" disabled={isBusy} className="shrink-0">
                {saveCategory.isPending ? (
                  <Spinner data-icon="inline-start" />
                ) : (
                  <PlusIcon />
                )}
                {isEditing ? "Сохранить" : "Добавить"}
              </Button>
              {isEditing ? (
                <Button
                  type="button"
                  variant="outline"
                  disabled={isBusy}
                  className="shrink-0"
                  onClick={resetForm}
                >
                  Отмена
                </Button>
              ) : null}
            </form>
          ) : null}

          <div className="flex flex-col gap-4">
            {sections.map((section) => {
              const items = categories.filter(
                (category) => category.type === section.type
              );

              return (
                <div key={section.type} className="flex flex-col gap-1">
                  <div
                    className={`border-b-2 pb-1 text-xs font-bold tracking-wide uppercase ${
                      section.type === "income"
                        ? "border-success/30 text-success"
                        : "border-destructive/30 text-destructive"
                    }`}
                  >
                    {section.label}
                  </div>
                  {items.length === 0 ? (
                    <p className="px-1 py-2 text-sm text-muted-foreground">
                      Статей нет
                    </p>
                  ) : (
                    <ul className="flex flex-col">
                      {items.map((category) => (
                        <li
                          key={category.id}
                          className="flex items-center gap-2 border-b border-border/50 py-1.5 last:border-b-0"
                        >
                          <span
                            className={`min-w-0 flex-1 truncate text-sm ${
                              editingId === category.id ? "font-semibold" : ""
                            }`}
                          >
                            {category.name}
                          </span>
                          {canUpdate ? (
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon-sm"
                              aria-label={`Переименовать статью «${category.name}»`}
                              title="Переименовать"
                              disabled={isBusy}
                              onClick={() => startEditing(category)}
                            >
                              <PencilIcon className="size-3.5" />
                            </Button>
                          ) : null}
                          {canDelete ? (
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon-sm"
                              aria-label={`Удалить статью «${category.name}»`}
                              title="Удалить"
                              disabled={isBusy}
                              onClick={() => setDeleteTarget(category)}
                            >
                              <TrashIcon className="size-3.5 text-destructive" />
                            </Button>
                          ) : null}
                        </li>
                      ))}
                    </ul>
                  )}
                </div>
              );
            })}
          </div>
        </DialogContent>
      </Dialog>

      <CashFlowConfirmDialog
        open={deleteTarget !== null}
        title="Удаление статьи"
        description={`Статья «${deleteTarget?.name ?? ""}» перестанет предлагаться в операциях.`}
        isPending={deleteCategory.isPending}
        onOpenChange={(next) => {
          if (!next) {
            setDeleteTarget(null);
          }
        }}
        onConfirm={handleDelete}
      />
    </>
  );
}
