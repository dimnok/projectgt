import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { assertCanWriteWorkItems } from "@/features/works/api/get-work-membership";
import { getWorkHours } from "@/features/works/api/get-work-hours";
import { getWorkItems } from "@/features/works/api/get-work-items";
import { mapWorkRow, WORK_SELECT } from "@/features/works/api/get-month-works";
import type { Work, WorksRow } from "@/features/works/types/work.types";
import { getWorkCloseChecks } from "@/features/works/utils/work.utils";

/**
 * Closes a shift. Same checks as Flutter `WorkValidationBlock`.
 * Telegram close is enqueued by DB trigger; client kicks the worker.
 */
export async function closeWork(workId: string): Promise<Work> {
  await assertCanWriteWorkItems(workId);

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { data: row, error: fetchError } = await client
    .from("works")
    .select(WORK_SELECT)
    .eq("id", workId)
    .eq("company_id", companyId)
    .maybeSingle();

  if (fetchError) {
    throw new Error(fetchError.message);
  }
  if (!row) {
    throw new Error("Смена не найдена");
  }

  const work = mapWorkRow(row as unknown as WorksRow);
  const [items, hours] = await Promise.all([
    getWorkItems(workId),
    getWorkHours(workId),
  ]);
  const { ready, message } = getWorkCloseChecks(work, items, hours);
  if (!ready) {
    throw new Error(message ?? "Смену ещё нельзя закрыть");
  }

  const { data, error } = await client
    .from("works")
    .update({
      status: "closed",
      updated_at: new Date().toISOString(),
    })
    .eq("id", workId)
    .eq("company_id", companyId)
    .select(WORK_SELECT)
    .single();

  if (error) {
    throw new Error(error.message);
  }

  const closed = mapWorkRow(data as unknown as WorksRow);

  try {
    void client.functions.invoke("process_telegram_outbox");
  } catch {
    // Same as Flutter: do not block close.
  }

  try {
    await client.functions.invoke("send_admin_work_event", {
      body: {
        action: "close",
        work_id: workId,
        notify_all: false,
      },
    });
  } catch {
    // Same as Flutter: push must not block close.
  }

  return closed;
}
