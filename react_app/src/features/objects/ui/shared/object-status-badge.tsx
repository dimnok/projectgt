"use client";

import { Badge } from "@/components/ui/badge";
import {
  objectStatusLabel,
  type ObjectStatus,
} from "@/features/objects/utils/object-status";

const statusVariant: Record<
  ObjectStatus,
  "success" | "destructive" | "warning"
> = {
  active: "success",
  paused: "destructive",
  completed: "warning",
};

type ObjectStatusBadgeProps = {
  status: ObjectStatus;
};

export function ObjectStatusBadge({ status }: ObjectStatusBadgeProps) {
  return (
    <Badge variant={statusVariant[status]}>{objectStatusLabel(status)}</Badge>
  );
}
