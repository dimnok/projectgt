"use client";

import { useIsMobile } from "@/hooks/use-mobile";
import { GtChatDesktop } from "@/features/gt-chat/ui/desktop/gt-chat-desktop";
import { GtChatMobile } from "@/features/gt-chat/ui/mobile/gt-chat-mobile";

/**
 * Экран «ГТ Чат»: мобильный и настольный вид.
 *
 * Логика общая — те же хуки и серверные функции. Интерфейс свой у каждой
 * платформы: на компьютере два столбца, на телефоне переписка на весь экран.
 */
export function GtChatScreen() {
  const isMobile = useIsMobile();

  if (isMobile) {
    return <GtChatMobile />;
  }

  return <GtChatDesktop />;
}
