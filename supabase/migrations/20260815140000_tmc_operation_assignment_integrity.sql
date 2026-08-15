-- Целостность выдач и статусов в tmc_post_operation.
-- Дополняет уже заложенную логику RPC (FIFO LIMIT 1, issue/return assignments,
-- статусная машина tmc_status_for_operation), без новых типов операций.

-- Закрыть активные выдачи индивидуальной единицы (как return_from_employee).
CREATE OR REPLACE FUNCTION public.tmc_close_unit_assignments(p_unit_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_unit_id IS NULL THEN
    RETURN;
  END IF;

  UPDATE public.tmc_assignments
  SET is_active = false, returned_at = now(), updated_at = now()
  WHERE unit_id = p_unit_id AND is_active = true;
END;
$$;

REVOKE ALL ON FUNCTION public.tmc_close_unit_assignments(UUID) FROM PUBLIC;

COMMENT ON FUNCTION public.tmc_close_unit_assignments(UUID) IS
  'Закрывает активные tmc_assignments индивидуальной единицы.';

-- Списать количество с активных количественных выдач сотрудника (FIFO по issued_at).
-- Раньше закрывалась одна запись LIMIT 1 без учёта quantity.
CREATE OR REPLACE FUNCTION public.tmc_consume_employee_assignments(
  p_company_id UUID,
  p_item_id UUID,
  p_employee_id UUID,
  p_qty NUMERIC
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_asg public.tmc_assignments%ROWTYPE;
  v_left NUMERIC := p_qty;
BEGIN
  IF p_employee_id IS NULL THEN
    RAISE EXCEPTION 'Укажите сотрудника, с которого списывается выдача';
  END IF;

  IF p_qty IS NULL OR p_qty <= 0 THEN
    RAISE EXCEPTION 'Количество должно быть больше нуля';
  END IF;

  FOR v_asg IN
    SELECT *
    FROM public.tmc_assignments
    WHERE company_id = p_company_id
      AND item_id = p_item_id
      AND employee_id = p_employee_id
      AND is_active = true
      AND unit_id IS NULL
    ORDER BY issued_at
    FOR UPDATE
  LOOP
    EXIT WHEN v_left <= 0;

    IF v_asg.quantity <= v_left THEN
      UPDATE public.tmc_assignments
      SET is_active = false, returned_at = now(), updated_at = now()
      WHERE id = v_asg.id;
      v_left := v_left - v_asg.quantity;
    ELSE
      UPDATE public.tmc_assignments
      SET quantity = v_asg.quantity - v_left, updated_at = now()
      WHERE id = v_asg.id;
      v_left := 0;
    END IF;
  END LOOP;

  IF v_left > 0 THEN
    RAISE EXCEPTION
      'Недостаточно выданного количества у сотрудника (не закрыто %)',
      v_left;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.tmc_consume_employee_assignments(UUID, UUID, UUID, NUMERIC) FROM PUBLIC;

COMMENT ON FUNCTION public.tmc_consume_employee_assignments(UUID, UUID, UUID, NUMERIC) IS
  'FIFO-списание количества с активных количественных выдач сотрудника.';
