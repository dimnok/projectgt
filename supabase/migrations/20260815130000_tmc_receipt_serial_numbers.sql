-- Серийные номера при поступлении: массив serial_numbers на каждую единицу.

CREATE OR REPLACE FUNCTION public.tmc_receipt_serial_number(
  p_item jsonb,
  p_index integer
)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
  SELECT NULLIF(
    btrim(
      COALESCE(
        NULLIF(p_item->'serial_numbers'->>(p_index - 1), ''),
        CASE
          WHEN p_index = 1 THEN COALESCE(p_item->>'serial_number', '')
          ELSE ''
        END
      )
    ),
    ''
  );
$$;

COMMENT ON FUNCTION public.tmc_receipt_serial_number(jsonb, integer) IS
  'S/N для i-й создаваемой единицы при поступлении (1-based). Берёт serial_numbers[i] или serial_number для первой.';

DO $$
DECLARE
  src text;
BEGIN
  src := pg_get_functiondef('public.tmc_post_operation(jsonb)'::regprocedure);
  src := replace(
    src,
    'NULLIF(v_item->>''serial_number'', ''''),',
    'public.tmc_receipt_serial_number(v_item, i),'
  );
  EXECUTE src;

  src := pg_get_functiondef('public.tmc_create_item_with_receipt(jsonb)'::regprocedure);
  src := replace(
    src,
    '''serial_number'', NULLIF(v_receive->>''serial_number'', '''')',
    '''serial_number'', NULLIF(v_receive->>''serial_number'', ''''), ''serial_numbers'', COALESCE(v_receive->''serial_numbers'', ''[]''::jsonb)'
  );
  EXECUTE src;
END $$;
