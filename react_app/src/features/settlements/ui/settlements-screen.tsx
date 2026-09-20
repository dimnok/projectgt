"use client";

import { useIsMobile } from "@/hooks/use-mobile";
import { SettlementsDesktop } from "@/features/settlements/ui/desktop/settlements-desktop";
import { SettlementsMobile } from "@/features/settlements/ui/mobile/settlements-mobile";

/**
 * Экран «Взаиморасчёты»: реестр счетов и карточка счёта.
 *
 * Логика общая для обеих платформ — те же хуки, серверные функции и права.
 */
export function SettlementsScreen() {
  const isMobile = useIsMobile();

  if (isMobile) {
    return <SettlementsMobile />;
  }

  return <SettlementsDesktop />;
}
