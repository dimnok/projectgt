-- Миграция: Умный поиск материалов с ранжированием по схожести
-- Дата: 7 октября 2025 года
-- Описание: Функция для поиска материалов с сортировкой по релевантности

-- 1. Включаем расширение pg_trgm для trigram similarity
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. Создаём индекс для быстрого поиска по названию материала
CREATE INDEX IF NOT EXISTS idx_materials_name_trgm 
ON materials USING gin (name gin_trgm_ops);

-- 3. Функция нормализации текста (х/x/× → единый символ)
CREATE OR REPLACE FUNCTION normalize_material_name(input_text text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT LOWER(
    TRANSLATE(
      input_text,
      'хХxX×⨯·*', -- Разные варианты "умножения"
      'xxxxxxxx'  -- Все заменяем на английское x
    )
  );
$$;

-- 4. Функция поиска с ранжированием по схожести (обновленная)
CREATE OR REPLACE FUNCTION search_materials_by_similarity(
  search_query text,
  contract_num text
)
RETURNS TABLE (
  id uuid,
  name text,
  unit text,
  receipt_number text,
  similarity_score real
)
LANGUAGE sql
STABLE
AS $$
  WITH normalized_query AS (
    SELECT normalize_material_name(search_query) AS nq
  )
  SELECT 
    v.id,
    v.name,
    v.unit,
    v.receipt_number,
    -- Вычисляем similarity score (0-1, где 1 = полное совпадение)
    GREATEST(
      similarity(normalize_material_name(v.name), (SELECT nq FROM normalized_query)),
      -- Бонус за точное начало строки
      CASE 
        WHEN normalize_material_name(v.name) LIKE (SELECT nq FROM normalized_query) || '%' THEN 0.9
        ELSE 0
      END,
      -- Бонус за вхождение в начале слова
      CASE 
        WHEN normalize_material_name(v.name) LIKE '% ' || (SELECT nq FROM normalized_query) || '%' THEN 0.8
        ELSE 0
      END
    ) AS similarity_score
  FROM v_materials_with_usage v
  WHERE v.contract_number = contract_num
    AND v.estimate_id IS NULL
    AND (
      -- Trigram similarity > 0.1 (настраиваемый порог)
      similarity(normalize_material_name(v.name), (SELECT nq FROM normalized_query)) > 0.1
      OR normalize_material_name(v.name) LIKE '%' || (SELECT nq FROM normalized_query) || '%'
    )
  ORDER BY 
    similarity_score DESC,  -- Сначала самые похожие
    v.name ASC              -- Потом по алфавиту
  LIMIT 500;
$$;

-- 5. Комментарии
COMMENT ON FUNCTION normalize_material_name IS 
'Нормализует название материала: приводит к нижнему регистру и заменяет все варианты "умножения" (х/x/×) на единый символ.';

COMMENT ON FUNCTION search_materials_by_similarity IS 
'Умный поиск материалов с ранжированием по схожести названия. 
Использует trigram similarity для нахождения похожих материалов даже при опечатках.
Автоматически нормализует разные варианты написания (х/x/×).
Сортирует результаты по релевантности: сначала самые похожие.';

-- 5. Проверка работы функции (для тестов)
-- SELECT * FROM search_materials_by_similarity('профиль', '173-суб-17');

