"use client";

import { useMemo, useState } from "react";
import { PlusIcon } from "lucide-react";
import { toast } from "sonner";

import { EmptyState } from "@/components/shared/empty-state";
import { Button } from "@/components/ui/button";
import { useContractors } from "@/features/contractors/hooks/use-contractors";
import { useContracts } from "@/features/contracts/hooks/use-contracts";
import { useObjects } from "@/features/objects/hooks/use-objects";
import { sortContractorsByName } from "@/features/contractors/utils/contractor.utils";
import { sortObjectsByName } from "@/features/objects/utils/object.utils";
import {
  useCreateSettlement,
  useSettlements,
  useUpdateSettlement,
} from "@/features/settlements/hooks/use-settlements";
import type {
  Settlement,
  SettlementDraft,
  SettlementPickItem,
} from "@/features/settlements/types/settlement.types";
import { SettlementsList } from "@/features/settlements/ui/desktop/settlements-list";
import { SettlementDetailsDialog } from "@/features/settlements/ui/shared/settlement-details-dialog";
import { SettlementFormDialog } from "@/features/settlements/ui/shared/settlement-form-dialog";
import { SettlementsTableSkeleton } from "@/features/settlements/ui/shared/settlement-skeletons";
import { formatCurrency, sumSettlements } from "@/features/settlements/utils/settlement.utils";
import type { Contract } from "@/features/contracts/types/contract.types";
import { usePermissions } from "@/hooks/use-permissions";
import { cn } from "@/lib/utils";

/**
 * Вкладка «Финансы» в карточке договора: счета взаиморасчётов по договору.
 *
 * Логика и права общие с разделом «Взаиморасчёты»: те же хуки и окна.
 */
export function ContractSettlementsTab({ contract }: { contract: Contract }) {
  const { can } = usePermissions();
  const listQuery = useSettlements(contract.id);
  const { data: contractorsData } = useContractors();
  const { data: objectsData } = useObjects();
  const { data: contractsData } = useContracts();
  const createSettlement = useCreateSettlement();
  const updateSettlement = useUpdateSettlement();

  const [selected, setSelected] = useState<Settlement | null>(null);
  const [editor, setEditor] = useState<Settlement | null | undefined>(
    undefined
  );

  const settlements = useMemo(() => listQuery.data ?? [], [listQuery.data]);
  const totals = useMemo(() => sumSettlements(settlements), [settlements]);

  const contractorItems = useMemo<SettlementPickItem[]>(
    () =>
      sortContractorsByName(contractorsData ?? []).map((contractor) => ({
        id: contractor.id,
        label: contractor.shortName || contractor.fullName,
      })),
    [contractorsData]
  );
  const objectItems = useMemo<SettlementPickItem[]>(
    () =>
      sortObjectsByName(objectsData ?? []).map((object) => ({
        id: object.id,
        label: object.name,
      })),
    [objectsData]
  );

  const canCreate = can("settlements", "create");
  const isEditorOpen = editor !== undefined;

  function handleCreate(draft: SettlementDraft) {
    createSettlement.mutate(draft, {
      onSuccess: (created) => {
        setEditor(undefined);
        setSelected(created);
        toast.success("Счёт создан");
      },
      onError: (error) =>
        toast.error(
          error instanceof Error ? error.message : "Не удалось создать счёт"
        ),
    });
  }

  function handleUpdate(draft: SettlementDraft) {
    if (!editor) return;
    updateSettlement.mutate(
      { settlement: editor, draft },
      {
        onSuccess: (updated) => {
          setEditor(undefined);
          setSelected(updated);
          toast.success("Изменения сохранены");
        },
        onError: (error) =>
          toast.error(
            error instanceof Error ? error.message : "Не удалось сохранить счёт"
          ),
      }
    );
  }

  return (
    <div className="flex h-full min-h-0 flex-col">
      <div className="flex flex-wrap items-center gap-x-6 gap-y-2 border-b border-border/70 px-5 py-3">
        <Stat label="К оплате" value={formatCurrency(totals.totalAmount)} />
        <Stat label="Оплачено" value={formatCurrency(totals.totalPaid)} />
        <Stat
          label="Долг"
          value={formatCurrency(totals.totalDebt)}
          emphasize={totals.totalDebt > 0}
        />
        {canCreate ? (
          <Button
            type="button"
            size="sm"
            className="ml-auto gap-1.5"
            onClick={() => {
              setSelected(null);
              setEditor(null);
            }}
          >
            <PlusIcon className="size-3.5 shrink-0" />
            <span>Новый счёт</span>
          </Button>
        ) : null}
      </div>

      <div className="min-h-0 min-w-0 flex-1 overflow-hidden">
        {listQuery.isLoading ? (
          <SettlementsTableSkeleton />
        ) : settlements.length === 0 ? (
          <div className="flex h-full items-center justify-center p-6">
            <EmptyState
              title="Счетов нет"
              description="По этому договору пока нет счетов. Создайте первый."
            />
          </div>
        ) : (
          <SettlementsList
            settlements={settlements}
            selectedId={selected?.id ?? null}
            onSelect={setSelected}
          />
        )}
      </div>

      <SettlementDetailsDialog
        settlement={selected}
        canUpdate={can("settlements", "update")}
        canDelete={can("settlements", "delete")}
        onOpenChange={(open) => {
          if (!open) setSelected(null);
        }}
        onEdit={(settlement) => {
          setEditor(settlement);
          setSelected(null);
        }}
        onDeleted={() => setSelected(null)}
      />

      <SettlementFormDialog
        open={isEditorOpen}
        settlement={editor}
        presetContract={contract}
        contractors={contractorItems}
        objects={objectItems}
        contracts={contractsData ?? []}
        isSaving={createSettlement.isPending || updateSettlement.isPending}
        onOpenChange={(open) => {
          if (!open) setEditor(undefined);
        }}
        onSubmit={editor ? handleUpdate : handleCreate}
      />
    </div>
  );
}

/** Показатель вкладки: подпись сверху, сумма снизу. */
function Stat({
  label,
  value,
  emphasize = false,
}: {
  label: string;
  value: string;
  emphasize?: boolean;
}) {
  return (
    <div className="flex flex-col">
      <span className="text-muted-foreground text-xs">{label}</span>
      <span
        className={cn(
          "font-heading text-base font-semibold tabular-nums",
          emphasize && "text-destructive"
        )}
      >
        {value}
      </span>
    </div>
  );
}
