-- =============================================================================
-- Заявки на закупку: push-уведомления
-- =============================================================================
--
-- 1. Инициатор получает уведомление на каждом этапе согласования, а также
--    об оплате и получении. Реализовано триггером на purchase_request_history:
--    тела RPC не дублируются — достаточно смотреть на код действия.
-- 2. Колонка `pushed_at` — отметка, что push по уведомлению отправлен.
--    Её читает и заполняет Edge Function `send_purchase_request_event`.
--
-- Кому уходит push: ровно тем, кому записано уведомление, — участникам роли
-- текущего этапа (как и раньше) плюс инициатору по действиям согласования.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1. Отметка отправки push
-- -----------------------------------------------------------------------------
ALTER TABLE public.purchase_request_notifications
    ADD COLUMN IF NOT EXISTS pushed_at timestamptz;

COMMENT ON COLUMN public.purchase_request_notifications.pushed_at IS
    'Когда push по уведомлению отправлен. Заполняет Edge Function send_purchase_request_event.';

-- Быстрый поиск неотправленных уведомлений по заявке.
CREATE INDEX IF NOT EXISTS idx_purchase_request_notifications_pending_push
    ON public.purchase_request_notifications (request_id)
    WHERE pushed_at IS NULL;

-- -----------------------------------------------------------------------------
-- 2. Уведомление инициатора по действиям согласования и оплаты
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purchase_request_internal_notify_creator_on_action()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_creator_id UUID;
    v_number TEXT;
    v_company_id UUID;
    v_phrase TEXT;
BEGIN
    -- Фразы только для этапов согласования, оплаты и получения.
    -- Возврат заявки на доработку (`returned`) уведомляет инициатора в самом RPC.
    v_phrase := CASE NEW.action
        WHEN 'approved' THEN 'согласована'
        WHEN 'invoice_approved' THEN 'счета согласованы'
        WHEN 'invoice_returned' THEN 'счета возвращены на доработку'
        WHEN 'queued_for_payment' THEN 'заведена на оплату'
        WHEN 'paid' THEN 'оплачена'
        WHEN 'received' THEN 'получена'
        ELSE NULL
    END;

    IF v_phrase IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT r.created_by, r.number, r.company_id
    INTO v_creator_id, v_number, v_company_id
    FROM public.purchase_requests r
    WHERE r.id = NEW.request_id;

    IF v_creator_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- Действие выполнил сам инициатор — уведомление ему не нужно.
    IF v_creator_id = NEW.user_id THEN
        RETURN NEW;
    END IF;

    INSERT INTO public.purchase_request_notifications (
        company_id, request_id, user_id, title, body
    ) VALUES (
        v_company_id, NEW.request_id, v_creator_id,
        v_number || ' ' || v_phrase,
        NEW.comment
    );

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.purchase_request_internal_notify_creator_on_action() IS
    'Уведомляет инициатора о согласовании, оплате и получении заявки на закупку.';

REVOKE ALL ON FUNCTION public.purchase_request_internal_notify_creator_on_action()
    FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS purchase_request_history_notify_creator
    ON public.purchase_request_history;

CREATE TRIGGER purchase_request_history_notify_creator
    AFTER INSERT ON public.purchase_request_history
    FOR EACH ROW
    EXECUTE FUNCTION public.purchase_request_internal_notify_creator_on_action();

COMMIT;
