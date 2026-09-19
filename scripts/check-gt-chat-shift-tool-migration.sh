#!/usr/bin/env bash
# Проверка миграции «ГТ Чат: данные по сменам» на временной локальной базе Postgres.
# Создаёт заглушки окружения Supabase (auth.uid, companies, profiles, company_members,
# objects, employees, works, work_hours, employee_attendance, get_my_company_ids,
# check_permission, is_super_admin), прогоняет миграцию и проверяет,
# что помощник видит только разрешённые объекты и правильно считает статусы.
set -euo pipefail

export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
DATA="$WORK/pgdata"
SOCK="$WORK/sock"
PORT=55433
MIGRATION="$ROOT/supabase/migrations/20260919150000_gt_chat_shift_status_tool.sql"

mkdir -p "$SOCK"

cleanup() {
  pg_ctl -D "$DATA" stop -m immediate >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

initdb -D "$DATA" -U postgres --no-locale -E UTF8 >/dev/null
pg_ctl -D "$DATA" -o "-p $PORT -k $SOCK -c listen_addresses=''" -l "$WORK/pg.log" start >/dev/null
createdb -h "$SOCK" -p "$PORT" -U postgres progt_shift_check

psql -h "$SOCK" -p "$PORT" -U postgres -d progt_shift_check -v ON_ERROR_STOP=1 -q <<'SQL'
-- Заглушки окружения Supabase: только то, на что ссылается миграция.
CREATE SCHEMA auth;
CREATE ROLE anon;
CREATE ROLE authenticated;
CREATE ROLE service_role;

CREATE TABLE auth.ctx (uid uuid);
INSERT INTO auth.ctx (uid) VALUES (NULL);

CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$
    SELECT uid FROM auth.ctx LIMIT 1
$$;

CREATE TABLE public.companies (
    id uuid PRIMARY KEY,
    name_short text
);

CREATE TABLE public.profiles (
    id uuid PRIMARY KEY,
    object_ids uuid[]
);

CREATE TABLE public.company_members (
    company_id uuid NOT NULL,
    user_id uuid NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    is_owner boolean NOT NULL DEFAULT false,
    system_role text
);

CREATE TABLE public.objects (
    id uuid PRIMARY KEY,
    company_id uuid NOT NULL,
    name text NOT NULL
);

CREATE TABLE public.employees (
    id uuid PRIMARY KEY,
    company_id uuid NOT NULL,
    last_name text,
    first_name text,
    middle_name text,
    position text,
    status text,
    object_ids text[]
);

CREATE TABLE public.works (
    id uuid PRIMARY KEY,
    company_id uuid NOT NULL,
    date date NOT NULL,
    object_id uuid,
    status text NOT NULL
);

CREATE TABLE public.work_hours (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    work_id uuid NOT NULL,
    employee_id uuid NOT NULL
);

CREATE TABLE public.employee_attendance (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    object_id uuid,
    date date NOT NULL,
    hours numeric
);

-- Права и супер-админ: в тесте управляются таблицами.
CREATE TABLE public.test_permissions (module_code text, permission_code text);
CREATE TABLE public.test_super_admins (user_id uuid);

CREATE FUNCTION public.check_permission(p_user_id uuid, p_module text, p_action text)
RETURNS boolean LANGUAGE sql STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.test_permissions t
        WHERE t.module_code = p_module AND t.permission_code = p_action
    )
$$;

CREATE FUNCTION public.is_super_admin(p_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE AS $$
    SELECT EXISTS (SELECT 1 FROM public.test_super_admins s WHERE s.user_id = p_user_id)
$$;

-- Как на сервере: таблица с колонкой company_id.
CREATE FUNCTION public.get_my_company_ids() RETURNS TABLE (company_id uuid)
LANGUAGE sql STABLE AS $$
    SELECT cm.company_id FROM public.company_members cm
    WHERE cm.user_id = auth.uid() AND cm.is_active = true
$$;

-- Данные: две компании, владелец и линейный сотрудник.
INSERT INTO public.companies (id, name_short) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Своя'),
    ('99999999-9999-9999-9999-999999999999', 'Чужая');

INSERT INTO public.profiles (id, object_ids) VALUES
    ('22222222-2222-2222-2222-222222222222', NULL),                      -- владелец
    ('44444444-4444-4444-4444-444444444444', '{aaaaaaaa-0000-0000-0000-000000000001}'::uuid[]); -- линейный

INSERT INTO public.company_members (company_id, user_id, is_active, is_owner) VALUES
    ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', true, true),
    ('11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', true, false);

INSERT INTO public.objects (id, company_id, name) VALUES
    ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'ЦОД Салтыковка'),
    ('aaaaaaaa-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'ЦОД Дубна ФНС'),
    ('aaaaaaaa-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'Склад Мытищи'),
    ('bbbbbbbb-0000-0000-0000-000000000001', '99999999-9999-9999-9999-999999999999', 'Чужой объект');

INSERT INTO public.employees (id, company_id, last_name, first_name, position, status, object_ids) VALUES
    ('e0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Иванов', 'Иван', 'Монтажник', 'working', '{aaaaaaaa-0000-0000-0000-000000000001}'),
    ('e0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Петров', 'Пётр', 'Сварщик', 'working', '{aaaaaaaa-0000-0000-0000-000000000001}'),
    ('e0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'Сидоров', 'Семён', 'Монтажник', 'working', '{aaaaaaaa-0000-0000-0000-000000000002}'),
    ('e0000000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'Безобъектов', 'Борис', 'Разнорабочий', 'working', '{}'),
    ('e0000000-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111', 'Уволенный', 'Ульяна', 'Монтажник', 'fired', '{aaaaaaaa-0000-0000-0000-000000000001}'),
    ('e0000000-0000-0000-0000-000000000006', '11111111-1111-1111-1111-111111111111', 'Складов', 'Степан', 'Кладовщик', 'working', '{aaaaaaaa-0000-0000-0000-000000000003}'),
    ('e0000000-0000-0000-0000-000000000007', '11111111-1111-1111-1111-111111111111', 'Невышедший', 'Николай', 'Монтажник', 'working', '{aaaaaaaa-0000-0000-0000-000000000001}');

-- Сегодня: открытая смена (Иванов), закрытая смена (Петров), смена на другом объекте (Сидоров),
-- ручная отметка (Складов). Невышедший — без отметок.
INSERT INTO public.works (id, company_id, date, object_id, status) VALUES
    ('c0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', (now() AT TIME ZONE 'Europe/Moscow')::date, 'aaaaaaaa-0000-0000-0000-000000000001', 'open'),
    ('c0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', (now() AT TIME ZONE 'Europe/Moscow')::date, 'aaaaaaaa-0000-0000-0000-000000000001', 'closed'),
    ('c0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', (now() AT TIME ZONE 'Europe/Moscow')::date, 'aaaaaaaa-0000-0000-0000-000000000002', 'open');

INSERT INTO public.work_hours (work_id, employee_id) VALUES
    ('c0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001'),
    ('c0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000002'),
    ('c0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000003');

INSERT INTO public.employee_attendance (company_id, employee_id, object_id, date, hours) VALUES
    ('11111111-1111-1111-1111-111111111111', 'e0000000-0000-0000-0000-000000000006', 'aaaaaaaa-0000-0000-0000-000000000003', (now() AT TIME ZONE 'Europe/Moscow')::date, 8);

INSERT INTO public.test_permissions (module_code, permission_code) VALUES ('chat', 'read'), ('timesheet', 'read');
SQL

echo "== Миграция =="
psql -h "$SOCK" -p "$PORT" -U postgres -d progt_shift_check -v ON_ERROR_STOP=1 -q -f "$MIGRATION"
echo "миграция применена без ошибок"

echo "== Проверка работы функции =="
psql -h "$SOCK" -p "$PORT" -U postgres -d progt_shift_check -v ON_ERROR_STOP=1 <<'SQL'
CREATE OR REPLACE FUNCTION set_user(p_uid uuid) RETURNS void LANGUAGE sql AS $$
    UPDATE auth.ctx SET uid = p_uid
$$;

-- Краткая сводка: «статус: имена».
CREATE OR REPLACE FUNCTION summary(p_company uuid, p_object text)
RETURNS text LANGUAGE sql AS $$
    SELECT string_agg(r.status || ': ' || r.employee_name, ' | ' ORDER BY r.status, r.employee_name)
    FROM public.chat_shift_status_today(p_company, p_object) r
$$;

DO $$
DECLARE
    v_summary text;
    v_total int;
    v_rows int;
BEGIN
    -- 1. Владелец: вся компания.
    PERFORM set_user('22222222-2222-2222-2222-222222222222');
    v_summary := summary('11111111-1111-1111-1111-111111111111', NULL);
    RAISE NOTICE 'вся компания: %', v_summary;
    IF v_summary NOT LIKE '%in_shift: Иванов Иван%' THEN
        RAISE EXCEPTION 'Иванов (открытая смена) не попал в in_shift: %', v_summary;
    END IF;
    IF v_summary NOT LIKE '%finished: Петров Пётр%' THEN
        RAISE EXCEPTION 'Петров (закрытая смена) не попал в finished: %', v_summary;
    END IF;
    IF v_summary NOT LIKE '%finished: Складов Степан%' THEN
        RAISE EXCEPTION 'Складов (ручная отметка) не попал в finished: %', v_summary;
    END IF;
    IF v_summary NOT LIKE '%absent: Невышедший Николай%' THEN
        RAISE EXCEPTION 'Невышедший не попал в absent: %', v_summary;
    END IF;
    IF position('Уволенный' in v_summary) > 0 THEN
        RAISE EXCEPTION 'уволенный попал в список: %', v_summary;
    END IF;
    IF position('Безобъектов' in v_summary) > 0 THEN
        RAISE EXCEPTION 'сотрудник без объектов попал в список: %', v_summary;
    END IF;
    IF position('Сидоров' in v_summary) = 0 THEN
        RAISE EXCEPTION 'Сидоров (смена на другом объекте) пропал: %', v_summary;
    END IF;

    SELECT count(*), max(total_count) INTO v_rows, v_total
    FROM public.chat_shift_status_today('11111111-1111-1111-1111-111111111111', NULL);
    IF v_total <> v_rows THEN
        RAISE EXCEPTION 'total_count (%) не совпал с числом строк (%)', v_total, v_rows;
    END IF;
    RAISE NOTICE 'проверено сотрудников по компании: %', v_rows;

    -- 2. Владелец: один объект (точное название).
    v_summary := summary('11111111-1111-1111-1111-111111111111', 'ЦОД Салтыковка');
    RAISE NOTICE 'ЦОД Салтыковка: %', v_summary;
    IF v_summary <> 'absent: Невышедший Николай | finished: Петров Пётр | in_shift: Иванов Иван' THEN
        RAISE EXCEPTION 'неожиданный состав по объекту: %', v_summary;
    END IF;

    -- 3. Поиск по части названия.
    v_summary := summary('11111111-1111-1111-1111-111111111111', 'Дубна');
    IF v_summary <> 'in_shift: Сидоров Семён' THEN
        RAISE EXCEPTION 'поиск по части названия не сработал: %', v_summary;
    END IF;
    RAISE NOTICE 'поиск по части названия работает';

    -- 4. Линейный сотрудник: видит только свой объект.
    PERFORM set_user('44444444-4444-4444-4444-444444444444');
    v_summary := summary('11111111-1111-1111-1111-111111111111', NULL);
    RAISE NOTICE 'линейный, вся компания: %', v_summary;
    IF v_summary <> 'absent: Невышедший Николай | finished: Петров Пётр | in_shift: Иванов Иван' THEN
        RAISE EXCEPTION 'линейный видит лишнее: %', v_summary;
    END IF;
    IF position('Сидоров' in v_summary) > 0 THEN
        RAISE EXCEPTION 'линейный увидел чужой объект: %', v_summary;
    END IF;

    -- 5. Линейный просит чужой объект — не найден.
    BEGIN
        PERFORM summary('11111111-1111-1111-1111-111111111111', 'Дубна');
        RAISE EXCEPTION 'чужой объект оказался доступен линейному';
    EXCEPTION WHEN OTHERS THEN
        IF position('не найден' in SQLERRM) = 0 THEN RAISE; END IF;
        RAISE NOTICE 'чужой объект для линейного закрыт';
    END;

    -- 6. Чужая компания — нет доступа.
    PERFORM set_user('22222222-2222-2222-2222-222222222222');
    BEGIN
        PERFORM summary('99999999-9999-9999-9999-999999999999', NULL);
        RAISE EXCEPTION 'чужая компания оказалась доступна';
    EXCEPTION WHEN OTHERS THEN
        IF position('Нет доступа к компании' in SQLERRM) = 0 THEN RAISE; END IF;
        RAISE NOTICE 'чужая компания закрыта';
    END;

    -- 7. Неизвестный объект — понятная ошибка со списком.
    BEGIN
        PERFORM summary('11111111-1111-1111-1111-111111111111', 'Космодром');
        RAISE EXCEPTION 'неизвестный объект приняли';
    EXCEPTION WHEN OTHERS THEN
        IF position('не найден' in SQLERRM) = 0 THEN RAISE; END IF;
        IF position('ЦОД Салтыковка' in SQLERRM) = 0 THEN RAISE; END IF;
        RAISE NOTICE 'неизвестный объект: %', SQLERRM;
    END;

    -- 8. Неоднозначное название — просим уточнить.
    BEGIN
        PERFORM summary('11111111-1111-1111-1111-111111111111', 'ЦОД');
        RAISE EXCEPTION 'неоднозначное название приняли';
    EXCEPTION WHEN OTHERS THEN
        IF position('подходит несколько объектов' in SQLERRM) = 0 THEN RAISE; END IF;
        RAISE NOTICE 'неоднозначное название: %', SQLERRM;
    END;

    -- 9. Нет права смотреть табель — отказано.
    DELETE FROM public.test_permissions WHERE module_code = 'timesheet';
    BEGIN
        PERFORM summary('11111111-1111-1111-1111-111111111111', NULL);
        RAISE EXCEPTION 'данные отдали без права на табель';
    EXCEPTION WHEN OTHERS THEN
        IF position('Нет права смотреть табель' in SQLERRM) = 0 THEN RAISE; END IF;
        RAISE NOTICE 'без права на табель доступ закрыт';
    END;
    INSERT INTO public.test_permissions (module_code, permission_code) VALUES ('timesheet', 'read');

    -- 10. Нет права на чат — отказано.
    DELETE FROM public.test_permissions WHERE module_code = 'chat';
    BEGIN
        PERFORM summary('11111111-1111-1111-1111-111111111111', NULL);
        RAISE EXCEPTION 'данные отдали без права на чат';
    EXCEPTION WHEN OTHERS THEN
        IF position('Нет права открывать чат' in SQLERRM) = 0 THEN RAISE; END IF;
        RAISE NOTICE 'без права на чат доступ закрыт';
    END;
    INSERT INTO public.test_permissions (module_code, permission_code) VALUES ('chat', 'read');

    -- 11. Ограничение размера списка.
    PERFORM set_user('22222222-2222-2222-2222-222222222222');
    SELECT count(*) INTO v_rows FROM public.chat_shift_status_today('11111111-1111-1111-1111-111111111111', NULL, 2);
    IF v_rows <> 2 THEN
        RAISE EXCEPTION 'ограничение p_limit не сработало: строк %', v_rows;
    END IF;
    SELECT max(total_count) INTO v_total FROM public.chat_shift_status_today('11111111-1111-1111-1111-111111111111', NULL, 2);
    IF v_total <= 2 THEN
        RAISE EXCEPTION 'total_count не показал полное число: %', v_total;
    END IF;
    RAISE NOTICE 'ограничение списка работает: показано %, всего %', v_rows, v_total;

    RAISE NOTICE 'все проверки пройдены';
END;
$$;
SQL

echo "== Готово: ошибок нет =="
