-- Создание GIN индекса на estimates.name для ускорения trigram similarity поиска
-- Дата: 9 октября 2025 года
-- Цель: Поиск похожих сметных позиций при привязке материалов

-- Создаём GIN индекс с оператором gin_trgm_ops
CREATE INDEX IF NOT EXISTS idx_estimates_name_gin_trgm 
ON public.estimates 
USING gin (name gin_trgm_ops);

-- Комментарий к индексу
COMMENT ON INDEX idx_estimates_name_gin_trgm IS 
'GIN индекс для быстрого поиска похожих названий сметных позиций через trigram similarity. Используется в функции find_similar_estimates для автоматического поиска дублирующихся работ в разных системах.';

