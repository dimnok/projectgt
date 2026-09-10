import type { WorkStatus } from "@/features/works/types/work.types";

export const WORK_STATUS_LABEL: Record<WorkStatus, string> = {
  open: "Открыта",
  closed: "Закрыта",
};

export function workStatusLabel(status: WorkStatus): string {
  return WORK_STATUS_LABEL[status];
}
