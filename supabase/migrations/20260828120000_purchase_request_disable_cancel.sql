-- После отправки на согласование откат в черновик запрещён.
-- Вернуть заявку может только согласующий текущего этапа (purchase_request_return).

CREATE OR REPLACE FUNCTION public.purchase_request_cancel(
    p_request_id UUID,
    p_comment TEXT
)
RETURNS public.purchase_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
BEGIN
    RAISE EXCEPTION
        'Заявку нельзя вернуть в черновик после отправки на согласование. Вернуть на доработку может только согласующий текущего этапа';
END;
$$;

COMMENT ON FUNCTION public.purchase_request_cancel(UUID, TEXT) IS
    'Заблокировано: после submit откат в draft запрещён. Используйте purchase_request_return.';
