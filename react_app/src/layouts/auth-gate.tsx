"use client";

import { ShieldIcon } from "lucide-react";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, type ReactNode } from "react";

import { ErrorState } from "@/components/shared/error-state";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import {
  getModuleForPath,
  getPostLoginPath,
  isMobileAllowedPath,
} from "@/config/navigation";
import { useCurrentProfile } from "@/features/profile/hooks/use-current-profile";
import type { CurrentProfile } from "@/features/profile/types/profile.types";
import { useAuth } from "@/hooks/use-auth";
import { useIsMobile } from "@/hooks/use-mobile";
import { usePermissions } from "@/hooks/use-permissions";
import { DesktopLayout } from "@/layouts/desktop/desktop-layout";
import { signOut } from "@/lib/supabase/auth";

type AuthGateProps = {
  children: ReactNode;
};

const LOGIN_PATH = "/login";
const COMPLETE_PROFILE_PATH = "/complete-profile";
const ONBOARDING_PATH = "/onboarding";
const ACCESS_DISABLED_PATH = "/access-disabled";

/** Экраны входа и онбординга: показываются вне основной оболочки приложения. */
const GATE_PATHS = [
  LOGIN_PATH,
  COMPLETE_PROFILE_PATH,
  ONBOARDING_PATH,
  ACCESS_DISABLED_PATH,
];

/**
 * Обязательный экран по состоянию профиля. Порядок как в приложении:
 * отключён → нет ФИО → нет компании.
 */
function requiredPathFor(profile: CurrentProfile): string | null {
  if (!profile.status) {
    return ACCESS_DISABLED_PATH;
  }
  if (!profile.fullName.trim()) {
    return COMPLETE_PROFILE_PATH;
  }
  if (!profile.lastCompanyId) {
    return ONBOARDING_PATH;
  }
  return null;
}

export function AuthGate({ children }: AuthGateProps) {
  const { session, isLoading } = useAuth();
  const { can, isReady, needsRole } = usePermissions();
  const {
    data: profile,
    isFetched: profileFetched,
    isError: profileError,
    error: profileErrorValue,
    refetch: refetchProfile,
  } = useCurrentProfile();
  const pathname = usePathname();
  const router = useRouter();
  const isMobile = useIsMobile();
  const isLoginPage = pathname === LOGIN_PATH;
  const isProfilePage =
    pathname === "/profile" || pathname.startsWith("/profile/");
  const isGatePath = GATE_PATHS.includes(pathname);
  const pathModule = getModuleForPath(pathname);
  const requiredPath = profile ? requiredPathFor(profile) : null;

  useEffect(() => {
    if (isLoading) {
      return;
    }

    if (!session) {
      if (pathname !== LOGIN_PATH) {
        router.replace(LOGIN_PATH);
      }
      return;
    }

    if (!profileFetched || !profile) {
      return;
    }

    if (requiredPath) {
      if (pathname !== requiredPath) {
        router.replace(requiredPath);
      }
      return;
    }

    if (isGatePath) {
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

    if (needsRole && isReady && !isProfilePage) {
      router.replace("/profile");
      return;
    }

    if (isReady && isMobile && !isMobileAllowedPath(pathname)) {
      router.replace(can("works", "read") ? "/works" : "/profile");
    }
  }, [
    can,
    isLoading,
    isGatePath,
    isMobile,
    isProfilePage,
    isReady,
    needsRole,
    pathname,
    profile,
    profileFetched,
    requiredPath,
    router,
    session,
  ]);

  if (isLoading) {
    return <FullScreenSpinner />;
  }

  if (!session) {
    return isLoginPage ? gateShell(children) : <FullScreenSpinner />;
  }

  if (!profileFetched) {
    return <FullScreenSpinner />;
  }

  if (profileError || !profile) {
    return (
      <div className="flex h-full min-h-0 items-center justify-center px-6">
        <div className="flex w-full max-w-sm flex-col gap-3">
          <ErrorState
            title="Ошибка при загрузке профиля"
            message={
              profileErrorValue instanceof Error
                ? profileErrorValue.message
                : "Не удалось загрузить профиль"
            }
          />
          <Button type="button" onClick={() => void refetchProfile()}>
            Повторить
          </Button>
          <Button type="button" variant="ghost" onClick={() => void signOut()}>
            Выйти
          </Button>
        </div>
      </div>
    );
  }

  if (requiredPath) {
    return pathname === requiredPath ? gateShell(children) : <FullScreenSpinner />;
  }

  if (isGatePath) {
    return <FullScreenSpinner />;
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

function gateShell(children: ReactNode) {
  return <div className="h-full min-h-0 overflow-hidden">{children}</div>;
}

function FullScreenSpinner() {
  return (
    <div className="flex h-full min-h-0 items-center justify-center">
      <Spinner />
    </div>
  );
}
