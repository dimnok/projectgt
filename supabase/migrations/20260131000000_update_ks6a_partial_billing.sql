-- ===================================================================
-- Миграция: Обновление логики КС-6а для поддержки частичного закрытия
-- ===================================================================

BEGIN;

-- 1. Функция получения остатка к закрытию по сметной позиции
CREATE OR REPLACE FUNCTION public.get_estimate_unbilled_quantity(
    p_estimate_id UUID
)
RETURNS DOUBLE PRECISION AS $$
DECLARE
    v_total_worked DOUBLE PRECISION;
    v_total_billed DOUBLE PRECISION;
BEGIN
    -- Всего выполнено в ежедневных отчетах
    SELECT COALESCE(SUM(quantity), 0) INTO v_total_worked
    FROM public.work_items
    WHERE estimate_id = p_estimate_id;

    -- Всего предъявлено в СОГЛАСОВАННЫХ периодах КС-6а
    SELECT COALESCE(SUM(pi.quantity), 0) INTO v_total_billed
    FROM public.ks6a_period_items pi
    JOIN public.ks6a_periods p ON pi.period_id = p.id
    WHERE pi.estimate_id = p_estimate_id AND p.status = 'approved';

    RETURN GREATEST(0, v_total_worked - v_total_billed);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 2. Обновленная функция инициализации периода (теперь учитывает ВСЕ непредъявленные работы)
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

    -- Собираем данные: все непредъявленные работы на текущий момент
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
        public.get_estimate_unbilled_quantity(e.id),
        e.price
    FROM public.estimates e
    WHERE e.contract_id = p_contract_id
      AND e.company_id = p_company_id
      AND public.get_estimate_unbilled_quantity(e.id) > 0;

    RETURN v_period_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Функция обновления количества в строке периода (для ручной правки)
CREATE OR REPLACE FUNCTION public.update_ks6a_item_quantity(
    p_item_id UUID,
    p_new_quantity DOUBLE PRECISION
)
RETURNS VOID AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_estimate_id UUID;
    v_max_available DOUBLE PRECISION;
    v_period_status TEXT;
BEGIN
    -- Проверка прав
    IF NOT public.check_permission(v_user_id, 'estimates', 'update') THEN
        RAISE EXCEPTION 'У вас недостаточно прав для изменения объемов';
    END IF;

    -- Проверка статуса периода
    SELECT p.status INTO v_period_status
    FROM public.ks6a_periods p
    JOIN public.ks6a_period_items pi ON pi.period_id = p.id
    WHERE pi.id = p_item_id;

    IF v_period_status != 'draft' THEN
        RAISE EXCEPTION 'Можно изменять объемы только в черновиках';
    END IF;

    -- Получаем ID сметной позиции
    SELECT estimate_id INTO v_estimate_id FROM public.ks6a_period_items WHERE id = p_item_id;

    -- Проверка: новое количество не должно превышать доступный остаток
    v_max_available := public.get_estimate_unbilled_quantity(v_estimate_id);
    
    -- Важно: текущее количество в этом черновике тоже входит в расчет остатка, 
    -- но get_estimate_unbilled_quantity считает только по APPROVED периодам, 
    -- так что v_max_available уже включает в себя то, что мы сейчас редактируем.
    
    IF p_new_quantity > v_max_available THEN
        RAISE EXCEPTION 'Введенное количество (%) превышает доступный остаток (%)', p_new_quantity, v_max_available;
    END IF;

    UPDATE public.ks6a_period_items
    SET quantity = p_new_quantity
    WHERE id = p_item_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
