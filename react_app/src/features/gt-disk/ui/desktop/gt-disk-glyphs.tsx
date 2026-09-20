"use client";

import { useId } from "react";

import { cn } from "@/lib/utils";

type FolderGlyphProps = {
  className?: string;
};

/**
 * Dimensional folder mark for the disk window.
 */
export function GtDiskFolderGlyph({ className }: FolderGlyphProps) {
  const id = useId();
  const bodyId = `${id}-body`;
  const glossId = `${id}-gloss`;

  return (
    <svg
      viewBox="0 0 88 72"
      fill="none"
      aria-hidden
      className={cn("overflow-visible", className)}
    >
      <defs>
        <linearGradient id={bodyId} x1="12" y1="18" x2="76" y2="68">
          <stop offset="0%" stopColor="var(--warning)" stopOpacity="0.95" />
          <stop offset="100%" stopColor="var(--warning)" />
        </linearGradient>
        <linearGradient id={glossId} x1="20" y1="24" x2="20" y2="44">
          <stop offset="0%" stopColor="white" stopOpacity="0.42" />
          <stop offset="100%" stopColor="white" stopOpacity="0" />
        </linearGradient>
      </defs>
      <ellipse
        cx="44"
        cy="66"
        rx="26"
        ry="4"
        className="fill-foreground/10"
      />
      <path
        d="M10 22c0-4.4 3.6-8 8-8h16.2c1.7 0 3.3.8 4.3 2.1l4.2 5.2c1 1.3 2.6 2.1 4.3 2.1H70c4.4 0 8 3.6 8 8v28c0 4.4-3.6 8-8 8H18c-4.4 0-8-3.6-8-8V22Z"
        fill={`url(#${bodyId})`}
      />
      <path
        d="M10 29c0-3.9 3.1-7 7-7h54c3.9 0 7 3.1 7 7v31c0 3.9-3.1 7-7 7H17c-3.9 0-7-3.1-7-7V29Z"
        fill={`url(#${bodyId})`}
      />
      <path
        d="M12 30h64c0-3.3-2.7-6-6-6H18c-3.3 0-6 2.7-6 6Z"
        fill={`url(#${glossId})`}
      />
    </svg>
  );
}

type FileGlyphProps = {
  className?: string;
  label?: string;
};

/**
 * Paper document mark with a type badge.
 */
export function GtDiskFileGlyph({ className, label }: FileGlyphProps) {
  const id = useId();
  const bodyId = `${id}-file`;

  return (
    <span className={cn("relative inline-flex items-end justify-center", className)}>
      <svg viewBox="0 0 52 64" fill="none" aria-hidden className="size-full">
        <defs>
          <linearGradient id={bodyId} x1="8" y1="4" x2="44" y2="60">
            <stop offset="0%" stopColor="var(--card)" />
            <stop offset="100%" stopColor="var(--muted)" />
          </linearGradient>
        </defs>
        <path
          d="M12 6h18l14 14v36c0 2.8-2.2 5-5 5H12c-2.8 0-5-2.2-5-5V11c0-2.8 2.2-5 5-5Z"
          fill={`url(#${bodyId})`}
          className="stroke-foreground/15"
          strokeWidth="1.25"
        />
        <path
          d="M30 6v11c0 2.2 1.8 4 4 4h12"
          className="stroke-foreground/15"
          strokeWidth="1.25"
        />
        <path
          d="M16 34h20M16 41h14"
          className="stroke-foreground/25"
          strokeWidth="1.5"
          strokeLinecap="round"
        />
      </svg>
      {label ? (
        <span className="absolute bottom-1 rounded-full bg-foreground px-1.5 py-0.5 text-[8px] font-semibold tracking-[0.12em] text-background">
          {label}
        </span>
      ) : null}
    </span>
  );
}
