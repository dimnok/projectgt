"use client";

import { QueryClientProvider } from "@tanstack/react-query";
import { ThemeProvider, useTheme } from "next-themes";
import { useEffect, type ReactNode } from "react";

import { RegisterPushNotifications } from "@/components/pwa/register-push-notifications";
import { RegisterServiceWorker } from "@/components/pwa/register-service-worker";
import { Toaster } from "@/components/ui/sonner";
import { findThemeOption, themeIds } from "@/config/themes";
import { AuthProvider } from "@/hooks/use-auth";
import { ConnectionStatusProvider } from "@/hooks/use-connection-status";
import { useHasMounted } from "@/hooks/use-has-mounted";
import { getQueryClient } from "@/lib/query/query-client";

type AppProvidersProps = {
  children: ReactNode;
};

/** Цвет строки браузера: берём фон темы из справочника тем. */
function themeColorFor(resolvedTheme: string | undefined) {
  return findThemeOption(resolvedTheme)?.statusBarColor ?? "#ffffff";
}

function ThemeColorSync() {
  const { resolvedTheme } = useTheme();
  const mounted = useHasMounted();

  useEffect(() => {
    if (!mounted) {
      return;
    }

    const color = themeColorFor(resolvedTheme);
    document.querySelectorAll('meta[name="theme-color"]').forEach((meta) => {
      meta.setAttribute("content", color);
    });
  }, [mounted, resolvedTheme]);

  return null;
}

export function AppProviders({ children }: AppProvidersProps) {
  const queryClient = getQueryClient();

  return (
    <ThemeProvider
      attribute="class"
      defaultTheme="system"
      enableSystem
      themes={themeIds}
    >
      <ThemeColorSync />
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          <ConnectionStatusProvider>
            {children}
            <RegisterServiceWorker />
            <RegisterPushNotifications />
            <Toaster />
          </ConnectionStatusProvider>
        </AuthProvider>
      </QueryClientProvider>
    </ThemeProvider>
  );
}
