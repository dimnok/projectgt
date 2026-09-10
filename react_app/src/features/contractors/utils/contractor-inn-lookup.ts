import type {
  ContractorDraft,
  ContractorInnLookup,
} from "@/features/contractors/types/contractor.types";
import { okvedInputValue } from "@/lib/okved/okved";
import { formatPhoneInput } from "@/lib/utils/phone";

function keep(next: string | null, current: string): string {
  return next ?? current;
}

/**
 * Fills the form from a DaData lookup.
 * Empty lookup fields are left unchanged. Legal address is copied
 * to the actual address, matching Flutter. OKVED is stored as a code.
 */
export function applyInnLookupToDraft(
  draft: ContractorDraft,
  lookup: ContractorInnLookup
): ContractorDraft {
  const legalAddress = lookup.legalAddress;
  const phone = lookup.phone ? formatPhoneInput(lookup.phone) : "";
  const activityDescription = lookup.activityDescription
    ? okvedInputValue(lookup.activityDescription)
    : "";

  return {
    ...draft,
    fullName: keep(lookup.nameFull, draft.fullName),
    shortName: keep(lookup.nameShort, draft.shortName),
    kpp: keep(lookup.kpp, draft.kpp),
    ogrn: keep(lookup.ogrn, draft.ogrn),
    okpo: keep(lookup.okpo, draft.okpo),
    legalAddress: keep(legalAddress, draft.legalAddress),
    actualAddress: keep(legalAddress, draft.actualAddress),
    director: keep(lookup.directorName, draft.director),
    activityDescription: activityDescription || draft.activityDescription,
    email: keep(lookup.email, draft.email),
    phone: phone || draft.phone,
  };
}
