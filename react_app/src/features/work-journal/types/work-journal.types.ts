export const WORK_JOURNAL_PAGE_SIZE = 250;

export type WorkJournalDateRange = {
  from: string;
  to: string;
};

export type WorkJournalFilters = {
  objectId: string | null;
  dateRange: WorkJournalDateRange | null;
  searchQuery: string;
  systems: string[];
  sections: string[];
  floors: string[];
};

export type WorkJournalFilterValues = {
  systems: string[];
  sections: string[];
  floors: string[];
};

export type WorkJournalRow = {
  workItemId: string;
  workId: string | null;
  workDate: string;
  objectId: string | null;
  objectName: string;
  workStatus: string | null;
  system: string;
  subsystem: string;
  section: string;
  floor: string;
  workName: string;
  unit: string;
  quantity: number;
  estimateId: string | null;
  price: number | null;
  total: number | null;
  positionNumber: string | null;
  contractNumber: string | null;
  m15Name: string | null;
};

export type WorkJournalPage = {
  items: WorkJournalRow[];
  totalCount: number;
  totalQuantity: number;
  totalSum: number;
  currentPage: number;
  pageSize: number;
  totalPages: number;
};

export type WorkJournalSearchParams = {
  objectId: string;
  startDate?: string | null;
  endDate?: string | null;
  searchQuery?: string | null;
  systemFilters?: string[];
  sectionFilters?: string[];
  floorFilters?: string[];
  page: number;
  pageSize?: number;
};
