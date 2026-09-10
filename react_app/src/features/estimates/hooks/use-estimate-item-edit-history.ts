"use client";

import { useQuery } from "@tanstack/react-query";
import { getEstimateItemEditHistory } from "@/features/estimates/api/get-estimate-item-edit-history";

export function useEstimateItemEditHistory(estimateId: string, enabled: boolean) {
  return useQuery({
    queryKey: ["estimates", "edit-history", estimateId],
    queryFn: () => getEstimateItemEditHistory(estimateId),
    enabled: enabled && Boolean(estimateId),
    staleTime: 5 * 60 * 1000,
  });
}
