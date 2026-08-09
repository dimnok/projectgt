-- Следующий номер счёта по договору (max завершающей цифровой группы + 1).
-- Семантика совпадает с Dart [computeNextInvoiceNumber].

BEGIN;

CREATE OR REPLACE FUNCTION public.get_next_settlement_invoice_number(
  p_company_id UUID,
  p_contract_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_prefix TEXT := '';
  v_max BIGINT := 0;
  v_row RECORD;
  v_digits TEXT;
  v_n BIGINT;
BEGIN
  IF p_company_id IS NULL OR p_contract_id IS NULL THEN
    RETURN '1';
  END IF;

  IF NOT (p_company_id IN (SELECT public.get_my_company_ids())) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  FOR v_row IN
    SELECT invoice_number
    FROM public.settlement_operations
    WHERE company_id = p_company_id
      AND contract_id = p_contract_id
  LOOP
    v_digits := (regexp_match(v_row.invoice_number, '(\d+)\s*$'))[1];
    IF v_digits IS NULL THEN
      CONTINUE;
    END IF;

    BEGIN
      v_n := v_digits::BIGINT;
    EXCEPTION
      WHEN numeric_value_out_of_range OR invalid_text_representation THEN
        CONTINUE;
    END;

    IF v_n > v_max THEN
      v_max := v_n;
      v_prefix := regexp_replace(v_row.invoice_number, '\d+\s*$', '');
    END IF;
  END LOOP;

  RETURN v_prefix || (v_max + 1)::TEXT;
END;
$$;

REVOKE ALL ON FUNCTION public.get_next_settlement_invoice_number(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_next_settlement_invoice_number(UUID, UUID) TO authenticated;

COMMENT ON FUNCTION public.get_next_settlement_invoice_number(UUID, UUID) IS
  'Подсказка следующего номера счёта: max завершающей цифровой группы + 1 с префиксом победителя.';

COMMIT;
