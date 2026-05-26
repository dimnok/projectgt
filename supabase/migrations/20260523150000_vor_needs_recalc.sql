-- Общий расчёт строк ВОР + проверка расхождения с сохранённым составом.

BEGIN;

CREATE OR REPLACE FUNCTION public.compute_vor_item_rows(p_vor_id UUID)
RETURNS TABLE (
    estimate_item_id UUID,
    name TEXT,
    unit TEXT,
    quantity DOUBLE PRECISION,
    is_extra BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_contract_id UUID;
    v_start_date DATE;
    v_end_date DATE;
    v_systems TEXT[];
BEGIN
    SELECT contract_id, start_date, end_date
    INTO v_contract_id, v_start_date, v_end_date
    FROM public.vors
    WHERE id = p_vor_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ведомость ВОР с ID % не найдена', p_vor_id;
    END IF;

    SELECT array_agg(system_name)
    INTO v_systems
    FROM public.vor_systems
    WHERE vor_id = p_vor_id;

    RETURN QUERY
    WITH fact_data AS (
        SELECT
            wi.estimate_id,
            wi.name AS work_name,
            wi.unit AS work_unit,
            SUM(wi.quantity) AS total_fact
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
    processed_items AS (
        SELECT
            fd.estimate_id,
            fd.work_name,
            fd.work_unit,
            fd.total_fact,
            e.quantity AS estimate_qty,
            COALESCE((
                SELECT SUM(vi.quantity)
                FROM public.vor_items vi
                JOIN public.vors v ON vi.vor_id = v.id
                WHERE vi.estimate_item_id = fd.estimate_id
                  AND v.status = 'approved'
                  AND v.end_date < v_start_date
            ), 0) AS prev_approved_qty
        FROM fact_data fd
        LEFT JOIN public.estimates e ON fd.estimate_id = e.id
    ),
    split_logic AS (
        SELECT
            estimate_id,
            work_name,
            work_unit,
            GREATEST(0, COALESCE(estimate_qty, 0) - prev_approved_qty) AS remaining_limit,
            total_fact
        FROM processed_items
    ),
    final_rows AS (
        SELECT
            estimate_id,
            work_name,
            work_unit,
            LEAST(total_fact, remaining_limit) AS qty,
            false AS is_extra
        FROM split_logic
        WHERE estimate_id IS NOT NULL
          AND remaining_limit > 0
          AND LEAST(total_fact, remaining_limit) > 0

        UNION ALL

        SELECT
            estimate_id,
            work_name,
            work_unit,
            CASE
                WHEN estimate_id IS NULL THEN total_fact
                ELSE GREATEST(0, total_fact - remaining_limit)
            END AS qty,
            true AS is_extra
        FROM split_logic
        WHERE estimate_id IS NULL
           OR (estimate_id IS NOT NULL AND total_fact > remaining_limit)
    )
    SELECT
        fr.estimate_id,
        fr.work_name,
        fr.work_unit,
        fr.qty::double precision,
        fr.is_extra
    FROM final_rows fr
    WHERE fr.qty > 0;
END;
$$;

CREATE OR REPLACE FUNCTION public.populate_vor_items(p_vor_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_company_id UUID;
BEGIN
    SELECT company_id
    INTO v_company_id
    FROM public.vors
    WHERE id = p_vor_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ведомость ВОР с ID % не найдена', p_vor_id;
    END IF;

    DELETE FROM public.vor_items
    WHERE vor_id = p_vor_id;

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
    FROM public.compute_vor_item_rows(p_vor_id) AS r;
END;
$$;

CREATE OR REPLACE FUNCTION public.vor_needs_recalc(p_vor_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_status public.vor_status;
    v_has_diff BOOLEAN;
BEGIN
    SELECT status
    INTO v_status
    FROM public.vors
    WHERE id = p_vor_id;

    IF NOT FOUND THEN
        RETURN false;
    END IF;

    IF v_status IS DISTINCT FROM 'draft'::public.vor_status THEN
        RETURN false;
    END IF;

    WITH expected AS (
        SELECT
            e.estimate_item_id,
            COALESCE(e.name, '') AS name,
            COALESCE(e.unit, '') AS unit,
            e.is_extra,
            ROUND(e.quantity::numeric, 6) AS quantity
        FROM public.compute_vor_item_rows(p_vor_id) AS e
    ),
    current_rows AS (
        SELECT
            vi.estimate_item_id,
            COALESCE(vi.name, '') AS name,
            COALESCE(vi.unit, '') AS unit,
            vi.is_extra,
            ROUND(vi.quantity::numeric, 6) AS quantity
        FROM public.vor_items vi
        WHERE vi.vor_id = p_vor_id
    ),
  diff AS (
        SELECT * FROM expected
        EXCEPT
        SELECT * FROM current_rows
        UNION ALL
        SELECT * FROM current_rows
        EXCEPT
        SELECT * FROM expected
    )
    SELECT EXISTS (SELECT 1 FROM diff)
    INTO v_has_diff;

    RETURN COALESCE(v_has_diff, false);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_draft_vor_needs_recalc(p_contract_id UUID)
RETURNS TABLE (vor_id UUID, needs_recalc BOOLEAN)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT
        v.id,
        public.vor_needs_recalc(v.id)
    FROM public.vors v
    WHERE v.contract_id = p_contract_id
      AND v.status = 'draft'::public.vor_status;
$$;

COMMENT ON FUNCTION public.compute_vor_item_rows(UUID) IS
    'Рассчитывает ожидаемый состав ВОР из журналов работ (без записи в vor_items).';

COMMENT ON FUNCTION public.vor_needs_recalc(UUID) IS
    'true, если факт работ за период не совпадает с сохранённым составом черновика ВОР.';

COMMENT ON FUNCTION public.get_draft_vor_needs_recalc(UUID) IS
    'Флаги необходимости пересчёта для всех черновиков ВОР по договору.';

GRANT EXECUTE ON FUNCTION public.compute_vor_item_rows(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.vor_needs_recalc(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_draft_vor_needs_recalc(UUID) TO authenticated;

COMMIT;
