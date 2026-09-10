"use client";

import { useState, useSyncExternalStore } from "react";
import { useRouter } from "next/navigation";
import {
  GlobeIcon,
  LogOutIcon,
  RefreshCwIcon,
  SmartphoneIcon,
  WifiIcon,
  WifiOffIcon,
} from "lucide-react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
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
import { ProfileMobileShell } from "@/features/profile/ui/mobile/profile-mobile-shell";
import { useStandalone } from "@/hooks/use-standalone";
import { signOut } from "@/lib/supabase/auth";

const APP_VERSION = "0.1.0";

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

type ProfileSystemMobileProps = {
  onBack: () => void;
};

export function ProfileSystemMobile({ onBack }: ProfileSystemMobileProps) {
  const router = useRouter();
  const isStandalone = useStandalone();
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
    window.location.reload();
  }

  return (
    <ProfileMobileShell title="Настройки" onBack={onBack}>
      <div className="flex flex-col gap-5">
        <div className="flex flex-col gap-3 rounded-2xl bg-card p-4 ring-1 ring-foreground/10">
          <p className="text-sm font-medium">Тема оформления</p>
          <ProfileAppearance />
        </div>

        <div className="flex flex-col gap-2 rounded-2xl bg-card p-4 ring-1 ring-foreground/10">
          <div className="flex h-11 items-center justify-between gap-3">
            <span className="text-sm text-muted-foreground">Версия</span>
            <Badge variant="secondary">v{APP_VERSION}</Badge>
          </div>
          <div className="flex h-11 items-center justify-between gap-3">
            <span className="text-sm text-muted-foreground">Режим</span>
            <span className="flex items-center gap-1.5 text-sm">
              {isStandalone ? <SmartphoneIcon /> : <GlobeIcon />}
              {isStandalone ? "PWA" : "Браузер"}
            </span>
          </div>
          <div className="flex h-11 items-center justify-between gap-3">
            <span className="text-sm text-muted-foreground">Сеть</span>
            <span className="flex items-center gap-1.5 text-sm">
              {isOnline ? <WifiIcon /> : <WifiOffIcon />}
              {isOnline ? "Онлайн" : "Офлайн"}
            </span>
          </div>
        </div>

        <Button
          type="button"
          variant="outline"
          size="lg"
          className="w-full"
          onClick={handleReload}
        >
          <RefreshCwIcon data-icon="inline-start" />
          Перезагрузить
        </Button>

        <Button
          type="button"
          variant="destructive"
          size="lg"
          className="w-full"
          onClick={() => setIsSignOutOpen(true)}
        >
          <LogOutIcon data-icon="inline-start" />
          Выйти из аккаунта
        </Button>
      </div>

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
              {isSigningOut ? <Spinner data-icon="inline-start" /> : null}
              Выйти
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </ProfileMobileShell>
  );
}
