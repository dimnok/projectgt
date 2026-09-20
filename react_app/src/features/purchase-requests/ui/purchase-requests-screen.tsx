"use client";

import { useIsMobile } from "@/hooks/use-mobile";
import { PurchaseRequestsDesktop } from "@/features/purchase-requests/ui/desktop/purchase-requests-desktop";
import { PurchaseRequestsMobile } from "@/features/purchase-requests/ui/mobile/purchase-requests-mobile";

/**
 * Экран «Заявки»: мобильный и настольный вид.
 *
 * Логика общая — те же хуки, серверные функции и права. Интерфейс свой
 * у каждой платформы: на компьютере таблица с правой колонкой, на телефоне
 * лента карточек с полноэкранной карточкой заявки.
 */
export function PurchaseRequestsScreen() {
  const isMobile = useIsMobile();

  if (isMobile) {
    return <PurchaseRequestsMobile />;
  }

  return <PurchaseRequestsDesktop />;
}
