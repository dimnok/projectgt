"use client";

import {
  useRef,
  useState,
  type PointerEvent,
  type ReactNode,
} from "react";
import { PencilIcon, Trash2Icon } from "lucide-react";

import { cn } from "@/lib/utils";

const THRESHOLD = 72;
const MAX_OFFSET = 112;
const AXIS_LOCK = 12;
const EDGE_GUARD = 24;

type SwipeEditDeleteRowProps = {
  disabled?: boolean;
  editLabel: string;
  deleteLabel: string;
  onEdit: () => void;
  onDelete: () => void;
  children: ReactNode;
};

export function SwipeEditDeleteRow({
  disabled = false,
  editLabel,
  deleteLabel,
  onEdit,
  onDelete,
  children,
}: SwipeEditDeleteRowProps) {
  const [offset, setOffset] = useState(0);
  const [animating, setAnimating] = useState(false);
  const start = useRef({ x: 0, y: 0 });
  const axis = useRef<"pending" | "h" | "v">("pending");
  const offsetRef = useRef(0);

  function reset(then?: () => void) {
    setAnimating(true);
    offsetRef.current = 0;
    setOffset(0);
    window.setTimeout(() => {
      setAnimating(false);
      then?.();
    }, 180);
  }

  function handlePointerDown(event: PointerEvent<HTMLDivElement>) {
    if (event.pointerType === "mouse" && event.button !== 0) {
      return;
    }
    if (event.clientX < EDGE_GUARD) {
      axis.current = "v";
      return;
    }
    start.current = { x: event.clientX, y: event.clientY };
    axis.current = "pending";
    setAnimating(false);
  }

  function handlePointerMove(event: PointerEvent<HTMLDivElement>) {
    if (axis.current === "v") {
      return;
    }
    const dx = event.clientX - start.current.x;
    const dy = event.clientY - start.current.y;
    if (axis.current === "pending") {
      if (Math.hypot(dx, dy) < AXIS_LOCK) {
        return;
      }
      if (Math.abs(dy) >= Math.abs(dx)) {
        axis.current = "v";
        return;
      }
      axis.current = "h";
      event.currentTarget.setPointerCapture(event.pointerId);
    }
    const next = Math.max(-MAX_OFFSET, Math.min(MAX_OFFSET, dx));
    offsetRef.current = next;
    setOffset(next);
  }

  function handlePointerEnd() {
    if (axis.current !== "h") {
      axis.current = "pending";
      return;
    }
    axis.current = "pending";
    const value = offsetRef.current;
    if (value <= -THRESHOLD) {
      reset(onDelete);
      return;
    }
    if (value >= THRESHOLD) {
      reset(onEdit);
      return;
    }
    reset();
  }

  if (disabled) {
    return children;
  }

  const showActions = offset !== 0 || animating;

  return (
    <div className="relative overflow-hidden rounded-xl shadow-float">
      <div
        aria-hidden
        className={cn("absolute inset-0 flex", !showActions && "hidden")}
      >
        <div className="flex flex-1 items-center justify-start gap-2 bg-muted px-4 text-foreground">
          <PencilIcon className="size-5" />
          <span className="text-xs font-medium">{editLabel}</span>
        </div>
        <div className="flex flex-1 items-center justify-end gap-2 bg-destructive px-4 text-destructive-foreground">
          <span className="text-xs font-medium">{deleteLabel}</span>
          <Trash2Icon className="size-5" />
        </div>
      </div>
      <div
        className={cn(
          "relative rounded-xl bg-card touch-pan-y select-none will-change-transform",
          animating && "transition-transform duration-200 ease-out"
        )}
        style={{ transform: `translate3d(${offset}px, 0, 0)` }}
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerEnd}
        onPointerCancel={handlePointerEnd}
      >
        {children}
      </div>
    </div>
  );
}
