"use client";

import { DownloadIcon, ShareIcon, SmartphoneIcon } from "lucide-react";
import { useMemo, type ReactNode } from "react";

import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import { useHasMounted } from "@/hooks/use-has-mounted";
import { useIsMobile } from "@/hooks/use-mobile";
import { usePwaInstallPrompt } from "@/hooks/use-pwa-install-prompt";
import { useStandalone } from "@/hooks/use-standalone";
import { isIosDevice } from "@/lib/pwa/display-mode";

type PwaInstallGateProps = {
  children: ReactNode;
};

export function PwaInstallGate({ children }: PwaInstallGateProps) {
  const mounted = useHasMounted();
  const isMobile = useIsMobile();
  const isStandalone = useStandalone();

  if (!mounted) {
    return (
      <div className="flex h-full min-h-0 items-center justify-center">
        <Spinner />
      </div>
    );
  }

  if (isMobile && !isStandalone) {
    return <PwaInstallScreen />;
  }

  return children;
}

function PwaInstallScreen() {
  const { canPrompt, promptInstall } = usePwaInstallPrompt();
  const ios = useMemo(() => isIosDevice(), []);

  return (
    <div className="flex h-full min-h-0 flex-col items-center justify-center overflow-y-auto px-6 py-8 pt-[max(2rem,env(safe-area-inset-top))] pb-[max(2rem,env(safe-area-inset-bottom))]">
      <div className="flex w-full max-w-sm flex-col gap-5">
        <div className="flex size-12 items-center justify-center rounded-full bg-foreground text-background">
          <SmartphoneIcon className="size-5" />
        </div>
        <div className="flex flex-col gap-2">
          <h1 className="font-heading text-2xl font-medium">
            Установите приложение
          </h1>
          <p className="text-sm text-muted-foreground">
            На телефоне Proстройка открывается только после установки на экран
            «Домой». В обычном браузере доступа нет.
          </p>
        </div>
        {canPrompt ? (
          <Button type="button" size="lg" onClick={() => void promptInstall()}>
            <DownloadIcon data-icon="inline-start" />
            Установить
          </Button>
        ) : null}
        {ios ? (
          <ol className="flex list-decimal flex-col gap-2 pl-5 text-sm">
            <li>
              Нажмите кнопку «Поделиться»
              <ShareIcon className="ml-1 inline size-4 align-text-bottom" />
            </li>
            <li>Выберите «На экран „Домой“»</li>
            <li>Откройте иконку Proстройка на экране телефона</li>
          </ol>
        ) : (
          <p className="text-sm text-muted-foreground">
            Если кнопки установки нет, откройте меню браузера и выберите
            «Установить приложение» или «На главный экран». Затем откройте
            Proстройка с иконки на телефоне.
          </p>
        )}
      </div>
    </div>
  );
}
