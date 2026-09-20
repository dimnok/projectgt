import type { SettlementFilters } from "@/features/settlements/types/settlement.types";

/** Пустые фильтры реестра (поиск, тип, статус, контрагент, объект, договор). */
export function emptySettlementFilters(): SettlementFilters {
  return {
    search: "",
    operationType: "all",
    paymentStatus: "all",
    contractorId: "",
    objectId: "",
    contractId: "",
  };
}

/** Есть хотя бы один активный фильтр. */
export function hasActiveSettlementFilters(filters: SettlementFilters): boolean {
  return (
    filters.search.trim() !== "" ||
    filters.operationType !== "all" ||
    filters.paymentStatus !== "all" ||
    filters.contractorId !== "" ||
    filters.objectId !== "" ||
    filters.contractId !== ""
  );
}
