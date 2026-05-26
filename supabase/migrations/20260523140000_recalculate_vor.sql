-- Пересчёт состава ВОР в статусе «черновик» без удаления ведомости.
-- Старые пути Excel сохраняются в истории; активные ссылки сбрасываются для новой выгрузки.

BEGIN;

CREATE OR REPLACE FUNCTION public.recalculate_vor(p_vor_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_status public.vor_status;
    v_company_id UUID;
    v_excel_url TEXT;
    v_excel_combined_url TEXT;
    v_comment TEXT;
BEGIN
    SELECT status, company_id, excel_url, excel_combined_url
    INTO v_status, v_company_id, v_excel_url, v_excel_combined_url
    FROM public.vors
    WHERE id = p_vor_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ведомость ВОР с ID % не найдена', p_vor_id;
    END IF;

    IF v_status IS DISTINCT FROM 'draft'::public.vor_status THEN
        RAISE EXCEPTION 'Пересчёт доступен только для черновика';
    END IF;

    v_comment := 'Пересчёт состава ведомости';

    IF v_excel_url IS NOT NULL OR v_excel_combined_url IS NOT NULL THEN
        v_comment := v_comment || '. Архив файлов:';
        IF v_excel_url IS NOT NULL THEN
            v_comment := v_comment || ' excel=' || v_excel_url;
        END IF;
        IF v_excel_combined_url IS NOT NULL THEN
            v_comment := v_comment || ' combined=' || v_excel_combined_url;
        END IF;

        UPDATE public.vors
        SET
            excel_url = NULL,
            excel_combined_url = NULL,
            updated_at = now()
        WHERE id = p_vor_id;
    END IF;

    PERFORM public.populate_vor_items(p_vor_id);

    INSERT INTO public.vor_status_history (
        vor_id,
        company_id,
        status,
        user_id,
        comment
    )
    VALUES (
        p_vor_id,
        v_company_id,
        'draft'::public.vor_status,
        auth.uid(),
        v_comment
    );
END;
$$;

COMMENT ON FUNCTION public.recalculate_vor(UUID) IS
    'Пересчитывает позиции ВОР из журналов работ (только draft). Архивирует пути Excel в истории.';

GRANT EXECUTE ON FUNCTION public.recalculate_vor(UUID) TO authenticated;

COMMIT;
