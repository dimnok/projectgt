"use client";

import { useQuery } from "@tanstack/react-query";
import { getEstimateItemHistory } from "@/features/estimates/api/get-estimate-item-history";

export function useEstimateItemHistory(estimateId: string, enabled: boolean) {
  return useQuery({
    queryKey: ["estimates", "history", estimateId],
    queryFn: () => getEstimateItemHistory(estimateId),
    enabled: enabled && Boolean(estimateId),
    staleTime: 5 * 60 * 1000,
  });
}
