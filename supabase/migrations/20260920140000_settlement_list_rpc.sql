-- Взаиморасчёты: реестр и итоги считает база.
--
-- Было: итоги читались в браузер порциями по 1000 строк (до 20 запросов) и
-- суммировались на клиенте, а поиск по контрагенту, объекту и договору шёл
-- тремя отдельными запросами и ограничивался первыми 200 совпадениями.
-- Стало: одна функция на итоги и одна на страницу реестра; поиск по всем
-- справочникам идёт одним условием внутри базы, лимита на совпадения нет.
--
-- Поиск — подстрока без шаблонов (`strpos` вместо `ilike`): символы % и _
-- в запросе не считаются служебными и не требуют экранирования.
-- Регистр не важен. Так же ищет приложение.
--
-- Функции объявлены SECURITY INVOKER: права и изоляция компаний работают как
-- при обычной выборке, переданный p_company_id сам по себе доступа не даёт.

BEGIN;

-- Счета компании с фильтрами и поиском. Общее основание для реестра и итогов.
CREATE OR REPLACE FUNCTION public.settlement_operations_filtered(
    p_company_id UUID,
    p_search TEXT DEFAULT NULL,
    p_operation_type TEXT DEFAULT NULL,
    p_payment_status TEXT DEFAULT NULL,
    p_contractor_id UUID DEFAULT NULL,
    p_object_id UUID DEFAULT NULL,
    p_contract_id UUID DEFAULT NULL
)
RETURNS SETOF public.settlement_operations
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
    SELECT o.*
    FROM public.settlement_operations o
    WHERE o.company_id = p_company_id
      AND (p_operation_type IS NULL OR o.operation_type = p_operation_type)
      AND (p_payment_status IS NULL OR o.payment_status = p_payment_status)
      AND (p_contractor_id IS NULL OR o.contractor_id = p_contractor_id)
      AND (p_object_id IS NULL OR o.object_id = p_object_id)
      AND (p_contract_id IS NULL OR o.contract_id = p_contract_id)
      AND (
        coalesce(btrim(p_search), '') = ''
        OR strpos(lower(o.invoice_number), lower(btrim(p_search))) > 0
        OR strpos(lower(coalesce(o.act_number, '')), lower(btrim(p_search))) > 0
        OR strpos(lower(coalesce(o.note, '')), lower(btrim(p_search))) > 0
        OR EXISTS (
            SELECT 1 FROM public.contracts c
            WHERE c.id = o.contract_id
              AND strpos(lower(c.number), lower(btrim(p_search))) > 0
        )
        OR EXISTS (
            SELECT 1 FROM public.contractors ct
            WHERE ct.id = o.contractor_id
              AND strpos(lower(ct.short_name), lower(btrim(p_search))) > 0
        )
        OR EXISTS (
            SELECT 1 FROM public.objects ob
            WHERE ob.id = o.object_id
              AND strpos(lower(ob.name), lower(btrim(p_search))) > 0
        )
      )
$$;

COMMENT ON FUNCTION public.settlement_operations_filtered(
    UUID, TEXT, TEXT, TEXT, UUID, UUID, UUID
) IS
    'Счета компании под фильтры реестра и поиск. Основание для итогов и страницы.';

-- Итоги реестра одним запросом: сколько счетов, суммы и разбивка по статусам.
CREATE OR REPLACE FUNCTION public.get_settlements_summary(
    p_company_id UUID,
    p_search TEXT DEFAULT NULL,
    p_operation_type TEXT DEFAULT NULL,
    p_payment_status TEXT DEFAULT NULL,
    p_contractor_id UUID DEFAULT NULL,
    p_object_id UUID DEFAULT NULL,
    p_contract_id UUID DEFAULT NULL
)
RETURNS TABLE (
    total_count BIGINT,
    total_amount NUMERIC,
    total_paid NUMERIC,
    total_debt NUMERIC,
    by_status JSONB
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
    WITH filtered AS (
        SELECT * FROM public.settlement_operations_filtered(
            p_company_id, p_search, p_operation_type, p_payment_status,
            p_contractor_id, p_object_id, p_contract_id
        )
    ),
    totals AS (
        SELECT
            count(*) AS cnt,
            coalesce(sum(f.total_to_pay), 0) AS amount,
            coalesce(sum(f.paid_amount), 0) AS paid,
            -- Остаток берём только положительный: переплата долг не уменьшает.
            -- Допуск 0.005 совпадает с триггером статуса и вебом.
            coalesce(
                sum(f.total_to_pay - f.paid_amount)
                    FILTER (WHERE f.total_to_pay - f.paid_amount > 0.005),
                0
            ) AS debt
        FROM filtered f
    ),
    statuses AS (
        SELECT f.payment_status, count(*) AS cnt
        FROM filtered f
        GROUP BY f.payment_status
    )
    SELECT
        t.cnt,
        t.amount,
        t.paid,
        t.debt,
        coalesce(
            (SELECT jsonb_object_agg(s.payment_status, s.cnt) FROM statuses s),
            '{}'::jsonb
        )
    FROM totals t
$$;

COMMENT ON FUNCTION public.get_settlements_summary(
    UUID, TEXT, TEXT, TEXT, UUID, UUID, UUID
) IS
    'Итоги реестра взаиморасчётов: количество, суммы, долг и разбивка по статусам.';

-- Страница реестра: те же фильтры, сортировка по колонке и точное общее число.
--
-- Возвращает одну строку: массив счетов страницы и общее число под фильтром.
-- Общее число приходит даже для пустой страницы — иначе после удаления счетов
-- в другом окне навигация по страницам пропадала бы вместе с данными.
CREATE OR REPLACE FUNCTION public.get_settlements_page(
    p_company_id UUID,
    p_search TEXT DEFAULT NULL,
    p_operation_type TEXT DEFAULT NULL,
    p_payment_status TEXT DEFAULT NULL,
    p_contractor_id UUID DEFAULT NULL,
    p_object_id UUID DEFAULT NULL,
    p_contract_id UUID DEFAULT NULL,
    p_sort_key TEXT DEFAULT 'date',
    p_sort_dir TEXT DEFAULT 'desc',
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    items JSONB,
    total_count BIGINT
)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
    -- Выражение сортировки берётся только из этого списка: в SQL не попадает
    -- ничего, что пришло от клиента.
    v_order TEXT;
    v_dir TEXT;
BEGIN
    v_order := CASE coalesce(p_sort_key, 'date')
        WHEN 'type' THEN 'o.operation_type'
        WHEN 'invoice' THEN 'lower(o.invoice_number)'
        WHEN 'act' THEN 'lower(coalesce(o.act_number, ''''))'
        WHEN 'contract' THEN 'lower(coalesce(ct.number, ''''))'
        WHEN 'contractor' THEN 'lower(coalesce(cr.short_name, ''''))'
        WHEN 'object' THEN 'lower(coalesce(ob.name, ''''))'
        WHEN 'totalToPay' THEN 'o.total_to_pay'
        -- Статус сортируем по смыслу: не оплачен → частично → оплачен → переплата.
        WHEN 'status' THEN
            'CASE o.payment_status'
            || ' WHEN ''unpaid'' THEN 1'
            || ' WHEN ''partial'' THEN 2'
            || ' WHEN ''paid'' THEN 3'
            || ' ELSE 4 END'
        WHEN 'paid' THEN 'o.paid_amount'
        ELSE 'o.invoice_date'
    END;

    v_dir := CASE WHEN lower(coalesce(p_sort_dir, 'desc')) = 'asc' THEN 'asc' ELSE 'desc' END;

    RETURN QUERY EXECUTE format($query$
        WITH filtered AS (
            SELECT * FROM public.settlement_operations_filtered(
                $1, $2, $3, $4, $5, $6, $7
            )
        ),
        total AS (
            SELECT count(*) AS cnt FROM filtered
        ),
        page AS (
            SELECT
                o.id, o.company_id, o.operation_type, o.object_id, o.contractor_id,
                o.contract_id, o.period_from, o.period_to, o.act_number, o.act_date,
                o.invoice_number, o.invoice_date, o.amount, o.vat_amount,
                o.advance_retention, o.warranty_retention, o.total_to_pay,
                o.paid_amount, o.payment_status, o.purpose, o.note,
                o.created_at, o.created_by, o.vat_rate, o.is_vat_included,
                ob.name AS object_name,
                cr.short_name AS contractor_name,
                ct.number AS contract_number,
                -- Второй ключ (id) делает порядок строгим: строки не повторяются
                -- и не пропадают между страницами при одинаковых значениях.
                row_number() OVER (ORDER BY %1$s %2$s, o.id ASC) AS rn
            FROM filtered o
            LEFT JOIN public.objects ob ON ob.id = o.object_id
            LEFT JOIN public.contractors cr ON cr.id = o.contractor_id
            LEFT JOIN public.contracts ct ON ct.id = o.contract_id
            -- Без NULLS LAST: ни одно выражение сортировки не может быть NULL,
            -- зато порядок совпадает с индексом idx_settlement_operations_company_date
            -- и база обходится без сортировки.
            ORDER BY %1$s %2$s, o.id ASC
            LIMIT greatest($8::integer, 0) OFFSET greatest($9::integer, 0)
        )
        SELECT
            coalesce(
                (SELECT jsonb_agg(to_jsonb(p) - 'rn' ORDER BY p.rn) FROM page p),
                '[]'::jsonb
            ),
            (SELECT cnt FROM total)
    $query$, v_order, v_dir)
    USING p_company_id, p_search, p_operation_type, p_payment_status,
          p_contractor_id, p_object_id, p_contract_id, p_limit, p_offset;
END;
$$;

COMMENT ON FUNCTION public.get_settlements_page(
    UUID, TEXT, TEXT, TEXT, UUID, UUID, UUID, TEXT, TEXT, INTEGER, INTEGER
) IS
    'Страница реестра взаиморасчётов: фильтры, поиск, сортировка и общее число строк.';

COMMIT;
