"use client";

import { useState, useSyncExternalStore } from "react";
import { useRouter } from "next/navigation";
import {
  GlobeIcon,
  LaptopIcon,
  LogOutIcon,
  PaletteIcon,
  RefreshCwIcon,
  SmartphoneIcon,
  WifiIcon,
  WifiOffIcon,
} from "lucide-react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Spinner } from "@/components/ui/spinner";
import { ProfileAppearance } from "@/features/profile/ui/profile-appearance";
import { useAppUpdate } from "@/hooks/use-app-update";
import { useStandalone } from "@/hooks/use-standalone";
import {
  formatAppBuildLabel,
  formatAppBuildTime,
  formatAppVersionLabel,
} from "@/lib/app-version";
import { signOut } from "@/lib/supabase/auth";

const BUILD_INFO = "Next.js 16 • React 19";

function subscribeOnline(callback: () => void) {
  window.addEventListener("online", callback);
  window.addEventListener("offline", callback);
  return () => {
    window.removeEventListener("online", callback);
    window.removeEventListener("offline", callback);
  };
}

function getOnlineSnapshot() {
  return navigator.onLine;
}

function getOnlineServerSnapshot() {
  return true;
}

export function ProfileSystemTab() {
  const router = useRouter();
  const isStandalone = useStandalone();
  const { current, hasUpdate, applyUpdate } = useAppUpdate();
  const versionLabel = formatAppVersionLabel(current.version);
  const buildLabel = formatAppBuildLabel(current.buildId);
  const buildTime = formatAppBuildTime(current.builtAt);
  const [isSignOutOpen, setIsSignOutOpen] = useState(false);
  const [isSigningOut, setIsSigningOut] = useState(false);
  const isOnline = useSyncExternalStore(
    subscribeOnline,
    getOnlineSnapshot,
    getOnlineServerSnapshot
  );

  async function handleSignOut() {
    setIsSigningOut(true);
    try {
      await signOut();
      router.replace("/login");
    } catch (err) {
      setIsSigningOut(false);
      toast.error(
        err instanceof Error ? err.message : "Не удалось завершить сеанс"
      );
    }
  }

  function handleReload() {
    applyUpdate();
  }

  return (
    <div className="flex flex-col gap-6">
      {/* 1. Оформление интерфейса */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <PaletteIcon className="size-4 text-primary" />
            <CardTitle>Тема оформления</CardTitle>
          </div>
          <CardDescription>
            Выбор цветовой схемы веб-приложения. Сохраняется в вашем браузере.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <ProfileAppearance />
        </CardContent>
      </Card>

      {/* 2. О приложении и среде */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <LaptopIcon className="size-4 text-primary" />
              <CardTitle>О приложении</CardTitle>
            </div>
            <Badge variant={hasUpdate ? "warning" : "secondary"}>
              {versionLabel}
            </Badge>
          </div>
          <CardDescription>
            Техническая информация о сборке и текущем режиме работы.
          </CardDescription>
        </CardHeader>

        <CardContent className="flex flex-col gap-3">
          <div className="grid gap-2 text-sm sm:grid-cols-2">
            <div className="flex items-center justify-between rounded-lg border bg-muted/20 p-3">
              <span className="text-muted-foreground">Версия приложения</span>
              <span className="flex flex-col items-end gap-0.5">
                <span className="font-semibold text-foreground">
                  {versionLabel}
                </span>
                {buildTime || buildLabel ? (
                  <span className="font-mono text-xs text-muted-foreground">
                    {[buildTime, buildLabel].filter(Boolean).join(" · ")}
                  </span>
                ) : null}
              </span>
            </div>

            <div className="flex items-center justify-between rounded-lg border bg-muted/20 p-3">
              <span className="text-muted-foreground">Архитектура</span>
              <span className="text-xs font-mono text-muted-foreground">
                {BUILD_INFO}
              </span>
            </div>

            <div className="flex items-center justify-between rounded-lg border bg-muted/20 p-3">
              <span className="text-muted-foreground">Режим работы</span>
              <div className="flex items-center gap-1.5 text-xs font-medium">
                {isStandalone ? (
                  <>
                    <SmartphoneIcon className="size-3.5 text-primary" />
                    <span>PWA (автономный)</span>
                  </>
                ) : (
                  <>
                    <GlobeIcon className="size-3.5 text-muted-foreground" />
                    <span>Веб-браузер</span>
                  </>
                )}
              </div>
            </div>

            <div className="flex items-center justify-between rounded-lg border bg-muted/20 p-3">
              <span className="text-muted-foreground">Подключение к сети</span>
              <div className="flex items-center gap-1.5 text-xs font-medium">
                {isOnline ? (
                  <>
                    <WifiIcon className="size-3.5 text-emerald-600" />
                    <span className="text-emerald-600 dark:text-emerald-400">
                      Онлайн
                    </span>
                  </>
                ) : (
                  <>
                    <WifiOffIcon className="size-3.5 text-destructive" />
                    <span className="text-destructive">Офлайн</span>
                  </>
                )}
              </div>
            </div>
          </div>
        </CardContent>

        <CardFooter className="justify-between gap-2">
          <span className="text-xs text-muted-foreground">
            {hasUpdate
              ? "Доступна новая версия. Обновите страницу."
              : "У вас актуальная версия"}
          </span>
          <Button
            type="button"
            variant={hasUpdate ? "default" : "outline"}
            size="sm"
            className="gap-1.5"
            onClick={handleReload}
          >
            <RefreshCwIcon data-icon="inline-start" />
            <span>{hasUpdate ? "Обновить" : "Перезагрузить страницу"}</span>
          </Button>
        </CardFooter>
      </Card>

      {/* 3. Сеанс и выход */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <LogOutIcon className="size-4 text-destructive" />
            <CardTitle>Сеанс учетной записи</CardTitle>
          </div>
          <CardDescription>
            Завершение работы в аккаунте на этом устройстве.
          </CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="text-sm font-medium text-foreground">
              Активный сеанс авторизации
            </p>
            <p className="text-xs text-muted-foreground">
              Все сохраненные данные синхронизированы с облаком.
            </p>
          </div>
          <Button
            type="button"
            variant="destructive"
            size="sm"
            className="gap-1.5 self-start sm:self-auto"
            onClick={() => setIsSignOutOpen(true)}
          >
            <LogOutIcon className="size-3.5" />
            <span>Выйти из аккаунта</span>
          </Button>
        </CardContent>
      </Card>

      {/* Диалог подтверждения выхода */}
      <Dialog open={isSignOutOpen} onOpenChange={setIsSignOutOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Выйти из учетной записи?</DialogTitle>
            <DialogDescription>
              Для повторного входа потребуется авторизоваться по номеру телефона
              и SMS-коду.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              disabled={isSigningOut}
              onClick={() => setIsSignOutOpen(false)}
            >
              Отмена
            </Button>
            <Button
              type="button"
              variant="destructive"
              disabled={isSigningOut}
              onClick={() => void handleSignOut()}
            >
              {isSigningOut ? <Spinner className="size-3.5" /> : null}
              Выйти
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
