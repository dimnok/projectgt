-- Убираем глобальное одобрение: новые пользователи сразу активны.
-- Доступ в компанию — через invitation_code и company_members.is_active.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_phone_digits text;
  v_email text;
BEGIN
  v_phone_digits := public.normalize_ru_phone_digits(
    COALESCE(NEW.phone, NEW.raw_user_meta_data->>'phone')
  );

  v_email := NULLIF(btrim(COALESCE(NEW.email, '')), '');
  IF v_email IS NULL AND v_phone_digits IS NOT NULL THEN
    v_email := v_phone_digits || '@telegram.gt';
  END IF;
  IF v_email IS NULL OR btrim(v_email) = '' THEN
    v_email := COALESCE(NULLIF(btrim(NEW.raw_user_meta_data->>'email'), ''), 'user_' || NEW.id::text);
  END IF;

  INSERT INTO public.profiles (
    id,
    email,
    full_name,
    short_name,
    phone,
    status,
    approved_at,
    disabled_at
  )
  VALUES (
    NEW.id,
    v_email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', ''),
    '',
    COALESCE(v_phone_digits, ''),
    true,
    now(),
    NULL
  );

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_new_user() IS
  'Создаёт активный profiles при регистрации. Доступ в компанию — через company_members.';

-- Ожидавшие глобального одобрения (никогда не были активны)
UPDATE public.profiles
SET
  status = true,
  approved_at = COALESCE(approved_at, now()),
  updated_at = now()
WHERE status = false
  AND approved_at IS NULL;
