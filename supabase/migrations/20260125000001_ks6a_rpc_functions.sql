-- ===================================================================
-- Миграция: RPC функции для работы с Журналом КС-6а
-- ===================================================================
-- Дата: 25.01.2026
-- ===================================================================

BEGIN;

-- 1. Функция инициализации нового периода КС-6а (Черновик)
CREATE OR REPLACE FUNCTION public.initialize_ks6a_period(
    p_company_id UUID,
    p_contract_id UUID,
    p_start_date DATE,
    p_end_date DATE,
    p_title TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_period_id UUID;
BEGIN
    -- Проверка прав
    IF NOT public.check_permission(v_user_id, 'estimates', 'create') THEN
        RAISE EXCEPTION 'У вас недостаточно прав для создания периода КС-6а';
    END IF;

    -- Создаем заголовок периода
    INSERT INTO public.ks6a_periods (
        company_id,
        contract_id,
        start_date,
        end_date,
        title,
        status,
        created_by
    )
    VALUES (
        p_company_id,
        p_contract_id,
        p_start_date,
        p_end_date,
        COALESCE(p_title, 'Период с ' || to_char(p_start_date, 'DD.MM.YYYY') || ' по ' || to_char(p_end_date, 'DD.MM.YYYY')),
        'draft',
        v_user_id
    )
    RETURNING id INTO v_period_id;

    -- Собираем данные из work_items и создаем строки периода
    INSERT INTO public.ks6a_period_items (
        company_id,
        period_id,
        estimate_id,
        quantity,
        price_snapshot
    )
    SELECT 
        p_company_id,
        v_period_id,
        e.id,
        COALESCE(SUM(wi.quantity), 0),
        e.price
    FROM public.estimates e
    LEFT JOIN public.work_items wi ON e.id = wi.estimate_id
    LEFT JOIN public.works w ON wi.work_id = w.id
    WHERE e.contract_id = p_contract_id
      AND e.company_id = p_company_id
      AND (w.id IS NULL OR (w.date BETWEEN p_start_date AND p_end_date))
    GROUP BY e.id, e.price
    HAVING SUM(wi.quantity) > 0 OR e.id IN (SELECT id FROM public.estimates WHERE contract_id = p_contract_id);

    RETURN v_period_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Функция синхронизации черновика с текущими отчетами
CREATE OR REPLACE FUNCTION public.refresh_ks6a_period(
    p_period_id UUID
)
RETURNS VOID AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_period public.ks6a_periods%ROWTYPE;
BEGIN
    -- Проверка прав
    IF NOT public.check_permission(v_user_id, 'estimates', 'update') THEN
        RAISE EXCEPTION 'У вас недостаточно прав для обновления периода КС-6а';
    END IF;

    -- Получаем данные периода
    SELECT * INTO v_period FROM public.ks6a_periods WHERE id = p_period_id;
    
    IF v_period.status != 'draft' THEN
        RAISE EXCEPTION 'Можно обновлять только черновики';
    END IF;

    -- Обновляем объемы, которые НЕ были изменены вручную (или просто все, если мы не трекаем ручные правки)
    -- В данном случае обновляем все объемы на основе текущих work_items
    
    -- Сначала удаляем старые строки (чтобы не было дублей и учесть удаленные работы)
    DELETE FROM public.ks6a_period_items WHERE period_id = p_period_id;

    -- Заново собираем данные
    INSERT INTO public.ks6a_period_items (
        company_id,
        period_id,
        estimate_id,
        quantity,
        price_snapshot
    )
    SELECT 
        v_period.company_id,
        p_period_id,
        e.id,
        COALESCE(SUM(wi.quantity), 0),
        e.price
    FROM public.estimates e
    LEFT JOIN public.work_items wi ON e.id = wi.estimate_id
    LEFT JOIN public.works w ON wi.work_id = w.id
    WHERE e.contract_id = v_period.contract_id
      AND e.company_id = v_period.company_id
      AND (w.id IS NULL OR (w.date BETWEEN v_period.start_date AND v_period.end_date))
    GROUP BY e.id, e.price
    HAVING SUM(wi.quantity) > 0 OR e.id IN (SELECT id FROM public.estimates WHERE contract_id = v_period.contract_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Функция согласования периода
CREATE OR REPLACE FUNCTION public.approve_ks6a_period(
    p_period_id UUID
)
RETURNS VOID AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_total DOUBLE PRECISION;
BEGIN
    -- Проверка прав
    IF NOT public.check_permission(v_user_id, 'estimates', 'update') THEN
        RAISE EXCEPTION 'У вас недостаточно прав для согласования периода КС-6а';
    END IF;

    -- Считаем финальную сумму периода
    SELECT SUM(amount) INTO v_total FROM public.ks6a_period_items WHERE period_id = p_period_id;

    -- Обновляем статус и итоговую сумму
    UPDATE public.ks6a_periods
    SET 
        status = 'approved',
        total_amount = COALESCE(v_total, 0),
        updated_at = now()
    WHERE id = p_period_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Функция получения всех данных КС-6а по договору
CREATE OR REPLACE FUNCTION public.get_contract_ks6a_data(
    p_company_id UUID,
    p_contract_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_periods JSONB;
    v_items JSONB;
BEGIN
    -- Проверка прав
    IF NOT public.check_permission(v_user_id, 'estimates', 'read') THEN
        RETURN JSONB_BUILD_OBJECT('periods', '[]'::JSONB, 'items', '[]'::JSONB);
    END IF;

    -- Получаем список периодов
    SELECT JSONB_AGG(row_to_json(p) ORDER BY p.start_date)
    INTO v_periods
    FROM (
        SELECT id, start_date, end_date, status, title, total_amount
        FROM public.ks6a_periods
        WHERE contract_id = p_contract_id AND company_id = p_company_id
    ) p;

    -- Получаем все строки периодов
    SELECT JSONB_AGG(row_to_json(i))
    INTO v_items
    FROM (
        SELECT pi.id, pi.period_id, pi.estimate_id, pi.quantity, pi.price_snapshot, pi.amount
        FROM public.ks6a_period_items pi
        JOIN public.ks6a_periods p ON pi.period_id = p.id
        WHERE p.contract_id = p_contract_id AND p.company_id = p_company_id
    ) i;

    RETURN JSONB_BUILD_OBJECT(
        'periods', COALESCE(v_periods, '[]'::JSONB),
        'items', COALESCE(v_items, '[]'::JSONB)
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMIT;
