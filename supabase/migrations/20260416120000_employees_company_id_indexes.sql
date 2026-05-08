-- Индексы по company_id для таблиц модуля Employees.
--
-- До этой миграции в employees и employee_rates не было индексов на
-- company_id. Все запросы модуля фильтруют по этому полю, включая RLS,
-- поэтому планировщик выбирал Seq Scan на employees (EXPLAIN показывал
-- отбрасывание лишних строк через Filter). На десятках строк это
-- несущественно, но линейно деградирует с ростом справочника.
--
-- idx_employees_company_last_name дополнительно покрывает ORDER BY
-- last_name при выборке списка сотрудников компании.

CREATE INDEX IF NOT EXISTS idx_employees_company_id
    ON public.employees(company_id);

CREATE INDEX IF NOT EXISTS idx_employees_company_last_name
    ON public.employees(company_id, last_name);

CREATE INDEX IF NOT EXISTS idx_employee_rates_company_id
    ON public.employee_rates(company_id);

ANALYZE public.employees;
ANALYZE public.employee_rates;
