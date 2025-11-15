-- Удаление колонок inventory_number из всех таблиц модуля Склад
-- Дата: 2025-01-17

-- 1. Удаляем уникальные ограничения (constraints) - они автоматически удалят индексы
ALTER TABLE inventory_items DROP CONSTRAINT IF EXISTS inventory_items_inventory_number_key CASCADE;
DROP INDEX IF EXISTS idx_inventory_items_inventory_number CASCADE;
ALTER TABLE inventory_inventory DROP CONSTRAINT IF EXISTS inventory_inventory_inventory_number_key CASCADE;
DROP INDEX IF EXISTS idx_inventory_inventory_inventory_number CASCADE;

-- 2. Удаляем колонку inventory_number из таблицы inventory_items
ALTER TABLE inventory_items DROP COLUMN IF EXISTS inventory_number;

-- 3. Удаляем колонку inventory_number из таблицы inventory_receipt_items
ALTER TABLE inventory_receipt_items DROP COLUMN IF EXISTS inventory_number;

-- 4. Удаляем колонку inventory_number из таблицы inventory_inventory
ALTER TABLE inventory_inventory DROP COLUMN IF EXISTS inventory_number;

-- 5. Удаляем колонку inventory_number из таблицы inventory_inventory_items
ALTER TABLE inventory_inventory_items DROP COLUMN IF EXISTS inventory_number;

