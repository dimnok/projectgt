-- Модуль «ГТ Чат»: данные по сменам для помощника.
--
-- Помощник отвечает на вопросы «кто сегодня на смене» и «кто не вышел».
-- Серверная функция gt_chat вызывает chat_shift_status_today от имени человека,
-- поэтому чужие компании и объекты недоступны: внутри проверяются
-- права (`chat.read`, `timesheet.read`) и область объектов профиля.
--
-- «Не вышел» = нет открытой смены сегодня (как фильтр «не в смене сегодня» в табеле).
-- Отдельно помечаем тех, кто смену уже закрыл (finished) и у кого есть ручная
-- отметка посещаемости: вечером они не должны выглядеть как «не вышли».
--
-- «Сегодня» считается по Москве: база живёт в UTC, а смены открываются по
-- местной дате (так же считает веб-приложение).
--
-- Запись помощнику не нужна: функции только читают.

BEGIN;

-- ---------------------------------------------------------------------------
-- Какие объекты видит пользователь
-- ---------------------------------------------------------------------------
-- Владелец компании и супер-админ — все объекты компании.
-- Остальные — только объекты, закреплённые за их профилем (profiles.object_ids),
-- как в модулях «Работы» и «Табель».
CREATE OR REPLACE FUNCTION public.chat_visible_object_ids(p_company_id UUID)
RETURNS UUID[]
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_is_owner BOOLEAN := false;
BEGIN
    IF v_uid IS NULL OR p_company_id IS NULL THEN
        RETURN '{}'::UUID[];
    END IF;

    SELECT (cm.is_owner = true OR cm.system_role = 'owner')
    INTO v_is_owner
    FROM public.company_members cm
    WHERE cm.company_id = p_company_id
      AND cm.user_id = v_uid
      AND cm.is_active = true;

    IF coalesce(v_is_owner, false) OR public.is_super_admin(v_uid) THEN
        RETURN ARRAY(
            SELECT o.id FROM public.objects o WHERE o.company_id = p_company_id
        );
    END IF;

    RETURN coalesce(
        (SELECT p.object_ids FROM public.profiles p WHERE p.id = v_uid),
        '{}'::UUID[]
    );
END;
$$;

COMMENT ON FUNCTION public.chat_visible_object_ids(UUID) IS
    'Объекты, доступные пользователю в компании: все — владельцу и супер-админу, иначе только привязанные к профилю.';

-- ---------------------------------------------------------------------------
-- Кто на смене сегодня и кто не вышел
-- ---------------------------------------------------------------------------
-- p_object_name — название объекта («ЦОД Салтыковка»). Пусто — вся компания.
-- Возвращает по строке на сотрудника:
--   status = in_shift — сейчас в открытой смене сегодня;
--            finished — сегодня работал, смена уже закрыта (или ручная отметка);
--            absent   — сегодня не выходил.
-- total_count — сколько всего строк до ограничения p_limit.
CREATE OR REPLACE FUNCTION public.chat_shift_status_today(
    p_company_id UUID,
    p_object_name TEXT DEFAULT NULL,
    p_limit INT DEFAULT 200
)
RETURNS TABLE (
    employee_name TEXT,
    employee_position TEXT,
    object_name TEXT,
    status TEXT,
    total_count INT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_today DATE := (now() AT TIME ZONE 'Europe/Moscow')::DATE;
    v_allowed UUID[];
    v_object_ids UUID[];
    v_object_label TEXT;
    v_query TEXT := btrim(coalesce(p_object_name, ''));
    v_matches TEXT;
    v_limit INT := least(greatest(coalesce(p_limit, 200), 1), 500);
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Нужно войти в аккаунт';
    END IF;

    IF p_company_id IS NULL
       OR p_company_id NOT IN (SELECT company_id FROM public.get_my_company_ids()) THEN
        RAISE EXCEPTION 'Нет доступа к компании';
    END IF;

    IF NOT public.check_permission(v_uid, 'chat', 'read') THEN
        RAISE EXCEPTION 'Нет права открывать чат';
    END IF;

    IF NOT public.check_permission(v_uid, 'timesheet', 'read') THEN
        RAISE EXCEPTION 'Нет права смотреть табель';
    END IF;

    v_allowed := public.chat_visible_object_ids(p_company_id);
    IF coalesce(array_length(v_allowed, 1), 0) = 0 THEN
        RETURN;
    END IF;

    IF v_query = '' THEN
        v_object_ids := v_allowed;
    ELSE
        -- Сначала точное совпадение названия, затем поиск по части названия.
        SELECT array_agg(o.id), min(o.name)
        INTO v_object_ids, v_object_label
        FROM public.objects o
        WHERE o.company_id = p_company_id
          AND o.id = ANY(v_allowed)
          AND lower(btrim(o.name)) = lower(v_query);

        IF v_object_ids IS NULL THEN
            SELECT array_agg(o.id), min(o.name)
            INTO v_object_ids, v_object_label
            FROM public.objects o
            WHERE o.company_id = p_company_id
              AND o.id = ANY(v_allowed)
              AND o.name ILIKE '%' || v_query || '%';
        END IF;

        IF v_object_ids IS NULL THEN
            SELECT string_agg(x.name, ', ' ORDER BY x.name) INTO v_matches
            FROM (
                SELECT o.name FROM public.objects o
                WHERE o.company_id = p_company_id
                  AND o.id = ANY(v_allowed)
                ORDER BY o.name
                LIMIT 30
            ) x;
            RAISE EXCEPTION 'Объект «%» не найден. Доступные объекты: %',
                p_object_name, coalesce(v_matches, 'нет');
        END IF;

        IF array_length(v_object_ids, 1) > 1 THEN
            SELECT string_agg(x.name, ', ' ORDER BY x.name) INTO v_matches
            FROM (
                SELECT o.name FROM public.objects o
                WHERE o.id = ANY(v_object_ids)
                ORDER BY o.name
                LIMIT 30
            ) x;
            RAISE EXCEPTION 'Названию «%» подходит несколько объектов: %. Уточните название.',
                p_object_name, v_matches;
        END IF;
    END IF;

    RETURN QUERY
    WITH scope_objects AS (
        SELECT o.id, o.name
        FROM public.objects o
        WHERE o.id = ANY(v_object_ids)
    ),
    open_today AS (
        SELECT DISTINCT wh.employee_id
        FROM public.works w
        JOIN public.work_hours wh ON wh.work_id = w.id
        WHERE w.company_id = p_company_id
          AND w.date = v_today
          AND w.status = 'open'
          AND w.object_id = ANY(v_object_ids)
    ),
    closed_today AS (
        SELECT DISTINCT wh.employee_id
        FROM public.works w
        JOIN public.work_hours wh ON wh.work_id = w.id
        WHERE w.company_id = p_company_id
          AND w.date = v_today
          AND w.status = 'closed'
          AND w.object_id = ANY(v_object_ids)
    ),
    marked_today AS (
        SELECT DISTINCT ea.employee_id
        FROM public.employee_attendance ea
        WHERE ea.company_id = p_company_id
          AND ea.date = v_today
          AND ea.object_id = ANY(v_object_ids)
          AND coalesce(ea.hours, 0) > 0
    ),
    -- Кого вообще проверяем: работающие, закреплённые за объектами из области,
    -- плюс все, кто сегодня как-то отмечен в этих объектах.
    base_ids AS (
        SELECT e.id
        FROM public.employees e
        WHERE e.company_id = p_company_id
          AND e.status = 'working'
          AND EXISTS (
              SELECT 1
              FROM unnest(coalesce(e.object_ids, '{}'::TEXT[])) AS obj
              WHERE obj = ANY (SELECT so.id::TEXT FROM scope_objects so)
          )
        UNION
        SELECT employee_id FROM open_today
        UNION
        SELECT employee_id FROM closed_today
        UNION
        SELECT employee_id FROM marked_today
    )
    SELECT
        coalesce(
            nullif(btrim(concat_ws(' ', e.last_name, e.first_name, e.middle_name)), ''),
            'Без имени'
        ) AS employee_name,
        coalesce(btrim(e.position), '') AS employee_position,
        coalesce(
            v_object_label,
            (
                SELECT string_agg(so.name, ', ' ORDER BY so.name)
                FROM scope_objects so
                WHERE so.id::TEXT = ANY (coalesce(e.object_ids, '{}'::TEXT[]))
            ),
            '—'
        ) AS object_name,
        CASE
            WHEN ot.employee_id IS NOT NULL THEN 'in_shift'
            WHEN ct.employee_id IS NOT NULL OR mt.employee_id IS NOT NULL THEN 'finished'
            ELSE 'absent'
        END AS status,
        count(*) OVER ()::INT AS total_count
    FROM base_ids b
    JOIN public.employees e ON e.id = b.id
    LEFT JOIN open_today ot ON ot.employee_id = b.id
    LEFT JOIN closed_today ct ON ct.employee_id = b.id
    LEFT JOIN marked_today mt ON mt.employee_id = b.id
    ORDER BY
        CASE
            WHEN ot.employee_id IS NOT NULL THEN 0
            WHEN ct.employee_id IS NOT NULL OR mt.employee_id IS NOT NULL THEN 1
            ELSE 2
        END,
        employee_name
    LIMIT v_limit;
END;
$$;

COMMENT ON FUNCTION public.chat_shift_status_today(UUID, TEXT, INT) IS
    'Смены за сегодня для ГТ Чата: кто в открытой смене (in_shift), кто уже закрыл смену (finished) и кто не выходил (absent). Область — доступные объекты.';

-- ---------------------------------------------------------------------------
-- Доступ
-- ---------------------------------------------------------------------------
-- Служебная функция нужна только внутри chat_shift_status_today.
REVOKE ALL ON FUNCTION public.chat_visible_object_ids(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.chat_visible_object_ids(UUID) FROM anon;
REVOKE ALL ON FUNCTION public.chat_visible_object_ids(UUID) FROM authenticated;

REVOKE ALL ON FUNCTION public.chat_shift_status_today(UUID, TEXT, INT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.chat_shift_status_today(UUID, TEXT, INT) FROM anon;
GRANT EXECUTE ON FUNCTION public.chat_shift_status_today(UUID, TEXT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.chat_shift_status_today(UUID, TEXT, INT) TO service_role;

COMMIT;
