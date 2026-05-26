-- Пересчёт НДС в актах КС-2 по настройкам договора (ранее vat_amount = 0).

BEGIN;

UPDATE public.contract_acts ca
SET
    vat_amount = CASE
        WHEN c.is_vat_included THEN
            ROUND(ca.amount * c.vat_rate / (100 + c.vat_rate), 2)
        ELSE
            ROUND(ca.amount * c.vat_rate / 100, 2)
    END,
    amount = CASE
        WHEN c.is_vat_included THEN
            ROUND(
                ca.amount - ROUND(ca.amount * c.vat_rate / (100 + c.vat_rate), 2),
                2
            )
        ELSE
            ca.amount
    END
FROM public.contracts c
WHERE ca.contract_id = c.id
  AND ca.company_id = c.company_id
  AND ca.act_kind = 'ks2'
  AND ca.vat_amount = 0
  AND c.vat_rate > 0
  AND ca.amount > 0;

COMMIT;
