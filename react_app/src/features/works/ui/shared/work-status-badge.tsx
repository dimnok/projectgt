"use client";

import { Badge } from "@/components/ui/badge";
import type { WorkStatus } from "@/features/works/types/work.types";
import { workStatusLabel } from "@/features/works/utils/work-status";

const statusVariant: Record<WorkStatus, "success" | "secondary"> = {
  open: "success",
  closed: "secondary",
};

type WorkStatusBadgeProps = {
  status: WorkStatus;
};

export function WorkStatusBadge({ status }: WorkStatusBadgeProps) {
  return <Badge variant={statusVariant[status]}>{workStatusLabel(status)}</Badge>;
}
