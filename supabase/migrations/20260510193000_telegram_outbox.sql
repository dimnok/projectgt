-- =============================================================================
-- Очередь уведомлений Telegram по сменам (outbox) + ретраи
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS public.telegram_outbox (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies (id) ON DELETE CASCADE,
  work_id uuid NOT NULL REFERENCES public.works (id) ON DELETE CASCADE,
  kind text NOT NULL CHECK (kind IN ('work_opening_telegram', 'work_close_telegram')),
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'sent', 'failed')),
  attempts integer NOT NULL DEFAULT 0,
  max_attempts integer NOT NULL DEFAULT 10,
  next_run_at timestamptz NOT NULL DEFAULT now(),
  last_error text,
  idempotency_key text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT telegram_outbox_idempotency_key_unique UNIQUE (idempotency_key)
);

CREATE INDEX IF NOT EXISTS idx_telegram_outbox_pending
  ON public.telegram_outbox (status, next_run_at)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_telegram_outbox_company_created
  ON public.telegram_outbox (company_id, created_at DESC);

COMMENT ON TABLE public.telegram_outbox IS
  'Очередь доставки сообщений о сменах в Telegram; обрабатывается Edge Function process_telegram_outbox.';

-- -----------------------------------------------------------------------------
-- RLS
-- -----------------------------------------------------------------------------
ALTER TABLE public.telegram_outbox ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "telegram_outbox_select_company" ON public.telegram_outbox;
CREATE POLICY "telegram_outbox_select_company"
  ON public.telegram_outbox
  FOR SELECT
  TO authenticated
  USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'works', 'read')
  );

-- -----------------------------------------------------------------------------
-- Закрытие смены → задача на вечерний отчёт (и обновление утреннего при наличии id)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trigger_works_enqueue_telegram_close()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'closed'
     AND (TG_OP = 'UPDATE')
     AND (OLD.status IS DISTINCT FROM NEW.status)
     AND (OLD.status <> 'closed') THEN
    INSERT INTO public.telegram_outbox (
      company_id,
      work_id,
      kind,
      payload,
      status,
      idempotency_key
    )
    VALUES (
      NEW.company_id,
      NEW.id,
      'work_close_telegram',
      '{}'::jsonb,
      'pending',
      NEW.id::text || ':work_close_telegram'
    )
    ON CONFLICT (idempotency_key) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS works_enqueue_telegram_close ON public.works;
CREATE TRIGGER works_enqueue_telegram_close
  AFTER UPDATE ON public.works
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_works_enqueue_telegram_close();

COMMENT ON FUNCTION public.trigger_works_enqueue_telegram_close() IS
  'Ставит в очередь отправку Telegram при переходе смены в статус closed.';

-- -----------------------------------------------------------------------------
-- Постановка утреннего отчёта (после создания смены и строк work_hours на клиенте)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enqueue_telegram_outbox_opening(
  p_work_id uuid,
  p_worker_names jsonb DEFAULT '[]'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_company_id uuid;
BEGIN
  SELECT w.company_id INTO v_company_id
  FROM public.works w
  WHERE w.id = p_work_id;

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'work not found';
  END IF;

  IF v_company_id NOT IN (SELECT public.get_my_company_ids()) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF NOT public.check_permission(auth.uid(), 'works', 'create') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  INSERT INTO public.telegram_outbox (
    company_id,
    work_id,
    kind,
    payload,
    status,
    idempotency_key
  )
  VALUES (
    v_company_id,
    p_work_id,
    'work_opening_telegram',
    jsonb_build_object('worker_names', COALESCE(p_worker_names, '[]'::jsonb)),
    'pending',
    p_work_id::text || ':work_opening_telegram'
  )
  ON CONFLICT (idempotency_key) DO NOTHING;
END;
$$;

COMMENT ON FUNCTION public.enqueue_telegram_outbox_opening(uuid, jsonb) IS
  'Ставит в очередь утренний отчёт Telegram по смене (ФИО сотрудников в payload.worker_names).';

GRANT EXECUTE ON FUNCTION public.enqueue_telegram_outbox_opening(uuid, jsonb) TO authenticated;

-- -----------------------------------------------------------------------------
-- Выборка батча для воркера (пользователь — только свои компании)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.claim_telegram_outbox_for_user(p_limit integer DEFAULT 15)
RETURNS SETOF public.telegram_outbox
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  UPDATE public.telegram_outbox o
  SET status = 'processing',
      updated_at = now()
  WHERE o.id IN (
    SELECT i.id
    FROM public.telegram_outbox i
    WHERE i.status = 'pending'
      AND i.next_run_at <= now()
      AND i.company_id IN (
        SELECT cm.company_id
        FROM public.company_members cm
        WHERE cm.user_id = auth.uid()
          AND cm.is_active IS TRUE
      )
    ORDER BY i.created_at
    FOR UPDATE OF i SKIP LOCKED
    LIMIT GREATEST(1, LEAST(p_limit, 50))
  )
  RETURNING o.*;
END;
$$;

COMMENT ON FUNCTION public.claim_telegram_outbox_for_user(integer) IS
  'Блокирует и возвращает строки очереди Telegram для компаний текущего пользователя.';

GRANT EXECUTE ON FUNCTION public.claim_telegram_outbox_for_user(integer) TO authenticated;

-- -----------------------------------------------------------------------------
-- Выборка батча для cron / сервисной роли (все компании)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.claim_telegram_outbox_cron(p_limit integer DEFAULT 25)
RETURNS SETOF public.telegram_outbox
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF (auth.jwt()->>'role') IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  UPDATE public.telegram_outbox o
  SET status = 'processing',
      updated_at = now()
  WHERE o.id IN (
    SELECT i.id
    FROM public.telegram_outbox i
    WHERE i.status = 'pending'
      AND i.next_run_at <= now()
    ORDER BY i.created_at
    FOR UPDATE OF i SKIP LOCKED
    LIMIT GREATEST(1, LEAST(p_limit, 100))
  )
  RETURNING o.*;
END;
$$;

COMMENT ON FUNCTION public.claim_telegram_outbox_cron(integer) IS
  'Блокирует батч очереди Telegram (только вызов с JWT role=service_role).';

REVOKE ALL ON FUNCTION public.claim_telegram_outbox_cron(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_telegram_outbox_cron(integer) TO service_role;

COMMIT;
