"use client";

import { ErrorState } from "@/components/shared/error-state";
import { Button } from "@/components/ui/button";

type PayrollsErrorStateProps = {
  title: string;
  message?: string;
  onRetry: () => void;
};

/** Ошибка загрузки вкладки ФОТ с кнопкой повтора. */
export function PayrollsErrorState({
  title,
  message,
  onRetry,
}: PayrollsErrorStateProps) {
  return (
    <div className="flex flex-col gap-3 p-4">
      <ErrorState
        title={title}
        message={message ?? "Не удалось загрузить данные"}
      />
      <div className="flex justify-end">
        <Button type="button" variant="outline" size="sm" onClick={onRetry}>
          Повторить попытку
        </Button>
      </div>
    </div>
  );
}
