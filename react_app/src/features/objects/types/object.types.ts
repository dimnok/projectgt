import type { ObjectStatus } from "@/features/objects/utils/object-status";

export type SiteObject = {
  id: string;
  companyId: string;
  name: string;
  address: string;
  description: string | null;
  status: ObjectStatus;
};

export type ObjectDraft = {
  name: string;
  address: string;
  description: string;
  status: ObjectStatus;
};

export type ObjectFilters = {
  search: string;
  status: ObjectStatus | "all";
};
