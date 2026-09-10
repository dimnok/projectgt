"use client";

import { usePathname, useRouter } from "next/navigation";
import { useEffect, type ReactNode } from "react";

import { ErrorState } from "@/components/shared/error-state";
import { Spinner } from "@/components/ui/spinner";
import {
  getModuleForPath,
  getPostLoginPath,
  isMobileAllowedPath,
} from "@/config/navigation";
import { useAuth } from "@/hooks/use-auth";
import { useIsMobile } from "@/hooks/use-mobile";
import { usePermissions } from "@/hooks/use-permissions";
import { DesktopLayout } from "@/layouts/desktop/desktop-layout";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { ShieldIcon } from "lucide-react";

type AuthGateProps = {
  children: ReactNode;
};

export function AuthGate({ children }: AuthGateProps) {
  const { session, isLoading } = useAuth();
  const { can, isReady, needsRole } = usePermissions();
  const pathname = usePathname();
  const router = useRouter();
  const isMobile = useIsMobile();
  const isLoginPage = pathname === "/login";
  const isProfilePage = pathname === "/profile" || pathname.startsWith("/profile/");
  const pathModule = getModuleForPath(pathname);

  useEffect(() => {
    if (isLoading) {
      return;
    }

    if (!session && !isLoginPage) {
      router.replace("/login");
      return;
    }

    if (session && isLoginPage) {
      if (!isReady) {
        return;
      }
      if (needsRole) {
        router.replace("/profile");
        return;
      }
      router.replace(getPostLoginPath(isMobile, can));
      return;
    }

    if (session && needsRole && isReady && !isProfilePage) {
      router.replace("/profile");
      return;
    }

    if (session && isReady && isMobile && !isMobileAllowedPath(pathname)) {
      router.replace(can("works", "read") ? "/works" : "/profile");
    }
  }, [
    can,
    isLoading,
    isLoginPage,
    isMobile,
    isProfilePage,
    isReady,
    needsRole,
    pathname,
    router,
    session,
  ]);

  if (
    isLoading ||
    (!session && !isLoginPage) ||
    (session && isLoginPage) ||
    (session && !isReady) ||
    (session && needsRole && !isProfilePage) ||
    (session && isMobile && !isMobileAllowedPath(pathname))
  ) {
    return (
      <div className="flex h-full min-h-0 items-center justify-center">
        <Spinner />
      </div>
    );
  }

  if (isLoginPage) {
    return <div className="h-full min-h-0 overflow-hidden">{children}</div>;
  }

  const denied =
    Boolean(pathModule) && !needsRole && !can(pathModule ?? "", "read");

  return (
    <div className="h-full min-h-0 min-w-0 overflow-hidden">
      <DesktopLayout>
        {denied ? (
          <ErrorState
            title="Доступ запрещён"
            message="У вашей роли нет права открывать этот раздел."
          />
        ) : needsRole && isProfilePage ? (
          <div className="flex min-w-0 flex-col gap-4">
            <Alert>
              <ShieldIcon />
              <AlertTitle>Ожидание роли</AlertTitle>
              <AlertDescription>
                Руководитель ещё не назначил роль. Пока открыт только профиль.
              </AlertDescription>
            </Alert>
            {children}
          </div>
        ) : (
          children
        )}
      </DesktopLayout>
    </div>
  );
}
