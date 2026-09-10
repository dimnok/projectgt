"use client";

import { useState } from "react";
import {
  Building2Icon,
  PencilIcon,
  PlusIcon,
  StarIcon,
  Trash2Icon,
} from "lucide-react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import { ContractorBankAccountDeleteDialog } from "@/features/contractors/ui/shared/contractor-bank-account-delete-dialog";
import { ContractorBankAccountFormDialog } from "@/features/contractors/ui/shared/contractor-bank-account-form-dialog";
import {
  useContractorBankAccounts,
  useCreateContractorBankAccount,
  useDeleteContractorBankAccount,
  useUpdateContractorBankAccount,
} from "@/features/contractors/hooks/use-contractor-bank-accounts";
import type {
  ContractorBankAccount,
  ContractorBankAccountDraft,
} from "@/features/contractors/types/contractor.types";
import { usePermissions } from "@/hooks/use-permissions";

type ContractorBankAccountsProps = {
  contractorId: string;
  enabled: boolean;
};

export function ContractorBankAccounts({
  contractorId,
  enabled,
}: ContractorBankAccountsProps) {
  const { can } = usePermissions();
  const canCreate = can("contractors", "create");
  const canUpdate = can("contractors", "update");
  const canDelete = can("contractors", "delete");
  const { data, isLoading, isError, error } = useContractorBankAccounts(
    contractorId,
    enabled
  );
  const createAccount = useCreateContractorBankAccount(contractorId);
  const updateAccount = useUpdateContractorBankAccount(contractorId);
  const deleteAccount = useDeleteContractorBankAccount(contractorId);

  const [editorAccount, setEditorAccount] = useState<
    ContractorBankAccount | null | undefined
  >(undefined);
  const [accountToDelete, setAccountToDelete] =
    useState<ContractorBankAccount | null>(null);

  const accounts = data ?? [];
  const isEditorOpen = editorAccount !== undefined;
  const isSaving = createAccount.isPending || updateAccount.isPending;

  function handleCreate(draft: ContractorBankAccountDraft) {
    createAccount.mutate(draft, {
      onSuccess: () => {
        setEditorAccount(undefined);
        toast.success("Счёт добавлен");
      },
      onError: (mutationError) =>
        toast.error(
          mutationError instanceof Error
            ? mutationError.message
            : "Не удалось добавить счёт"
        ),
    });
  }

  function handleUpdate(draft: ContractorBankAccountDraft) {
    if (!editorAccount) {
      return;
    }
    updateAccount.mutate(
      { account: editorAccount, draft },
      {
        onSuccess: () => {
          setEditorAccount(undefined);
          toast.success("Счёт обновлён");
        },
        onError: (mutationError) =>
          toast.error(
            mutationError instanceof Error
              ? mutationError.message
              : "Не удалось сохранить счёт"
          ),
      }
    );
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
      onError: (mutationError) =>
        toast.error(
          mutationError instanceof Error
            ? mutationError.message
            : "Не удалось удалить счёт"
        ),
    });
  }

  return (
    <div className="flex flex-col gap-3 rounded-xl border bg-muted/20 p-3.5 sm:p-4">
      <div className="flex items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <Building2Icon className="size-4 text-muted-foreground" />
          <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            Банковские счета
          </p>
          {accounts.length > 0 ? (
            <Badge variant="outline" className="h-4 px-1.5 py-0 text-[10px] font-mono">
              {accounts.length}
            </Badge>
          ) : null}
        </div>
        {canCreate ? (
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={() => setEditorAccount(null)}
          >
            <PlusIcon data-icon="inline-start" />
            Добавить счёт
          </Button>
        ) : null}
      </div>

      {isLoading ? (
        <div className="flex items-center gap-2 py-3 text-sm text-muted-foreground">
          <Spinner />
          Загрузка счетов...
        </div>
      ) : isError ? (
        <p className="py-2 text-sm text-destructive">
          {error instanceof Error ? error.message : "Не удалось загрузить счета"}
        </p>
      ) : accounts.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-lg border border-dashed py-4 text-center">
          <p className="text-xs text-muted-foreground">Счета не добавлены</p>
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          {accounts.map((account) => (
            <BankAccountRow
              key={account.id}
              account={account}
              canUpdate={canUpdate}
              canDelete={canDelete}
              onEdit={() => setEditorAccount(account)}
              onDelete={() => setAccountToDelete(account)}
            />
          ))}
        </div>
      )}

      <ContractorBankAccountFormDialog
        open={isEditorOpen}
        account={editorAccount}
        isSaving={isSaving}
        onOpenChange={(open) => {
          if (!open) {
            setEditorAccount(undefined);
          }
        }}
        onSubmit={editorAccount ? handleUpdate : handleCreate}
      />
      <ContractorBankAccountDeleteDialog
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

function BankAccountRow({
  account,
  canUpdate,
  canDelete,
  onEdit,
  onDelete,
}: {
  account: ContractorBankAccount;
  canUpdate: boolean;
  canDelete: boolean;
  onEdit: () => void;
  onDelete: () => void;
}) {
  return (
    <div className="flex flex-col gap-2 rounded-lg border bg-background p-3 shadow-2xs transition-colors hover:border-border">
      <div className="flex items-start justify-between gap-3">
        <div className="flex min-w-0 flex-1 flex-col gap-0.5">
          <div className="flex min-w-0 flex-wrap items-center gap-2">
            <p className="truncate text-sm font-medium">{account.bankName}</p>
            {account.isPrimary ? (
              <Badge variant="secondary" className="gap-1 text-[11px]">
                <StarIcon className="size-3 fill-amber-500 text-amber-500" />
                По умолчанию
              </Badge>
            ) : null}
          </div>
          {account.bankCity ? (
            <p className="text-xs text-muted-foreground">{account.bankCity}</p>
          ) : null}
        </div>

        {canUpdate || canDelete ? (
          <div className="flex shrink-0 items-center gap-0.5">
            {canUpdate ? (
              <Button
                type="button"
                variant="ghost"
                size="icon-xs"
                aria-label="Изменить счёт"
                onClick={onEdit}
              >
                <PencilIcon />
              </Button>
            ) : null}
            {canDelete ? (
              <Button
                type="button"
                variant="ghost"
                size="icon-xs"
                aria-label="Удалить счёт"
                onClick={onDelete}
              >
                <Trash2Icon />
              </Button>
            ) : null}
          </div>
        ) : null}
      </div>

      <div className="flex flex-wrap items-baseline gap-x-5 gap-y-1 pt-0.5 text-xs">
        {account.bik ? (
          <div className="flex flex-wrap items-baseline gap-1.5">
            <span className="text-muted-foreground">БИК:</span>
            <span className="font-mono text-xs font-medium tracking-wide text-foreground select-all">
              {account.bik}
            </span>
          </div>
        ) : null}
        <div className="flex flex-wrap items-baseline gap-1.5">
          <span className="text-muted-foreground">Р/С:</span>
          <span className="font-mono text-xs font-medium tracking-wide text-foreground select-all">
            {account.accountNumber}
          </span>
        </div>
        {account.corrAccount ? (
          <div className="flex flex-wrap items-baseline gap-1.5">
            <span className="text-muted-foreground">К/С:</span>
            <span className="font-mono text-xs text-muted-foreground select-all">
              {account.corrAccount}
            </span>
          </div>
        ) : null}
      </div>
    </div>
  );
}
