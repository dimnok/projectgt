-- Минимум выработки компании: рубли на одного человека за один час.
-- План дня = сумма часов смен × это значение. NULL = план не задан.
ALTER TABLE public.companies
  ADD COLUMN min_output_per_person_hour numeric;

ALTER TABLE public.companies
  ADD CONSTRAINT companies_min_output_per_person_hour_non_negative
  CHECK (min_output_per_person_hour IS NULL OR min_output_per_person_hour >= 0);

COMMENT ON COLUMN public.companies.min_output_per_person_hour IS
  'Минимум выработки, ₽ на человеко-час. Используется как план компании.';
