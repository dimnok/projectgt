-- RPC проведения операций ТМЦ: транзакционное изменение остатков / единиц.

BEGIN;

-- ---------------------------------------------------------------------------
-- Генерация инвентарного номера
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.tmc_next_inventory_number(p_company_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next BIGINT;
BEGIN
  INSERT INTO public.tmc_inventory_number_seq (company_id, last_value)
  VALUES (p_company_id, 1)
  ON CONFLICT (company_id) DO UPDATE
    SET last_value = public.tmc_inventory_number_seq.last_value + 1
  RETURNING last_value INTO v_next;

  RETURN 'ТМЦ-' || lpad(v_next::text, 6, '0');
END;
$$;

REVOKE ALL ON FUNCTION public.tmc_next_inventory_number(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tmc_next_inventory_number(UUID) TO authenticated;

-- ---------------------------------------------------------------------------
-- Корректировка количественного остатка (внутренний helper)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.tmc_adjust_balance(
  p_company_id UUID,
  p_item_id UUID,
  p_location_type TEXT,
  p_warehouse_id UUID,
  p_object_id UUID,
  p_employee_id UUID,
  p_location_note TEXT,
  p_delta NUMERIC
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.tmc_balances%ROWTYPE;
  v_new_qty NUMERIC;
BEGIN
  SELECT * INTO v_row
  FROM public.tmc_balances
  WHERE company_id = p_company_id
    AND item_id = p_item_id
    AND location_type = p_location_type
    AND warehouse_id IS NOT DISTINCT FROM p_warehouse_id
    AND object_id IS NOT DISTINCT FROM p_object_id
    AND employee_id IS NOT DISTINCT FROM p_employee_id
    AND location_note IS NOT DISTINCT FROM p_location_note
  FOR UPDATE;

  IF NOT FOUND THEN
    IF p_delta < 0 THEN
      RAISE EXCEPTION 'Недостаточно остатка ТМЦ для списания';
    END IF;
    IF p_delta = 0 THEN
      RETURN;
    END IF;
    INSERT INTO public.tmc_balances (
      company_id, item_id, location_type,
      warehouse_id, object_id, employee_id, location_note, quantity
    ) VALUES (
      p_company_id, p_item_id, p_location_type,
      p_warehouse_id, p_object_id, p_employee_id, p_location_note, p_delta
    );
    RETURN;
  END IF;

  v_new_qty := v_row.quantity + p_delta;
  IF v_new_qty < 0 THEN
    RAISE EXCEPTION 'Недостаточно остатка ТМЦ (доступно %, требуется %)',
      v_row.quantity, abs(p_delta);
  END IF;

  IF v_new_qty = 0 AND v_row.reserved_quantity = 0 THEN
    DELETE FROM public.tmc_balances WHERE id = v_row.id;
  ELSE
    UPDATE public.tmc_balances
    SET quantity = v_new_qty, updated_at = now()
    WHERE id = v_row.id;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.tmc_adjust_balance(
  UUID, UUID, TEXT, UUID, UUID, UUID, TEXT, NUMERIC
) FROM PUBLIC;

-- ---------------------------------------------------------------------------
-- Статус по типу операции / локации
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.tmc_status_for_location(p_location_type TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_location_type
    WHEN 'warehouse' THEN 'in_stock'
    WHEN 'office' THEN 'in_stock'
    WHEN 'object' THEN 'on_object'
    WHEN 'employee' THEN 'issued'
    WHEN 'repair_org' THEN 'in_repair'
    ELSE 'in_stock'
  END;
$$;

CREATE OR REPLACE FUNCTION public.tmc_status_for_operation(p_operation_type TEXT, p_to_location_type TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_operation_type
    WHEN 'issue' THEN 'issued'
    WHEN 'transfer_between_employees' THEN 'issued'
    WHEN 'temporarily_transferred' THEN 'temporarily_transferred'
    WHEN 'send_to_repair' THEN 'in_repair'
    WHEN 'write_off' THEN 'written_off'
    WHEN 'shortage' THEN 'lost'
    WHEN 'reserve' THEN 'reserved'
    ELSE public.tmc_status_for_location(COALESCE(p_to_location_type, 'warehouse'))
  END;
$$;

-- ---------------------------------------------------------------------------
-- Основной RPC проведения операции
-- p_payload JSONB:
-- {
--   "company_id": "...",
--   "operation_type": "receipt|issue|...",
--   "operated_at": "...",
--   "document_number": null,
--   "basis": null,
--   "comment": null,
--   "from_location_type": "...",
--   "from_warehouse_id": null,
--   "from_object_id": null,
--   "from_employee_id": null,
--   "from_location_note": null,
--   "to_location_type": "...",
--   "to_warehouse_id": null,
--   "to_object_id": null,
--   "to_employee_id": null,
--   "to_location_note": null,
--   "responsible_employee_id": null,
--   "object_id": null,
--   "planned_return_date": null,
--   "condition_id": null,
--   "reverses_operation_id": null,
--   "items": [
--     {
--       "item_id": "...",
--       "unit_id": null,
--       "quantity": 1,
--       "unit_price": null,
--       "condition_id": null,
--       "inventory_number": null,
--       "serial_number": null,
--       "create_units": false,
--       "clothing_size": null,
--       "height_cm": null,
--       "season": null,
--       "service_life_days": null,
--       "next_replacement_date": null,
--       "comment": null,
--       "completeness_note": null
--     }
--   ],
--   -- extras for repair / write_off
--   "repair": { "reason": "...", "fault_description": "...", "repair_org_name": "...", "estimated_cost": 0 },
--   "write_off": { "reason": "wear", "act_number": "...", "book_value": 0 }
-- }
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.tmc_post_operation(p_payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_company_id UUID;
  v_op_type TEXT;
  v_op_id UUID;
  v_item JSONB;
  v_item_id UUID;
  v_unit_id UUID;
  v_qty NUMERIC;
  v_accounting TEXT;
  v_unit public.tmc_units%ROWTYPE;
  v_inv TEXT;
  v_new_status TEXT;
  v_perm_ok BOOLEAN := false;
  v_condition_id UUID;
  v_repair_id UUID;
  v_write_off_id UUID;
  v_from_type TEXT;
  v_to_type TEXT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Не авторизован';
  END IF;

  v_company_id := (p_payload->>'company_id')::UUID;
  v_op_type := p_payload->>'operation_type';

  IF v_company_id IS NULL OR v_op_type IS NULL THEN
    RAISE EXCEPTION 'company_id и operation_type обязательны';
  END IF;

  IF NOT (v_company_id IN (SELECT public.get_my_company_ids())) THEN
    RAISE EXCEPTION 'Нет доступа к компании';
  END IF;

  -- Права по типу операции
  v_perm_ok := public.check_permission(v_uid, 'tmc', 'create')
    OR CASE v_op_type
         WHEN 'issue' THEN public.check_permission(v_uid, 'tmc', 'issue')
         WHEN 'return_from_employee' THEN public.check_permission(v_uid, 'tmc', 'issue')
         WHEN 'transfer_between_employees' THEN public.check_permission(v_uid, 'tmc', 'issue')
         WHEN 'transfer_to_object' THEN public.check_permission(v_uid, 'tmc', 'move')
         WHEN 'return_from_object' THEN public.check_permission(v_uid, 'tmc', 'move')
         WHEN 'move_between_objects' THEN public.check_permission(v_uid, 'tmc', 'move')
         WHEN 'move_between_warehouses' THEN public.check_permission(v_uid, 'tmc', 'move')
         WHEN 'send_to_repair' THEN public.check_permission(v_uid, 'tmc', 'repair')
         WHEN 'return_from_repair' THEN public.check_permission(v_uid, 'tmc', 'repair')
         WHEN 'write_off' THEN public.check_permission(v_uid, 'tmc', 'write_off')
         WHEN 'shortage' THEN public.check_permission(v_uid, 'tmc', 'write_off')
         WHEN 'inventory_adjust' THEN public.check_permission(v_uid, 'tmc', 'inventory')
         WHEN 'change_condition' THEN public.check_permission(v_uid, 'tmc', 'update')
         WHEN 'correction' THEN public.check_permission(v_uid, 'tmc', 'update')
         WHEN 'receipt' THEN public.check_permission(v_uid, 'tmc', 'create')
         WHEN 'reserve' THEN public.check_permission(v_uid, 'tmc', 'move')
         WHEN 'unreserve' THEN public.check_permission(v_uid, 'tmc', 'move')
         ELSE false
       END;

  IF NOT v_perm_ok THEN
    RAISE EXCEPTION 'Недостаточно прав для операции %', v_op_type;
  END IF;

  IF p_payload->'items' IS NULL OR jsonb_array_length(p_payload->'items') = 0 THEN
    RAISE EXCEPTION 'Список позиций операции пуст';
  END IF;

  v_from_type := p_payload->>'from_location_type';
  v_to_type := p_payload->>'to_location_type';

  IF v_op_type IN (
    'move_between_objects', 'move_between_warehouses',
    'transfer_to_object', 'return_from_object',
    'issue', 'return_from_employee', 'transfer_between_employees',
    'send_to_repair', 'return_from_repair'
  ) THEN
    IF v_from_type IS NULL OR v_to_type IS NULL THEN
      RAISE EXCEPTION 'Для перемещения нужны исходное и новое местонахождение';
    END IF;
  END IF;

  INSERT INTO public.tmc_operations (
    company_id, operation_type, operated_at,
    document_number, basis, comment,
    from_location_type, from_warehouse_id, from_object_id, from_employee_id, from_location_note,
    to_location_type, to_warehouse_id, to_object_id, to_employee_id, to_location_note,
    responsible_employee_id, object_id, planned_return_date, condition_id,
    reverses_operation_id, created_by
  ) VALUES (
    v_company_id,
    v_op_type,
    COALESCE((p_payload->>'operated_at')::TIMESTAMPTZ, now()),
    NULLIF(p_payload->>'document_number', ''),
    NULLIF(p_payload->>'basis', ''),
    NULLIF(p_payload->>'comment', ''),
    v_from_type,
    NULLIF(p_payload->>'from_warehouse_id', '')::UUID,
    NULLIF(p_payload->>'from_object_id', '')::UUID,
    NULLIF(p_payload->>'from_employee_id', '')::UUID,
    NULLIF(p_payload->>'from_location_note', ''),
    v_to_type,
    NULLIF(p_payload->>'to_warehouse_id', '')::UUID,
    NULLIF(p_payload->>'to_object_id', '')::UUID,
    NULLIF(p_payload->>'to_employee_id', '')::UUID,
    NULLIF(p_payload->>'to_location_note', ''),
    NULLIF(p_payload->>'responsible_employee_id', '')::UUID,
    NULLIF(p_payload->>'object_id', '')::UUID,
    NULLIF(p_payload->>'planned_return_date', '')::DATE,
    NULLIF(p_payload->>'condition_id', '')::UUID,
    NULLIF(p_payload->>'reverses_operation_id', '')::UUID,
    v_uid
  )
  RETURNING id INTO v_op_id;

  v_new_status := public.tmc_status_for_operation(v_op_type, v_to_type);

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_payload->'items')
  LOOP
    v_item_id := (v_item->>'item_id')::UUID;
    v_unit_id := NULLIF(v_item->>'unit_id', '')::UUID;
    v_qty := COALESCE((v_item->>'quantity')::NUMERIC, 1);
    v_condition_id := COALESCE(
      NULLIF(v_item->>'condition_id', '')::UUID,
      NULLIF(p_payload->>'condition_id', '')::UUID
    );

    IF v_item_id IS NULL THEN
      RAISE EXCEPTION 'item_id обязателен в строке операции';
    END IF;

    SELECT accounting_type INTO v_accounting
    FROM public.tmc_items
    WHERE id = v_item_id AND company_id = v_company_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Позиция ТМЦ не найдена';
    END IF;

    INSERT INTO public.tmc_operation_items (
      company_id, operation_id, item_id, unit_id, quantity, unit_price,
      condition_id, completeness_note, comment,
      clothing_size, height_cm, season, service_life_days, next_replacement_date
    ) VALUES (
      v_company_id, v_op_id, v_item_id, v_unit_id, v_qty,
      NULLIF(v_item->>'unit_price', '')::NUMERIC,
      v_condition_id,
      NULLIF(v_item->>'completeness_note', ''),
      NULLIF(v_item->>'comment', ''),
      NULLIF(v_item->>'clothing_size', ''),
      NULLIF(v_item->>'height_cm', '')::NUMERIC,
      NULLIF(v_item->>'season', ''),
      NULLIF(v_item->>'service_life_days', '')::INT,
      NULLIF(v_item->>'next_replacement_date', '')::DATE
    );

    -- ===== Поступление =====
    IF v_op_type = 'receipt' THEN
      IF v_accounting = 'quantitative' THEN
        PERFORM public.tmc_adjust_balance(
          v_company_id, v_item_id,
          COALESCE(v_to_type, 'warehouse'),
          NULLIF(p_payload->>'to_warehouse_id', '')::UUID,
          NULLIF(p_payload->>'to_object_id', '')::UUID,
          NULLIF(p_payload->>'to_employee_id', '')::UUID,
          NULLIF(p_payload->>'to_location_note', ''),
          v_qty
        );
      ELSE
        -- создаём единицы
        FOR i IN 1..CEIL(v_qty)::INT LOOP
          v_inv := COALESCE(
            NULLIF(v_item->>'inventory_number', ''),
            public.tmc_next_inventory_number(v_company_id)
          );
          -- если передан один inventory_number и qty>1 — генерируем дальше
          IF i > 1 OR (v_item->>'inventory_number') IS NULL OR (v_item->>'inventory_number') = '' THEN
            IF i > 1 THEN
              v_inv := public.tmc_next_inventory_number(v_company_id);
            END IF;
          END IF;

          INSERT INTO public.tmc_units (
            company_id, item_id, inventory_number, serial_number,
            purchase_date, purchase_price, condition_id, status,
            location_type, warehouse_id, object_id, employee_id, location_note,
            warranty_until, created_by
          ) VALUES (
            v_company_id, v_item_id, v_inv,
            NULLIF(v_item->>'serial_number', ''),
            COALESCE((p_payload->>'operated_at')::DATE, CURRENT_DATE),
            COALESCE(NULLIF(v_item->>'unit_price', '')::NUMERIC, 0),
            v_condition_id,
            public.tmc_status_for_location(COALESCE(v_to_type, 'warehouse')),
            COALESCE(v_to_type, 'warehouse'),
            NULLIF(p_payload->>'to_warehouse_id', '')::UUID,
            NULLIF(p_payload->>'to_object_id', '')::UUID,
            NULLIF(p_payload->>'to_employee_id', '')::UUID,
            NULLIF(p_payload->>'to_location_note', ''),
            NULLIF(v_item->>'warranty_until', '')::DATE,
            v_uid
          )
          RETURNING id INTO v_unit_id;

          UPDATE public.tmc_operation_items
          SET unit_id = COALESCE(unit_id, v_unit_id)
          WHERE operation_id = v_op_id AND item_id = v_item_id AND unit_id IS NULL
          AND id = (
            SELECT id FROM public.tmc_operation_items
            WHERE operation_id = v_op_id AND item_id = v_item_id AND unit_id IS NULL
            ORDER BY created_at LIMIT 1
          );
        END LOOP;
      END IF;

    -- ===== Индивидуальная единица: перемещения / статусы =====
    ELSIF v_accounting = 'individual' THEN
      IF v_unit_id IS NULL THEN
        RAISE EXCEPTION 'Для индивидуального учёта укажите unit_id';
      END IF;

      SELECT * INTO v_unit
      FROM public.tmc_units
      WHERE id = v_unit_id AND company_id = v_company_id
      FOR UPDATE;

      IF NOT FOUND THEN
        RAISE EXCEPTION 'Единица ТМЦ не найдена';
      END IF;

      IF v_op_type = 'write_off' AND v_unit.status = 'written_off' THEN
        RAISE EXCEPTION 'Единица уже списана';
      END IF;

      IF v_op_type = 'issue' AND v_unit.status = 'issued' THEN
        RAISE EXCEPTION 'Единица уже выдана сотруднику';
      END IF;

      IF v_op_type = 'change_condition' THEN
        IF v_condition_id IS NULL THEN
          RAISE EXCEPTION 'condition_id обязателен для смены состояния';
        END IF;
        INSERT INTO public.tmc_condition_history (
          company_id, unit_id, item_id, previous_condition_id, new_condition_id,
          comment, operation_id, created_by
        ) VALUES (
          v_company_id, v_unit_id, v_item_id, v_unit.condition_id, v_condition_id,
          NULLIF(v_item->>'comment', ''), v_op_id, v_uid
        );
        UPDATE public.tmc_units
        SET condition_id = v_condition_id, updated_at = now()
        WHERE id = v_unit_id;
      ELSE
        UPDATE public.tmc_units SET
          location_type = COALESCE(v_to_type, location_type),
          warehouse_id = CASE
            WHEN v_to_type = 'warehouse' THEN NULLIF(p_payload->>'to_warehouse_id', '')::UUID
            ELSE NULL
          END,
          object_id = CASE
            WHEN v_to_type = 'object' THEN NULLIF(p_payload->>'to_object_id', '')::UUID
            ELSE CASE WHEN v_to_type = 'employee' THEN object_id ELSE NULL END
          END,
          employee_id = CASE
            WHEN v_to_type = 'employee' THEN NULLIF(p_payload->>'to_employee_id', '')::UUID
            ELSE NULL
          END,
          location_note = CASE
            WHEN v_to_type IN ('office', 'repair_org', 'other')
              THEN NULLIF(p_payload->>'to_location_note', '')
            ELSE NULL
          END,
          usage_object_id = COALESCE(
            NULLIF(p_payload->>'object_id', '')::UUID,
            usage_object_id
          ),
          responsible_employee_id = COALESCE(
            NULLIF(p_payload->>'responsible_employee_id', '')::UUID,
            responsible_employee_id
          ),
          status = v_new_status,
          condition_id = COALESCE(v_condition_id, condition_id),
          last_issue_date = CASE
            WHEN v_op_type = 'issue' THEN CURRENT_DATE
            ELSE last_issue_date
          END,
          is_archived = CASE WHEN v_op_type = 'write_off' THEN true ELSE is_archived END,
          archived_at = CASE WHEN v_op_type = 'write_off' THEN now() ELSE archived_at END,
          updated_at = now()
        WHERE id = v_unit_id;

        IF v_condition_id IS NOT NULL AND v_condition_id IS DISTINCT FROM v_unit.condition_id THEN
          INSERT INTO public.tmc_condition_history (
            company_id, unit_id, item_id, previous_condition_id, new_condition_id,
            comment, operation_id, created_by
          ) VALUES (
            v_company_id, v_unit_id, v_item_id, v_unit.condition_id, v_condition_id,
            NULLIF(v_item->>'comment', ''), v_op_id, v_uid
          );
        END IF;
      END IF;

      -- Выдача / возврат assignments
      IF v_op_type = 'issue' THEN
        INSERT INTO public.tmc_assignments (
          company_id, item_id, unit_id, employee_id, object_id, quantity,
          planned_return_date, condition_id, issue_operation_id,
          clothing_size, height_cm, season, service_life_days, next_replacement_date,
          comment, created_by
        ) VALUES (
          v_company_id, v_item_id, v_unit_id,
          NULLIF(p_payload->>'to_employee_id', '')::UUID,
          NULLIF(p_payload->>'object_id', '')::UUID,
          1,
          NULLIF(p_payload->>'planned_return_date', '')::DATE,
          v_condition_id, v_op_id,
          NULLIF(v_item->>'clothing_size', ''),
          NULLIF(v_item->>'height_cm', '')::NUMERIC,
          NULLIF(v_item->>'season', ''),
          NULLIF(v_item->>'service_life_days', '')::INT,
          NULLIF(v_item->>'next_replacement_date', '')::DATE,
          NULLIF(v_item->>'comment', ''),
          v_uid
        );
      ELSIF v_op_type = 'return_from_employee' THEN
        UPDATE public.tmc_assignments
        SET is_active = false, returned_at = now(), updated_at = now()
        WHERE unit_id = v_unit_id AND is_active = true;
      ELSIF v_op_type = 'transfer_between_employees' THEN
        UPDATE public.tmc_assignments
        SET is_active = false, returned_at = now(), updated_at = now()
        WHERE unit_id = v_unit_id AND is_active = true;
        INSERT INTO public.tmc_assignments (
          company_id, item_id, unit_id, employee_id, object_id, quantity,
          planned_return_date, condition_id, issue_operation_id, created_by
        ) VALUES (
          v_company_id, v_item_id, v_unit_id,
          NULLIF(p_payload->>'to_employee_id', '')::UUID,
          NULLIF(p_payload->>'object_id', '')::UUID,
          1,
          NULLIF(p_payload->>'planned_return_date', '')::DATE,
          v_condition_id, v_op_id, v_uid
        );
      END IF;

    -- ===== Количественный учёт: перемещения =====
    ELSE
      IF v_op_type NOT IN ('change_condition') THEN
        -- списать с from
        IF v_from_type IS NOT NULL AND v_op_type <> 'receipt' THEN
          PERFORM public.tmc_adjust_balance(
            v_company_id, v_item_id, v_from_type,
            NULLIF(p_payload->>'from_warehouse_id', '')::UUID,
            NULLIF(p_payload->>'from_object_id', '')::UUID,
            NULLIF(p_payload->>'from_employee_id', '')::UUID,
            NULLIF(p_payload->>'from_location_note', ''),
            -v_qty
          );
        END IF;
        -- добавить на to (кроме write_off / shortage без to)
        IF v_to_type IS NOT NULL AND v_op_type NOT IN ('write_off', 'shortage') THEN
          PERFORM public.tmc_adjust_balance(
            v_company_id, v_item_id, v_to_type,
            NULLIF(p_payload->>'to_warehouse_id', '')::UUID,
            NULLIF(p_payload->>'to_object_id', '')::UUID,
            NULLIF(p_payload->>'to_employee_id', '')::UUID,
            NULLIF(p_payload->>'to_location_note', ''),
            v_qty
          );
        END IF;
      END IF;

      IF v_op_type = 'issue' THEN
        INSERT INTO public.tmc_assignments (
          company_id, item_id, employee_id, object_id, quantity,
          planned_return_date, condition_id, issue_operation_id,
          clothing_size, height_cm, season, service_life_days, next_replacement_date,
          comment, created_by
        ) VALUES (
          v_company_id, v_item_id,
          NULLIF(p_payload->>'to_employee_id', '')::UUID,
          NULLIF(p_payload->>'object_id', '')::UUID,
          v_qty,
          NULLIF(p_payload->>'planned_return_date', '')::DATE,
          v_condition_id, v_op_id,
          NULLIF(v_item->>'clothing_size', ''),
          NULLIF(v_item->>'height_cm', '')::NUMERIC,
          NULLIF(v_item->>'season', ''),
          NULLIF(v_item->>'service_life_days', '')::INT,
          NULLIF(v_item->>'next_replacement_date', '')::DATE,
          NULLIF(v_item->>'comment', ''),
          v_uid
        );
      ELSIF v_op_type = 'return_from_employee' THEN
        UPDATE public.tmc_assignments
        SET is_active = false, returned_at = now(), updated_at = now()
        WHERE id = (
          SELECT id FROM public.tmc_assignments
          WHERE company_id = v_company_id
            AND item_id = v_item_id
            AND employee_id = NULLIF(p_payload->>'from_employee_id', '')::UUID
            AND is_active = true
            AND unit_id IS NULL
          ORDER BY issued_at
          LIMIT 1
        );
      END IF;
    END IF;

    -- Ремонт
    IF v_op_type = 'send_to_repair' AND p_payload ? 'repair' THEN
      INSERT INTO public.tmc_repairs (
        company_id, item_id, unit_id, reason, fault_description,
        repair_org_name, responsible_employee_id, estimated_cost,
        send_operation_id, created_by
      ) VALUES (
        v_company_id, v_item_id, v_unit_id,
        NULLIF(p_payload->'repair'->>'reason', ''),
        NULLIF(p_payload->'repair'->>'fault_description', ''),
        NULLIF(p_payload->'repair'->>'repair_org_name', ''),
        NULLIF(p_payload->>'responsible_employee_id', '')::UUID,
        NULLIF(p_payload->'repair'->>'estimated_cost', '')::NUMERIC,
        v_op_id, v_uid
      )
      RETURNING id INTO v_repair_id;
    ELSIF v_op_type = 'return_from_repair' THEN
      UPDATE public.tmc_repairs SET
        status = 'completed',
        completed_at = CURRENT_DATE,
        actual_cost = NULLIF(p_payload->'repair'->>'actual_cost', '')::NUMERIC,
        result = NULLIF(p_payload->'repair'->>'result', ''),
        condition_after_id = v_condition_id,
        return_operation_id = v_op_id,
        updated_at = now()
      WHERE company_id = v_company_id
        AND status = 'open'
        AND (
          (v_unit_id IS NOT NULL AND unit_id = v_unit_id)
          OR (v_unit_id IS NULL AND item_id = v_item_id)
        );
    END IF;

    -- Списание
    IF v_op_type = 'write_off' THEN
      INSERT INTO public.tmc_write_offs (
        company_id, item_id, unit_id, reason, quantity, condition_id,
        book_value, responsible_employee_id, object_id, act_number, comment,
        operation_id, created_by
      ) VALUES (
        v_company_id, v_item_id, v_unit_id,
        COALESCE(NULLIF(p_payload->'write_off'->>'reason', ''), 'other'),
        v_qty, v_condition_id,
        NULLIF(p_payload->'write_off'->>'book_value', '')::NUMERIC,
        NULLIF(p_payload->>'responsible_employee_id', '')::UUID,
        NULLIF(p_payload->>'object_id', '')::UUID,
        NULLIF(p_payload->'write_off'->>'act_number', ''),
        NULLIF(p_payload->>'comment', ''),
        v_op_id, v_uid
      )
      RETURNING id INTO v_write_off_id;
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'operation_id', v_op_id,
    'repair_id', v_repair_id,
    'write_off_id', v_write_off_id
  );
END;
$$;

REVOKE ALL ON FUNCTION public.tmc_post_operation(JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tmc_post_operation(JSONB) TO authenticated;

-- Дашборд KPI
CREATE OR REPLACE FUNCTION public.tmc_dashboard_stats(p_company_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
  v_can_cost BOOLEAN;
  v_result JSONB;
BEGIN
  IF NOT (p_company_id IN (SELECT public.get_my_company_ids())) THEN
    RAISE EXCEPTION 'Нет доступа';
  END IF;
  IF NOT public.check_permission(auth.uid(), 'tmc', 'read') THEN
    RAISE EXCEPTION 'Нет права просмотра ТМЦ';
  END IF;

  v_can_cost := public.check_permission(auth.uid(), 'tmc', 'view_cost');

  SELECT jsonb_build_object(
    'total_items', (SELECT count(*) FROM tmc_items WHERE company_id = p_company_id AND is_archived = false),
    'total_units', (SELECT count(*) FROM tmc_units WHERE company_id = p_company_id AND is_archived = false AND status <> 'written_off'),
    'in_stock', (
      SELECT count(*) FROM tmc_units
      WHERE company_id = p_company_id AND is_archived = false AND status = 'in_stock'
    ) + COALESCE((
      SELECT sum(quantity) FROM tmc_balances
      WHERE company_id = p_company_id AND location_type IN ('warehouse', 'office')
    ), 0),
    'on_object', (
      SELECT count(*) FROM tmc_units
      WHERE company_id = p_company_id AND is_archived = false AND status = 'on_object'
    ) + COALESCE((
      SELECT sum(quantity) FROM tmc_balances
      WHERE company_id = p_company_id AND location_type = 'object'
    ), 0),
    'issued', (
      SELECT count(*) FROM tmc_units
      WHERE company_id = p_company_id AND is_archived = false AND status = 'issued'
    ) + COALESCE((
      SELECT sum(quantity) FROM tmc_balances
      WHERE company_id = p_company_id AND location_type = 'employee'
    ), 0),
    'in_repair', (
      SELECT count(*) FROM tmc_units
      WHERE company_id = p_company_id AND is_archived = false AND status = 'in_repair'
    ),
    'needs_repair', (
      SELECT count(*) FROM tmc_units u
      JOIN tmc_conditions c ON c.id = u.condition_id
      WHERE u.company_id = p_company_id AND u.is_archived = false AND c.code = 'needs_repair'
    ),
    'lost', (
      SELECT count(*) FROM tmc_units
      WHERE company_id = p_company_id AND status = 'lost'
    ),
    'written_off', (
      SELECT count(*) FROM tmc_write_offs
      WHERE company_id = p_company_id
        AND written_off_at >= date_trunc('month', CURRENT_DATE)::date
    ),
    'total_cost', CASE WHEN v_can_cost THEN (
      SELECT COALESCE(sum(total_cost), 0) FROM tmc_items
      WHERE company_id = p_company_id AND is_archived = false
    ) ELSE NULL END
  ) INTO v_result;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.tmc_dashboard_stats(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tmc_dashboard_stats(UUID) TO authenticated;

-- Пагинированный реестр позиций
CREATE OR REPLACE FUNCTION public.tmc_list_items(
  p_company_id UUID,
  p_search TEXT DEFAULT NULL,
  p_category_id UUID DEFAULT NULL,
  p_status TEXT DEFAULT NULL,
  p_accounting_type TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  category_name TEXT,
  subcategory_name TEXT,
  accounting_type TEXT,
  sku TEXT,
  unit_of_measure TEXT,
  quantity NUMERIC,
  unit_price NUMERIC,
  total_cost NUMERIC,
  status TEXT,
  photo_url TEXT,
  delivery_date DATE,
  supplier_name TEXT,
  created_at TIMESTAMPTZ,
  total_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
  v_can_cost BOOLEAN;
BEGIN
  IF NOT (p_company_id IN (SELECT public.get_my_company_ids())) THEN
    RAISE EXCEPTION 'Нет доступа';
  END IF;
  IF NOT public.check_permission(auth.uid(), 'tmc', 'read') THEN
    RAISE EXCEPTION 'Нет права просмотра ТМЦ';
  END IF;
  v_can_cost := public.check_permission(auth.uid(), 'tmc', 'view_cost');

  RETURN QUERY
  WITH filtered AS (
    SELECT
      i.id,
      i.name,
      cat.name AS category_name,
      sub.name AS subcategory_name,
      i.accounting_type,
      i.sku,
      i.unit_of_measure,
      i.quantity,
      CASE WHEN v_can_cost THEN i.unit_price ELSE NULL END AS unit_price,
      CASE WHEN v_can_cost THEN i.total_cost ELSE NULL END AS total_cost,
      i.status,
      i.photo_url,
      i.delivery_date,
      co.short_name AS supplier_name,
      i.created_at,
      count(*) OVER() AS total_count
    FROM public.tmc_items i
    LEFT JOIN public.tmc_categories cat ON cat.id = i.category_id
    LEFT JOIN public.tmc_categories sub ON sub.id = i.subcategory_id
    LEFT JOIN public.contractors co ON co.id = i.supplier_id
    WHERE i.company_id = p_company_id
      AND i.is_archived = false
      AND (p_category_id IS NULL OR i.category_id = p_category_id OR i.subcategory_id = p_category_id)
      AND (p_status IS NULL OR i.status = p_status)
      AND (p_accounting_type IS NULL OR i.accounting_type = p_accounting_type)
      AND (
        p_search IS NULL OR p_search = ''
        OR i.name ILIKE '%' || p_search || '%'
        OR COALESCE(i.sku, '') ILIKE '%' || p_search || '%'
        OR COALESCE(i.model, '') ILIKE '%' || p_search || '%'
      )
  )
  SELECT *
  FROM filtered
  ORDER BY name
  LIMIT GREATEST(COALESCE(p_limit, 50), 1)
  OFFSET GREATEST(COALESCE(p_offset, 0), 0);
END;
$$;

REVOKE ALL ON FUNCTION public.tmc_list_items(
  UUID, TEXT, UUID, TEXT, TEXT, INT, INT
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tmc_list_items(
  UUID, TEXT, UUID, TEXT, TEXT, INT, INT
) TO authenticated;

COMMIT;
