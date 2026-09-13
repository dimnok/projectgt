"use client";

import { useEffect, useState, type FormEvent } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  Field,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Spinner } from "@/components/ui/spinner";
import { useUpdateCompanyMinOutput } from "@/features/profile/hooks/use-current-profile";
import type { CurrentProfile } from "@/features/profile/types/profile.types";
import { cn } from "@/lib/utils";

type ProfileCompanyOutputNormProps = {
  profile: CurrentProfile;
  className?: string;
  compact?: boolean;
};

function formatStoredValue(value: number | null): string {
  if (value === null) {
    return "";
  }
  return String(value);
}

function parseNormInput(raw: string): { value: number | null; error?: string } {
  const trimmed = raw.trim().replace(/\s/g, "").replace(",", ".");
  if (!trimmed) {
    return { value: null };
  }
  const parsed = Number(trimmed);
  if (!Number.isFinite(parsed)) {
    return { value: null, error: "Введите число" };
  }
  if (parsed < 0) {
    return { value: null, error: "Сумма не может быть отрицательной" };
  }
  return { value: parsed };
}

export function ProfileCompanyOutputNorm({
  profile,
  className,
  compact = false,
}: ProfileCompanyOutputNormProps) {
  const active = profile.activeMembership;
  const saveNorm = useUpdateCompanyMinOutput();
  const stored = active?.minOutputPerPersonHour ?? null;
  const canEdit = Boolean(active?.isOwner);
  const [draft, setDraft] = useState(() => formatStoredValue(stored));
  const [error, setError] = useState<string | undefined>();

  useEffect(() => {
    setDraft(formatStoredValue(stored));
    setError(undefined);
  }, [active?.companyId, stored]);

  if (!active) {
    return null;
  }

  const isDirty = draft !== formatStoredValue(stored);

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const parsed = parseNormInput(draft);
    if (parsed.error) {
      setError(parsed.error);
      return;
    }
    setError(undefined);
    saveNorm.mutate(parsed.value, {
      onSuccess: () =>
        toast.success(
          parsed.value === null
            ? "Норма выработки сброшена"
            : "Норма выработки сохранена"
        ),
      onError: (err) =>
        toast.error(
          err instanceof Error ? err.message : "Не удалось сохранить норму"
        ),
    });
  }

  return (
    <form
      className={cn("flex flex-col gap-3", className)}
      onSubmit={handleSubmit}
    >
      <FieldGroup>
        <Field data-invalid={Boolean(error) || undefined}>
          <FieldLabel htmlFor="company-min-output">
            Минимум выработки, ₽ / чел. / час
          </FieldLabel>
          <Input
            id="company-min-output"
            inputMode="decimal"
            placeholder="Например, 2000"
            value={draft}
            onChange={(event) => setDraft(event.target.value)}
            disabled={!canEdit || saveNorm.isPending}
            aria-invalid={Boolean(error)}
            className={compact ? "h-11" : undefined}
          />
          <FieldDescription>
            План дня на графике: часы смены × эта сумма. Пустое поле — план не
            считается. Меняет только владелец организации.
          </FieldDescription>
          <FieldError>{error}</FieldError>
        </Field>
      </FieldGroup>

      {canEdit ? (
        <div className="flex items-center gap-2">
          <Button
            type="submit"
            disabled={!isDirty || saveNorm.isPending}
            className={compact ? "h-11" : undefined}
          >
            {saveNorm.isPending ? <Spinner data-icon="inline-start" /> : null}
            Сохранить норму
          </Button>
          {isDirty ? (
            <Button
              type="button"
              variant="outline"
              disabled={saveNorm.isPending}
              onClick={() => {
                setDraft(formatStoredValue(stored));
                setError(undefined);
              }}
            >
              Отмена
            </Button>
          ) : null}
        </div>
      ) : (
        <p className="text-xs text-muted-foreground">
          Изменить норму может только владелец организации.
        </p>
      )}
    </form>
  );
}
