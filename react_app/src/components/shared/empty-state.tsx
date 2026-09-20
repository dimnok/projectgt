import type { LucideIcon } from "lucide-react";
import type { ReactNode } from "react";
import { InboxIcon } from "lucide-react";

import {
  Empty,
  EmptyContent,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty";

type EmptyStateProps = {
  title: string;
  description: string;
  icon?: LucideIcon;
  /** Кнопка под текстом: что сделать дальше. */
  action?: ReactNode;
};

export function EmptyState({
  title,
  description,
  icon: Icon = InboxIcon,
  action,
}: EmptyStateProps) {
  return (
    <Empty className="border border-dashed bg-muted/20">
      <EmptyHeader>
        <EmptyMedia variant="icon">
          <Icon />
        </EmptyMedia>
        <EmptyTitle>{title}</EmptyTitle>
        <EmptyDescription>{description}</EmptyDescription>
      </EmptyHeader>
      {action ? <EmptyContent>{action}</EmptyContent> : null}
    </Empty>
  );
}
