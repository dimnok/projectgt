"use client";

import { useRef, useState } from "react";
import { Maximize2Icon, Minimize2Icon, XIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { ContractDetailsTabs } from "@/features/contracts/ui/shared/contract-details-tabs";
import { ContractKindBadge } from "@/features/contracts/ui/shared/contract-kind-badge";
import { ContractStatusBadge } from "@/features/contracts/ui/shared/contract-status-badge";
import type { Contract } from "@/features/contracts/types/contract.types";
import { cn } from "@/lib/utils";

type ContractDetailsDialogProps = {
  contract: Contract | null;
  canUpdate: boolean;
  canDelete: boolean;
  onOpenChange: (open: boolean) => void;
  onEdit: () => void;
  onDelete: () => void;
};

export function ContractDetailsDialog({
  contract,
  canUpdate,
  canDelete,
  onOpenChange,
  onEdit,
  onDelete,
}: ContractDetailsDialogProps) {
  const [isMaximized, setIsMaximized] = useState(false);
  const [customSize, setCustomSize] = useState<{ width: number; height: number } | null>(null);
  const dialogRef = useRef<HTMLDivElement | null>(null);

  const parties = contract
    ? [contract.contractorName, contract.objectName].filter(Boolean).join(" · ")
    : "";

  function handleOpenChangeInternal(open: boolean) {
    if (!open) {
      setIsMaximized(false);
      setCustomSize(null);
    }
    onOpenChange(open);
  }

  function toggleMaximize() {
    setIsMaximized((prev) => !prev);
  }

  function startResize(e: React.MouseEvent) {
    e.preventDefault();
    e.stopPropagation();

    const dialogEl = dialogRef.current;
    if (!dialogEl) return;

    if (isMaximized) {
      setIsMaximized(false);
    }

    const startRect = dialogEl.getBoundingClientRect();
    const startX = e.clientX;
    const startY = e.clientY;

    function onPointerMove(moveEvent: MouseEvent) {
      const deltaX = (moveEvent.clientX - startX) * 2;
      const deltaY = (moveEvent.clientY - startY) * 2;

      const minW = Math.min(680, window.innerWidth * 0.95);
      const maxW = window.innerWidth * 0.98;
      const minH = Math.min(480, window.innerHeight * 0.85);
      const maxH = window.innerHeight * 0.98;

      const newWidth = Math.max(minW, Math.min(maxW, startRect.width + deltaX));
      const newHeight = Math.max(minH, Math.min(maxH, startRect.height + deltaY));

      setCustomSize({ width: newWidth, height: newHeight });
    }

    function onPointerUp() {
      window.removeEventListener("mousemove", onPointerMove);
      window.removeEventListener("mouseup", onPointerUp);
    }

    window.addEventListener("mousemove", onPointerMove);
    window.addEventListener("mouseup", onPointerUp);
  }

  return (
    <Dialog
      open={Boolean(contract)}
      onOpenChange={handleOpenChangeInternal}
      disablePointerDismissal
    >
      <DialogContent
        ref={dialogRef}
        showCloseButton={false}
        className={cn(
          "flex flex-col overflow-hidden transition-[width,height] duration-150 ease-out",
          isMaximized
            ? "!h-[97vh] !max-h-[97vh] !w-[98vw] !max-w-[98vw] sm:!max-w-[98vw]"
            : customSize
              ? "!max-w-[98vw] sm:!max-w-[98vw]"
              : "h-[min(82vh,54rem)] w-[min(90vw,85rem)] sm:max-w-[min(90vw,85rem)]"
        )}
        style={
          !isMaximized && customSize
            ? {
                width: `${customSize.width}px`,
                height: `${customSize.height}px`,
              }
            : undefined
        }
      >
        {/* Кнопки управления окном: Развернуть / Восстановить + Закрыть */}
        <div className="absolute top-2.5 right-2.5 z-20 flex items-center gap-1">
          <Button
            type="button"
            variant="ghost"
            size="icon-sm"
            onClick={toggleMaximize}
            className="text-muted-foreground hover:text-foreground cursor-pointer"
            title={isMaximized ? "Восстановить размер" : "Развернуть на весь экран"}
            aria-label={isMaximized ? "Восстановить размер" : "Развернуть на весь экран"}
          >
            {isMaximized ? (
              <Minimize2Icon className="size-4" />
            ) : (
              <Maximize2Icon className="size-4" />
            )}
          </Button>

          <DialogClose
            render={
              <Button
                type="button"
                variant="ghost"
                size="icon-sm"
                className="text-muted-foreground hover:text-foreground cursor-pointer"
                title="Закрыть"
                aria-label="Закрыть"
              />
            }
          >
            <XIcon className="size-4" />
          </DialogClose>
        </div>

        <DialogHeader className="shrink-0 pr-20">
          <DialogTitle>
            {contract ? `Договор № ${contract.number}` : "Договор"}
          </DialogTitle>
          <DialogDescription>
            {parties || "Карточка договора"}
          </DialogDescription>
          {contract ? (
            <div className="flex flex-wrap items-center gap-2">
              <ContractKindBadge kind={contract.kind} />
              <ContractStatusBadge status={contract.status} />
            </div>
          ) : null}
        </DialogHeader>
        {contract ? (
          <ContractDetailsTabs
            contract={contract}
            canUpdate={canUpdate}
            canDelete={canDelete}
            onEdit={onEdit}
            onDelete={onDelete}
          />
        ) : null}
        <DialogFooter className="relative shrink-0 sm:justify-start">
          <DialogClose render={<Button type="button" variant="outline" />}>
            Закрыть
          </DialogClose>

          {/* Индикатор ручного изменения размера мышкой */}
          <div
            onMouseDown={startResize}
            title="Потяните для изменения размера окна"
            className="absolute bottom-0 right-0 z-20 flex size-5 cursor-nwse-resize items-center justify-center p-0.5 text-muted-foreground/50 hover:text-foreground select-none"
          >
            <svg
              className="size-3"
              viewBox="0 0 12 12"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.5"
            >
              <line x1="10" y1="2" x2="2" y2="10" />
              <line x1="10" y1="6" x2="6" y2="10" />
              <line x1="10" y1="10" x2="10" y2="10" />
            </svg>
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
