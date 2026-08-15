-- tmc_post_operation: целостность выдач, статусов и привязки unit/item.
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
  v_from_employee_id UUID;
  v_to_employee_id UUID;
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
  v_from_employee_id := NULLIF(p_payload->>'from_employee_id', '')::UUID;
  v_to_employee_id := NULLIF(p_payload->>'to_employee_id', '')::UUID;

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

  IF v_op_type IN ('write_off', 'shortage') AND v_from_type IS NULL THEN
    RAISE EXCEPTION 'Для списания укажите место, с которого списывается остаток';
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
    v_from_employee_id,
    NULLIF(p_payload->>'from_location_note', ''),
    v_to_type,
    NULLIF(p_payload->>'to_warehouse_id', '')::UUID,
    NULLIF(p_payload->>'to_object_id', '')::UUID,
    v_to_employee_id,
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

    IF v_qty <= 0 THEN
      RAISE EXCEPTION 'Количество операции должно быть больше нуля';
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
        FOR i IN 1..CEIL(v_qty)::INT LOOP
          v_inv := COALESCE(
            NULLIF(v_item->>'inventory_number', ''),
            public.tmc_next_inventory_number(v_company_id)
          );
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
            public.tmc_receipt_serial_number(v_item, i),
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

    -- ===== Индивидуальная единица =====
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

      IF v_unit.item_id IS DISTINCT FROM v_item_id THEN
        RAISE EXCEPTION 'Единица не принадлежит выбранной позиции ТМЦ';
      END IF;

      IF v_op_type = 'write_off' AND v_unit.status = 'written_off' THEN
        RAISE EXCEPTION 'Единица уже списана';
      END IF;

      IF v_op_type = 'issue' AND v_unit.status IS DISTINCT FROM 'in_stock' THEN
        RAISE EXCEPTION 'Выдать можно только единицу со склада';
      END IF;

      IF v_op_type = 'return_from_employee' AND v_unit.status IS DISTINCT FROM 'issued' THEN
        RAISE EXCEPTION 'Возврат возможен только для выданной единицы';
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
            WHEN v_to_type = 'employee' THEN v_to_employee_id
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

      IF v_op_type = 'issue' THEN
        INSERT INTO public.tmc_assignments (
          company_id, item_id, unit_id, employee_id, object_id, quantity,
          planned_return_date, condition_id, issue_operation_id,
          clothing_size, height_cm, season, service_life_days, next_replacement_date,
          comment, created_by
        ) VALUES (
          v_company_id, v_item_id, v_unit_id,
          v_to_employee_id,
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
        PERFORM public.tmc_close_unit_assignments(v_unit_id);
      ELSIF v_op_type = 'transfer_between_employees' THEN
        PERFORM public.tmc_close_unit_assignments(v_unit_id);
        INSERT INTO public.tmc_assignments (
          company_id, item_id, unit_id, employee_id, object_id, quantity,
          planned_return_date, condition_id, issue_operation_id, created_by
        ) VALUES (
          v_company_id, v_item_id, v_unit_id,
          v_to_employee_id,
          NULLIF(p_payload->>'object_id', '')::UUID,
          1,
          NULLIF(p_payload->>'planned_return_date', '')::DATE,
          v_condition_id, v_op_id, v_uid
        );
      ELSIF v_op_type IN ('write_off', 'shortage', 'send_to_repair') THEN
        PERFORM public.tmc_close_unit_assignments(v_unit_id);
      END IF;

    -- ===== Количественный учёт =====
    ELSE
      IF v_op_type NOT IN ('change_condition') THEN
        IF v_from_type IS NOT NULL AND v_op_type <> 'receipt' THEN
          PERFORM public.tmc_adjust_balance(
            v_company_id, v_item_id, v_from_type,
            NULLIF(p_payload->>'from_warehouse_id', '')::UUID,
            NULLIF(p_payload->>'from_object_id', '')::UUID,
            v_from_employee_id,
            NULLIF(p_payload->>'from_location_note', ''),
            -v_qty
          );
        END IF;
        IF v_to_type IS NOT NULL AND v_op_type NOT IN ('write_off', 'shortage') THEN
          PERFORM public.tmc_adjust_balance(
            v_company_id, v_item_id, v_to_type,
            NULLIF(p_payload->>'to_warehouse_id', '')::UUID,
            NULLIF(p_payload->>'to_object_id', '')::UUID,
            v_to_employee_id,
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
          v_to_employee_id,
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
        PERFORM public.tmc_consume_employee_assignments(
          v_company_id, v_item_id, v_from_employee_id, v_qty
        );
      ELSIF v_op_type = 'transfer_between_employees' THEN
        PERFORM public.tmc_consume_employee_assignments(
          v_company_id, v_item_id, v_from_employee_id, v_qty
        );
        INSERT INTO public.tmc_assignments (
          company_id, item_id, employee_id, object_id, quantity,
          planned_return_date, condition_id, issue_operation_id, created_by
        ) VALUES (
          v_company_id, v_item_id,
          v_to_employee_id,
          NULLIF(p_payload->>'object_id', '')::UUID,
          v_qty,
          NULLIF(p_payload->>'planned_return_date', '')::DATE,
          v_condition_id, v_op_id, v_uid
        );
      ELSIF v_op_type IN ('write_off', 'shortage', 'send_to_repair')
            AND v_from_type = 'employee' THEN
        PERFORM public.tmc_consume_employee_assignments(
          v_company_id, v_item_id, v_from_employee_id, v_qty
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
          OR (v_unit_id IS NULL AND item_id = v_item_id AND unit_id IS NULL)
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
