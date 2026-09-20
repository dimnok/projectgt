"use client";

import { useState } from "react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Field, FieldLabel } from "@/components/ui/field";
import { Spinner } from "@/components/ui/spinner";
import { Textarea } from "@/components/ui/textarea";

type CommentDialogProps = {
  open: boolean;
  title: string;
  description: string;
  required?: boolean;
  isSaving?: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (comment: string) => void;
};

export function PurchaseRequestCommentDialog({
  open,
  title,
  description,
  required = false,
  isSaving = false,
  onOpenChange,
  onSubmit,
}: CommentDialogProps) {
  const [comment, setComment] = useState("");

  return (
    <Dialog
      open={open}
      onOpenChange={(next) => {
        if (!next) {
          setComment("");
        }
        onOpenChange(next);
      }}
    >
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
          <DialogDescription>{description}</DialogDescription>
        </DialogHeader>
        <Field>
          <FieldLabel htmlFor="purchase-request-comment">Комментарий</FieldLabel>
          <Textarea
            id="purchase-request-comment"
            value={comment}
            onChange={(event) => setComment(event.target.value)}
            rows={4}
          />
        </Field>
        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            disabled={isSaving}
            onClick={() => onOpenChange(false)}
          >
            Отмена
          </Button>
          <Button
            type="button"
            disabled={isSaving || (required && !comment.trim())}
            onClick={() => onSubmit(comment.trim())}
          >
            {isSaving ? <Spinner data-icon="inline-start" /> : null}
            Подтвердить
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
