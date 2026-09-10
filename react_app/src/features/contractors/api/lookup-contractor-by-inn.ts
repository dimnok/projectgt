import { getRequiredClient } from "@/lib/supabase/client";
import type { ContractorInnLookup } from "@/features/contractors/types/contractor.types";
import {
  digitsInn,
  isValidInn,
} from "@/features/contractors/utils/contractor.utils";

function asText(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed ? trimmed : null;
}

function parseLookup(data: unknown): ContractorInnLookup | null {
  if (!data || typeof data !== "object") {
    return null;
  }

  const row = data as Record<string, unknown>;
  if (row.success === false) {
    return null;
  }

  return {
    nameFull: asText(row.nameFull),
    nameShort: asText(row.nameShort),
    kpp: asText(row.kpp),
    ogrn: asText(row.ogrn),
    okpo: asText(row.okpo),
    legalAddress: asText(row.legalAddress),
    directorName: asText(row.directorName),
    activityDescription: asText(row.activityDescription),
    email: asText(row.email),
    phone: asText(row.phone),
  };
}

/**
 * Loads company details by INN through Edge Function `dadata-proxy`.
 * Does not call DaData from the browser.
 */
export async function lookupContractorByInn(
  inn: string,
  signal?: AbortSignal
): Promise<ContractorInnLookup> {
  const normalized = digitsInn(inn);
  if (!isValidInn(normalized)) {
    throw new Error("ИНН должен содержать 10 или 12 цифр");
  }

  const { data, error } = await getRequiredClient().functions.invoke(
    "dadata-proxy",
    {
      body: { inn: normalized },
      signal,
    }
  );

  if (error) {
    if (signal?.aborted) {
      throw error;
    }
    throw new Error("Не удалось загрузить данные по ИНН");
  }

  const lookup = parseLookup(data);
  if (!lookup) {
    throw new Error("Организация не найдена");
  }

  return lookup;
}
