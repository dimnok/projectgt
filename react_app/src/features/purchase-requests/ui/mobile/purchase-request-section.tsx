"use client";

import type { ReactNode } from "react";

type SectionTitleProps = {
  title: string;
  /** Счётчик справа от названия. Ноль не показываем. */
  count?: number;
  /** Действие раздела (например, «Добавить»). */
  action?: ReactNode;
};

/** Заголовок раздела карточки заявки. */
export function SectionTitle({ title, count, action }: SectionTitleProps) {
  return (
    <div className="flex items-center justify-between gap-2">
      <h3 className="text-sm font-medium">
        {title}
        {typeof count === "number" && count > 0 ? (
          <span className="ml-1.5 text-xs font-normal text-muted-foreground">
            {count}
          </span>
        ) : null}
      </h3>
      {action}
    </div>
  );
}

/** Пустой раздел: аккуратная пунктирная заглушка. */
export function EmptySection({ text }: { text: string }) {
  return (
    <p className="rounded-xl border border-dashed border-border/60 py-5 text-center text-sm text-muted-foreground">
      {text}
    </p>
  );
}
