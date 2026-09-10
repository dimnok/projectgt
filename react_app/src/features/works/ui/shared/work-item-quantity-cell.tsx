"use client";

import { useEffect, useRef, useState } from "react";

import { Input } from "@/components/ui/input";
import { Spinner } from "@/components/ui/spinner";
import type { WorkItem } from "@/features/works/types/work.types";
import {
  formatQuantity,
  parseWorkQuantity,
} from "@/features/works/utils/work.utils";
import { cn } from "@/lib/utils";

type WorkItemQuantityCellProps = {
  item: WorkItem;
  canEdit: boolean;
  isSaving: boolean;
  onSave: (quantity: number) => Promise<void>;
};

export function WorkItemQuantityCell({
  item,
  canEdit,
  isSaving,
  onSave,
}: WorkItemQuantityCellProps) {
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState("");
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (editing) {
      inputRef.current?.focus();
      inputRef.current?.select();
    }
  }, [editing]);

  async function commit() {
    const parsed = parseWorkQuantity(draft);
    setEditing(false);
    if (parsed == null || !(parsed > 0) || parsed === item.quantity) {
      return;
    }
    await onSave(parsed);
  }

  if (!canEdit) {
    return (
      <span className="tabular-nums">{formatQuantity(item.quantity)}</span>
    );
  }

  if (editing) {
    return (
      <Input
        ref={inputRef}
        value={draft}
        inputMode="decimal"
        aria-label="Количество"
        disabled={isSaving}
        className="h-7 w-20 ml-auto text-right text-base tabular-nums md:text-xs"
        onChange={(event) => setDraft(event.target.value)}
        onBlur={() => {
          void commit();
        }}
        onKeyDown={(event) => {
          if (event.key === "Enter") {
            event.preventDefault();
            void commit();
          }
          if (event.key === "Escape") {
            setEditing(false);
          }
        }}
      />
    );
  }

  return (
    <button
      type="button"
      disabled={isSaving}
      className={cn(
        "ml-auto block tabular-nums text-right underline-offset-2 hover:underline",
        isSaving && "opacity-60"
      )}
      onClick={() => {
        setDraft(String(item.quantity).replace(".", ","));
        setEditing(true);
      }}
    >
      {isSaving ? <Spinner className="size-3.5" /> : formatQuantity(item.quantity)}
    </button>
  );
}
