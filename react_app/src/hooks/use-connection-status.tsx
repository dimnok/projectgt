"use client";

import {
  createContext,
  use,
  useCallback,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { toast } from "sonner";

import { env, isSupabaseConfigured } from "@/config/env";
import { isConnectionOnline } from "@/lib/connection/connection";

/** Как часто перепроверяем соединение, мс. */
const CHECK_INTERVAL_MS = 25_000;
/** Сколько ждём ответа backend, мс. */
const PROBE_TIMEOUT_MS = 4_000;
/** Пауза перед повторной попыткой, мс. */
const RETRY_DELAY_MS = 1_000;

type ConnectionStatusValue = {
  /** `true` — интернет есть и backend отвечает; иначе `false`. */
  isOnline: boolean;
};

const ConnectionStatusContext = createContext<ConnectionStatusValue | null>(null);

/**
 * Единое состояние соединения для всего приложения.
 *
 * Должен стоять выше любого экрана, который показывает индикатор или
 * использует `useConnectionStatus`. Проверяет соединение при запуске,
 * по событиям `online`/`offline`, при возврате вкладки из фона и
 * периодически раз в `CHECK_INTERVAL_MS`.
 */
export function ConnectionStatusProvider({ children }: { children: ReactNode }) {
  // Стартуем «онлайн», чтобы не мигать офлайном до первой проверки
  // и не расходиться с серверной отрисовкой при гидратации.
  const [isOnline, setIsOnline] = useState(true);
  const isOnlineRef = useRef(true);
  const isProbingRef = useRef(false);

  const applyStatus = useCallback((next: boolean) => {
    if (isOnlineRef.current === next) {
      return;
    }

    isOnlineRef.current = next;
    setIsOnline(next);
    toast[next ? "success" : "error"](
      next ? "Соединение восстановлено" : "Нет соединения"
    );
  }, []);

  const check = useCallback(async () => {
    // Браузер уже знает, что сети нет — запрос не нужен.
    if (!navigator.onLine) {
      applyStatus(isConnectionOnline(false, null));
      return;
    }

    // Без ключей Supabase проверяем только браузер.
    if (!isSupabaseConfigured()) {
      applyStatus(isConnectionOnline(true, null));
      return;
    }

    // Не допускаем наложения проверок друг на друга.
    if (isProbingRef.current) {
      return;
    }

    isProbingRef.current = true;
    try {
      let reachable = await probeBackend();
      if (!reachable && navigator.onLine) {
        // Один повторный замер отсекает случайные сбои.
        await delay(RETRY_DELAY_MS);
        reachable = await probeBackend();
      }

      applyStatus(isConnectionOnline(navigator.onLine, reachable));
    } finally {
      isProbingRef.current = false;
    }
  }, [applyStatus]);

  useEffect(() => {
    void check();

    const handleOnline = () => void check();
    const handleOffline = () => applyStatus(false);
    const handleVisibility = () => {
      if (document.visibilityState === "visible") {
        void check();
      }
    };

    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);
    document.addEventListener("visibilitychange", handleVisibility);

    const intervalId = window.setInterval(() => {
      // В фоне сервер не дёргаем — проверим при возврате во вкладку.
      if (document.visibilityState === "visible") {
        void check();
      }
    }, CHECK_INTERVAL_MS);

    return () => {
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
      document.removeEventListener("visibilitychange", handleVisibility);
      window.clearInterval(intervalId);
    };
  }, [applyStatus, check]);

  return (
    <ConnectionStatusContext.Provider value={{ isOnline }}>
      {children}
    </ConnectionStatusContext.Provider>
  );
}

/**
 * Доступ к общему состоянию соединения.
 * Бросает ошибку, если провайдер не подключён.
 */
export function useConnectionStatus(): ConnectionStatusValue {
  const value = use(ConnectionStatusContext);
  if (!value) {
    throw new Error(
      "useConnectionStatus must be used within ConnectionStatusProvider"
    );
  }

  return value;
}

/**
 * Лёгкая проверка доступности backend/Supabase.
 * Короткий health-запрос к Supabase Auth; ответ 2xx — сервер доступен.
 */
async function probeBackend(): Promise<boolean> {
  const controller = new AbortController();
  const timeoutId = window.setTimeout(() => controller.abort(), PROBE_TIMEOUT_MS);

  try {
    const response = await fetch(`${env.supabaseUrl}/auth/v1/health`, {
      method: "GET",
      headers: { apikey: env.supabasePublishableKey },
      cache: "no-store",
      signal: controller.signal,
    });

    return response.ok;
  } catch {
    return false;
  } finally {
    window.clearTimeout(timeoutId);
  }
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => window.setTimeout(resolve, ms));
}
