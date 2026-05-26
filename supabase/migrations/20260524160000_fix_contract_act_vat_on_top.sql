-- Акты КС-2: сумма строк — без НДС, НДС начисляется сверху (исправление ошибочного split «включён в сумму»).

BEGIN;

UPDATE public.contract_acts ca
SET
    amount = ca.amount + COALESCE(ca.vat_amount, 0),
    vat_amount = ROUND(
        (ca.amount + COALESCE(ca.vat_amount, 0)) * c.vat_rate / 100,
        2
    )
FROM public.contracts c
WHERE ca.contract_id = c.id
  AND ca.company_id = c.company_id
  AND ca.act_kind = 'ks2'
  AND c.vat_rate > 0
  AND (ca.amount + COALESCE(ca.vat_amount, 0)) > 0;

COMMIT;
