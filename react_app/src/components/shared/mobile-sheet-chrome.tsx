"use client";

import { CheckIcon, XIcon } from "lucide-react";
import type { ReactNode } from "react";

import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetClose,
  SheetContent,
  SheetDescription,
  SheetTitle,
} from "@/components/ui/sheet";
import { Spinner } from "@/components/ui/spinner";

const MOBILE_SHEET_CONTENT_CLASS =
  "max-h-[calc(100dvh-4.5rem)] w-full gap-0 overflow-hidden rounded-t-[28px] border-0 bg-background p-0 pb-[env(safe-area-inset-bottom)] shadow-[0_-8px_40px_rgba(0,0,0,0.18)] data-[side=bottom]:h-auto data-[side=bottom]:max-h-[calc(100dvh-4.5rem)] data-[side=bottom]:border-t-0";

type MobileSheetProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  children: ReactNode;
};

export function MobileSheet({
  open,
  onOpenChange,
  children,
}: MobileSheetProps) {
  return (
    <Sheet
      open={open}
      onOpenChange={(next, details) => {
        if (
          !next &&
          details.reason === "outside-press" &&
          details.event.target instanceof Element &&
          details.event.target.closest("[data-slot=select-content]")
        ) {
          details.cancel();
          return;
        }
        onOpenChange(next);
      }}
    >
      <SheetContent
        side="bottom"
        showCloseButton={false}
        overlayClassName="bg-black/40 backdrop-blur-none"
        className={MOBILE_SHEET_CONTENT_CLASS}
      >
        {children}
      </SheetContent>
    </Sheet>
  );
}

type MobileSheetChromeProps = {
  title: string;
  description: string;
  confirmLabel: string;
  closeLabel?: string;
  confirmDisabled?: boolean;
  confirmPending?: boolean;
  /** When the confirm button is enabled, show `confirmLabel` instead of a check icon. */
  confirmShowLabelWhenEnabled?: boolean;
  onConfirm: () => void;
  /** If set, the close button goes back instead of closing the sheet. */
  onClose?: () => void;
};

/**
 * Шапка мобильного окна снизу: полоска, крестик слева, заголовок по центру,
 * круглая кнопка подтверждения справа.
 */
export function MobileSheetChrome({
  title,
  description,
  confirmLabel,
  closeLabel = "Закрыть",
  confirmDisabled = false,
  confirmPending = false,
  confirmShowLabelWhenEnabled = false,
  onConfirm,
  onClose,
}: MobileSheetChromeProps) {
  const showConfirmText =
    confirmShowLabelWhenEnabled && !confirmDisabled && !confirmPending;

  return (
    <div className="relative shrink-0">
      <div className="pointer-events-none absolute inset-x-0 top-1 z-10 flex justify-center">
        <span
          aria-hidden
          className="h-1 w-8 rounded-full bg-muted-foreground/40"
        />
      </div>
      <div className="relative flex items-center px-2.5 pt-2.5 pb-1">
        {onClose ? (
          <Button
            type="button"
            variant="secondary"
            size="icon"
            className="relative z-10 size-10 rounded-full bg-muted text-foreground shadow-none hover:bg-muted/80"
            aria-label={closeLabel}
            onClick={onClose}
          >
            <XIcon className="size-5" />
          </Button>
        ) : (
          <SheetClose
            render={
              <Button
                type="button"
                variant="secondary"
                size="icon"
                className="relative z-10 size-10 rounded-full bg-muted text-foreground shadow-none hover:bg-muted/80"
              />
            }
          >
            <XIcon className="size-5" />
            <span className="sr-only">{closeLabel}</span>
          </SheetClose>
        )}
        <div
          className={
            showConfirmText
              ? "pointer-events-none absolute inset-x-14 right-[5.75rem] flex flex-col items-center justify-center"
              : "pointer-events-none absolute inset-x-14 flex flex-col items-center justify-center"
          }
        >
          <SheetTitle className="truncate text-center text-[17px] font-semibold leading-tight">
            {title}
          </SheetTitle>
          <SheetDescription className="sr-only">{description}</SheetDescription>
        </div>
        <Button
          type="button"
          size={showConfirmText ? "sm" : "icon"}
          className={
            showConfirmText
              ? "relative z-10 ml-auto h-10 min-w-10 rounded-full px-3.5 text-[15px] font-semibold"
              : "relative z-10 ml-auto size-10 rounded-full"
          }
          disabled={confirmDisabled}
          aria-label={confirmLabel}
          onClick={onConfirm}
        >
          {confirmPending ? (
            <Spinner />
          ) : showConfirmText ? (
            confirmLabel
          ) : (
            <CheckIcon className="size-5" />
          )}
        </Button>
      </div>
    </div>
  );
}

type MobileSheetBodyProps = {
  children: ReactNode;
  nested?: boolean;
};

export function MobileSheetBody({
  children,
  nested = false,
}: MobileSheetBodyProps) {
  return (
    <div
      className={
        nested
          ? "flex min-h-0 min-w-0 shrink flex-col overflow-hidden px-4 pt-1 pb-3"
          : "min-h-0 min-w-0 shrink overflow-y-auto overscroll-contain px-4 pt-1 pb-3"
      }
    >
      <div
        className={
          nested
            ? "flex min-h-0 min-w-0 flex-col gap-3"
            : "flex min-w-0 flex-col gap-3"
        }
      >
        {children}
      </div>
    </div>
  );
}
