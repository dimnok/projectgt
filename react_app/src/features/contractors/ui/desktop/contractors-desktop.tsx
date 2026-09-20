"use client";

import { useMemo, useState } from "react";
import { toast } from "sonner";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { ContractorsFilters } from "@/features/contractors/ui/desktop/contractors-filters";
import { ContractorsList } from "@/features/contractors/ui/desktop/contractors-list";
import { ContractorsSummary } from "@/features/contractors/ui/desktop/contractors-summary";
import { ContractorDeleteDialog } from "@/features/contractors/ui/shared/contractor-delete-dialog";
import { ContractorFormDialog } from "@/features/contractors/ui/shared/contractor-form-dialog";
import { useContractorFilters } from "@/features/contractors/hooks/use-contractor-filters";
import {
  useCreateContractor,
  useDeleteContractor,
  useContractors,
  useUpdateContractor,
} from "@/features/contractors/hooks/use-contractors";
import type {
  Contractor,
  ContractorDraft,
} from "@/features/contractors/types/contractor.types";
import {
  filterContractors,
  sortContractorsByName,
} from "@/features/contractors/utils/contractor.utils";
import { usePermissions } from "@/hooks/use-permissions";
import { useAppSearch, AppSearchField } from "@/layouts/desktop/app-search";

export function ContractorsDesktop() {
  const { data, isLoading, isError, error } = useContractors();
  const { type, setType } = useContractorFilters();
  const { query } = useAppSearch();
  const { can } = usePermissions();
  const createContractor = useCreateContractor();
  const updateContractor = useUpdateContractor();
  const deleteContractor = useDeleteContractor();

  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [editorContractor, setEditorContractor] = useState<
    Contractor | null | undefined
  >(undefined);
  const [contractorToDelete, setContractorToDelete] =
    useState<Contractor | null>(null);

  const contractors = useMemo(
    () =>
      sortContractorsByName(
        filterContractors(data ?? [], { search: query, type })
      ),
    [data, query, type]
  );
  const isEditorOpen = editorContractor !== undefined;

  function handleCreate(draft: ContractorDraft) {
    createContractor.mutate(draft, {
      onSuccess: (created) => {
        setExpandedId(created.id);
        setEditorContractor(undefined);
        toast.success("Контрагент создан");
      },
      onError: (error) =>
        toast.error(
          error instanceof Error ? error.message : "Не удалось создать контрагента"
        ),
    });
  }

  function handleUpdate(draft: ContractorDraft) {
    if (!editorContractor) {
      return;
    }
    updateContractor.mutate(
      { contractor: editorContractor, draft },
      {
        onSuccess: (updated) => {
          setExpandedId(updated.id);
          setEditorContractor(undefined);
          toast.success("Изменения сохранены");
        },
        onError: (error) =>
          toast.error(
            error instanceof Error
              ? error.message
              : "Не удалось сохранить контрагента"
          ),
      }
    );
  }

  function handleDelete() {
    if (!contractorToDelete) {
      return;
    }
    deleteContractor.mutate(contractorToDelete.id, {
      onSuccess: () => {
        setContractorToDelete(null);
        setExpandedId((current) =>
          current === contractorToDelete.id ? null : current
        );
        toast.success("Контрагент удалён");
      },
      onError: () => toast.error("Не удалось удалить контрагента"),
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
          {contractors.length === 0 ? (
            <EmptyState
              title="Контрагентов нет"
              description="Добавьте контрагента или измените фильтры."
            />
          ) : (
            <ContractorsList
              contractors={contractors}
              expandedId={expandedId}
              canUpdate={can("contractors", "update")}
              canDelete={can("contractors", "delete")}
              onExpandedChange={(id, open) => {
                setExpandedId(open ? id : null);
              }}
              onEdit={setEditorContractor}
              onDelete={setContractorToDelete}
            />
          )}
        </div>
        <aside className="order-first flex min-w-0 w-full flex-col gap-3 lg:sticky lg:top-0 lg:order-2 lg:gap-6 lg:self-start">
          <div className="flex min-w-0 flex-col gap-2">
            <AppSearchField
              variant="aside"
              placeholder="Поиск по названию, ИНН, телефону..."
              aria-label="Поиск по контрагентам"
            />
            <ContractorsFilters
              type={type}
              onTypeChange={setType}
              canCreate={can("contractors", "create")}
              onCreate={() => setEditorContractor(null)}
            />
          </div>
          <ContractorsSummary contractors={data ?? []} />
        </aside>
      </div>
      <ContractorFormDialog
        open={isEditorOpen}
        contractor={editorContractor}
        existingContractors={data ?? []}
        isSaving={createContractor.isPending || updateContractor.isPending}
        onOpenChange={(open) => {
          if (!open) {
            setEditorContractor(undefined);
          }
        }}
        onSubmit={editorContractor ? handleUpdate : handleCreate}
      />
      <ContractorDeleteDialog
        contractor={contractorToDelete}
        isDeleting={deleteContractor.isPending}
        onOpenChange={(open) => {
          if (!open) {
            setContractorToDelete(null);
          }
        }}
        onConfirm={handleDelete}
      />
    </>
  );
}
