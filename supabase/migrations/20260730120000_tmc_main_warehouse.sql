-- Основной склад + авто-приёмка при создании позиции каталога.
-- Добавляет is_main / is_system на tmc_warehouses, seed основного склада,
-- RPC tmc_create_item_with_receipt (одна транзакция: позиция + поступление).

BEGIN;

-- ---------------------------------------------------------------------------
-- Колонки is_main / is_system на складах
-- ---------------------------------------------------------------------------
ALTER TABLE public.tmc_warehouses
    ADD COLUMN IF NOT EXISTS is_main BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS is_system BOOLEAN NOT NULL DEFAULT false;

-- Один основной склад на компанию
DROP INDEX IF EXISTS public.idx_tmc_warehouses_main_unique;
CREATE UNIQUE INDEX IF NOT EXISTS idx_tmc_warehouses_main_unique
    ON public.tmc_warehouses (company_id)
    WHERE is_main = true;

-- Системный склад нельзя переименовать (через UPDATE name) — защищаем триггером.
CREATE OR REPLACE FUNCTION public.tmc_protect_system_warehouse()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF OLD.is_system = true AND NEW.name IS DISTINCT FROM OLD.name THEN
        RAISE EXCEPTION 'Системный склад нельзя переименовать';
    END IF;
    IF OLD.is_system = true AND NEW.is_archived = true THEN
        RAISE EXCEPTION 'Системный склад нельзя архивировать';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tmc_warehouses_protect_system ON public.tmc_warehouses;
CREATE TRIGGER trg_tmc_warehouses_protect_system
    BEFORE UPDATE ON public.tmc_warehouses
    FOR EACH ROW EXECUTE FUNCTION public.tmc_protect_system_warehouse();

REVOKE ALL ON FUNCTION public.tmc_protect_system_warehouse() FROM PUBLIC;

-- ---------------------------------------------------------------------------
-- Seed: основной склад для каждой компании (если его ещё нет)
-- ---------------------------------------------------------------------------
INSERT INTO public.tmc_warehouses (company_id, name, is_main, is_system)
SELECT c.id, 'Основной', true, true
FROM public.companies c
WHERE NOT EXISTS (
    SELECT 1 FROM public.tmc_warehouses w
    WHERE w.company_id = c.id AND w.is_main = true
)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------------
-- RLS: запретить DELETE системных складов
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "tmc_delete_tmc_warehouses" ON public.tmc_warehouses;
CREATE POLICY "tmc_delete_tmc_warehouses"
ON public.tmc_warehouses FOR DELETE TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'tmc', 'delete')
    AND is_system = false
);

-- ---------------------------------------------------------------------------
-- RPC: создание позиции каталога + (опционально) поступление на склад
-- p_payload JSONB:
-- {
--   "company_id": "...",
--   "item": { поля tmc_items без id/company_id/quantity/total_cost },
--   "receive": null | { "warehouse_id": "...", "quantity": 10, "unit_price": null, "condition_id": null }
-- }
-- Возвращает { "item_id": "...", "operation_id": null|uuid }
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.tmc_create_item_with_receipt(p_payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_company_id UUID;
    v_item JSONB;
    v_receive JSONB;
    v_item_id UUID;
    v_op_id UUID;
    v_op_result JSONB;
    v_qty NUMERIC;
    v_warehouse_id UUID;
    v_condition_id UUID;
    v_op_payload JSONB;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Не авторизован';
    END IF;

    v_company_id := (p_payload->>'company_id')::UUID;
    v_item := p_payload->'item';
    v_receive := p_payload->'receive';

    IF v_company_id IS NULL OR v_item IS NULL THEN
        RAISE EXCEPTION 'company_id и item обязательны';
    END IF;

    IF NOT (v_company_id IN (SELECT public.get_my_company_ids())) THEN
        RAISE EXCEPTION 'Нет доступа к компании';
    END IF;

    IF NOT public.check_permission(v_uid, 'tmc', 'create') THEN
        RAISE EXCEPTION 'Нет права создания ТМЦ';
    END IF;

    -- Создаём позицию каталога
    INSERT INTO public.tmc_items (
        company_id, name, category_id, subcategory_id, accounting_type,
        sku, manufacturer, model, unit_of_measure, description, photo_url,
        status, delivery_date, acceptance_date, supplier_id, document_number,
        unit_price, vat_amount, warranty_until, created_by
    ) VALUES (
        v_company_id,
        v_item->>'name',
        NULLIF(v_item->>'category_id', '')::UUID,
        NULLIF(v_item->>'subcategory_id', '')::UUID,
        COALESCE(v_item->>'accounting_type', 'individual'),
        NULLIF(v_item->>'sku', ''),
        NULLIF(v_item->>'manufacturer', ''),
        NULLIF(v_item->>'model', ''),
        COALESCE(v_item->>'unit_of_measure', 'шт'),
        NULLIF(v_item->>'description', ''),
        NULLIF(v_item->>'photo_url', ''),
        COALESCE(v_item->>'status', 'active'),
        NULLIF(v_item->>'delivery_date', '')::DATE,
        NULLIF(v_item->>'acceptance_date', '')::DATE,
        NULLIF(v_item->>'supplier_id', '')::UUID,
        NULLIF(v_item->>'document_number', ''),
        COALESCE(NULLIF(v_item->>'unit_price', '')::NUMERIC, 0),
        COALESCE(NULLIF(v_item->>'vat_amount', '')::NUMERIC, 0),
        NULLIF(v_item->>'warranty_until', '')::DATE,
        v_uid
    )
    RETURNING id INTO v_item_id;

    -- Если приёмка не запрошена — выходим
    IF v_receive IS NULL OR v_receive = 'null'::jsonb THEN
        RETURN jsonb_build_object('item_id', v_item_id, 'operation_id', NULL);
    END IF;

    v_qty := COALESCE((v_receive->>'quantity')::NUMERIC, 0);
    v_warehouse_id := NULLIF(v_receive->>'warehouse_id', '')::UUID;
    v_condition_id := NULLIF(v_receive->>'condition_id', '')::UUID;

    IF v_qty <= 0 THEN
        RAISE EXCEPTION 'Количество приёмки должно быть больше 0';
    END IF;
    IF v_warehouse_id IS NULL THEN
        RAISE EXCEPTION 'Склад приёмки обязателен';
    END IF;

    -- Проверяем склад принадлежит компании
    IF NOT EXISTS (
        SELECT 1 FROM public.tmc_warehouses
        WHERE id = v_warehouse_id AND company_id = v_company_id AND is_archived = false
    ) THEN
        RAISE EXCEPTION 'Склад не найден';
    END IF;

    -- Создаём операцию поступления (тип учёта обрабатывается внутри tmc_post_operation)
    v_op_payload := jsonb_build_object(
        'company_id', v_company_id,
        'operation_type', 'receipt',
        'operated_at', now(),
        'to_location_type', 'warehouse',
        'to_warehouse_id', v_warehouse_id,
        'condition_id', v_condition_id,
        'items', jsonb_build_array(jsonb_build_object(
            'item_id', v_item_id,
            'quantity', v_qty,
            'unit_price', NULLIF(v_receive->>'unit_price', '')::NUMERIC,
            'condition_id', v_condition_id
        ))
    );

    v_op_result := public.tmc_post_operation(v_op_payload);
    v_op_id := (v_op_result->>'operation_id')::UUID;

    RETURN jsonb_build_object(
        'item_id', v_item_id,
        'operation_id', v_op_id
    );
END;
$$;

REVOKE ALL ON FUNCTION public.tmc_create_item_with_receipt(JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tmc_create_item_with_receipt(JSONB) TO authenticated;

COMMIT;
