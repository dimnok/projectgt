"use client";

import { QueryClientProvider } from "@tanstack/react-query";
import { ThemeProvider, useTheme } from "next-themes";
import { useEffect, type ReactNode } from "react";

import { RegisterServiceWorker } from "@/components/pwa/register-service-worker";
import { Toaster } from "@/components/ui/sonner";
import { AuthProvider } from "@/hooks/use-auth";
import { useHasMounted } from "@/hooks/use-has-mounted";
import { getQueryClient } from "@/lib/query/query-client";

type AppProvidersProps = {
  children: ReactNode;
};

function themeColorFor(resolvedTheme: string | undefined) {
  if (resolvedTheme === "dark") {
    return "#0a0a0a";
  }
  if (resolvedTheme === "brand") {
    return "#E6E9EE";
  }
  return "#ffffff";
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
      themes={["light", "dark", "brand"]}
    >
      <ThemeColorSync />
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          {children}
          <RegisterServiceWorker />
          <Toaster />
        </AuthProvider>
      </QueryClientProvider>
    </ThemeProvider>
  );
}
