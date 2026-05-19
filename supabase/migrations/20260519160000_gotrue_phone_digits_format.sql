-- GoTrue хранит и ищет phone без префикса '+' (E.164 digits only).
-- normalize_ru_phone_e164 (+7...) ломает FindUserByPhoneAndAudience при OTP.

COMMENT ON FUNCTION public.normalize_ru_phone_e164(text) IS
  'E.164 с «+» для клиента/UI. В auth.users — только normalize_ru_phone_digits.';

-- 1. auth.users.phone → 11 цифр (79...)
UPDATE auth.users
SET phone = public.normalize_ru_phone_digits(phone)
WHERE phone IS NOT NULL
  AND btrim(phone) <> ''
  AND public.normalize_ru_phone_digits(phone) IS NOT NULL
  AND phone IS DISTINCT FROM public.normalize_ru_phone_digits(phone);

-- 2. Удалить некорректные phone identities (provider_id = номер вместо user id)
DELETE FROM auth.identities i
WHERE i.provider = 'phone'
  AND i.provider_id !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- 3. Корректные phone identities (provider_id = user id, как в GoTrue)
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
  u.id::text,
  jsonb_build_object(
    'sub', u.id::text,
    'phone', u.phone,
    'phone_verified', u.phone_confirmed_at IS NOT NULL,
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

-- 4. sync_profile_to_auth — писать в Auth формат GoTrue
CREATE OR REPLACE FUNCTION public.sync_profile_to_auth()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE auth.users
  SET
    phone = public.normalize_ru_phone_digits(NEW.phone),
    phone_confirmed_at = COALESCE(phone_confirmed_at, now()),
    raw_user_meta_data = raw_user_meta_data || jsonb_build_object(
      'phone', NEW.phone,
      'full_name', NEW.full_name,
      'name', NEW.full_name
    )
  WHERE id = NEW.id;

  RETURN NEW;
END;
$$;
