-- Функция для поиска похожих сметных позиций в других системах/подсистемах
-- Дата: 9 октября 2025 года
-- Цель: Автоматический поиск дублирующихся работ при привязке материалов

-- Удаляем старые версии функции (если есть)
DROP FUNCTION IF EXISTS public.find_similar_estimates(uuid, text, text, uuid, float);
DROP FUNCTION IF EXISTS public.find_similar_estimates(uuid, text, text, uuid, double precision);
DROP FUNCTION IF EXISTS public.find_similar_estimates(uuid, text, text, uuid, real);

-- Создаём функцию с правильным типом real (совместим с similarity())
CREATE FUNCTION public.find_similar_estimates(
  p_contract_id uuid,
  p_estimate_name text,
  p_unit text,
  p_current_estimate_id uuid DEFAULT NULL,
  p_min_similarity real DEFAULT 0.4
)
RETURNS TABLE (
  estimate_id uuid,
  estimate_name text,
  estimate_unit text,
  system text,
  subsystem text,
  similarity_score real
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  -- Поиск похожих позиций
  RETURN QUERY
  SELECT 
    e.id,
    e.name,
    e.unit,
    e.system,
    e.subsystem,
    similarity(e.name, p_estimate_name)::real
  FROM public.estimates e
  WHERE 
    -- Тот же договор
    e.contract_id = p_contract_id
    -- Исключаем текущую позицию
    AND e.id != COALESCE(p_current_estimate_id, '00000000-0000-0000-0000-000000000000'::uuid)
    -- Та же единица измерения (точное совпадение)
    AND e.unit = p_unit
    -- Similarity >= минимального порога (по умолчанию 0.4 = 40%)
    AND similarity(e.name, p_estimate_name) >= p_min_similarity
  ORDER BY 
    -- Сначала самые похожие
    similarity(e.name, p_estimate_name) DESC,
    -- Затем по системе
    e.system ASC,
    -- Затем по подсистеме
    e.subsystem ASC
  -- Ограничение результатов
  LIMIT 10;
END;
$$;

-- Комментарий к функции
COMMENT ON FUNCTION public.find_similar_estimates IS
'Находит похожие сметные позиции в других системах/подсистемах того же договора.

Использует trigram similarity (расширение pg_trgm) для сравнения названий работ.

Параметры:
- p_contract_id: UUID договора для фильтрации
- p_estimate_name: Название сметной позиции для сравнения
- p_unit: Единица измерения (фильтр по точному совпадению)
- p_current_estimate_id: UUID текущей позиции (исключается из результатов)
- p_min_similarity: Минимальный порог схожести от 0 до 1 (по умолчанию 0.4 = 40%)

Возвращает до 10 похожих позиций с similarity_score >= порога.

Пример использования:
SELECT * FROM find_similar_estimates(
  ''8de1f1eb-b2a6-4ad2-a270-d5e07a75f960'',
  ''Заглушка 41х41, TERMOCLIP, 9379005'',
  ''шт.'',
  ''067b0315-0bcd-4374-8004-b48f5c02d80d'',
  0.4
);';

-- Предоставление прав доступа
GRANT EXECUTE ON FUNCTION public.find_similar_estimates TO authenticated;
GRANT EXECUTE ON FUNCTION public.find_similar_estimates TO anon;

