"use client";

import { useEffect, useRef } from "react";

import { useAuth } from "@/hooks/use-auth";
import {
  deactivatePushToken,
  registerPushNotifications,
} from "@/lib/notifications/push";

/**
 * Подключает устройство к push-уведомлениям.
 *
 * После входа сохраняет токен устройства, при выходе — гасит его,
 * при возврате на вкладку обновляет токен (Firebase периодически его меняет).
 * Ничего не рисует; ошибки push не влияют на работу приложения.
 */
export function RegisterPushNotifications() {
  const { session, isLoading } = useAuth();
  const userId = session?.user?.id ?? null;
  const previousUserId = useRef<string | null>(null);

  useEffect(() => {
    if (isLoading) {
      return;
    }

    if (!userId) {
      if (previousUserId.current) {
        void deactivatePushToken();
      }
      previousUserId.current = null;
      return;
    }

    if (previousUserId.current !== userId) {
      previousUserId.current = userId;
      void registerPushNotifications(userId);
    }
  }, [isLoading, userId]);

  useEffect(() => {
    if (!userId) {
      return;
    }

    function handleVisibilityChange() {
      if (document.visibilityState === "visible" && userId) {
        void registerPushNotifications(userId);
      }
    }

    document.addEventListener("visibilitychange", handleVisibilityChange);
    return () => {
      document.removeEventListener("visibilitychange", handleVisibilityChange);
    };
  }, [userId]);

  return null;
}
