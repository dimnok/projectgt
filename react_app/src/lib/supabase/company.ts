import { getRequiredClient } from "@/lib/supabase/client";

/**
 * Общий запрос на время выполнения: пока он в полёте, повторные вызовы
 * получают тот же результат и не дублируют обращения к базе. После
 * завершения запрос сбрасывается — значение всегда актуальное и не
 * «залипает» при смене активной компании.
 */
let activeCompanyRequest: Promise<string> | null = null;

/**
 * Reads the active company from the signed-in user's profile.
 * Matches Flutter's `activeCompanyIdProvider` (`profiles.last_company_id`).
 */
export function getActiveCompanyId(): Promise<string> {
  if (activeCompanyRequest) {
    return activeCompanyRequest;
  }

  const request = fetchActiveCompanyId();
  activeCompanyRequest = request;
  void request.then(
    () => {
      activeCompanyRequest = null;
    },
    () => {
      activeCompanyRequest = null;
    }
  );
  return request;
}

async function fetchActiveCompanyId(): Promise<string> {
  const client = getRequiredClient();
  const {
    data: { user },
    error: userError,
  } = await client.auth.getUser();

  if (userError || !user) {
    throw new Error("Нужно войти в аккаунт");
  }

  const { data, error } = await client
    .from("profiles")
    .select("last_company_id")
    .eq("id", user.id)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }

  const companyId = data?.last_company_id;
  if (typeof companyId !== "string" || !companyId) {
    throw new Error("Активная компания не выбрана");
  }

  return companyId;
}
