-- В деталях сметы показывать короткое ФИО (Фамилия И.О.), как в профиле.

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
  e.visible_in_estimates_module,
  e.position_id,
  e.created_by,
  COALESCE(
    NULLIF(BTRIM(p.short_name), ''),
    NULLIF(BTRIM(p.full_name), '')
  ) AS created_by_name
FROM public.estimates e
LEFT JOIN public.profiles p ON p.id = e.created_by;
