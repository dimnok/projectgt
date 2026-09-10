"use client";

import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";

import { getEstimateCompletionByIds } from "@/features/estimates/api/get-estimate-completion";
import { mapEstimateCompletionById } from "@/features/estimates/utils/estimate-execution";

export function useEstimateCompletion(ids: string[], enabled: boolean) {
  const sortedIds = useMemo(() => [...ids].sort(), [ids]);
  const query = useQuery({
    queryKey: ["estimates", "completion", sortedIds],
    queryFn: () => getEstimateCompletionByIds(sortedIds),
    enabled: enabled && sortedIds.length > 0,
  });
  const completionById = useMemo(
    () => mapEstimateCompletionById(query.data ?? []),
    [query.data]
  );

  return {
    ...query,
    completionById,
  };
}
