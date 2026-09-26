"use client";

import { LandmarkIcon, PencilIcon, PlusIcon, StarIcon, Trash2Icon } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { CompanyBankAccountDeleteDialog } from "@/features/company/ui/shared/company-bank-account-delete-dialog";
import { CompanyBankAccountFormDialog } from "@/features/company/ui/shared/company-bank-account-form-dialog";
import { CompanyBankAccountSheet } from "@/features/company/ui/mobile/company-bank-account-sheet";
import { CompanyListIconButton } from "@/features/company/ui/shared/company-list-icon-button";
import { CompanyListSkeleton } from "@/features/company/ui/shared/company-skeletons";
import {
  useCompanyBankAccounts,
  useCreateCompanyBankAccount,
  useDeleteCompanyBankAccount,
  useUpdateCompanyBankAccount,
} from "@/features/company/hooks/use-company-bank-accounts";
import type { CompanyBankAccount, CompanyBankAccountDraft } from "@/features/company/types/company.types";
import { useIsMobile } from "@/hooks/use-mobile";

type CompanyBankAccountsProps = {
  canEdit: boolean;
};

/** Банковские счета компании: список и операции. */
export function CompanyBankAccounts({ canEdit }: CompanyBankAccountsProps) {
  const isMobile = useIsMobile();
  const { data, isLoading, isError, error } = useCompanyBankAccounts();
  const createAccount = useCreateCompanyBankAccount();
  const updateAccount = useUpdateCompanyBankAccount();
  const deleteAccount = useDeleteCompanyBankAccount();

  const [editorAccount, setEditorAccount] = useState<
    CompanyBankAccount | null | undefined
  >(undefined);
  const [accountToDelete, setAccountToDelete] =
    useState<CompanyBankAccount | null>(null);

  const accounts = data ?? [];
  const isEditorOpen = editorAccount !== undefined;
  const isSaving = createAccount.isPending || updateAccount.isPending;

  function handleSubmit(draft: CompanyBankAccountDraft) {
    if (editorAccount) {
      updateAccount.mutate(
        { id: editorAccount.id, draft },
        {
          onSuccess: () => {
            setEditorAccount(undefined);
            toast.success("Счёт обновлён");
          },
          onError: (err) =>
            toast.error(
              err instanceof Error ? err.message : "Не удалось сохранить счёт"
            ),
        }
      );
      return;
    }

    createAccount.mutate(draft, {
      onSuccess: () => {
        setEditorAccount(undefined);
        toast.success("Счёт добавлен");
      },
      onError: (err) =>
        toast.error(
          err instanceof Error ? err.message : "Не удалось добавить счёт"
        ),
    });
  }

  function handleDelete() {
    if (!accountToDelete) {
      return;
    }
    deleteAccount.mutate(accountToDelete.id, {
      onSuccess: () => {
        setAccountToDelete(null);
        toast.success("Счёт удалён");
      },
      onError: (err) =>
        toast.error(
          err instanceof Error ? err.message : "Не удалось удалить счёт"
        ),
    });
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-3">
        <div>
          <p className="text-sm font-medium">Банковские счета</p>
          <p className="text-xs text-muted-foreground">
            {accounts.length > 0
              ? `${accounts.length} счёт(а)`
              : "Счета не добавлены"}
          </p>
        </div>
        {canEdit ? (
          <Button type="button" size="sm" onClick={() => setEditorAccount(null)}>
            <PlusIcon data-icon="inline-start" />
            Добавить счёт
          </Button>
        ) : null}
      </div>

      {isLoading ? (
        <CompanyListSkeleton />
      ) : isError ? (
        <p className="text-sm text-destructive">
          {error instanceof Error ? error.message : "Не удалось загрузить счета"}
        </p>
      ) : accounts.length === 0 ? (
        <div className="rounded-lg border border-dashed p-4 text-sm text-muted-foreground">
          Банковские счета не добавлены.
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          {accounts.map((account) => (
            <div
              key={account.id}
              className="flex items-center justify-between gap-3 rounded-lg border bg-card p-3"
            >
              <div className="flex min-w-0 items-center gap-3">
                <div className="flex size-9 shrink-0 items-center justify-center rounded-md bg-primary/10 text-primary">
                  <LandmarkIcon className="size-4" />
                </div>
                <div className="min-w-0">
                  <p className="flex items-center gap-2 truncate text-sm font-medium">
                    {account.bankName}
                    {account.isPrimary ? (
                      <Badge variant="secondary" className="gap-1">
                        <StarIcon className="size-3" />
                        Основной
                      </Badge>
                    ) : null}
                  </p>
                  <p className="truncate text-xs text-muted-foreground">
                    Р/с {account.accountNumber || "—"}
                    {account.bik ? ` · БИК ${account.bik}` : ""}
                  </p>
                </div>
              </div>
              {canEdit ? (
                <div className="flex shrink-0 items-center gap-1">
                  <CompanyListIconButton
                    icon={PencilIcon}
                    label="Изменить счёт"
                    onClick={() => setEditorAccount(account)}
                  />
                  <CompanyListIconButton
                    icon={Trash2Icon}
                    label="Удалить счёт"
                    onClick={() => setAccountToDelete(account)}
                  />
                </div>
              ) : null}
            </div>
          ))}
        </div>
      )}

      {isMobile ? (
        <CompanyBankAccountSheet
          open={isEditorOpen}
          account={editorAccount ?? null}
          isSaving={isSaving}
          onOpenChange={(open) => {
            if (!open) {
              setEditorAccount(undefined);
            }
          }}
          onSubmit={handleSubmit}
        />
      ) : (
        <CompanyBankAccountFormDialog
          open={isEditorOpen}
          account={editorAccount ?? null}
          isSaving={isSaving}
          onOpenChange={(open) => {
            if (!open) {
              setEditorAccount(undefined);
            }
          }}
          onSubmit={handleSubmit}
        />
      )}

      <CompanyBankAccountDeleteDialog
        account={accountToDelete}
        isDeleting={deleteAccount.isPending}
        onOpenChange={(open) => {
          if (!open) {
            setAccountToDelete(null);
          }
        }}
        onConfirm={handleDelete}
      />
    </div>
  );
}
