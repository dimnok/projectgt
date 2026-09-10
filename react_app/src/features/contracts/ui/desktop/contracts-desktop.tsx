"use client";

import { useMemo, useState } from "react";
import { toast } from "sonner";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { ContractsFilters } from "@/features/contracts/ui/desktop/contracts-filters";
import { ContractsList } from "@/features/contracts/ui/desktop/contracts-list";
import { ContractsSummary } from "@/features/contracts/ui/desktop/contracts-summary";
import { ContractDeleteDialog } from "@/features/contracts/ui/shared/contract-delete-dialog";
import { ContractDetailsDialog } from "@/features/contracts/ui/shared/contract-details-dialog";
import { ContractFormDialog } from "@/features/contracts/ui/shared/contract-form-dialog";
import { useContractFilters } from "@/features/contracts/hooks/use-contract-filters";
import {
  useCreateContract,
  useDeleteContract,
  useContracts,
  useUpdateContract,
} from "@/features/contracts/hooks/use-contracts";
import type {
  Contract,
  ContractDraft,
  ContractPickItem,
} from "@/features/contracts/types/contract.types";
import {
  filterContracts,
  sortContractsByDate,
} from "@/features/contracts/utils/contract.utils";
import { useContractors } from "@/features/contractors/hooks/use-contractors";
import { useObjects } from "@/features/objects/hooks/use-objects";
import { sortContractorsByName } from "@/features/contractors/utils/contractor.utils";
import { sortObjectsByName } from "@/features/objects/utils/object.utils";
import { usePermissions } from "@/hooks/use-permissions";
import { useAppSearch, AppSearchField } from "@/layouts/desktop/app-search";

export function ContractsDesktop() {
  const { data, isLoading, isError, error } = useContracts();
  const { data: contractorsData } = useContractors();
  const { data: objectsData } = useObjects();
  const { kind, setKind, status, setStatus } = useContractFilters();
  const { query } = useAppSearch();
  const { can } = usePermissions();
  const createContract = useCreateContract();
  const updateContract = useUpdateContract();
  const deleteContract = useDeleteContract();

  const [selectedContract, setSelectedContract] = useState<Contract | null>(
    null
  );
  const [editorContract, setEditorContract] = useState<
    Contract | null | undefined
  >(undefined);
  const [contractToDelete, setContractToDelete] = useState<Contract | null>(
    null
  );

  const contracts = useMemo(
    () =>
      sortContractsByDate(
        filterContracts(data ?? [], { search: query, kind, status })
      ),
    [data, query, kind, status]
  );
  const contractorItems = useMemo<ContractPickItem[]>(
    () =>
      sortContractorsByName(contractorsData ?? []).map((contractor) => ({
        id: contractor.id,
        label: contractor.fullName || contractor.shortName,
      })),
    [contractorsData]
  );
  const objectItems = useMemo<ContractPickItem[]>(
    () =>
      sortObjectsByName(objectsData ?? []).map((object) => ({
        id: object.id,
        label: object.name,
      })),
    [objectsData]
  );
  const isEditorOpen = editorContract !== undefined;

  function handleCreate(draft: ContractDraft) {
    createContract.mutate(draft, {
      onSuccess: (created) => {
        setEditorContract(undefined);
        setSelectedContract(created);
        toast.success("Договор создан");
      },
      onError: (error) =>
        toast.error(
          error instanceof Error ? error.message : "Не удалось создать договор"
        ),
    });
  }

  function handleUpdate(draft: ContractDraft) {
    if (!editorContract) {
      return;
    }
    updateContract.mutate(
      { contract: editorContract, draft },
      {
        onSuccess: (updated) => {
          setEditorContract(undefined);
          setSelectedContract(updated);
          toast.success("Изменения сохранены");
        },
        onError: (error) =>
          toast.error(
            error instanceof Error
              ? error.message
              : "Не удалось сохранить договор"
          ),
      }
    );
  }

  function handleDelete() {
    if (!contractToDelete) {
      return;
    }
    deleteContract.mutate(contractToDelete.id, {
      onSuccess: () => {
        setContractToDelete(null);
        setSelectedContract(null);
        toast.success("Договор удалён");
      },
      onError: (error) =>
        toast.error(
          error instanceof Error ? error.message : "Не удалось удалить договор"
        ),
    });
  }

  if (isLoading) {
    return <Loading />;
  }

  if (isError) {
    return (
      <ErrorState
        message={error instanceof Error ? error.message : "Неизвестная ошибка"}
      />
    );
  }

  return (
    <>
      <div className="grid min-h-fit min-w-0 w-full flex-1 grid-cols-1 content-start items-start gap-3 lg:grid-cols-[minmax(0,1fr)_var(--content-aside-width)] lg:gap-6">
        <div className="min-w-0 w-full lg:order-1">
          {contracts.length === 0 ? (
            <EmptyState
              title="Договоров нет"
              description="Добавьте договор или измените фильтры."
            />
          ) : (
            <ContractsList
              contracts={contracts}
              selectedId={selectedContract?.id ?? null}
              onSelect={setSelectedContract}
            />
          )}
        </div>
        <aside className="order-first flex min-w-0 w-full flex-col gap-3 lg:sticky lg:top-0 lg:order-2 lg:gap-6 lg:self-start">
          <ContractsFilters
            kind={kind}
            status={status}
            onKindChange={setKind}
            onStatusChange={setStatus}
            canCreate={can("contracts", "create")}
            onCreate={() => {
              setSelectedContract(null);
              setEditorContract(null);
            }}
          />
          <ContractsSummary contracts={data ?? []} />
          <AppSearchField className="lg:hidden" />
        </aside>
      </div>
      <ContractDetailsDialog
        contract={selectedContract}
        canUpdate={can("contracts", "update")}
        canDelete={can("contracts", "delete")}
        onOpenChange={(open) => {
          if (!open) {
            setSelectedContract(null);
          }
        }}
        onEdit={() => {
          if (selectedContract) {
            setEditorContract(selectedContract);
            setSelectedContract(null);
          }
        }}
        onDelete={() => {
          if (selectedContract) {
            setContractToDelete(selectedContract);
          }
        }}
      />
      <ContractFormDialog
        open={isEditorOpen}
        contract={editorContract}
        contractors={contractorItems}
        objects={objectItems}
        isSaving={createContract.isPending || updateContract.isPending}
        onOpenChange={(open) => {
          if (!open) {
            setEditorContract(undefined);
          }
        }}
        onSubmit={editorContract ? handleUpdate : handleCreate}
      />
      <ContractDeleteDialog
        contract={contractToDelete}
        isDeleting={deleteContract.isPending}
        onOpenChange={(open) => {
          if (!open) {
            setContractToDelete(null);
          }
        }}
        onConfirm={handleDelete}
      />
    </>
  );
}
