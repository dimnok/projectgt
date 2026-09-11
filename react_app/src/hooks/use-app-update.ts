"use client";

import { useQuery } from "@tanstack/react-query";

import {
  applyAppUpdate,
  getClientAppVersion,
  isAppUpdateAvailable,
  type AppVersionInfo,
} from "@/lib/app-version";

export const appVersionQueryKey = ["app-version"] as const;

async function fetchRemoteAppVersion(): Promise<AppVersionInfo> {
  const response = await fetch("/api/version", { cache: "no-store" });
  if (!response.ok) {
    throw new Error("Не удалось проверить версию приложения");
  }
  return (await response.json()) as AppVersionInfo;
}

export function useAppUpdate() {
  const current = getClientAppVersion();
  const query = useQuery({
    queryKey: appVersionQueryKey,
    queryFn: fetchRemoteAppVersion,
    staleTime: 30_000,
    refetchInterval: 5 * 60_000,
    refetchOnWindowFocus: true,
    retry: 1,
  });

  return {
    current,
    remote: query.data,
    hasUpdate: isAppUpdateAvailable(current, query.data),
    isChecking: query.isLoading,
    applyUpdate: applyAppUpdate,
  };
}
