-- Сохранение позиций заявки одной операцией.
--
-- Заменяет последовательные insert/update/delete с клиента: правка позиций
-- становится атомарной и не зависит от числа строк. Позиции без id добавляются,
-- с id — обновляются, отсутствующие в списке — удаляются.
-- Доступно автору заявки в статусах draft и revision.

BEGIN;

CREATE OR REPLACE FUNCTION public.purchase_request_replace_items(
    p_request_id UUID,
    p_items JSONB
)
RETURNS SETOF public.purchase_request_items
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
    v_item JSONB;
    v_id UUID;
    v_name TEXT;
    v_quantity_text TEXT;
    v_quantity NUMERIC;
    v_unit TEXT;
    v_article TEXT;
    v_order INT := 0;
    v_kept UUID[] := '{}';
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
    END IF;

    SELECT * INTO v_row
    FROM public.purchase_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка не найдена';
    END IF;

    PERFORM public.purchase_request_internal_assert_company(v_row.company_id);

    IF v_row.created_by <> v_uid THEN
        RAISE EXCEPTION 'Редактировать можно только свою заявку';
    END IF;

    IF v_row.status NOT IN ('draft', 'revision') THEN
        RAISE EXCEPTION 'Позиции доступны для правки только в черновике и на доработке';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'create') THEN
        RAISE EXCEPTION 'Access denied' USING ERRCODE = '42501';
    END IF;

    FOR v_item IN
        SELECT elem
        FROM jsonb_array_elements(COALESCE(p_items, '[]'::jsonb)) AS t(elem)
    LOOP
        v_name := btrim(COALESCE(v_item->>'name', ''));
        IF v_name = '' THEN
            RAISE EXCEPTION 'У позиции не указано наименование';
        END IF;

        v_quantity_text := btrim(COALESCE(v_item->>'quantity', ''));
        IF v_quantity_text !~ '^[0-9]+([.,][0-9]+)?([eE][+-]?[0-9]+)?$' THEN
            RAISE EXCEPTION 'Некорректное количество позиции: %', v_quantity_text;
        END IF;

        v_quantity := replace(v_quantity_text, ',', '.')::NUMERIC;
        IF v_quantity <= 0 THEN
            RAISE EXCEPTION 'Количество позиции должно быть больше нуля';
        END IF;

        v_unit := COALESCE(NULLIF(btrim(COALESCE(v_item->>'unit', '')), ''), 'шт');
        v_article := NULLIF(btrim(COALESCE(v_item->>'article', '')), '');
        v_id := NULLIF(btrim(COALESCE(v_item->>'id', '')), '')::UUID;

        IF v_id IS NULL THEN
            INSERT INTO public.purchase_request_items (
                company_id, request_id, name, quantity, unit, article, sort_order
            ) VALUES (
                v_row.company_id, p_request_id, v_name, v_quantity, v_unit, v_article, v_order
            )
            RETURNING id INTO v_id;
        ELSE
            UPDATE public.purchase_request_items
            SET name = v_name,
                quantity = v_quantity,
                unit = v_unit,
                article = v_article,
                sort_order = v_order
            WHERE id = v_id
              AND request_id = p_request_id
              AND company_id = v_row.company_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Позиция не относится к заявке';
            END IF;
        END IF;

        v_kept := array_append(v_kept, v_id);
        v_order := v_order + 1;
    END LOOP;

    DELETE FROM public.purchase_request_items
    WHERE request_id = p_request_id
      AND NOT (id = ANY (v_kept));

    RETURN QUERY
    SELECT *
    FROM public.purchase_request_items
    WHERE request_id = p_request_id
    ORDER BY sort_order, created_at;
END;
$$;

COMMENT ON FUNCTION public.purchase_request_replace_items(UUID, JSONB) IS
    'Атомарно заменяет позиции заявки: добавляет, обновляет и удаляет строки одним вызовом.';

REVOKE ALL ON FUNCTION public.purchase_request_replace_items(UUID, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_replace_items(UUID, JSONB) TO authenticated;

COMMIT;
