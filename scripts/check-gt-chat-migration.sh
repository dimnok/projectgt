#!/usr/bin/env bash
# Проверка миграции ГТ Чата на временной локальной базе Postgres.
# Создаёт заглушки окружения Supabase (auth.users, companies, profiles,
# app_modules, role_permissions, get_my_company_ids, check_permission),
# прогоняет миграцию и пробует основные функции чата.
set -euo pipefail

export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
DATA="$WORK/pgdata"
SOCK="$WORK/sock"
PORT=55432
MIGRATION="$ROOT/supabase/migrations/20260918120000_create_gt_chat_module.sql"

mkdir -p "$SOCK"

cleanup() {
  pg_ctl -D "$DATA" stop -m immediate >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

initdb -D "$DATA" -U postgres --no-locale -E UTF8 >/dev/null
pg_ctl -D "$DATA" -o "-p $PORT -k $SOCK -c listen_addresses=''" -l "$WORK/pg.log" start >/dev/null
createdb -h "$SOCK" -p "$PORT" -U postgres progt_check

psql -h "$SOCK" -p "$PORT" -U postgres -d progt_check -v ON_ERROR_STOP=1 -q <<'SQL'
-- Заглушки окружения Supabase: только то, на что ссылается миграция.
CREATE SCHEMA auth;
CREATE ROLE anon;
CREATE ROLE authenticated;
CREATE ROLE service_role;

CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$ SELECT NULL::uuid $$;

CREATE TABLE auth.users (id uuid PRIMARY KEY DEFAULT gen_random_uuid());

CREATE TABLE public.companies (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name_short text,
    name_full text
);

CREATE TABLE public.profiles (
    id uuid PRIMARY KEY REFERENCES auth.users(id),
    full_name text,
    short_name text,
    last_company_id uuid
);

CREATE TABLE public.app_modules (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code text UNIQUE,
    name text,
    icon_key text,
    sort_order int,
    is_active boolean DEFAULT true
);

CREATE TABLE public.role_permissions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id uuid NOT NULL,
    company_id uuid,
    module_code text NOT NULL,
    permission_code text NOT NULL,
    is_enabled boolean
);

-- Как на сервере: уникальность без компании.
CREATE UNIQUE INDEX role_permissions_unique_key
    ON public.role_permissions (role_id, module_code, permission_code);

CREATE TABLE public.roles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name text NOT NULL,
    company_id uuid
);

CREATE FUNCTION public.get_my_company_ids() RETURNS SETOF uuid LANGUAGE sql STABLE AS $$
    SELECT id FROM public.companies
$$;

CREATE FUNCTION public.check_permission(p_user_id uuid, p_module text, p_action text)
RETURNS boolean LANGUAGE sql STABLE AS $$ SELECT true $$;

-- Данные: компания, человек, роль с правами.
INSERT INTO public.companies (id, name_short) VALUES ('11111111-1111-1111-1111-111111111111', 'Тест');
INSERT INTO auth.users (id) VALUES ('22222222-2222-2222-2222-222222222222');
INSERT INTO auth.users (id) VALUES ('44444444-4444-4444-4444-444444444444');
INSERT INTO public.profiles (id, full_name, last_company_id)
VALUES ('22222222-2222-2222-2222-222222222222', 'Иван Тестов', '11111111-1111-1111-1111-111111111111');
INSERT INTO public.role_permissions (role_id, company_id, module_code, permission_code, is_enabled)
VALUES ('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'works', 'read', true);
INSERT INTO public.roles (id, role_name, company_id)
VALUES ('33333333-3333-3333-3333-333333333333', 'Прораб', '11111111-1111-1111-1111-111111111111');
INSERT INTO public.roles (id, role_name, company_id)
VALUES ('55555555-5555-5555-5555-555555555555', 'Кладовщик', '11111111-1111-1111-1111-111111111111');
-- Роль уже с правами на чат: повторная выдача не должна падать.
INSERT INTO public.role_permissions (role_id, company_id, module_code, permission_code, is_enabled)
VALUES ('55555555-5555-5555-5555-555555555555', '11111111-1111-1111-1111-111111111111', 'chat', 'read', true);
SQL

echo "== Миграция =="
psql -h "$SOCK" -p "$PORT" -U postgres -d progt_check -v ON_ERROR_STOP=1 -q -f "$MIGRATION"
echo "миграция применена без ошибок"

echo "== Проверка работы функций =="
psql -h "$SOCK" -p "$PORT" -U postgres -d progt_check -v ON_ERROR_STOP=1 <<'SQL'
-- Работаем от имени пользователя: подменяем auth.uid().
CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$
    SELECT '22222222-2222-2222-2222-222222222222'::uuid
$$;

DO $$
DECLARE
    v_thread uuid;
    v_msg record;
    v_list record;
    v_msgs int;
BEGIN
    v_thread := public.chat_thread_create('11111111-1111-1111-1111-111111111111');
    RAISE NOTICE 'диалог создан: %', v_thread;

    SELECT * INTO v_msg FROM public.chat_message_add_user(v_thread, 'Привет, помоги с табелем');
    RAISE NOTICE 'сообщение: % / % / %', v_msg.author_kind, v_msg.author_name, left(v_msg.body, 20);

    SELECT * INTO v_list FROM public.chat_thread_list('11111111-1111-1111-1111-111111111111');
    RAISE NOTICE 'список: название «%», сообщений %, последнее от %',
        v_list.title, v_list.message_count, v_list.last_message_author_kind;

    SELECT count(*) INTO v_msgs FROM public.chat_thread_messages(v_thread, 200);
    RAISE NOTICE 'сообщений в ленте: %', v_msgs;

    IF NOT public.chat_is_member(v_thread) THEN
        RAISE EXCEPTION 'chat_is_member вернул false для своего диалога';
    END IF;

    -- Ответ помощника пишется ключом service_role, минуя RLS.
    INSERT INTO public.chat_messages (thread_id, company_id, author_kind, body)
    VALUES (v_thread, '11111111-1111-1111-1111-111111111111', 'ai', 'Здравствуйте!');

    SELECT count(*) INTO v_msgs FROM public.chat_thread_messages(v_thread, 200);
    IF v_msgs <> 2 THEN
        RAISE EXCEPTION 'в ленте ожидалось 2 сообщения, получено %', v_msgs;
    END IF;

    -- Пустое сообщение отклоняется.
    BEGIN
        PERFORM public.chat_message_add_user(v_thread, '   ');
        RAISE EXCEPTION 'пустое сообщение приняли';
    EXCEPTION WHEN OTHERS THEN
        IF position('Пустое сообщение' in SQLERRM) = 0 THEN RAISE; END IF;
        RAISE NOTICE 'пустое сообщение отклонено';
    END;
END;
$$;

-- Другой человек в диалог не попадает: чужие данные закрыты.
CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$
    SELECT '44444444-4444-4444-4444-444444444444'::uuid
$$;

DO $$
DECLARE
    v_thread uuid;
BEGIN
    SELECT id INTO v_thread FROM public.chat_threads LIMIT 1;

    BEGIN
        PERFORM public.chat_thread_messages(v_thread, 200);
        RAISE EXCEPTION 'чужой диалог оказался доступен';
    EXCEPTION WHEN OTHERS THEN
        IF position('Нет доступа к диалогу' in SQLERRM) = 0 THEN RAISE; END IF;
        RAISE NOTICE 'чужой диалог закрыт';
    END;
END;
$$;

-- Удаление диалога автором: сообщения уходят вместе с ним.
CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$
    SELECT '22222222-2222-2222-2222-222222222222'::uuid
$$;

DO $$
DECLARE
    v_thread uuid;
    v_msgs int;
BEGIN
    SELECT id INTO v_thread FROM public.chat_threads LIMIT 1;
    PERFORM public.chat_thread_delete(v_thread);
    SELECT count(*) INTO v_msgs FROM public.chat_messages WHERE thread_id = v_thread;
    IF v_msgs <> 0 THEN
        RAISE EXCEPTION 'после удаления диалога остались сообщения: %', v_msgs;
    END IF;
    RAISE NOTICE 'диалог удалён вместе с сообщениями';
END;
$$;

SELECT count(*) AS prav_na_chat FROM public.role_permissions WHERE module_code = 'chat';
SELECT code, name FROM public.app_modules WHERE code = 'chat';
SQL

echo "== Готово: ошибок нет =="
