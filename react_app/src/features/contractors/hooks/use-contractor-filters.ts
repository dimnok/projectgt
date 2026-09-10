"use client";

import { useState } from "react";

import type { ContractorFilters } from "@/features/contractors/types/contractor.types";

export function useContractorFilters() {
  const [type, setType] = useState<ContractorFilters["type"]>("all");

  return { type, setType };
}
