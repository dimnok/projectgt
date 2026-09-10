"use client";

import { PencilIcon, Trash2Icon, type LucideIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import type { SiteObject } from "@/features/objects/types/object.types";

type ObjectDetailsProps = {
  object: SiteObject;
  canUpdate: boolean;
  canDelete: boolean;
  onEdit: () => void;
  onDelete: () => void;
};

function Detail({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex flex-col gap-1">
      <p className="text-xs text-muted-foreground">{label}</p>
      <p className="text-sm">{value.trim() ? value : "—"}</p>
    </div>
  );
}

function ActionButton({
  label,
  variant,
  icon: Icon,
  onClick,
}: {
  label: string;
  variant: "outline" | "destructive";
  icon: LucideIcon;
  onClick: () => void;
}) {
  return (
    <Tooltip>
      <TooltipTrigger
        render={
          <Button
            type="button"
            variant={variant}
            size="icon"
            className="@4xl:h-8 @4xl:w-auto @4xl:gap-1.5 @4xl:px-2.5"
            aria-label={label}
            onClick={onClick}
          />
        }
      >
        <Icon data-icon="inline-start" />
        <span className="hidden @4xl:inline">{label}</span>
      </TooltipTrigger>
      <TooltipContent>{label}</TooltipContent>
    </Tooltip>
  );
}

export function ObjectDetails({
  object,
  canUpdate,
  canDelete,
  onEdit,
  onDelete,
}: ObjectDetailsProps) {
  return (
    <div className="@container flex flex-col gap-4 border-t px-(--card-spacing) py-(--card-spacing)">
      <div className="grid gap-4 @4xl:grid-cols-3">
        <Detail label="Название" value={object.name} />
        <Detail label="Адрес" value={object.address} />
        <Detail label="Описание" value={object.description ?? ""} />
      </div>
      {canUpdate || canDelete ? (
        <div className="flex flex-wrap justify-end gap-2">
          {canUpdate ? (
            <ActionButton
              label="Изменить"
              variant="outline"
              icon={PencilIcon}
              onClick={onEdit}
            />
          ) : null}
          {canDelete ? (
            <ActionButton
              label="Удалить"
              variant="destructive"
              icon={Trash2Icon}
              onClick={onDelete}
            />
          ) : null}
        </div>
      ) : null}
    </div>
  );
}
