"use client";

import { useQuery } from "@tanstack/react-query";

import { getMyProfileFinance } from "@/features/profile/api/get-my-profile-finance";
import type { ProfileFinancePeriod } from "@/features/profile/types/profile-finance.types";
import { useAuth } from "@/hooks/use-auth";

export function profileFinanceQueryKey(period: ProfileFinancePeriod) {
  return ["profile-finance", period.year, period.month] as const;
}

export function useProfileFinance(period: ProfileFinancePeriod) {
  const { session } = useAuth();

  return useQuery({
    queryKey: profileFinanceQueryKey(period),
    queryFn: () => getMyProfileFinance(period.year, period.month),
    enabled: Boolean(session?.user),
  });
}
