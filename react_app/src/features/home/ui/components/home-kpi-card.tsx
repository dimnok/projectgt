"use client";

import Link from "next/link";
import type { LucideIcon } from "lucide-react";
import type { ReactNode } from "react";

import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";

type HomeKpiCardProps = {
  title: string;
  value: ReactNode;
  subtitle: string;
  icon: LucideIcon;
  badge?: {
    text: string;
    variant?: "default" | "secondary" | "success" | "warning" | "outline";
  };
  href?: string;
  className?: string;
  accent?: "primary" | "success" | "default";
};

export function HomeKpiCard({
  title,
  value,
  subtitle,
  icon: Icon,
  badge,
  href,
  className,
  accent = "default",
}: HomeKpiCardProps) {
  const content = (
    <Card
      className={cn(
        "relative overflow-hidden transition-all duration-200",
        href && "hover:border-foreground/20 hover:shadow-sm cursor-pointer",
        accent === "success" && "border-success/30 bg-success/5",
        accent === "primary" && "border-primary/30 bg-primary/5",
        className
      )}
    >
      <CardContent className="p-4 sm:p-5">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0 flex-1">
            <p className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
              {title}
            </p>
            <div className="mt-1.5 flex items-baseline gap-2">
              <span className="font-heading text-2xl font-semibold tracking-tight sm:text-3xl">
                {value}
              </span>
              {badge ? (
                <Badge variant={badge.variant ?? "default"} className="text-[10px] h-4.5 px-1.5">
                  {badge.text}
                </Badge>
              ) : null}
            </div>
            <p className="mt-1 line-clamp-1 text-xs text-muted-foreground">
              {subtitle}
            </p>
          </div>

          <div
            className={cn(
              "flex size-10 shrink-0 items-center justify-center rounded-xl bg-muted text-foreground transition-colors",
              accent === "success" && "bg-success/15 text-success",
              accent === "primary" && "bg-primary/15 text-primary"
            )}
          >
            <Icon className="size-5" />
          </div>
        </div>
      </CardContent>
    </Card>
  );

  if (href) {
    return (
      <Link href={href} className="block no-underline">
        {content}
      </Link>
    );
  }

  return content;
}
