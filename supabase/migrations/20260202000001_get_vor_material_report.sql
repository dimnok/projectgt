-- ===================================================================
-- Функция: get_vor_material_report
-- Описание: Формирует отчет о списании материалов на основании конкретного ВОР.
--           Использует объемы из vor_items и распределяет их по накладным (FIFO).
-- ===================================================================

CREATE OR REPLACE FUNCTION public.get_vor_material_report(p_company_id UUID, p_vor_id UUID)
RETURNS TABLE (
    material_id UUID,
    material_name TEXT,
    related_works TEXT,
    unit TEXT,
    batch_quantity NUMERIC,
    price NUMERIC,
    total NUMERIC,
    receipt_number TEXT,
    receipt_date DATE,
    used_in_vor NUMERIC,
    remaining_after_vor NUMERIC
) AS $$
DECLARE
    v_contract_id UUID;
    v_contract_number TEXT;
BEGIN
    -- 1. Получаем данные контракта из ВОР
    SELECT contract_id INTO v_contract_id FROM public.vors WHERE id = p_vor_id AND company_id = p_company_id;
    SELECT number INTO v_contract_number FROM public.contracts WHERE id = v_contract_id;

    RETURN QUERY
    WITH 
    -- Объемы из текущего ВОР, переведенные в единицы материала через алиасы
    vor_usage_units AS (
        SELECT 
            ma.normalized_alias,
            normalize_material_name(ma.uom_raw) as normalized_uom,
            SUM(vi.quantity / COALESCE(NULLIF(ma.multiplier_to_estimate, 0), 1)) as total_usage_in_material_units
        FROM public.vor_items vi
        JOIN public.material_aliases ma ON ma.estimate_id = vi.estimate_item_id
        WHERE vi.vor_id = p_vor_id 
          AND ma.is_active = true 
          AND ma.company_id = p_company_id
        GROUP BY ma.normalized_alias, normalize_material_name(ma.uom_raw)
    ),
    -- Все работы, к которым привязан данный материал (для колонки "Связанные работы")
    material_works AS (
        SELECT 
            ma.normalized_alias,
            normalize_material_name(ma.uom_raw) as normalized_uom,
            string_agg(DISTINCT e.name, ', ') as works_list
        FROM public.material_aliases ma
        JOIN public.estimates e ON e.id = ma.estimate_id
        WHERE ma.company_id = p_company_id 
          AND ma.is_active = true
          AND e.contract_id = v_contract_id
        GROUP BY ma.normalized_alias, normalize_material_name(ma.uom_raw)
    ),
    -- Накладные по данному контракту
    contract_materials AS (
        SELECT 
            m.id,
            m.name,
            m.unit,
            m.quantity as batch_qty,
            m.price,
            m.total,
            m.receipt_number,
            m.receipt_date,
            normalize_material_name(m.name) as n_name,
            normalize_material_name(m.unit) as n_unit,
            -- Накопительный итог прихода для FIFO
            SUM(m.quantity) OVER (
                PARTITION BY normalize_material_name(m.name), normalize_material_name(m.unit) 
                ORDER BY m.receipt_date, m.id
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ) as prev_cum_qty
        FROM public.materials m
        WHERE m.company_id = p_company_id 
          AND m.contract_number = v_contract_number
    )
    SELECT 
        cm.id,
        cm.name,
        COALESCE(mw.works_list, 'Не привязано') as related_works,
        cm.unit,
        cm.batch_qty::NUMERIC,
        cm.price::NUMERIC,
        cm.total::NUMERIC,
        cm.receipt_number,
        cm.receipt_date,
        -- Расчет использованного в рамках этого ВОР (FIFO логика)
        GREATEST(0, LEAST(cm.batch_qty, COALESCE(vu.total_usage_in_material_units, 0) - COALESCE(cm.prev_cum_qty, 0)))::NUMERIC as used_in_vor,
        -- Остаток после списания этого ВОР
        (cm.batch_qty - GREATEST(0, LEAST(cm.batch_qty, COALESCE(vu.total_usage_in_material_units, 0) - COALESCE(cm.prev_cum_qty, 0))))::NUMERIC as remaining_after_vor
    FROM contract_materials cm
    LEFT JOIN vor_usage_units vu ON vu.normalized_alias = cm.n_name AND vu.normalized_uom = cm.n_unit
    LEFT JOIN material_works mw ON mw.normalized_alias = cm.n_name AND mw.normalized_uom = cm.n_unit
    ORDER BY cm.receipt_date DESC, cm.name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
