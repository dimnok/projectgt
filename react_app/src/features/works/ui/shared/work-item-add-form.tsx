"use client";

import { useMemo, useState } from "react";
import { ChevronDownIcon } from "lucide-react";
import { toast } from "sonner";

import {
  MobileSheetBody,
  MobileSheetChrome,
} from "@/components/shared/mobile-sheet-chrome";
import { Button } from "@/components/ui/button";
import {
  Collapsible,
  CollapsibleContent,
} from "@/components/ui/collapsible";
import { DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Field, FieldDescription, FieldLabel } from "@/components/ui/field";
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
import { useContractors } from "@/features/contractors/hooks/use-contractors";
import type { AddWorkItemDraft } from "@/features/works/api/add-work-items";
import type { WorkEstimateOption } from "@/features/works/api/get-work-item-catalog";
import {
  useAddWorkItems,
  useUpdateWorkItem,
  useWorkItemCatalog,
} from "@/features/works/hooks/use-work-item-mutations";
import { WorkItemNewMaterialForm } from "@/features/works/ui/shared/work-item-new-material-form";
import type { WorkItem } from "@/features/works/types/work.types";
import {
  formatCurrency,
  parseWorkQuantity,
  uniqueWorkItemFloors,
  uniqueWorkItemSections,
} from "@/features/works/utils/work.utils";

type FilterOption = { value: string; label: string };

type WorkItemAddFormProps = {
  layout: "dialog" | "sheet";
  workId: string;
  objectId: string;
  existingItems: WorkItem[];
  initial: WorkItem | null;
  onCancel: () => void;
};

export function WorkItemAddForm({
  layout,
  workId,
  objectId,
  existingItems,
  initial,
  onCancel,
}: WorkItemAddFormProps) {
  const isEdit = Boolean(initial);
  const catalog = useWorkItemCatalog(objectId, true);
  const contractorsQuery = useContractors();
  const addMutation = useAddWorkItems(workId);
  const updateMutation = useUpdateWorkItem(workId);

  const [section, setSection] = useState<string | null>(
    initial?.section.trim() || null
  );
  const [floor, setFloor] = useState<string | null>(
    initial?.floor.trim() || null
  );
  const [system, setSystem] = useState<string | null>(
    initial?.system.trim() || null
  );
  const [subsystem, setSubsystem] = useState<string | null>(
    initial?.subsystem.trim() || null
  );
  const [contractorId, setContractorId] = useState<string | null>(
    initial?.contractorId ?? null
  );
  const [search, setSearch] = useState("");
  const [materialOpen, setMaterialOpen] = useState(false);
  const [extraEstimates, setExtraEstimates] = useState<WorkEstimateOption[]>([]);
  const [selected, setSelected] = useState<Record<string, string>>(() =>
    initial
      ? { [initial.estimateId]: String(initial.quantity).replace(".", ",") }
      : {}
  );

  const estimates = useMemo(() => {
    const catalogEstimates = catalog.estimatesQuery.data ?? [];
    const merged = [
      ...extraEstimates.filter(
        (item) => !catalogEstimates.some((row) => row.id === item.id)
      ),
      ...catalogEstimates,
    ];
    if (!initial) {
      return merged;
    }
    if (merged.some((item) => item.id === initial.estimateId)) {
      return merged;
    }
    const extra: WorkEstimateOption = {
      id: initial.estimateId,
      system: initial.system,
      subsystem: initial.subsystem,
      number: initial.number,
      name: initial.name,
      unit: initial.unit,
      price: initial.price,
    };
    return [extra, ...merged];
  }, [catalog.estimatesQuery.data, extraEstimates, initial]);
  const sectionOptions = useMemo(() => {
    return uniqueSorted([
      ...(catalog.sectionsQuery.data ?? []),
      ...uniqueWorkItemSections(existingItems, null),
      initial?.section ?? "",
    ]);
  }, [catalog.sectionsQuery.data, existingItems, initial]);
  const floorOptions = useMemo(() => {
    return uniqueSorted([
      ...(catalog.floorsQuery.data ?? []),
      ...uniqueWorkItemFloors(existingItems, null, null),
      initial?.floor ?? "",
    ]);
  }, [catalog.floorsQuery.data, existingItems, initial]);

  const systems = useMemo(
    () => uniqueSorted([...estimates.map((item) => item.system), initial?.system ?? ""]),
    [estimates, initial]
  );
  const subsystems = useMemo(
    () =>
      uniqueSorted([
        ...estimates
          .filter((item) => !system || item.system === system)
          .map((item) => item.subsystem),
        system && initial?.system === system ? (initial.subsystem ?? "") : "",
      ]),
    [estimates, system, initial]
  );

  const occupiedIds = useMemo(() => {
    if (!section || !floor || !system || !subsystem) {
      return new Set<string>();
    }
    return new Set(
      existingItems
        .filter(
          (item) =>
            item.id !== initial?.id &&
            item.section === section &&
            item.floor === floor &&
            item.system === system &&
            item.subsystem === subsystem &&
            item.contractorId === contractorId
        )
        .map((item) => item.estimateId)
    );
  }, [existingItems, section, floor, system, subsystem, contractorId, initial?.id]);

  const visibleEstimates = useMemo(() => {
    if (!section || !floor || !system || !subsystem) {
      return [] as WorkEstimateOption[];
    }
    const query = search.trim().toLowerCase();
    return estimates.filter((item) => {
      if (item.system !== system || item.subsystem !== subsystem) {
        return false;
      }
      if (occupiedIds.has(item.id)) {
        return false;
      }
      if (!query) {
        return true;
      }
      return [item.name, item.number, item.unit]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(query));
    });
  }, [estimates, section, floor, system, subsystem, occupiedIds, search]);

  const selectedCount = Object.keys(selected).length;
  const isSaving = addMutation.isPending || updateMutation.isPending;
  const canSave =
    Boolean(section && floor && system && subsystem) &&
    selectedCount > 0 &&
    (!isEdit || selectedCount === 1) &&
    !isSaving;

  const contractorItems: FilterOption[] = [
    { value: "own", label: "Свои" },
    ...(contractorsQuery.data ?? []).map((contractor) => ({
      value: contractor.id,
      label: contractor.shortName || contractor.fullName,
    })),
  ];
  const placeReady = Boolean(section && floor && system && subsystem);
  const showCatalog = layout === "dialog" || placeReady;
  const [editFilters, setEditFilters] = useState(false);
  const filtersOpen = layout === "dialog" || !placeReady || editFilters;

  async function handleSave() {
    if (!section || !floor || !system || !subsystem) {
      return;
    }
    const drafts: AddWorkItemDraft[] = [];
    for (const [estimateId, raw] of Object.entries(selected)) {
      const estimate = estimates.find((item) => item.id === estimateId);
      if (!estimate) {
        continue;
      }
      const parsed = parseWorkQuantity(raw);
      const quantity = parsed == null ? 0 : parsed;
      if (parsed != null && parsed < 0) {
        toast.error("Количество не может быть отрицательным");
        return;
      }
      drafts.push({
        estimateId: estimate.id,
        name: estimate.name,
        unit: estimate.unit,
        price: estimate.price,
        quantity,
        section: section.trim(),
        floor: floor.trim(),
        system,
        subsystem,
        contractorId,
        specialistsCount: null,
      });
    }
    if (drafts.length === 0) {
      return;
    }
    try {
      if (isEdit && initial) {
        const draft = drafts[0];
        await updateMutation.mutateAsync({
          itemId: initial.id,
          workId,
          estimateId: draft.estimateId,
          name: draft.name,
          unit: draft.unit,
          price: draft.price,
          quantity: draft.quantity,
          section: draft.section,
          floor: draft.floor,
          system: draft.system,
          subsystem: draft.subsystem,
          contractorId: draft.contractorId,
          specialistsCount: contractorId ? initial.specialistsCount : null,
        });
        toast.success("Работа сохранена");
      } else {
        await addMutation.mutateAsync(drafts);
        toast.success(
          drafts.length === 1
            ? "Работа добавлена"
            : `Добавлено позиций: ${drafts.length}`
        );
      }
      onCancel();
    } catch (error) {
      toast.error(
        error instanceof Error
          ? error.message
          : isEdit
            ? "Не удалось сохранить работу"
            : "Не удалось добавить работы"
      );
    }
  }

  if (materialOpen && system && subsystem) {
    return (
      <WorkItemNewMaterialForm
        layout={layout}
        objectId={objectId}
        system={system}
        subsystem={subsystem}
        onCancel={() => setMaterialOpen(false)}
        onCreated={(item) => {
          setExtraEstimates((current) =>
            current.some((row) => row.id === item.id)
              ? current
              : [item, ...current]
          );
          setSelected((current) => ({
            ...current,
            [item.id]: current[item.id] ?? "",
          }));
          setSearch("");
          setMaterialOpen(false);
        }}
      />
    );
  }

  const actions = (
    <>
      <Button type="button" variant="outline" onClick={onCancel}>
        Отмена
      </Button>
      <Button type="button" disabled={!canSave} onClick={() => void handleSave()}>
        {isSaving ? <Spinner data-icon="inline-start" /> : null}
        {isEdit ? "Сохранить" : "Добавить"}
      </Button>
    </>
  );

  const formBody = (
      <div
        className={
          layout === "sheet"
            ? "flex min-h-0 flex-col gap-3 overflow-hidden"
            : "flex min-h-0 flex-1 flex-col gap-3 overflow-hidden"
        }
      >
        {layout === "sheet" && placeReady ? (
          <Button
            type="button"
            variant="outline"
            className="h-auto min-h-8 w-full justify-between gap-2 whitespace-normal text-left"
            aria-expanded={filtersOpen}
            onClick={() => setEditFilters((open) => !open)}
          >
            <span className="min-w-0 flex-1 text-xs">
              {[
                system,
                subsystem,
                section,
                floor,
                contractorItems.find(
                  (item) => item.value === (contractorId ?? "own")
                )?.label,
              ]
                .filter(Boolean)
                .join(" · ")}
            </span>
            {filtersOpen ? "Скрыть" : "Изменить"}
            <ChevronDownIcon
              data-icon="inline-end"
              className={filtersOpen ? "rotate-180" : undefined}
            />
          </Button>
        ) : null}

        <Collapsible
          open={filtersOpen}
          className="shrink-0"
        >
          <CollapsibleContent className="h-[var(--collapsible-panel-height)] overflow-hidden data-ending-style:h-0 data-starting-style:h-0">
            <div className="flex flex-col gap-3 p-1">
            <div
              className={
                layout === "sheet"
                  ? "grid grid-cols-2 gap-3"
                  : "grid gap-3 sm:grid-cols-2"
              }
            >
        <CatalogSelect
          id="add-system"
          label="Система"
          layout={layout}
          value={system}
          options={systems}
          placeholder="Система"
          disabled={systems.length === 0}
          onChange={(next) => {
            setSystem(next);
            setSubsystem(null);
            if (!isEdit) {
              setSection(null);
              setFloor(null);
            }
            setSelected((current) => {
              const [estimateId] = Object.keys(current);
              const estimate = estimates.find((item) => item.id === estimateId);
              if (isEdit && estimate && estimate.system === next) {
                return current;
              }
              return {};
            });
          }}
        />
        <CatalogSelect
          id="add-subsystem"
          label="Подсистема"
          layout={layout}
          value={subsystem}
          options={subsystems}
          placeholder="Подсистема"
          disabled={!system || subsystems.length === 0}
          onChange={(next) => {
            setSubsystem(next);
            if (!isEdit) {
              setSection(null);
              setFloor(null);
            }
            setSelected((current) => {
              const [estimateId] = Object.keys(current);
              const estimate = estimates.find((item) => item.id === estimateId);
              if (
                isEdit &&
                estimate &&
                estimate.system === system &&
                estimate.subsystem === next
              ) {
                return current;
              }
              return {};
            });
          }}
        />
        <PlaceField
          id="add-section"
          label="Участок"
          compact={layout === "sheet"}
          value={section}
          options={sectionOptions}
          placeholder="Выберите или введите"
          disabled={!subsystem}
          onChange={(next) => {
            setSection(next);
            if (!isEdit) {
              setFloor(null);
              setSelected({});
            }
          }}
        />
        <PlaceField
          id="add-floor"
          label="Этаж"
          compact={layout === "sheet"}
          value={floor}
          options={floorOptions}
          placeholder="Выберите или введите"
          disabled={!section}
          onChange={(next) => {
            setFloor(next);
            if (!isEdit) {
              setSelected({});
            }
          }}
        />
            </div>
      <Field>
        <FieldLabel htmlFor="add-contractor">Подрядчик</FieldLabel>
        <Select
          value={contractorId ?? "own"}
          items={contractorItems}
          onValueChange={(next) => {
            if (typeof next !== "string") {
              return;
            }
            setContractorId(next === "own" ? null : next);
            if (!isEdit) {
              setSelected({});
            }
          }}
        >
          <SelectTrigger id="add-contractor" className="w-full">
            <SelectValue />
          </SelectTrigger>
          <SelectContent
            align="start"
            side={layout === "sheet" ? "top" : "bottom"}
            alignItemWithTrigger={layout !== "sheet"}
            className={
              layout === "sheet" ? "max-h-[min(50vh,16rem)] z-[70]" : undefined
            }
          >
            <SelectGroup>
              {contractorItems.map((item) => (
                <SelectItem key={item.value} value={item.value}>
                  {item.label}
                </SelectItem>
              ))}
            </SelectGroup>
          </SelectContent>
        </Select>
      </Field>
            </div>
          </CollapsibleContent>
        </Collapsible>

      {showCatalog ? (
        <>
      <Input
        type="search"
        value={search}
        placeholder="Поиск по смете"
        aria-label="Поиск по смете"
        className="shrink-0"
        disabled={!section || !floor || !system || !subsystem}
        onChange={(event) => setSearch(event.target.value)}
      />
      {!isEdit && placeReady ? (
        <Button
          type="button"
          variant="outline"
          className="shrink-0"
          onClick={() => setMaterialOpen(true)}
        >
          Новый материал
        </Button>
      ) : null}

      <div
        className={
          layout === "sheet"
            ? "min-h-0 overflow-y-auto overscroll-contain rounded-lg border"
            : "min-h-0 flex-1 overflow-y-auto rounded-lg border"
        }
      >
        {catalog.estimatesQuery.isLoading ? (
          <div className="flex items-center justify-center p-8">
            <Spinner />
          </div>
        ) : !section || !floor || !system || !subsystem ? (
          <p className="p-4 text-sm text-muted-foreground">
            Сначала выберите систему, подсистему, участок и этаж.
          </p>
        ) : visibleEstimates.length === 0 ? (
          <p className="p-4 text-sm text-muted-foreground">
            Нет доступных позиций сметы.
          </p>
        ) : (
          <ul className="divide-y py-1">
            {visibleEstimates.map((item) => {
              const checked = item.id in selected;
              return (
                <li key={item.id} className="flex items-start gap-2 px-3 py-2">
                  <input
                    type={isEdit ? "radio" : "checkbox"}
                    name={isEdit ? "edit-estimate" : undefined}
                    className="mt-1 size-4 accent-foreground"
                    checked={checked}
                    aria-label={item.name}
                    onChange={(event) => {
                      if (!event.target.checked && isEdit) {
                        return;
                      }
                      setSelected((current) => {
                        if (isEdit) {
                          return {
                            [item.id]:
                              item.id in current ? current[item.id] ?? "" : "",
                          };
                        }
                        const next = { ...current };
                        if (event.target.checked) {
                          next[item.id] = "";
                        } else {
                          delete next[item.id];
                        }
                        return next;
                      });
                    }}
                  />
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-medium">{item.name}</p>
                    <p className="text-xs text-muted-foreground">
                      {[item.number, item.unit, formatCurrency(item.price)]
                        .filter(Boolean)
                        .join(" · ")}
                    </p>
                  </div>
                  {checked ? (
                    <Input
                      value={selected[item.id] ?? ""}
                      inputMode="decimal"
                      placeholder="Кол-во"
                      aria-label={`Количество ${item.name}`}
                      className="h-7 w-20 text-right text-base md:text-xs"
                      onChange={(event) =>
                        setSelected((current) => ({
                          ...current,
                          [item.id]: event.target.value,
                        }))
                      }
                    />
                  ) : null}
                </li>
              );
            })}
          </ul>
        )}
      </div>
        </>
      ) : (
        <p className="text-sm text-muted-foreground">
          Сначала система и подсистема, затем участок и этаж.
        </p>
      )}
      </div>
  );

  if (layout === "sheet") {
    return (
      <>
        <MobileSheetChrome
          title={isEdit ? "Изменить работу" : "Добавить работы"}
          description={
            isEdit
              ? "Можно сменить систему, подсистему, участок, этаж, позицию сметы и количество."
              : "Сначала система и подсистема, затем участок и этаж, после этого позиции из сметы."
          }
          confirmLabel={isEdit ? "Сохранить" : "Добавить"}
          confirmDisabled={!canSave}
          confirmPending={isSaving}
          onConfirm={() => void handleSave()}
        />
        <MobileSheetBody nested>{formBody}</MobileSheetBody>
      </>
    );
  }

  return (
    <div className="flex min-h-0 flex-1 flex-col gap-3 overflow-hidden">
      <DialogHeader className="shrink-0">
        <DialogTitle>
          {isEdit ? "Изменить работу" : "Добавить работы"}
        </DialogTitle>
        <DialogDescription>
          {isEdit
            ? "Можно сменить систему, подсистему, участок, этаж, позицию сметы и количество."
            : "Сначала система и подсистема, затем участок и этаж, после этого позиции из сметы."}
        </DialogDescription>
      </DialogHeader>
      {formBody}
      <DialogFooter className="-mx-0 -mb-0 shrink-0 rounded-none border-t-0 bg-transparent p-0">
        {actions}
      </DialogFooter>
    </div>
  );
}

function uniqueSorted(values: string[]): string[] {
  return [...new Set(values.map((value) => value.trim()).filter(Boolean))].sort(
    (a, b) => a.localeCompare(b, "ru")
  );
}

function CatalogSelect({
  id,
  label,
  layout,
  value,
  options,
  placeholder,
  disabled,
  onChange,
}: {
  id: string;
  label: string;
  layout: "dialog" | "sheet";
  value: string | null;
  options: string[];
  placeholder: string;
  disabled?: boolean;
  onChange: (value: string | null) => void;
}) {
  const items: FilterOption[] = options.map((option) => ({
    value: option,
    label: option,
  }));
  const selected = value && options.includes(value) ? value : null;

  return (
    <Field>
      <FieldLabel htmlFor={id}>{label}</FieldLabel>
      <Select
        value={selected}
        items={items}
        disabled={disabled || items.length === 0}
        onValueChange={(next) => {
          if (typeof next === "string") {
            onChange(next);
          }
        }}
      >
        <SelectTrigger id={id} className="w-full">
          <SelectValue placeholder={placeholder} />
        </SelectTrigger>
        <SelectContent
          align="start"
          side={layout === "sheet" ? "top" : "bottom"}
          alignItemWithTrigger={layout !== "sheet"}
          className={
            layout === "sheet" ? "max-h-[min(50vh,16rem)] z-[70]" : undefined
          }
        >
          <SelectGroup>
            {items.map((item) => (
              <SelectItem key={item.value} value={item.value}>
                {item.label}
              </SelectItem>
            ))}
          </SelectGroup>
        </SelectContent>
      </Select>
    </Field>
  );
}

function PlaceField({
  id,
  label,
  compact = false,
  value,
  options,
  placeholder,
  disabled,
  onChange,
}: {
  id: string;
  label: string;
  compact?: boolean;
  value: string | null;
  options: string[];
  placeholder: string;
  disabled?: boolean;
  onChange: (value: string | null) => void;
}) {
  const listId = `${id}-list`;

  return (
    <Field data-disabled={disabled || undefined}>
      <FieldLabel htmlFor={id}>{label}</FieldLabel>
      <Input
        id={id}
        list={options.length > 0 ? listId : undefined}
        value={value ?? ""}
        placeholder={placeholder}
        disabled={disabled}
        autoComplete="off"
        onChange={(event) => {
          const next = event.target.value;
          onChange(next.trim() ? next : null);
        }}
      />
      {options.length > 0 ? (
        <datalist id={listId}>
          {options.map((option) => (
            <option key={option} value={option} />
          ))}
        </datalist>
      ) : null}
      {compact ? null : (
        <FieldDescription>
          Можно выбрать из списка или ввести свой.
        </FieldDescription>
      )}
    </Field>
  );
}
