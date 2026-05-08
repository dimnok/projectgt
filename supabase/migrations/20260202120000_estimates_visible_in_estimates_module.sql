-- Сметы: видимость строки в модуле «Сметы» (карточка договора показывает все строки).
-- Добавляет колонку, расширяет представление и фильтрует get_estimate_groups.

BEGIN;

ALTER TABLE public.estimates
  ADD COLUMN IF NOT EXISTS visible_in_estimates_module boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.estimates.visible_in_estimates_module IS
  'If false, the row is hidden from the Estimates module UI and from get_estimate_groups; still available on the contract card and for execution/materials.';

CREATE OR REPLACE VIEW public.estimates_with_contracts AS
SELECT
  e.id,
  e.contract_id,
  e.object_id,
  e.system,
  e.subsystem,
  e.name,
  e.article,
  e.manufacturer,
  e.unit,
  e.quantity,
  e.price,
  e.total,
  e.created_at,
  e.updated_at,
  e.estimate_title,
  e.number,
  public.get_contract_number(e.contract_id) AS contract_number,
  e.company_id,
  e.visible_in_estimates_module
FROM public.estimates e;

CREATE OR REPLACE FUNCTION public.get_estimate_groups(p_company_id UUID)
RETURNS TABLE (
  estimate_title TEXT,
  object_id UUID,
  contract_id UUID,
  contract_number TEXT,
  items_count BIGINT,
  total_amount DOUBLE PRECISION
) AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_is_owner BOOLEAN;
  v_user_objects UUID[];
BEGIN
  IF NOT public.check_permission(v_user_id, 'estimates', 'read') THEN
    RETURN;
  END IF;

  SELECT
    COALESCE(cm.is_owner, false),
    p.object_ids
  INTO v_is_owner, v_user_objects
  FROM public.profiles p
  LEFT JOIN public.company_members cm
    ON cm.user_id = p.id AND cm.company_id = p_company_id
  WHERE p.id = v_user_id;

  RETURN QUERY
  SELECT
    COALESCE(e.estimate_title, 'Без названия')::TEXT AS estimate_title,
    e.object_id,
    e.contract_id,
    c.number::TEXT AS contract_number,
    COUNT(*)::BIGINT AS items_count,
    COALESCE(SUM(e.total), 0)::DOUBLE PRECISION AS total_amount
  FROM public.estimates e
  LEFT JOIN public.contracts c ON e.contract_id = c.id
  WHERE e.company_id = p_company_id
    AND e.visible_in_estimates_module = true
    AND (
      v_is_owner = true
      OR (
        e.object_id IS NOT NULL
        AND e.object_id = ANY (COALESCE(v_user_objects, '{}'::UUID[]))
      )
    )
  GROUP BY e.estimate_title, e.object_id, e.contract_id, c.number
  ORDER BY e.estimate_title;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMIT;
