/** Значок помощника: «ГТ» — тот же, что в меню и шапке диалога. */
export function ChatBadge({ className }: { className?: string }) {
  return (
    <div
      className={
        className ??
        "flex size-8 shrink-0 items-center justify-center rounded-full bg-primary text-[11px] font-bold text-primary-foreground"
      }
    >
      ГТ
    </div>
  );
}

/** Подсказка в пустом диалоге: что писать и чего помощник пока не умеет. */
export function ChatEmptyHint() {
  return (
    <>
      <ChatBadge />
      <p className="font-heading text-base font-medium">Чем помочь?</p>
      <p className="max-w-sm text-sm leading-relaxed text-muted-foreground">
        Напишите вопрос обычными словами. Помощник умеет искать в интернете и
        ссылается на источники; данные компании — объекты, смены, сметы — он
        пока не видит.
      </p>
    </>
  );
}
