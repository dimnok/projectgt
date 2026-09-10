"use client";

import { useQuery } from "@tanstack/react-query";

import { getEstimateGroups } from "@/features/estimates/api/get-estimate-groups";

export const estimateGroupsQueryKey = ["estimates", "groups"] as const;

export function useEstimateGroups() {
  return useQuery({
    queryKey: estimateGroupsQueryKey,
    queryFn: getEstimateGroups,
  });
}
