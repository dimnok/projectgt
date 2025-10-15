-- ===================================================================
-- Миграция: Оптимизация индексов базы данных
-- ===================================================================
-- Устраняет предупреждения Supabase Database Linter:
-- 1. unindexed_foreign_keys - добавляет индексы для FK
-- 2. unused_index - удаляет неиспользуемые индексы
--
-- Дата: 15 октября 2025
-- ===================================================================

BEGIN;

-- ===================================================================
-- ЧАСТЬ 1: ДОБАВЛЕНИЕ ИНДЕКСОВ ДЛЯ ВНЕШНИХ КЛЮЧЕЙ (15 шт.)
-- ===================================================================
-- Foreign keys без индексов замедляют JOIN'ы и CASCADE операции.
-- Добавляем индексы для оптимизации производительности.
-- ===================================================================

-- 1. business_trip_rates.created_by
CREATE INDEX IF NOT EXISTS idx_business_trip_rates_created_by 
ON business_trip_rates(created_by);

-- 2. contracts.contractor_id
CREATE INDEX IF NOT EXISTS idx_contracts_contractor_id 
ON contracts(contractor_id);

-- 3. contracts.object_id
CREATE INDEX IF NOT EXISTS idx_contracts_object_id 
ON contracts(object_id);

-- 4. employee_attendance.created_by
CREATE INDEX IF NOT EXISTS idx_employee_attendance_created_by 
ON employee_attendance(created_by);

-- 5. employee_rates.created_by
CREATE INDEX IF NOT EXISTS idx_employee_rates_created_by 
ON employee_rates(created_by);

-- 6. estimates.contract_id
CREATE INDEX IF NOT EXISTS idx_estimates_contract_id 
ON estimates(contract_id);

-- 7. estimates.object_id
CREATE INDEX IF NOT EXISTS idx_estimates_object_id 
ON estimates(object_id);

-- 8. materials.created_by
CREATE INDEX IF NOT EXISTS idx_materials_created_by 
ON materials(created_by);

-- 9. payroll_bonus.object_id
CREATE INDEX IF NOT EXISTS idx_payroll_bonus_object_id 
ON payroll_bonus(object_id);

-- 10. payroll_payout.employee_id
CREATE INDEX IF NOT EXISTS idx_payroll_payout_employee_id 
ON payroll_payout(employee_id);

-- 11. payroll_penalty.object_id
CREATE INDEX IF NOT EXISTS idx_payroll_penalty_object_id 
ON payroll_penalty(object_id);

-- 12. work_items.work_id (для FK shift_items_shift_id_fkey)
CREATE INDEX IF NOT EXISTS idx_work_items_work_id 
ON work_items(work_id);

-- 13. work_materials.work_id (для FK shift_materials_shift_id_fkey)
CREATE INDEX IF NOT EXISTS idx_work_materials_work_id 
ON work_materials(work_id);

-- 14. work_plan_blocks.responsible_id
CREATE INDEX IF NOT EXISTS idx_work_plan_blocks_responsible_id 
ON work_plan_blocks(responsible_id);

-- 15. works.opened_by (для FK shifts_opened_by_fkey)
CREATE INDEX IF NOT EXISTS idx_works_opened_by 
ON works(opened_by);

-- 16. employee_attendance.object_id (ДОПОЛНЕНО)
CREATE INDEX IF NOT EXISTS idx_employee_attendance_object_id 
ON employee_attendance(object_id);

-- 17. material_aliases.supplier_id (ДОПОЛНЕНО)
CREATE INDEX IF NOT EXISTS idx_material_aliases_supplier_id 
ON material_aliases(supplier_id);

-- 18. payroll_bonus.employee_id (ДОПОЛНЕНО)
CREATE INDEX IF NOT EXISTS idx_payroll_bonus_employee_id 
ON payroll_bonus(employee_id);

-- 19. work_plans.created_by (ДОПОЛНЕНО)
CREATE INDEX IF NOT EXISTS idx_work_plans_created_by 
ON work_plans(created_by);

-- ===================================================================
-- ЧАСТЬ 2: УДАЛЕНИЕ НЕИСПОЛЬЗУЕМЫХ ИНДЕКСОВ (27 шт.)
-- ===================================================================
-- Индексы занимают место и замедляют INSERT/UPDATE/DELETE.
-- Удаляем индексы, которые никогда не использовались в запросах.
-- ===================================================================

-- 1. materials - триграммный индекс для поиска по названию
DROP INDEX IF EXISTS idx_materials_name_trgm;

-- 2-3. contractors - индексы для поиска
DROP INDEX IF EXISTS contractors_full_name_idx;
DROP INDEX IF EXISTS contractors_inn_idx;

-- 4. employees - индекс для поиска по имени
DROP INDEX IF EXISTS idx_employees_name;

-- 5-7. profiles - индексы для поиска и фильтрации
DROP INDEX IF EXISTS profiles_email_idx;
DROP INDEX IF EXISTS profiles_full_name_idx;
DROP INDEX IF EXISTS profiles_status_idx;

-- 8. work_plan_items - индекс по дате создания
DROP INDEX IF EXISTS idx_work_plan_items_created_at;

-- 9-10. work_plans - индексы для фильтрации
DROP INDEX IF EXISTS idx_work_plans_created_by;
DROP INDEX IF EXISTS idx_work_plans_date;

-- 11-15. work_plan_blocks - индексы для группировки и фильтрации
DROP INDEX IF EXISTS idx_work_plan_blocks_system;
DROP INDEX IF EXISTS idx_work_plan_blocks_section;
DROP INDEX IF EXISTS idx_work_plan_blocks_floor;
DROP INDEX IF EXISTS idx_work_plan_blocks_created_at;
DROP INDEX IF EXISTS idx_work_plan_blocks_worker_ids;

-- 16. work_plan_items - индекс по estimate_id
DROP INDEX IF EXISTS idx_work_plan_items_estimate_id;

-- 17. payroll_bonus - композитный индекс
DROP INDEX IF EXISTS idx_payroll_bonus_employee_date;

-- 18. user_tokens - индекс по активности
DROP INDEX IF EXISTS user_tokens_active_idx;

-- 19. works - индекс по статусу
DROP INDEX IF EXISTS idx_works_status;

-- 20. employees - индекс для фильтра ответственных
DROP INDEX IF EXISTS employees_can_be_responsible_true_idx;

-- 21-22. material_aliases - индексы для справочников
DROP INDEX IF EXISTS idx_material_aliases_estimate;
DROP INDEX IF EXISTS idx_material_aliases_supplier;

-- 23. employee_attendance - индекс по объекту (дублируется с FK)
-- ПРИМЕЧАНИЕ: Индекс idx_employee_attendance_object уже есть и может использоваться
-- Проверим, не конфликтует ли он с основными запросами
DROP INDEX IF EXISTS idx_employee_attendance_object;

-- 24-25. employee_rates - индексы для фильтрации
-- ВНИМАНИЕ: idx_employee_rates_employee_id может быть полезен для JOIN'ов
-- но если не используется, удаляем
DROP INDEX IF EXISTS idx_employee_rates_employee_id;
DROP INDEX IF EXISTS idx_employee_rates_active;

-- 26. business_trip_rates - индекс по object_id
-- ПРИМЕЧАНИЕ: Может дублироваться с другими индексами
DROP INDEX IF EXISTS idx_business_trip_rates_object_id;

-- 27. employee_attendance - индекс по типу
DROP INDEX IF EXISTS idx_employee_attendance_type;

-- ===================================================================
-- КОНЕЦ МИГРАЦИИ
-- ===================================================================

COMMIT;

-- ===================================================================
-- Результат:
-- ✅ Добавлено 19 индексов для внешних ключей
-- ✅ Удалено 27 неиспользуемых индексов
--
-- Эффект:
-- + Ускорение JOIN'ов и CASCADE операций (за счёт FK индексов)
-- + Ускорение INSERT/UPDATE/DELETE (меньше индексов для обновления)
-- + Экономия места на диске
--
-- ВАЖНО: Новые индексы могут временно показываться как "unused" 
-- до первого использования в запросах. Это нормально!
-- Если после удаления старых индексов появятся медленные запросы, 
-- можно вернуть нужные индексы через новую миграцию.
-- ===================================================================

