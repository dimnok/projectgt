"use client";

import { useState } from "react";

import { MobileSheet, MobileSheetBody, MobileSheetChrome } from "@/components/shared/mobile-sheet-chrome";
import { Field, FieldLabel } from "@/components/ui/field";
import { Textarea } from "@/components/ui/textarea";

type PurchaseRequestCommentSheetProps = {
  open: boolean;
  title: string;
  description: string;
  required?: boolean;
  isSaving?: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (comment: string) => void;
};

/** Причина возврата заявки или счетов (телефон). */
export function PurchaseRequestCommentSheet({
  open,
  title,
  description,
  required = false,
  isSaving = false,
  onOpenChange,
  onSubmit,
}: PurchaseRequestCommentSheetProps) {
  return (
    <MobileSheet open={open} onOpenChange={onOpenChange}>
      {open ? (
        <CommentForm
          title={title}
          description={description}
          required={required}
          isSaving={isSaving}
          onSubmit={onSubmit}
        />
      ) : null}
    </MobileSheet>
  );
}

function CommentForm({
  title,
  description,
  required,
  isSaving,
  onSubmit,
}: {
  title: string;
  description: string;
  required: boolean;
  isSaving: boolean;
  onSubmit: (comment: string) => void;
}) {
  const [comment, setComment] = useState("");

  return (
    <>
      <MobileSheetChrome
        title={title}
        description={description}
        confirmLabel="Подтвердить"
        confirmDisabled={isSaving || (required && !comment.trim())}
        confirmPending={isSaving}
        confirmShowLabelWhenEnabled
        onConfirm={() => onSubmit(comment.trim())}
      />
      <MobileSheetBody>
        <Field>
          <FieldLabel htmlFor="purchase-request-mobile-comment">
            Комментарий
          </FieldLabel>
          <Textarea
            id="purchase-request-mobile-comment"
            value={comment}
            rows={4}
            onChange={(event) => setComment(event.target.value)}
          />
        </Field>
      </MobileSheetBody>
    </>
  );
}
