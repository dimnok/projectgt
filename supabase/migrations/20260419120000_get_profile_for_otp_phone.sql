-- Поиск профиля для OTP: сравнение по нормализованному номеру (только цифры, ведущая 8→7),
-- чтобы находить записи вроде "+7 961 009 21 41" при входе по коду, где в токене "79610092141".

CREATE OR REPLACE FUNCTION public.get_profile_for_otp_phone(p_normalized text)
RETURNS TABLE (id uuid, email text, phone text)
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT p.id, p.email, p.phone
  FROM public.profiles p
  WHERE coalesce(nullif(trim(p_normalized), ''), '') <> ''
    AND regexp_replace(
      regexp_replace(coalesce(p.phone, ''), '\D', '', 'g'),
      '^8',
      '7'
    ) = p_normalized
  ORDER BY p.created_at ASC NULLS LAST
  LIMIT 1;
$$;

COMMENT ON FUNCTION public.get_profile_for_otp_phone(text) IS
  'OTP login: find profile by normalized RU mobile (digits, 8→7). Used from otp-notisend (service_role).';

REVOKE ALL ON FUNCTION public.get_profile_for_otp_phone(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_profile_for_otp_phone(text) TO service_role;
