-- ===================================================================
-- Функция: populate_vor_items
-- Описание: Наполняет состав ведомости ВОР фактически выполненными работами
--           за указанный в заголовке период. Учитывает сметные лимиты,
--           выделяет превышения и новые позиции.
-- ===================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.populate_vor_items(p_vor_id UUID)
RETURNS VOID AS $$
DECLARE
    v_contract_id UUID;
    v_company_id UUID;
    v_start_date DATE;
    v_end_date DATE;
    v_systems TEXT[];
BEGIN
    -- 1. Получаем параметры ВОР из заголовка
    SELECT 
        contract_id, company_id, start_date, end_date
    INTO 
        v_contract_id, v_company_id, v_start_date, v_end_date
    FROM public.vors
    WHERE id = p_vor_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ведомость ВОР с ID % не найдена', p_vor_id;
    END IF;

    -- 2. Получаем список выбранных систем для этой ведомости
    SELECT array_agg(system_name) INTO v_systems
    FROM public.vor_systems
    WHERE vor_id = p_vor_id;

    -- 3. Очищаем старые позиции (если были), так как наполнение идет заново
    DELETE FROM public.vor_items WHERE vor_id = p_vor_id;

    -- 4. Наполняем vor_items
    -- Используем CTE для агрегации факта и сопоставления со сметой
    INSERT INTO public.vor_items (
        company_id, 
        vor_id, 
        estimate_item_id, 
        name, 
        unit, 
        quantity, 
        is_extra, 
        sort_order
    )
    WITH fact_data AS (
        -- Агрегируем выполнение из журналов работ
        SELECT 
            wi.estimate_id,
            wi.name as work_name,
            wi.unit as work_unit,
            SUM(wi.quantity) as total_fact
        FROM public.work_items wi
        JOIN public.works w ON wi.work_id = w.id
        WHERE w.date >= v_start_date 
          AND w.date <= v_end_date
          -- Фильтр по системам (если выбраны)
          AND (v_systems IS NULL OR wi.system = ANY(v_systems))
          -- Привязка к объекту через контракт (безопаснее всего через estimate_id)
          AND EXISTS (
              SELECT 1 FROM public.estimates e 
              WHERE e.id = wi.estimate_id AND e.contract_id = v_contract_id
          )
        GROUP BY wi.estimate_id, wi.name, wi.unit
    ),
    processed_items AS (
        -- Сопоставляем с лимитами сметы
        SELECT 
            fd.estimate_id,
            fd.work_name,
            fd.work_unit,
            fd.total_fact,
            e.quantity as estimate_qty,
            -- Рассчитываем накопленное выполнение ДО текущего периода (утвержденное)
            COALESCE((
                SELECT SUM(vi.quantity)
                FROM public.vor_items vi
                JOIN public.vors v ON vi.vor_id = v.id
                WHERE vi.estimate_item_id = fd.estimate_id
                  AND v.status = 'approved'
                  AND v.end_date < v_start_date
            ), 0) as prev_approved_qty
        FROM fact_data fd
        LEFT JOIN public.estimates e ON fd.estimate_id = e.id
    ),
    split_logic AS (
        -- Разделяем каждую позицию на норму и превышение
        SELECT 
            estimate_id,
            work_name,
            work_unit,
            -- Остаток лимита до начала превышения
            GREATEST(0, COALESCE(estimate_qty, 0) - prev_approved_qty) as remaining_limit,
            total_fact
        FROM processed_items
    ),
    final_rows AS (
        -- 1. Строки нормы (в пределах лимита)
        SELECT 
            estimate_id,
            work_name,
            work_unit,
            LEAST(total_fact, remaining_limit) as qty,
            false as is_extra
        FROM split_logic
        WHERE estimate_id IS NOT NULL AND remaining_limit > 0 AND LEAST(total_fact, remaining_limit) > 0

        UNION ALL

        -- 2. Строки превышения (сверх лимита)
        SELECT 
            estimate_id,
            work_name,
            work_unit,
            CASE 
                WHEN estimate_id IS NULL THEN total_fact -- Новая работа (всегда экстра)
                ELSE GREATEST(0, total_fact - remaining_limit) -- Хвост превышения
            END as qty,
            true as is_extra
        FROM split_logic
        WHERE (estimate_id IS NULL) -- Новые работы
           OR (estimate_id IS NOT NULL AND total_fact > remaining_limit) -- Превышения
    )
    SELECT 
        v_company_id,
        p_vor_id,
        estimate_id,
        work_name,
        work_unit,
        qty,
        is_extra,
        0 as sort_order
    FROM final_rows
    WHERE qty > 0;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
