-- Список пользователей компании для настройки маршрута заявок.

BEGIN;

CREATE OR REPLACE FUNCTION public.purchase_request_company_users(
    p_company_id UUID
)
RETURNS TABLE (
    id UUID,
    email TEXT,
    full_name TEXT,
    short_name TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    PERFORM public.purchase_request_internal_assert_company(p_company_id);

    RETURN QUERY
    SELECT
        p.id,
        COALESCE(p.email, ''),
        p.full_name,
        p.short_name
    FROM public.company_members cm
    JOIN public.profiles p ON p.id = cm.user_id
    WHERE cm.company_id = p_company_id
      AND cm.is_active = true
    ORDER BY COALESCE(p.full_name, p.email);
END;
$$;

REVOKE ALL ON FUNCTION public.purchase_request_company_users(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_company_users(UUID) TO authenticated;

COMMIT;
