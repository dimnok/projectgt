import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";

/**
 * Current user and whether they have system role «Супер-админ».
 * Closed shifts may be edited only by that role.
 */
export async function getWorkMembership(): Promise<{
  userId: string;
  isSuperAdmin: boolean;
}> {
  const client = getRequiredClient();
  const {
    data: { user },
    error: userError,
  } = await client.auth.getUser();

  if (userError || !user) {
    throw new Error("Нужно войти в аккаунт");
  }

  const { data, error } = await client.rpc("is_super_admin", {
    user_id: user.id,
  });

  if (error) {
    throw new Error(error.message);
  }

  return {
    userId: user.id,
    isSuperAdmin: data === true,
  };
}

/**
 * Blocks writes unless the user may change this shift.
 * Super-admin: any status. Everyone else: only own open shift.
 */
export async function assertCanWriteWorkItems(workId: string): Promise<void> {
  if (!workId) {
    throw new Error("Не указана смена");
  }

  const client = getRequiredClient();
  const {
    data: { user },
    error: userError,
  } = await client.auth.getUser();

  if (userError || !user) {
    throw new Error("Нужно войти в аккаунт");
  }

  const companyId = await getActiveCompanyId();
  const { data: isSuperAdmin, error: rpcError } = await client.rpc(
    "is_super_admin",
    { user_id: user.id }
  );

  if (rpcError) {
    throw new Error(rpcError.message);
  }

  const { data: work, error } = await client
    .from("works")
    .select("status, opened_by")
    .eq("id", workId)
    .eq("company_id", companyId)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }
  if (!work) {
    throw new Error("Смена не найдена");
  }

  if (isSuperAdmin === true) {
    return;
  }

  if (String(work.status).toLowerCase() === "closed") {
    throw new Error("Закрытую смену нельзя изменять");
  }

  if (work.opened_by !== user.id) {
    throw new Error("Изменять смену может только тот, кто её открыл");
  }
}

/**
 * Super-admin only: reopen or delete a shift of any status.
 */
export async function assertIsSuperAdmin(): Promise<void> {
  const client = getRequiredClient();
  const {
    data: { user },
    error: userError,
  } = await client.auth.getUser();

  if (userError || !user) {
    throw new Error("Нужно войти в аккаунт");
  }

  const { data, error } = await client.rpc("is_super_admin", {
    user_id: user.id,
  });

  if (error) {
    throw new Error(error.message);
  }
  if (data !== true) {
    throw new Error("Это действие доступно только супер-админу");
  }
}
