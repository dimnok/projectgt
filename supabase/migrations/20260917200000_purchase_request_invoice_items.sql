-- Строки счёта: позиции «как в счёте» и связь с позициями заявки.
--
-- Заявка и счёт называют товары по-разному, поэтому у счёта свои строки.
-- Необязательная ссылка на позицию заявки связывает «что заказали» и
-- «что в счёте» — это основа для сверки и будущей приёмки по позициям.
--
-- Запись — только через функцию `purchase_request_replace_invoice_items`
-- (одной операцией, как у позиций заявки). Прямая запись запрещена.

BEGIN;

-- ---------------------------------------------------------------------------
-- Таблица строк счёта
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.purchase_request_invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES public.purchase_request_invoices(id) ON DELETE CASCADE,
    request_id UUID NOT NULL REFERENCES public.purchase_requests(id) ON DELETE CASCADE,
    request_item_id UUID REFERENCES public.purchase_request_items(id) ON DELETE SET NULL,
    article TEXT,
    name TEXT NOT NULL CHECK (btrim(name) <> ''),
    unit TEXT,
    quantity NUMERIC(14, 3) CHECK (quantity IS NULL OR quantity >= 0),
    price NUMERIC(14, 2) CHECK (price IS NULL OR price >= 0),
    amount NUMERIC(14, 2) CHECK (amount IS NULL OR amount >= 0),
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_purchase_request_invoice_items_invoice
    ON public.purchase_request_invoice_items (invoice_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_purchase_request_invoice_items_request
    ON public.purchase_request_invoice_items (request_id);

CREATE INDEX IF NOT EXISTS idx_purchase_request_invoice_items_request_item
    ON public.purchase_request_invoice_items (request_item_id)
    WHERE request_item_id IS NOT NULL;

COMMENT ON TABLE public.purchase_request_invoice_items IS
    'Позиции счёта: как товары названы в самом счёте. Ссылка на позицию заявки — необязательная.';

-- ---------------------------------------------------------------------------
-- Доступ: чтение — как у счёта, запись — только через функцию
-- ---------------------------------------------------------------------------
ALTER TABLE public.purchase_request_invoice_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pr_invoice_items_select" ON public.purchase_request_invoice_items;
CREATE POLICY "pr_invoice_items_select"
ON public.purchase_request_invoice_items FOR SELECT TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = purchase_request_invoice_items.request_id
          AND public.purchase_request_can_read(r.company_id, r.created_by, r.status)
    )
);

GRANT SELECT ON public.purchase_request_invoice_items TO authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.purchase_request_invoice_items FROM authenticated;
REVOKE ALL ON public.purchase_request_invoice_items FROM anon;

-- ---------------------------------------------------------------------------
-- Кому разрешено распознавать счёт
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purchase_request_can_recognize_invoice(
    p_request_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.purchase_requests r
        WHERE r.id = p_request_id
          AND public.purchase_request_can_read(r.company_id, r.created_by, r.status)
          AND public.check_permission(
              auth.uid(), 'purchase_requests', 'prepare_invoice'
          )
    );
$$;

COMMENT ON FUNCTION public.purchase_request_can_recognize_invoice(UUID) IS
    'Может ли текущий пользователь запускать распознавание счёта по заявке.';

REVOKE ALL ON FUNCTION public.purchase_request_can_recognize_invoice(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_can_recognize_invoice(UUID) TO authenticated;

-- ---------------------------------------------------------------------------
-- Сохранение строк счёта одной операцией
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purchase_request_replace_invoice_items(
    p_invoice_id UUID,
    p_items JSONB
)
RETURNS SETOF public.purchase_request_invoice_items
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_invoice public.purchase_request_invoices;
    v_request public.purchase_requests;
    v_uid UUID := auth.uid();
    v_item JSONB;
    v_id UUID;
    v_name TEXT;
    v_unit TEXT;
    v_article TEXT;
    v_quantity_text TEXT;
    v_price_text TEXT;
    v_amount_text TEXT;
    v_request_item_id UUID;
    v_order INT := 0;
    v_kept UUID[] := '{}';
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
    END IF;

    SELECT * INTO v_invoice
    FROM public.purchase_request_invoices
    WHERE id = p_invoice_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Счёт не найден';
    END IF;

    SELECT * INTO v_request
    FROM public.purchase_requests
    WHERE id = v_invoice.request_id
    FOR UPDATE;

    PERFORM public.purchase_request_internal_assert_company(v_invoice.company_id);

    IF v_request.status <> 'invoice_preparation' THEN
        RAISE EXCEPTION 'Строки счёта правятся только на этапе подготовки счетов';
    END IF;

    IF NOT public.purchase_request_internal_user_is_assignee(
        v_request.company_id, v_request.status, v_request.created_by, v_uid
    ) THEN
        RAISE EXCEPTION 'Access denied' USING ERRCODE = '42501';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'prepare_invoice') THEN
        RAISE EXCEPTION 'Access denied' USING ERRCODE = '42501';
    END IF;

    FOR v_item IN
        SELECT elem
        FROM jsonb_array_elements(COALESCE(p_items, '[]'::jsonb)) AS t(elem)
    LOOP
        v_name := btrim(COALESCE(v_item->>'name', ''));
        IF v_name = '' THEN
            RAISE EXCEPTION 'У позиции счёта не указано наименование';
        END IF;

        v_unit := NULLIF(btrim(COALESCE(v_item->>'unit', '')), '');
        v_article := NULLIF(btrim(COALESCE(v_item->>'article', '')), '');

        v_quantity_text := btrim(COALESCE(v_item->>'quantity', ''));
        v_price_text := btrim(COALESCE(v_item->>'price', ''));
        v_amount_text := btrim(COALESCE(v_item->>'amount', ''));

        v_request_item_id := NULLIF(btrim(COALESCE(v_item->>'request_item_id', '')), '')::UUID;
        IF v_request_item_id IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM public.purchase_request_items i
            WHERE i.id = v_request_item_id
              AND i.request_id = v_invoice.request_id
        ) THEN
            RAISE EXCEPTION 'Позиция заявки не относится к этому счёту';
        END IF;

        v_id := NULLIF(btrim(COALESCE(v_item->>'id', '')), '')::UUID;

        IF v_id IS NULL THEN
            INSERT INTO public.purchase_request_invoice_items (
                company_id, invoice_id, request_id, request_item_id,
                article, name, unit, quantity, price, amount, sort_order
            ) VALUES (
                v_invoice.company_id, p_invoice_id, v_invoice.request_id, v_request_item_id,
                v_article, v_name, v_unit,
                NULLIF(v_quantity_text, '')::NUMERIC,
                NULLIF(v_price_text, '')::NUMERIC,
                NULLIF(v_amount_text, '')::NUMERIC,
                v_order
            )
            RETURNING id INTO v_id;
        ELSE
            UPDATE public.purchase_request_invoice_items
            SET request_item_id = v_request_item_id,
                article = v_article,
                name = v_name,
                unit = v_unit,
                quantity = NULLIF(v_quantity_text, '')::NUMERIC,
                price = NULLIF(v_price_text, '')::NUMERIC,
                amount = NULLIF(v_amount_text, '')::NUMERIC,
                sort_order = v_order
            WHERE id = v_id
              AND invoice_id = p_invoice_id
              AND company_id = v_invoice.company_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Строка счёта не относится к этому счёту';
            END IF;
        END IF;

        v_kept := array_append(v_kept, v_id);
        v_order := v_order + 1;
    END LOOP;

    DELETE FROM public.purchase_request_invoice_items
    WHERE invoice_id = p_invoice_id
      AND NOT (id = ANY (v_kept));

    RETURN QUERY
    SELECT *
    FROM public.purchase_request_invoice_items
    WHERE invoice_id = p_invoice_id
    ORDER BY sort_order, created_at;
END;
$$;

COMMENT ON FUNCTION public.purchase_request_replace_invoice_items(UUID, JSONB) IS
    'Атомарно заменяет строки счёта: добавляет, обновляет и удаляет одним вызовом.';

REVOKE ALL ON FUNCTION public.purchase_request_replace_invoice_items(UUID, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_replace_invoice_items(UUID, JSONB) TO authenticated;

COMMIT;
