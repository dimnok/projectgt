-- Один ИНН на компанию. Сравнение по цифрам, чтобы «7707 083893» и «7707083893» считались одним значением.
-- Пустой ИНН в уникальность не входит.

CREATE UNIQUE INDEX IF NOT EXISTS contractors_company_id_inn_digits_uidx
  ON public.contractors (company_id, (regexp_replace(inn, '\D', '', 'g')))
  WHERE regexp_replace(inn, '\D', '', 'g') <> '';

COMMENT ON INDEX public.contractors_company_id_inn_digits_uidx IS
  'Уникальный ИНН контрагента в рамках компании. Сравнение по цифрам.';
