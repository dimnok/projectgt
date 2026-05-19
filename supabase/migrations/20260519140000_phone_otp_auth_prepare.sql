-- Подготовка Phone OTP (Supabase Auth): handle_new_user + phone identities

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
    false,
    NULL,
    NULL
  );

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_new_user() IS
  'Создаёт profiles при регистрации. Phone-only: email = {phone}@telegram.gt.';

-- Синхронизируем phone в auth.users из profiles (если пусто)
UPDATE auth.users u
SET phone = public.normalize_ru_phone_e164(p.phone)
FROM public.profiles p
WHERE p.id = u.id
  AND public.normalize_ru_phone_e164(p.phone) IS NOT NULL
  AND (
    u.phone IS NULL
    OR btrim(u.phone) = ''
    OR u.phone IS DISTINCT FROM public.normalize_ru_phone_e164(p.phone)
  );

-- Phone identity для существующих пользователей (GoTrue ищет provider=phone)
INSERT INTO auth.identities (
  id,
  user_id,
  provider,
  provider_id,
  identity_data,
  created_at,
  updated_at,
  last_sign_in_at
)
SELECT
  gen_random_uuid(),
  u.id,
  'phone',
  u.phone,
  jsonb_build_object(
    'sub', u.id::text,
    'phone', u.phone,
    'phone_verified', true,
    'email_verified', false
  ),
  COALESCE(u.created_at, now()),
  now(),
  u.last_sign_in_at
FROM auth.users u
WHERE u.phone IS NOT NULL
  AND btrim(u.phone) <> ''
  AND NOT EXISTS (
    SELECT 1
    FROM auth.identities i
    WHERE i.user_id = u.id
      AND i.provider = 'phone'
  )
ON CONFLICT (provider_id, provider) DO NOTHING;
