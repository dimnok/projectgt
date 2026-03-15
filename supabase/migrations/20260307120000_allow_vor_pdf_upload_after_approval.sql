BEGIN;

CREATE OR REPLACE FUNCTION public.set_vor_pdf_document(
    p_vor_id UUID,
    p_company_id UUID,
    p_pdf_url TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Пользователь не авторизован';
    END IF;

    IF p_company_id IS NULL THEN
        RAISE EXCEPTION 'Компания не указана';
    END IF;

    IF NOT public.check_permission(auth.uid(), 'estimates', 'update') THEN
        RAISE EXCEPTION 'Недостаточно прав для загрузки PDF ВОР';
    END IF;

    UPDATE public.vors
    SET
        pdf_url = NULLIF(TRIM(p_pdf_url), ''),
        updated_at = now()
    WHERE id = p_vor_id
      AND company_id = p_company_id
      AND company_id IN (SELECT public.get_my_company_ids())
      AND status = 'approved';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Подписанная ВОР не найдена или недоступна для обновления';
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_vor_pdf_document(UUID, UUID, TEXT)
TO authenticated;

COMMENT ON FUNCTION public.set_vor_pdf_document(UUID, UUID, TEXT)
IS 'Обновляет pdf_url у подписанной ВОР без разблокировки остальных полей записи';

COMMIT;
