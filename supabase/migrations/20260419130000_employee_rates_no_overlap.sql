-- ЭТАП E3: запрет пересечений периодов в employee_rates на уровне БД.
--
-- Контекст: после правок UI/репозитория (E2) пересечения уже невозможны
-- через приложение, но constraint в БД нужен как «последняя линия защиты»
-- от прямых вставок (миграции, импорты, ручные правки в SQL).
--
-- Реализовано через EXCLUDE USING gist + btree_gist, потому что нам нужно
-- сравнивать диапазон дат (gist) одновременно с равенством по
-- (employee_id, company_id) (btree).

CREATE EXTENSION IF NOT EXISTS btree_gist;

ALTER TABLE public.employee_rates
  ADD CONSTRAINT employee_rates_no_overlap
  EXCLUDE USING gist (
    employee_id WITH =,
    company_id  WITH =,
    daterange(valid_from, COALESCE(valid_to, 'infinity'::date), '[]') WITH &&
  );
