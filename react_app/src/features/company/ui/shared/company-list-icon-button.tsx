"use client";

import type { LucideIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { useIsMobile } from "@/hooks/use-mobile";

/**
 * Размер кнопки-иконки на телефоне: по ней нужно попадать пальцем
 * (рекомендация — не меньше 44 пикселей). Тот же класс используют заглушки
 * загрузки, чтобы строки не меняли высоту после подгрузки.
 */
export const companyListIconButtonMobileClass = "size-11";

/** Иконка внутри крупной кнопки — соразмерно больше. */
const MOBILE_ICON_CLASS = "size-5";

type CompanyListIconButtonProps = {
  icon: LucideIcon;
  /** Подпись для чтения с экрана. */
  label: string;
  disabled?: boolean;
  onClick: () => void;
};

/** Кнопка-иконка в строке списка: изменить, удалить, скопировать. */
export function CompanyListIconButton({
  icon: Icon,
  label,
  disabled,
  onClick,
}: CompanyListIconButtonProps) {
  const isMobile = useIsMobile();

  return (
    <Button
      type="button"
      variant="ghost"
      size="icon-sm"
      className={isMobile ? companyListIconButtonMobileClass : undefined}
      aria-label={label}
      disabled={disabled}
      onClick={onClick}
    >
      <Icon className={isMobile ? MOBILE_ICON_CLASS : undefined} />
    </Button>
  );
}
