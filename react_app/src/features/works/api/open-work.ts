import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { getMyOpenWorkId } from "@/features/works/api/get-open-work-context";
import { mapWorkRow } from "@/features/works/api/get-month-works";
import { uploadWorkMorningPhoto } from "@/features/works/api/upload-work-morning-photo";
import { composeWorkPhotoCollage } from "@/features/works/utils/compose-work-photo-collage";
import { employeeFullName } from "@/features/employees/utils/employee.utils";
import type { Employee } from "@/features/employees/types/employee.types";
import type { Work, WorksRow } from "@/features/works/types/work.types";
import { toDateKey } from "@/features/works/utils/work.utils";
import { createId } from "@/lib/utils";

const WORK_SELECT = [
  "id",
  "company_id",
  "date",
  "object_id",
  "opened_by",
  "status",
  "photo_url",
  "evening_photo_url",
  "total_amount",
  "own_total_amount",
  "items_count",
  "employees_count",
  "objects!object_id(name)",
  "profiles!opened_by(short_name, full_name)",
].join(", ");

export type OpenWorkDraft = {
  objectId: string;
  employeeIds: string[];
  photos: File[];
  employees: Employee[];
};

/**
 * Opens a shift: morning photo, `works` row, `work_hours` with 0 hours.
 * Then Telegram outbox and admin push — same as Flutter `_saveWork`.
 * Local phone reminders are not scheduled in the web app.
 */
export async function openWork(draft: OpenWorkDraft): Promise<Work> {
  if (!draft.objectId) {
    throw new Error("Выберите объект");
  }
  if (draft.employeeIds.length === 0) {
    throw new Error("Выберите хотя бы одного сотрудника");
  }
  if (draft.photos.length === 0) {
    throw new Error("Добавьте фото смены");
  }
  if (draft.photos.length > 4) {
    throw new Error("Можно приложить не больше 4 фото");
  }

  const existing = await getMyOpenWorkId();
  if (existing) {
    throw new Error(
      "У вас уже есть открытая смена. Закройте её перед открытием новой."
    );
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const {
    data: { user },
    error: userError,
  } = await client.auth.getUser();

  if (userError || !user) {
    throw new Error("Нужно войти в аккаунт");
  }

  const morningFile =
    draft.photos.length === 1
      ? draft.photos[0]
      : await composeWorkPhotoCollage(draft.photos);
  const photoUrl = await uploadWorkMorningPhoto(draft.objectId, morningFile);
  const today = toDateKey(new Date());
  const now = new Date().toISOString();

  const { data: inserted, error: insertError } = await client
    .from("works")
    .insert({
      company_id: companyId,
      date: today,
      object_id: draft.objectId,
      opened_by: user.id,
      status: "open",
      photo_url: photoUrl,
      evening_photo_url: null,
      created_at: now,
      updated_at: now,
      total_amount: 0,
      own_total_amount: 0,
      items_count: 0,
      employees_count: 0,
    })
    .select(WORK_SELECT)
    .single();

  if (insertError) {
    throw new Error(insertError.message);
  }

  const work = mapWorkRow(inserted as unknown as WorksRow);

  const hourRows = draft.employeeIds.map((employeeId) => ({
    id: createId(),
    company_id: companyId,
    work_id: work.id,
    employee_id: employeeId,
    hours: 0,
    comment: null,
    created_at: now,
    updated_at: now,
  }));

  const { error: hoursError } = await client.from("work_hours").insert(hourRows);
  if (hoursError) {
    throw new Error(hoursError.message);
  }

  const workerNames = draft.employeeIds
    .map((id) => {
      const employee = draft.employees.find((item) => item.id === id);
      return employee ? employeeFullName(employee) : "";
    })
    .filter(Boolean);

  try {
    await client.rpc("enqueue_telegram_outbox_opening", {
      p_work_id: work.id,
      p_worker_names: workerNames,
    });
    void client.functions.invoke("process_telegram_outbox");
  } catch {
    // Same as Flutter: Telegram must not block opening the shift.
  }

  try {
    await client.functions.invoke("send_admin_work_event", {
      body: {
        action: "open",
        work_id: work.id,
        notify_all: false,
      },
    });
  } catch {
    // Same as Flutter: push must not block opening the shift.
  }

  return work;
}
