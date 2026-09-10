"use client";

import { useState, type FormEvent } from "react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Field,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Spinner } from "@/components/ui/spinner";
import { Textarea } from "@/components/ui/textarea";

type CreateRoleDialogProps = {
  open: boolean;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (input: { name: string; description: string }) => void;
};

export function CreateRoleDialog({
  open,
  isSaving,
  onOpenChange,
  onSubmit,
}: CreateRoleDialogProps) {
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");

  function handleOpenChange(next: boolean) {
    if (!next) {
      setName("");
      setDescription("");
    }
    onOpenChange(next);
  }

  function handleSubmit(event: FormEvent) {
    event.preventDefault();
    onSubmit({ name, description });
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent>
        <form onSubmit={handleSubmit} className="grid gap-4">
          <DialogHeader>
            <DialogTitle>Новая роль</DialogTitle>
            <DialogDescription>
              Название должно быть уникальным. Права настраиваются после создания.
            </DialogDescription>
          </DialogHeader>
          <FieldGroup>
            <Field>
              <FieldLabel htmlFor="role-name">Название</FieldLabel>
              <Input
                id="role-name"
                value={name}
                onChange={(event) => setName(event.target.value)}
                required
                autoFocus
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="role-description">Описание</FieldLabel>
              <Textarea
                id="role-description"
                value={description}
                onChange={(event) => setDescription(event.target.value)}
                rows={3}
              />
            </Field>
          </FieldGroup>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              disabled={isSaving}
              onClick={() => handleOpenChange(false)}
            >
              Отмена
            </Button>
            <Button type="submit" disabled={isSaving || !name.trim()}>
              {isSaving ? <Spinner data-icon="inline-start" /> : null}
              Создать
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
