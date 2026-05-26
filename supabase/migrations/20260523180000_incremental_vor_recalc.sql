-- Инкрементальный пересчёт ВОР: только новые/изменённые по журналу позиции.
-- Раскладка «по смете / превышение» для неизменённых объёмов сохраняется.

BEGIN;

CREATE OR REPLACE FUNCTION public.recalculate_vor_items_incremental(p_vor_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_company_id UUID;
    v_contract_id UUID;
    v_start_date DATE;
    v_end_date DATE;
    v_systems TEXT[];
BEGIN
    SELECT company_id, contract_id, start_date, end_date
    INTO v_company_id, v_contract_id, v_start_date, v_end_date
    FROM public.vors
    WHERE id = p_vor_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ведомость ВОР с ID % не найдена', p_vor_id;
    END IF;

    SELECT array_agg(system_name)
    INTO v_systems
    FROM public.vor_systems
    WHERE vor_id = p_vor_id;

    WITH journal AS (
        SELECT
            wi.estimate_id AS estimate_item_id,
            wi.name,
            wi.unit,
            SUM(wi.quantity) AS journal_total
        FROM public.work_items wi
        JOIN public.works w ON wi.work_id = w.id
        WHERE w.date >= v_start_date
          AND w.date <= v_end_date
          AND (v_systems IS NULL OR wi.system = ANY(v_systems))
          AND EXISTS (
              SELECT 1
              FROM public.estimates e
              WHERE e.id = wi.estimate_id
                AND e.contract_id = v_contract_id
          )
        GROUP BY wi.estimate_id, wi.name, wi.unit
    ),
    current_agg AS (
        SELECT
            vi.estimate_item_id,
            vi.name,
            vi.unit,
            SUM(vi.quantity) AS current_total
        FROM public.vor_items vi
        WHERE vi.vor_id = p_vor_id
        GROUP BY vi.estimate_item_id, vi.name, vi.unit
    ),
    keys_to_update AS (
        SELECT
            COALESCE(j.estimate_item_id, c.estimate_item_id) AS estimate_item_id,
            COALESCE(j.name, c.name) AS name,
            COALESCE(j.unit, c.unit) AS unit,
            j.journal_total
        FROM journal j
        FULL OUTER JOIN current_agg c
            ON j.estimate_item_id IS NOT DISTINCT FROM c.estimate_item_id
           AND j.name = c.name
           AND j.unit = c.unit
        WHERE c.current_total IS NULL
           OR j.journal_total IS NULL
           OR ROUND(j.journal_total::numeric, 6)
                IS DISTINCT FROM ROUND(c.current_total::numeric, 6)
    ),
    deleted AS (
        DELETE FROM public.vor_items vi
        USING keys_to_update k
        WHERE vi.vor_id = p_vor_id
          AND vi.estimate_item_id IS NOT DISTINCT FROM k.estimate_item_id
          AND vi.name = k.name
          AND vi.unit = k.unit
        RETURNING vi.id
    )
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
    SELECT
        v_company_id,
        p_vor_id,
        r.estimate_item_id,
        r.name,
        r.unit,
        r.quantity,
        r.is_extra,
        0
    FROM public.compute_vor_item_rows(p_vor_id) AS r
    INNER JOIN keys_to_update k
        ON r.estimate_item_id IS NOT DISTINCT FROM k.estimate_item_id
       AND r.name = k.name
       AND r.unit = k.unit
    WHERE k.journal_total IS NOT NULL
      AND k.journal_total > 0;
END;
$$;

CREATE OR REPLACE FUNCTION public.recalculate_vor(p_vor_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_status public.vor_status;
    v_company_id UUID;
    v_excel_url TEXT;
    v_excel_combined_url TEXT;
    v_comment TEXT;
BEGIN
    SELECT status, company_id, excel_url, excel_combined_url
    INTO v_status, v_company_id, v_excel_url, v_excel_combined_url
    FROM public.vors
    WHERE id = p_vor_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ведомость ВОР с ID % не найдена', p_vor_id;
    END IF;

    IF v_status IS DISTINCT FROM 'draft'::public.vor_status THEN
        RAISE EXCEPTION 'Пересчёт доступен только для черновика';
    END IF;

    v_comment :=
        'Пересчёт состава ведомости (только новые и изменённые позиции по журналу работ)';

    IF v_excel_url IS NOT NULL OR v_excel_combined_url IS NOT NULL THEN
        v_comment := v_comment || '. Архив файлов:';
        IF v_excel_url IS NOT NULL THEN
            v_comment := v_comment || ' excel=' || v_excel_url;
        END IF;
        IF v_excel_combined_url IS NOT NULL THEN
            v_comment := v_comment || ' combined=' || v_excel_combined_url;
        END IF;

        UPDATE public.vors
        SET
            excel_url = NULL,
            excel_combined_url = NULL,
            updated_at = now()
        WHERE id = p_vor_id;
    END IF;

    PERFORM public.recalculate_vor_items_incremental(p_vor_id);

    INSERT INTO public.vor_status_history (
        vor_id,
        company_id,
        status,
        user_id,
        comment
    )
    VALUES (
        p_vor_id,
        v_company_id,
        'draft'::public.vor_status,
        auth.uid(),
        v_comment
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.vor_needs_recalc(p_vor_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
    v_status public.vor_status;
    v_contract_id UUID;
    v_start_date DATE;
    v_end_date DATE;
    v_systems TEXT[];
    v_has_diff BOOLEAN;
BEGIN
    SELECT status, contract_id, start_date, end_date
    INTO v_status, v_contract_id, v_start_date, v_end_date
    FROM public.vors
    WHERE id = p_vor_id;

    IF NOT FOUND OR v_status IS DISTINCT FROM 'draft'::public.vor_status THEN
        RETURN false;
    END IF;

    SELECT array_agg(system_name)
    INTO v_systems
    FROM public.vor_systems
    WHERE vor_id = p_vor_id;

    WITH journal AS (
        SELECT
            wi.estimate_id AS estimate_item_id,
            wi.name,
            wi.unit,
            SUM(wi.quantity) AS journal_total
        FROM public.work_items wi
        JOIN public.works w ON wi.work_id = w.id
        WHERE w.date >= v_start_date
          AND w.date <= v_end_date
          AND (v_systems IS NULL OR wi.system = ANY(v_systems))
          AND EXISTS (
              SELECT 1
              FROM public.estimates e
              WHERE e.id = wi.estimate_id
                AND e.contract_id = v_contract_id
          )
        GROUP BY wi.estimate_id, wi.name, wi.unit
    ),
    current_agg AS (
        SELECT
            vi.estimate_item_id,
            vi.name,
            vi.unit,
            SUM(vi.quantity) AS current_total
        FROM public.vor_items vi
        WHERE vi.vor_id = p_vor_id
        GROUP BY vi.estimate_item_id, vi.name, vi.unit
    )
    SELECT EXISTS (
        SELECT 1
        FROM journal j
        FULL OUTER JOIN current_agg c
            ON j.estimate_item_id IS NOT DISTINCT FROM c.estimate_item_id
           AND j.name = c.name
           AND j.unit = c.unit
        WHERE c.current_total IS NULL
           OR j.journal_total IS NULL
           OR ROUND(j.journal_total::numeric, 6)
                IS DISTINCT FROM ROUND(c.current_total::numeric, 6)
    )
    INTO v_has_diff;

    RETURN COALESCE(v_has_diff, false);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_vor_recalc_changes(p_vor_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
    v_status public.vor_status;
    v_contract_id UUID;
    v_start_date DATE;
    v_end_date DATE;
    v_systems TEXT[];
    v_result JSONB;
BEGIN
    SELECT status, contract_id, start_date, end_date
    INTO v_status, v_contract_id, v_start_date, v_end_date
    FROM public.vors
    WHERE id = p_vor_id;

    IF NOT FOUND OR v_status IS DISTINCT FROM 'draft'::public.vor_status THEN
        RETURN '[]'::jsonb;
    END IF;

    SELECT array_agg(system_name)
    INTO v_systems
    FROM public.vor_systems
    WHERE vor_id = p_vor_id;

    WITH journal AS (
        SELECT
            wi.estimate_id AS estimate_item_id,
            wi.name,
            wi.unit,
            SUM(wi.quantity) AS journal_total,
            CASE
                WHEN wi.estimate_id IS NULL THEN 'Вне сметы'
                ELSE COALESCE(NULLIF(TRIM(e.system), ''), 'Без системы')
            END AS section,
            CASE
                WHEN wi.estimate_id IS NOT NULL AND NULLIF(TRIM(e.number::text), '') IS NOT NULL
                    THEN TRIM(e.number::text) || ' — ' || COALESCE(NULLIF(TRIM(e.name), ''), wi.name)
                ELSE COALESCE(NULLIF(TRIM(wi.name), ''), 'Без наименования')
            END AS row_label
        FROM public.work_items wi
        JOIN public.works w ON wi.work_id = w.id
        LEFT JOIN public.estimates e ON e.id = wi.estimate_id
        WHERE w.date >= v_start_date
          AND w.date <= v_end_date
          AND (v_systems IS NULL OR wi.system = ANY(v_systems))
          AND EXISTS (
              SELECT 1
              FROM public.estimates e2
              WHERE e2.id = wi.estimate_id
                AND e2.contract_id = v_contract_id
          )
        GROUP BY
            wi.estimate_id,
            wi.name,
            wi.unit,
            e.system,
            e.number,
            e.name
    ),
    current_agg AS (
        SELECT
            vi.estimate_item_id,
            vi.name,
            vi.unit,
            SUM(vi.quantity) AS current_total,
            CASE
                WHEN vi.estimate_item_id IS NULL THEN 'Вне сметы'
                ELSE COALESCE(NULLIF(TRIM(e.system), ''), 'Без системы')
            END AS section,
            CASE
                WHEN vi.estimate_item_id IS NOT NULL AND NULLIF(TRIM(e.number::text), '') IS NOT NULL
                    THEN TRIM(e.number::text) || ' — ' || COALESCE(NULLIF(TRIM(e.name), ''), vi.name)
                ELSE COALESCE(NULLIF(TRIM(vi.name), ''), 'Без наименования')
            END AS row_label
        FROM public.vor_items vi
        LEFT JOIN public.estimates e ON e.id = vi.estimate_item_id
        WHERE vi.vor_id = p_vor_id
        GROUP BY vi.estimate_item_id, vi.name, vi.unit, e.system, e.number, e.name
    ),
    changes AS (
        SELECT
            CASE
                WHEN c.current_total IS NULL THEN 'added'
                WHEN j.journal_total IS NULL THEN 'removed'
                ELSE 'modified'
            END AS change_type,
            COALESCE(j.section, c.section) AS section,
            COALESCE(j.row_label, c.row_label) AS row_label,
            COALESCE(j.unit, c.unit) AS unit,
            c.current_total AS old_quantity,
            j.journal_total AS new_quantity
        FROM journal j
        FULL OUTER JOIN current_agg c
            ON j.estimate_item_id IS NOT DISTINCT FROM c.estimate_item_id
           AND j.name = c.name
           AND j.unit = c.unit
        WHERE c.current_total IS NULL
           OR j.journal_total IS NULL
           OR ROUND(j.journal_total::numeric, 6)
                IS DISTINCT FROM ROUND(c.current_total::numeric, 6)
    )
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'change_type', change_type,
                'section', section,
                'row_label', row_label,
                'unit', unit,
                'old_quantity', old_quantity,
                'new_quantity', new_quantity
            )
            ORDER BY section, row_label
        ),
        '[]'::jsonb
    )
    INTO v_result
    FROM changes;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

COMMENT ON FUNCTION public.recalculate_vor_items_incremental(UUID) IS
    'Обновляет только позиции ВОР, у которых изменился суммарный факт в журнале; сохраняет раскладку норма/превышение для остальных.';

COMMENT ON FUNCTION public.recalculate_vor(UUID) IS
    'Инкрементальный пересчёт черновика ВОР из журналов работ.';

COMMENT ON FUNCTION public.vor_needs_recalc(UUID) IS
    'true, если суммарный факт в журнале отличается от суммы по позиции в vor_items (без учёта перераспределения).';

COMMENT ON FUNCTION public.get_vor_recalc_changes(UUID) IS
    'Список добавленных/удалённых/изменённых по объёму позиций для окна пересчёта.';

GRANT EXECUTE ON FUNCTION public.recalculate_vor_items_incremental(UUID) TO authenticated;

COMMIT;
