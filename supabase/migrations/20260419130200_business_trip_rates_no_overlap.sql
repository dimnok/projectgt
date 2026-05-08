-- ЭТАП E4: запрет пересечений периодов в business_trip_rates на уровне БД.
--
-- Контекст: клиентская проверка (BusinessTripRateRepositoryImpl)
-- уже есть, но прямые INSERT/UPDATE через миграции, импорты или SQL
-- могут её обойти. Constraint в БД — последняя линия защиты.
--
-- Особенность: business_trip_rates.employee_id NULLABLE
-- (значение NULL = «общая ставка по объекту, для всех сотрудников»).
-- Стандартное равенство в EXCLUDE считает NULL != NULL, поэтому
-- две общие ставки на один объект не были бы заблокированы.
-- Решение: сравниваем COALESCE(employee_id, '00000000-0000-0000-0000-000000000000'::uuid)
-- — для общих ставок этот «sentinel» совпадёт сам с собой.
--
-- Расширение btree_gist уже установлено миграцией 20260419130000.

ALTER TABLE public.business_trip_rates
  ADD CONSTRAINT business_trip_rates_no_overlap
  EXCLUDE USING gist (
    object_id  WITH =,
    company_id WITH =,
    (COALESCE(employee_id, '00000000-0000-0000-0000-000000000000'::uuid)) WITH =,
    daterange(valid_from, COALESCE(valid_to, 'infinity'::date), '[]') WITH &&
  );
