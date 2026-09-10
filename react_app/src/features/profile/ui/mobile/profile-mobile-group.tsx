"use client";

import { ChevronRightIcon } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { Children, Fragment, type ReactNode } from "react";

import { Separator } from "@/components/ui/separator";
import { cn } from "@/lib/utils";

type ProfileMobileGroupProps = {
  children: ReactNode;
};

export function ProfileMobileGroup({ children }: ProfileMobileGroupProps) {
  const items = Children.toArray(children).filter(Boolean);

  return (
    <div className="overflow-hidden rounded-2xl bg-card ring-1 ring-foreground/10">
      {items.map((child, index) => (
        <Fragment key={index}>
          {index > 0 ? <Separator /> : null}
          {child}
        </Fragment>
      ))}
    </div>
  );
}

type ProfileMobileRowProps = {
  icon: LucideIcon;
  title: string;
  subtitle?: string;
  onClick?: () => void;
  trailing?: ReactNode;
  destructive?: boolean;
};

export function ProfileMobileRow({
  icon: Icon,
  title,
  subtitle,
  onClick,
  trailing,
  destructive = false,
}: ProfileMobileRowProps) {
  const content = (
    <>
      <span
        className={cn(
          "flex size-9 shrink-0 items-center justify-center rounded-full",
          destructive ? "bg-destructive/10 text-destructive" : "bg-muted text-foreground"
        )}
      >
        <Icon />
      </span>
      <span className="min-w-0 flex-1">
        <span
          className={cn(
            "block text-sm font-medium",
            destructive ? "text-destructive" : "text-foreground"
          )}
        >
          {title}
        </span>
        {subtitle ? (
          <span className="mt-0.5 block truncate text-xs text-muted-foreground">
            {subtitle}
          </span>
        ) : null}
      </span>
      {trailing ??
        (onClick ? (
          <ChevronRightIcon className="size-4 shrink-0 text-muted-foreground" />
        ) : null)}
    </>
  );

  if (onClick) {
    return (
      <button
        type="button"
        className="flex min-h-11 w-full items-center gap-3 px-3 py-2.5 text-left active:bg-muted/70"
        onClick={onClick}
      >
        {content}
      </button>
    );
  }

  return (
    <div className="flex min-h-11 w-full items-center gap-3 px-3 py-2.5">
      {content}
    </div>
  );
}
