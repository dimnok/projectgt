-- Создание организации текущим пользователем (онбординг веб-приложения).
--
-- Раньше компания создавалась прямыми вставками в `companies` и `company_members`
-- из клиента. На `companies` нет политики INSERT, поэтому такой способ зависит от
-- настроек RLS вне репозитория. Делаем создание через SECURITY DEFINER функцию —
-- тем же способом, что и вступление по коду (`redeem_company_invitation`).

CREATE OR REPLACE FUNCTION public.create_company_for_user(p_data JSONB)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_company_id UUID;
  v_name_full TEXT;
  v_name_short TEXT;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  v_name_full := NULLIF(trim(COALESCE(p_data->>'name_full', '')), '');
  v_name_short := NULLIF(trim(COALESCE(p_data->>'name_short', '')), '');

  IF v_name_full IS NULL OR v_name_short IS NULL THEN
    RAISE EXCEPTION 'invalid_company_name';
  END IF;

  INSERT INTO public.companies (
    name_full,
    name_short,
    logo_url,
    website,
    email,
    phone,
    activity_description,
    inn,
    kpp,
    ogrn,
    okpo,
    legal_address,
    actual_address,
    director_name,
    director_position,
    director_basis,
    director_phone,
    chief_accountant_name,
    chief_accountant_phone,
    contact_person,
    taxation_system,
    is_vat_payer,
    vat_rate,
    owner_id
  )
  VALUES (
    v_name_full,
    v_name_short,
    NULLIF(trim(COALESCE(p_data->>'logo_url', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'website', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'email', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'phone', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'activity_description', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'inn', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'kpp', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'ogrn', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'okpo', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'legal_address', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'actual_address', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'director_name', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'director_position', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'director_basis', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'director_phone', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'chief_accountant_name', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'chief_accountant_phone', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'contact_person', '')), ''),
    NULLIF(trim(COALESCE(p_data->>'taxation_system', '')), ''),
    COALESCE((p_data->>'is_vat_payer')::boolean, false),
    COALESCE(NULLIF(p_data->>'vat_rate', '')::numeric, 0),
    v_user_id
  )
  RETURNING id INTO v_company_id;

  INSERT INTO public.company_members (company_id, user_id, is_owner, system_role, is_active)
  VALUES (v_company_id, v_user_id, true, 'owner', true)
  ON CONFLICT (company_id, user_id)
  DO UPDATE SET is_owner = true, system_role = 'owner', is_active = true;

  UPDATE public.profiles
  SET last_company_id = v_company_id,
      updated_at = now()
  WHERE id = v_user_id;

  RETURN v_company_id;
END;
$$;

COMMENT ON FUNCTION public.create_company_for_user(JSONB) IS
  'Создаёт организацию от имени текущего пользователя и назначает его владельцем.';

REVOKE EXECUTE ON FUNCTION public.create_company_for_user(JSONB) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_company_for_user(JSONB) TO authenticated;
