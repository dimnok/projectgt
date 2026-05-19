-- Нормализация российских мобильных номеров:
-- profiles / employees: 7XXXXXXXXXX (11 цифр)
-- auth.users.phone: +7XXXXXXXXXX (E.164)

CREATE OR REPLACE FUNCTION public.normalize_ru_phone_digits(p_phone text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
DECLARE
  d text;
BEGIN
  IF p_phone IS NULL OR btrim(p_phone) = '' THEN
    RETURN NULL;
  END IF;

  d := regexp_replace(p_phone, '\D', '', 'g');
  IF d = '' THEN
    RETURN NULL;
  END IF;

  IF length(d) = 11 AND left(d, 1) = '8' THEN
    d := '7' || substring(d FROM 2);
  ELSIF length(d) = 10 THEN
    d := '7' || d;
  END IF;

  IF length(d) = 11 AND left(d, 1) = '7' THEN
    RETURN d;
  END IF;

  RETURN NULL;
END;
$$;

COMMENT ON FUNCTION public.normalize_ru_phone_digits(text) IS
  'RU mobile: 11 digits starting with 7. Strips formatting; 8→7, 10-digit → 7+10.';

CREATE OR REPLACE FUNCTION public.normalize_ru_phone_e164(p_phone text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT CASE
    WHEN public.normalize_ru_phone_digits(p_phone) IS NOT NULL
      THEN '+' || public.normalize_ru_phone_digits(p_phone)
    ELSE NULL
  END;
$$;

COMMENT ON FUNCTION public.normalize_ru_phone_e164(text) IS
  'E.164 for Supabase Auth phone (+7XXXXXXXXXX).';

-- OTP lookup: единая нормализация
CREATE OR REPLACE FUNCTION public.get_profile_for_otp_phone(p_normalized text)
RETURNS TABLE (id uuid, email text, phone text)
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT p.id, p.email, p.phone
  FROM public.profiles p
  WHERE public.normalize_ru_phone_digits(p_normalized) IS NOT NULL
    AND public.normalize_ru_phone_digits(p.phone)
      = public.normalize_ru_phone_digits(p_normalized)
  ORDER BY p.created_at ASC NULLS LAST
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.normalize_profiles_phone_trigger()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.phone IS NOT NULL AND btrim(NEW.phone) <> '' THEN
    NEW.phone := public.normalize_ru_phone_digits(NEW.phone);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS normalize_profiles_phone ON public.profiles;
CREATE TRIGGER normalize_profiles_phone
  BEFORE INSERT OR UPDATE OF phone ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.normalize_profiles_phone_trigger();

CREATE OR REPLACE FUNCTION public.normalize_employees_phone_trigger()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  normalized text;
BEGIN
  IF NEW.phone IS NOT NULL AND btrim(NEW.phone) <> '' THEN
    normalized := public.normalize_ru_phone_digits(NEW.phone);
    IF normalized IS NOT NULL THEN
      NEW.phone := normalized;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS normalize_employees_phone ON public.employees;
CREATE TRIGGER normalize_employees_phone
  BEFORE INSERT OR UPDATE OF phone ON public.employees
  FOR EACH ROW
  EXECUTE FUNCTION public.normalize_employees_phone_trigger();

-- Синхронизация profiles → auth.users (E.164 в Auth)
CREATE OR REPLACE FUNCTION public.sync_profile_to_auth()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE auth.users
  SET
    phone = public.normalize_ru_phone_e164(NEW.phone),
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

-- Разовое выравнивание существующих данных
UPDATE public.profiles
SET phone = public.normalize_ru_phone_digits(phone)
WHERE phone IS NOT NULL AND btrim(phone) <> '';

UPDATE public.employees
SET phone = public.normalize_ru_phone_digits(phone)
WHERE phone IS NOT NULL
  AND btrim(phone) <> ''
  AND public.normalize_ru_phone_digits(phone) IS NOT NULL;

UPDATE auth.users u
SET phone = public.normalize_ru_phone_e164(COALESCE(p.phone, u.phone))
FROM public.profiles p
WHERE p.id = u.id
  AND public.normalize_ru_phone_e164(COALESCE(p.phone, u.phone)) IS NOT NULL;

UPDATE auth.users
SET phone = public.normalize_ru_phone_e164(phone)
WHERE phone IS NOT NULL
  AND btrim(phone) <> ''
  AND public.normalize_ru_phone_e164(phone) IS NOT NULL;

GRANT EXECUTE ON FUNCTION public.normalize_ru_phone_digits(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.normalize_ru_phone_e164(text) TO authenticated;
