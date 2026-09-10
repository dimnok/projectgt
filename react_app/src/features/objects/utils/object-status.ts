export const OBJECT_STATUSES = ["active", "paused", "completed"] as const;

export type ObjectStatus = (typeof OBJECT_STATUSES)[number];

const OBJECT_STATUS_LABELS: Record<ObjectStatus, string> = {
  active: "Активный",
  paused: "Приостановлен",
  completed: "Завершён",
};

export const OBJECT_STATUS_OPTIONS = OBJECT_STATUSES.map((value) => ({
  value,
  label: OBJECT_STATUS_LABELS[value],
}));

export function isObjectStatus(value: unknown): value is ObjectStatus {
  return OBJECT_STATUSES.includes(value as ObjectStatus);
}

export function objectStatusLabel(status: ObjectStatus): string {
  return OBJECT_STATUS_LABELS[status];
}

export const OBJECT_STATUS_RING_CLASS: Record<ObjectStatus, string> = {
  active: "ring-2 ring-inset ring-success",
  paused: "ring-2 ring-inset ring-destructive",
  completed: "ring-2 ring-inset ring-warning",
};

export const OBJECT_STATUS_HEADER_CLASS: Record<ObjectStatus, string> = {
  active: "bg-success/10 hover:bg-success/15",
  paused: "bg-destructive/10 hover:bg-destructive/15",
  completed: "bg-warning/10 hover:bg-warning/15",
};

