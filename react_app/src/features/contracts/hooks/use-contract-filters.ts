"use client";

import { useState } from "react";

import type { ContractFilters } from "@/features/contracts/types/contract.types";

export function useContractFilters() {
  const [kind, setKind] = useState<ContractFilters["kind"]>("all");
  const [status, setStatus] = useState<ContractFilters["status"]>("all");

  return { kind, setKind, status, setStatus };
}
