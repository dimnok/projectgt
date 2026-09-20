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

/**
 * Проверяет, не вышла ли новая сборка сайта.
 *
 * Запрос лёгкий, поэтому спрашиваем сервер раз в 2 минуты и дополнительно при
 * возврате на вкладку: колокольчик появляется вскоре после выкладки.
 */
export function useAppUpdate() {
  const current = getClientAppVersion();
  const query = useQuery({
    queryKey: appVersionQueryKey,
    queryFn: fetchRemoteAppVersion,
    staleTime: 60_000,
    refetchInterval: 2 * 60_000,
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
