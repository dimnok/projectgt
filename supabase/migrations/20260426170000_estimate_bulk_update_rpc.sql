-- Массовое обновление строк сметы из Excel без удаления существующих данных.
-- RPC сначала поддерживает dry-run, а при применении пишет audit и выполняет
-- только update/insert по неизменяемым ключам строк.

BEGIN;

CREATE TABLE IF NOT EXISTS public.estimate_bulk_update_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    contract_id UUID NOT NULL REFERENCES public.contracts(id) ON DELETE CASCADE,
    object_id UUID REFERENCES public.objects(id) ON DELETE SET NULL,
    estimate_title TEXT NOT NULL,
    source_file_name TEXT,
    rows_total INTEGER NOT NULL DEFAULT 0,
    rows_updated INTEGER NOT NULL DEFAULT 0,
    rows_inserted INTEGER NOT NULL DEFAULT 0,
    rows_skipped INTEGER NOT NULL DEFAULT 0,
    rows_conflicts INTEGER NOT NULL DEFAULT 0,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.estimate_bulk_update_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES public.estimate_bulk_update_batches(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    estimate_id UUID REFERENCES public.estimates(id) ON DELETE SET NULL,
    position_id UUID,
    row_no INTEGER NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('update', 'insert', 'noop', 'invalid', 'conflict')),
    status TEXT NOT NULL CHECK (status IN ('applied', 'skipped', 'conflict')),
    message TEXT,
    old_data JSONB,
    new_data JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_estimate_bulk_update_batches_company
    ON public.estimate_bulk_update_batches(company_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_estimate_bulk_update_batches_estimate
    ON public.estimate_bulk_update_batches(company_id, contract_id, estimate_title);

CREATE INDEX IF NOT EXISTS idx_estimate_bulk_update_items_batch
    ON public.estimate_bulk_update_items(batch_id);

ALTER TABLE public.estimate_bulk_update_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estimate_bulk_update_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Strict SELECT for estimate_bulk_update_batches" ON public.estimate_bulk_update_batches;
CREATE POLICY "Strict SELECT for estimate_bulk_update_batches"
ON public.estimate_bulk_update_batches FOR SELECT
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'read')
);

DROP POLICY IF EXISTS "Strict INSERT for estimate_bulk_update_batches" ON public.estimate_bulk_update_batches;
CREATE POLICY "Strict INSERT for estimate_bulk_update_batches"
ON public.estimate_bulk_update_batches FOR INSERT
TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'update')
);

DROP POLICY IF EXISTS "Strict SELECT for estimate_bulk_update_items" ON public.estimate_bulk_update_items;
CREATE POLICY "Strict SELECT for estimate_bulk_update_items"
ON public.estimate_bulk_update_items FOR SELECT
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'read')
);

DROP POLICY IF EXISTS "Strict INSERT for estimate_bulk_update_items" ON public.estimate_bulk_update_items;
CREATE POLICY "Strict INSERT for estimate_bulk_update_items"
ON public.estimate_bulk_update_items FOR INSERT
TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'update')
);

CREATE OR REPLACE FUNCTION public.apply_estimate_bulk_update(
    p_company_id UUID,
    p_contract_id UUID,
    p_estimate_title TEXT,
    p_rows JSONB,
    p_dry_run BOOLEAN DEFAULT true,
    p_object_id UUID DEFAULT NULL,
    p_source_file_name TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_is_owner BOOLEAN := false;
    v_user_objects UUID[] := '{}'::UUID[];
    v_row JSONB;
    v_result JSONB;
    v_results JSONB := '[]'::JSONB;
    v_row_no INTEGER;
    v_id_text TEXT;
    v_position_text TEXT;
    v_updated_at_text TEXT;
    v_id UUID;
    v_position_id UUID;
    v_import_updated_at TIMESTAMPTZ;
    v_existing RECORD;
    v_system TEXT;
    v_subsystem TEXT;
    v_number TEXT;
    v_name TEXT;
    v_article TEXT;
    v_manufacturer TEXT;
    v_unit TEXT;
    v_quantity DOUBLE PRECISION;
    v_price DOUBLE PRECISION;
    v_total DOUBLE PRECISION;
    v_action TEXT;
    v_status TEXT;
    v_message TEXT;
    v_old_data JSONB;
    v_new_data JSONB;
    v_fact_count INTEGER;
    v_rows_total INTEGER := 0;
    v_rows_updated INTEGER := 0;
    v_rows_inserted INTEGER := 0;
    v_rows_skipped INTEGER := 0;
    v_rows_conflicts INTEGER := 0;
    v_batch_id UUID;
    v_applied_estimate_id UUID;
    v_uuid_pattern CONSTANT TEXT := '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Пользователь не авторизован';
    END IF;

    IF NOT public.check_permission(v_user_id, 'estimates', 'update') THEN
        RAISE EXCEPTION 'Нет права на обновление смет';
    END IF;

    IF NOT public.check_permission(v_user_id, 'estimates', 'create') THEN
        RAISE EXCEPTION 'Нет права на добавление новых строк смет';
    END IF;

    IF p_company_id NOT IN (SELECT public.get_my_company_ids()) THEN
        RAISE EXCEPTION 'Компания недоступна текущему пользователю';
    END IF;

    IF p_estimate_title IS NULL OR btrim(p_estimate_title) = '' THEN
        RAISE EXCEPTION 'Название сметы обязательно';
    END IF;

    IF jsonb_typeof(p_rows) IS DISTINCT FROM 'array' THEN
        RAISE EXCEPTION 'p_rows должен быть JSON-массивом';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.contracts c
        WHERE c.id = p_contract_id
          AND c.company_id = p_company_id
          AND (p_object_id IS NULL OR c.object_id = p_object_id)
    ) THEN
        RAISE EXCEPTION 'Договор не найден или не принадлежит выбранной компании/объекту';
    END IF;

    SELECT COALESCE(cm.is_owner, false), COALESCE(p.object_ids, '{}'::UUID[])
    INTO v_is_owner, v_user_objects
    FROM public.profiles p
    LEFT JOIN public.company_members cm
      ON cm.user_id = p.id
     AND cm.company_id = p_company_id
    WHERE p.id = v_user_id;

    IF NOT v_is_owner AND (
        p_object_id IS NULL OR NOT (p_object_id = ANY(v_user_objects))
    ) THEN
        RAISE EXCEPTION 'Нет доступа к объекту выбранной сметы';
    END IF;

    FOR v_row, v_row_no IN
        SELECT value, ordinality::INTEGER
        FROM jsonb_array_elements(p_rows) WITH ORDINALITY
    LOOP
        v_rows_total := v_rows_total + 1;
        v_action := 'invalid';
        v_status := 'skipped';
        v_message := NULL;
        v_old_data := NULL;
        v_new_data := NULL;
        v_id := NULL;
        v_position_id := NULL;
        v_import_updated_at := NULL;

        v_id_text := NULLIF(btrim(COALESCE(v_row->>'id', '')), '');
        v_position_text := NULLIF(btrim(COALESCE(v_row->>'position_id', '')), '');
        v_updated_at_text := NULLIF(btrim(COALESCE(v_row->>'updated_at', '')), '');

        IF v_id_text IS NOT NULL THEN
            IF lower(v_id_text) !~ v_uuid_pattern THEN
                v_message := 'Некорректный ID строки';
                v_rows_skipped := v_rows_skipped + 1;
                v_results := v_results || jsonb_build_array(jsonb_build_object(
                    'row_no', v_row_no,
                    'id', v_id_text,
                    'position_id', v_position_text,
                    'action', v_action,
                    'status', v_status,
                    'message', v_message
                ));
                CONTINUE;
            END IF;
            v_id := v_id_text::UUID;
        END IF;

        IF v_position_text IS NOT NULL THEN
            IF lower(v_position_text) !~ v_uuid_pattern THEN
                v_message := 'Некорректный ID позиции';
                v_rows_skipped := v_rows_skipped + 1;
                v_results := v_results || jsonb_build_array(jsonb_build_object(
                    'row_no', v_row_no,
                    'id', v_id_text,
                    'position_id', v_position_text,
                    'action', v_action,
                    'status', v_status,
                    'message', v_message
                ));
                CONTINUE;
            END IF;
            v_position_id := v_position_text::UUID;
        END IF;

        IF v_updated_at_text IS NOT NULL THEN
            BEGIN
                v_import_updated_at := v_updated_at_text::TIMESTAMPTZ;
            EXCEPTION WHEN OTHERS THEN
                v_message := 'Некорректное значение updated_at';
                v_rows_skipped := v_rows_skipped + 1;
                v_results := v_results || jsonb_build_array(jsonb_build_object(
                    'row_no', v_row_no,
                    'id', v_id_text,
                    'position_id', v_position_text,
                    'action', v_action,
                    'status', v_status,
                    'message', v_message
                ));
                CONTINUE;
            END;
        END IF;

        v_system := COALESCE(v_row->>'system', '');
        v_subsystem := COALESCE(v_row->>'subsystem', '');
        v_number := COALESCE(v_row->>'number', '');
        v_name := btrim(COALESCE(v_row->>'name', ''));
        v_article := COALESCE(v_row->>'article', '');
        v_manufacturer := COALESCE(v_row->>'manufacturer', '');
        v_unit := btrim(COALESCE(v_row->>'unit', ''));

        BEGIN
            v_quantity := COALESCE(NULLIF(v_row->>'quantity', '')::DOUBLE PRECISION, 0);
            v_price := COALESCE(NULLIF(v_row->>'price', '')::DOUBLE PRECISION, 0);
        EXCEPTION WHEN OTHERS THEN
            v_message := 'Количество и цена должны быть числами';
            v_rows_skipped := v_rows_skipped + 1;
            v_results := v_results || jsonb_build_array(jsonb_build_object(
                'row_no', v_row_no,
                'id', v_id_text,
                'position_id', v_position_text,
                'action', v_action,
                'status', v_status,
                'message', v_message
            ));
            CONTINUE;
        END;

        IF v_name = '' OR v_unit = '' THEN
            v_message := 'Наименование и единица измерения обязательны';
            v_rows_skipped := v_rows_skipped + 1;
            v_results := v_results || jsonb_build_array(jsonb_build_object(
                'row_no', v_row_no,
                'id', v_id_text,
                'position_id', v_position_text,
                'action', v_action,
                'status', v_status,
                'message', v_message
            ));
            CONTINUE;
        END IF;

        IF v_quantity < 0 OR v_price < 0 THEN
            v_message := 'Количество и цена не могут быть отрицательными';
            v_rows_skipped := v_rows_skipped + 1;
            v_results := v_results || jsonb_build_array(jsonb_build_object(
                'row_no', v_row_no,
                'id', v_id_text,
                'position_id', v_position_text,
                'action', v_action,
                'status', v_status,
                'message', v_message
            ));
            CONTINUE;
        END IF;

        v_total := v_quantity * v_price;
        v_new_data := jsonb_build_object(
            'system', v_system,
            'subsystem', v_subsystem,
            'number', v_number,
            'name', v_name,
            'article', v_article,
            'manufacturer', v_manufacturer,
            'unit', v_unit,
            'quantity', v_quantity,
            'price', v_price,
            'total', v_total
        );

        IF v_id IS NOT NULL THEN
            SELECT e.*
            INTO v_existing
            FROM public.estimates e
            WHERE e.id = v_id
              AND e.company_id = p_company_id
              AND e.contract_id = p_contract_id
              AND e.estimate_title = p_estimate_title
              AND (
                (p_object_id IS NULL AND e.object_id IS NULL)
                OR (p_object_id IS NOT NULL AND e.object_id = p_object_id)
              );

            IF NOT FOUND THEN
                v_message := 'Строка с указанным ID не найдена в выбранной смете';
                v_rows_skipped := v_rows_skipped + 1;
                v_results := v_results || jsonb_build_array(jsonb_build_object(
                    'row_no', v_row_no,
                    'id', v_id_text,
                    'position_id', v_position_text,
                    'action', v_action,
                    'status', v_status,
                    'message', v_message
                ));
                CONTINUE;
            END IF;

            v_old_data := jsonb_build_object(
                'system', v_existing.system,
                'subsystem', v_existing.subsystem,
                'number', v_existing.number,
                'name', v_existing.name,
                'article', v_existing.article,
                'manufacturer', v_existing.manufacturer,
                'unit', v_existing.unit,
                'quantity', v_existing.quantity,
                'price', v_existing.price,
                'total', v_existing.total,
                'updated_at', v_existing.updated_at
            );

            IF v_position_id IS NOT NULL AND v_existing.position_id <> v_position_id THEN
                v_action := 'conflict';
                v_status := 'conflict';
                v_message := 'ID строки и ID позиции относятся к разным записям';
                v_rows_conflicts := v_rows_conflicts + 1;
            ELSIF v_import_updated_at IS NOT NULL
                AND abs(extract(epoch FROM (v_existing.updated_at - v_import_updated_at))) > 1 THEN
                v_action := 'conflict';
                v_status := 'conflict';
                v_message := 'Строка была изменена после выгрузки Excel';
                v_rows_conflicts := v_rows_conflicts + 1;
            ELSIF v_existing.system IS NOT DISTINCT FROM v_system
                AND v_existing.subsystem IS NOT DISTINCT FROM v_subsystem
                AND v_existing.number IS NOT DISTINCT FROM v_number
                AND v_existing.name IS NOT DISTINCT FROM v_name
                AND v_existing.article IS NOT DISTINCT FROM v_article
                AND v_existing.manufacturer IS NOT DISTINCT FROM v_manufacturer
                AND v_existing.unit IS NOT DISTINCT FROM v_unit
                AND abs(v_existing.quantity - v_quantity) <= 0.000001
                AND abs(v_existing.price - v_price) <= 0.000001 THEN
                v_action := 'noop';
                v_status := 'skipped';
                v_message := 'Без изменений';
                v_rows_skipped := v_rows_skipped + 1;
            ELSE
                SELECT count(*)::INTEGER
                INTO v_fact_count
                FROM public.work_items wi
                WHERE wi.estimate_id = v_existing.id;

                v_action := 'update';
                v_status := 'applied';
                v_message := CASE
                    WHEN v_fact_count > 0 THEN
                        format('Будут обновлены связанные фактические строки: %s', v_fact_count)
                    ELSE
                        'Будет обновлена существующая строка'
                END;
                v_rows_updated := v_rows_updated + 1;
            END IF;

            v_results := v_results || jsonb_build_array(jsonb_build_object(
                'row_no', v_row_no,
                'id', v_existing.id,
                'position_id', v_existing.position_id,
                'action', v_action,
                'status', v_status,
                'message', v_message,
                'old_data', v_old_data,
                'new_data', v_new_data
            ));
        ELSE
            IF v_position_id IS NOT NULL AND EXISTS (
                SELECT 1
                FROM public.estimates e
                WHERE e.company_id = p_company_id
                  AND e.contract_id = p_contract_id
                  AND e.position_id = v_position_id
            ) THEN
                v_action := 'conflict';
                v_status := 'conflict';
                v_message := 'ID позиции уже существует, но ID строки пустой';
                v_rows_conflicts := v_rows_conflicts + 1;
            ELSE
                v_action := 'insert';
                v_status := 'applied';
                v_message := 'Будет добавлена новая строка';
                v_rows_inserted := v_rows_inserted + 1;
                IF v_position_id IS NULL THEN
                    v_position_id := gen_random_uuid();
                END IF;
            END IF;

            v_results := v_results || jsonb_build_array(jsonb_build_object(
                'row_no', v_row_no,
                'id', NULL,
                'position_id', v_position_id,
                'action', v_action,
                'status', v_status,
                'message', v_message,
                'old_data', NULL,
                'new_data', v_new_data
            ));
        END IF;
    END LOOP;

    IF p_dry_run THEN
        RETURN jsonb_build_object(
            'dry_run', true,
            'applied', false,
            'summary', jsonb_build_object(
                'total', v_rows_total,
                'updated', v_rows_updated,
                'inserted', v_rows_inserted,
                'skipped', v_rows_skipped,
                'conflicts', v_rows_conflicts
            ),
            'items', v_results
        );
    END IF;

    IF v_rows_conflicts > 0 OR EXISTS (
        SELECT 1
        FROM jsonb_array_elements(v_results) item
        WHERE item->>'action' = 'invalid'
    ) THEN
        RETURN jsonb_build_object(
            'dry_run', false,
            'applied', false,
            'message', 'Обновление не применено: есть конфликты или ошибки в строках',
            'summary', jsonb_build_object(
                'total', v_rows_total,
                'updated', v_rows_updated,
                'inserted', v_rows_inserted,
                'skipped', v_rows_skipped,
                'conflicts', v_rows_conflicts
            ),
            'items', v_results
        );
    END IF;

    INSERT INTO public.estimate_bulk_update_batches (
        company_id,
        contract_id,
        object_id,
        estimate_title,
        source_file_name,
        rows_total,
        rows_updated,
        rows_inserted,
        rows_skipped,
        rows_conflicts,
        created_by
    )
    VALUES (
        p_company_id,
        p_contract_id,
        p_object_id,
        p_estimate_title,
        p_source_file_name,
        v_rows_total,
        v_rows_updated,
        v_rows_inserted,
        v_rows_skipped,
        v_rows_conflicts,
        v_user_id
    )
    RETURNING id INTO v_batch_id;

    FOR v_result IN
        SELECT value
        FROM jsonb_array_elements(v_results)
    LOOP
        v_action := v_result->>'action';
        v_status := v_result->>'status';
        v_message := v_result->>'message';
        v_old_data := v_result->'old_data';
        v_new_data := v_result->'new_data';
        v_row_no := (v_result->>'row_no')::INTEGER;
        v_applied_estimate_id := NULL;
        v_id_text := NULLIF(v_result->>'id', '');
        v_position_text := NULLIF(v_result->>'position_id', '');
        v_position_id := CASE
            WHEN v_position_text IS NOT NULL AND lower(v_position_text) ~ v_uuid_pattern
                THEN v_position_text::UUID
            ELSE NULL
        END;

        IF v_action = 'update' AND v_status = 'applied' THEN
            v_applied_estimate_id := (v_result->>'id')::UUID;

            UPDATE public.estimates
            SET
                system = v_new_data->>'system',
                subsystem = v_new_data->>'subsystem',
                number = v_new_data->>'number',
                name = v_new_data->>'name',
                article = v_new_data->>'article',
                manufacturer = v_new_data->>'manufacturer',
                unit = v_new_data->>'unit',
                quantity = (v_new_data->>'quantity')::DOUBLE PRECISION,
                price = (v_new_data->>'price')::DOUBLE PRECISION,
                total = (v_new_data->>'total')::DOUBLE PRECISION,
                updated_at = now()
            WHERE id = v_applied_estimate_id
              AND company_id = p_company_id;
        ELSIF v_action = 'insert' AND v_status = 'applied' THEN
            INSERT INTO public.estimates (
                company_id,
                contract_id,
                object_id,
                estimate_title,
                position_id,
                system,
                subsystem,
                number,
                name,
                article,
                manufacturer,
                unit,
                quantity,
                price,
                total
            )
            VALUES (
                p_company_id,
                p_contract_id,
                p_object_id,
                p_estimate_title,
                v_position_id,
                v_new_data->>'system',
                v_new_data->>'subsystem',
                v_new_data->>'number',
                v_new_data->>'name',
                v_new_data->>'article',
                v_new_data->>'manufacturer',
                v_new_data->>'unit',
                (v_new_data->>'quantity')::DOUBLE PRECISION,
                (v_new_data->>'price')::DOUBLE PRECISION,
                (v_new_data->>'total')::DOUBLE PRECISION
            )
            RETURNING id INTO v_applied_estimate_id;
        ELSE
            IF v_id_text IS NOT NULL AND lower(v_id_text) ~ v_uuid_pattern THEN
                v_applied_estimate_id := v_id_text::UUID;
            END IF;
        END IF;

        INSERT INTO public.estimate_bulk_update_items (
            batch_id,
            company_id,
            estimate_id,
            position_id,
            row_no,
            action,
            status,
            message,
            old_data,
            new_data
        )
        VALUES (
            v_batch_id,
            p_company_id,
            v_applied_estimate_id,
            v_position_id,
            v_row_no,
            v_action,
            CASE
                WHEN v_action IN ('update', 'insert') AND v_status = 'applied' THEN 'applied'
                WHEN v_status = 'conflict' THEN 'conflict'
                ELSE 'skipped'
            END,
            v_message,
            v_old_data,
            v_new_data
        );
    END LOOP;

    RETURN jsonb_build_object(
        'dry_run', false,
        'applied', true,
        'batch_id', v_batch_id,
        'summary', jsonb_build_object(
            'total', v_rows_total,
            'updated', v_rows_updated,
            'inserted', v_rows_inserted,
            'skipped', v_rows_skipped,
            'conflicts', v_rows_conflicts
        ),
        'items', v_results
    );
END;
$$;

REVOKE ALL ON FUNCTION public.apply_estimate_bulk_update(UUID, UUID, TEXT, JSONB, BOOLEAN, UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.apply_estimate_bulk_update(UUID, UUID, TEXT, JSONB, BOOLEAN, UUID, TEXT) TO authenticated;

NOTIFY pgrst, 'reload schema';

COMMIT;
