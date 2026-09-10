"use client";

import { useQuery } from "@tanstack/react-query";

import { getEstimateItems } from "@/features/estimates/api/get-estimate-items";
import type { EstimateFileQuery } from "@/features/estimates/types/estimate.types";
import { estimateFileKey } from "@/features/estimates/utils/estimate.utils";

export function useEstimateItems(file: EstimateFileQuery | null) {
  return useQuery({
    queryKey: ["estimates", "items", file ? estimateFileKey(file) : null],
    queryFn: () => getEstimateItems(file as EstimateFileQuery),
    enabled: file !== null,
  });
}
