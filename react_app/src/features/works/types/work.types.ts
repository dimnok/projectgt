export type WorkStatus = "open" | "closed";

export type Work = {
  id: string;
  companyId: string;
  date: string;
  objectId: string;
  objectName: string;
  openedBy: string;
  openedByName: string;
  status: WorkStatus;
  photoUrl: string | null;
  eveningPhotoUrl: string | null;
  totalAmount: number;
  ownTotalAmount: number;
  itemsCount: number;
  employeesCount: number;
};

export type MonthHeader = {
  month: string;
  worksCount: number;
  totalAmount: number;
  ownTotalAmount: number;
};

export type WorkItem = {
  id: string;
  workId: string;
  section: string;
  floor: string;
  system: string;
  subsystem: string;
  estimateId: string;
  number: string | null;
  name: string;
  unit: string;
  quantity: number;
  price: number;
  total: number;
  contractorId: string | null;
  contractorName: string | null;
  specialistsCount: number | null;
  contractActId: string | null;
};

export type WorkHour = {
  id: string;
  workId: string;
  employeeId: string;
  employeeName: string;
  employeePosition: string;
  employeePhotoUrl: string | null;
  hours: number;
  comment: string | null;
};

export type MonthObjectSummary = {
  objectId: string;
  objectName: string;
  worksCount: number;
  totalAmount: number;
  ownTotalAmount: number;
};

export type MonthSystemSummary = {
  system: string;
  worksCount: number;
  itemsCount: number;
  totalAmount: number;
};

export type WorksRow = {
  id: string;
  company_id: string;
  date: string;
  object_id: string;
  opened_by: string;
  status: string;
  photo_url: string | null;
  evening_photo_url: string | null;
  total_amount: number | string | null;
  own_total_amount: number | string | null;
  items_count: number | string | null;
  employees_count: number | string | null;
  objects?: { name: string | null } | { name: string | null }[] | null;
  profiles?:
    | { short_name: string | null; full_name: string | null }
    | { short_name: string | null; full_name: string | null }[]
    | null;
};

export type WorkItemsRow = {
  id: string;
  work_id: string;
  section: string;
  floor: string;
  system: string;
  subsystem: string;
  estimate_id: string;
  name: string;
  unit: string;
  quantity: number | string;
  price: number | string | null;
  total: number | string | null;
  contractor_id: string | null;
  specialists_count: number | string | null;
  contract_act_id: string | null;
  estimates?: { number: string | number | null } | { number: string | number | null }[] | null;
  contractors?:
    | { short_name: string | null; full_name: string | null }
    | { short_name: string | null; full_name: string | null }[]
    | null;
};

export type WorkHoursRow = {
  id: string;
  work_id: string;
  employee_id: string;
  hours: number | string;
  comment: string | null;
  employees?:
    | {
        last_name: string | null;
        first_name: string | null;
        middle_name: string | null;
        position: string | null;
        photo_url: string | null;
      }
    | {
        last_name: string | null;
        first_name: string | null;
        middle_name: string | null;
        position: string | null;
        photo_url: string | null;
      }[]
    | null;
};
