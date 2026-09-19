-- Модуль «ГТ Чат»: диалоги, участники и сообщения.
--
-- Пока в диалоге два собеседника: человек и ИИ. Схема сразу сделана как
-- настоящий чат (диалог + участники + сообщения), чтобы позже добавить
-- переписку между людьми без переделки таблиц.
--
-- Запись — только через функции (chat_thread_create, chat_message_add_user).
-- Сообщение ИИ пишет серверная функция gt_chat ключом service_role.
--
-- Права: чтение и запись — участнику диалога и только в своей компании.
-- Модуль `chat` получают все существующие роли; руководитель может снять
-- право в разделе «Управление ролями».

BEGIN;

-- ---------------------------------------------------------------------------
-- Диалоги
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chat_threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    kind TEXT NOT NULL DEFAULT 'ai',
    title TEXT,
    created_by UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_message_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chat_threads_kind_chk CHECK (kind IN ('ai', 'direct', 'group')),
    CONSTRAINT chat_threads_title_chk CHECK (title IS NULL OR btrim(title) <> '')
);

CREATE INDEX IF NOT EXISTS idx_chat_threads_company_created_by
    ON public.chat_threads (company_id, created_by, last_message_at DESC);

COMMENT ON TABLE public.chat_threads IS
    'Диалоги ГТ Чата. kind = ai — диалог с помощником, direct/group — переписка между людьми (на будущее).';

-- ---------------------------------------------------------------------------
-- Участники диалога
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chat_thread_members (
    thread_id UUID NOT NULL REFERENCES public.chat_threads(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_read_at TIMESTAMPTZ,
    PRIMARY KEY (thread_id, user_id),
    CONSTRAINT chat_thread_members_role_chk CHECK (role IN ('member', 'assistant'))
);

CREATE INDEX IF NOT EXISTS idx_chat_thread_members_user
    ON public.chat_thread_members (user_id, thread_id);

COMMENT ON TABLE public.chat_thread_members IS
    'Кто видит диалог. Сейчас в диалоге с ИИ один человек — автор.';

-- ---------------------------------------------------------------------------
-- Сообщения
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID NOT NULL REFERENCES public.chat_threads(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    author_kind TEXT NOT NULL,
    author_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    body TEXT NOT NULL CHECK (btrim(body) <> ''),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chat_messages_author_kind_chk CHECK (author_kind IN ('user', 'ai')),
    CONSTRAINT chat_messages_author_chk CHECK (
        (author_kind = 'user' AND author_user_id IS NOT NULL)
        OR (author_kind = 'ai' AND author_user_id IS NULL)
    )
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_thread_created
    ON public.chat_messages (thread_id, created_at);

COMMENT ON TABLE public.chat_messages IS
    'Сообщения диалога. author_kind = ai — ответ помощника, author_user_id пустой.';

-- ---------------------------------------------------------------------------
-- Доступ
-- ---------------------------------------------------------------------------
-- Участник диалога своей компании. Основа всех проверок ниже.
CREATE OR REPLACE FUNCTION public.chat_is_member(p_thread_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.chat_threads t
        JOIN public.chat_thread_members m
          ON m.thread_id = t.id
         AND m.user_id = auth.uid()
        WHERE t.id = p_thread_id
          AND t.company_id IN (SELECT public.get_my_company_ids())
    );
$$;

-- Имя автора для ленты сообщений: полное, при отсутствии — короткое.
CREATE OR REPLACE FUNCTION public.chat_author_name(p_user_id UUID)
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT coalesce(nullif(btrim(p.full_name), ''), p.short_name)
    FROM public.profiles p
    WHERE p.id = p_user_id;
$$;

ALTER TABLE public.chat_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_thread_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "chat_threads_select" ON public.chat_threads;
CREATE POLICY "chat_threads_select"
ON public.chat_threads FOR SELECT TO authenticated
USING (public.chat_is_member(id));

DROP POLICY IF EXISTS "chat_thread_members_select" ON public.chat_thread_members;
CREATE POLICY "chat_thread_members_select"
ON public.chat_thread_members FOR SELECT TO authenticated
USING (user_id = auth.uid() OR public.chat_is_member(thread_id));

DROP POLICY IF EXISTS "chat_messages_select" ON public.chat_messages;
CREATE POLICY "chat_messages_select"
ON public.chat_messages FOR SELECT TO authenticated
USING (public.chat_is_member(thread_id));

GRANT SELECT ON public.chat_threads TO authenticated;
GRANT SELECT ON public.chat_thread_members TO authenticated;
GRANT SELECT ON public.chat_messages TO authenticated;

REVOKE INSERT, UPDATE, DELETE ON public.chat_threads FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.chat_thread_members FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.chat_messages FROM authenticated;
REVOKE ALL ON public.chat_threads FROM anon;
REVOKE ALL ON public.chat_thread_members FROM anon;
REVOKE ALL ON public.chat_messages FROM anon;

-- Ответ помощника дописывает серверная функция gt_chat ключом service_role:
-- у человека права на запись в ленту нет.
GRANT SELECT, INSERT, UPDATE, DELETE ON public.chat_messages TO service_role;
GRANT SELECT, UPDATE ON public.chat_threads TO service_role;

-- ---------------------------------------------------------------------------
-- Диалог: создать, список, удалить
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.chat_thread_create(
    p_company_id UUID,
    p_title TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_thread_id UUID;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Нужно войти в аккаунт';
    END IF;

    IF p_company_id IS NULL
       OR p_company_id NOT IN (SELECT public.get_my_company_ids()) THEN
        RAISE EXCEPTION 'Нет доступа к компании';
    END IF;

    IF NOT public.check_permission(v_uid, 'chat', 'create') THEN
        RAISE EXCEPTION 'Нет права создавать диалоги';
    END IF;

    INSERT INTO public.chat_threads (company_id, kind, title, created_by)
    VALUES (p_company_id, 'ai', nullif(btrim(coalesce(p_title, '')), ''), v_uid)
    RETURNING id INTO v_thread_id;

    INSERT INTO public.chat_thread_members (thread_id, user_id, role)
    VALUES (v_thread_id, v_uid, 'member');

    RETURN v_thread_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.chat_thread_list(p_company_id UUID)
RETURNS TABLE (
    id UUID,
    title TEXT,
    kind TEXT,
    created_at TIMESTAMPTZ,
    last_message_at TIMESTAMPTZ,
    message_count INT,
    last_message_body TEXT,
    last_message_author_kind TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Нужно войти в аккаунт';
    END IF;

    IF p_company_id IS NULL
       OR p_company_id NOT IN (SELECT public.get_my_company_ids()) THEN
        RAISE EXCEPTION 'Нет доступа к компании';
    END IF;

    IF NOT public.check_permission(v_uid, 'chat', 'read') THEN
        RAISE EXCEPTION 'Нет права открывать чат';
    END IF;

    RETURN QUERY
    SELECT
        t.id,
        t.title,
        t.kind,
        t.created_at,
        t.last_message_at,
        (SELECT count(*)::INT FROM public.chat_messages m WHERE m.thread_id = t.id),
        last_message.body,
        last_message.author_kind
    FROM public.chat_threads t
    JOIN public.chat_thread_members mem
      ON mem.thread_id = t.id
     AND mem.user_id = v_uid
    LEFT JOIN LATERAL (
        SELECT m.body, m.author_kind
        FROM public.chat_messages m
        WHERE m.thread_id = t.id
        ORDER BY m.created_at DESC
        LIMIT 1
    ) AS last_message ON TRUE
    WHERE t.company_id = p_company_id
    ORDER BY t.last_message_at DESC
    LIMIT 100;
END;
$$;

CREATE OR REPLACE FUNCTION public.chat_thread_delete(p_thread_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Нужно войти в аккаунт';
    END IF;

    IF NOT public.chat_is_member(p_thread_id) THEN
        RAISE EXCEPTION 'Нет доступа к диалогу';
    END IF;

    DELETE FROM public.chat_threads WHERE id = p_thread_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Сообщения: лента и отправка человеком
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.chat_thread_messages(
    p_thread_id UUID,
    p_limit INT DEFAULT 200
)
RETURNS TABLE (
    id UUID,
    author_kind TEXT,
    author_user_id UUID,
    author_name TEXT,
    body TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_limit INT := least(greatest(coalesce(p_limit, 200), 1), 500);
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Нужно войти в аккаунт';
    END IF;

    IF NOT public.chat_is_member(p_thread_id) THEN
        RAISE EXCEPTION 'Нет доступа к диалогу';
    END IF;

    -- Возвращаем последние сообщения, но в прямом порядке: так лента
    -- прокручивается вниз и длинные диалоги не тормозят открытие.
    RETURN QUERY
    SELECT * FROM (
        SELECT
            m.id,
            m.author_kind,
            m.author_user_id,
            public.chat_author_name(m.author_user_id) AS author_name,
            m.body,
            m.created_at
        FROM public.chat_messages m
        WHERE m.thread_id = p_thread_id
        ORDER BY m.created_at DESC, m.id DESC
        LIMIT v_limit
    ) AS tail
    ORDER BY tail.created_at, tail.id;
END;
$$;

CREATE OR REPLACE FUNCTION public.chat_message_add_user(
    p_thread_id UUID,
    p_body TEXT
)
RETURNS TABLE (
    id UUID,
    author_kind TEXT,
    author_user_id UUID,
    author_name TEXT,
    body TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_company_id UUID;
    v_body TEXT := btrim(coalesce(p_body, ''));
    v_message_id UUID;
    v_created_at TIMESTAMPTZ;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Нужно войти в аккаунт';
    END IF;

    IF v_body = '' THEN
        RAISE EXCEPTION 'Пустое сообщение';
    END IF;

    IF length(v_body) > 4000 THEN
        RAISE EXCEPTION 'Сообщение длиннее 4000 символов';
    END IF;

    SELECT t.company_id INTO v_company_id
    FROM public.chat_threads t
    JOIN public.chat_thread_members m
      ON m.thread_id = t.id
     AND m.user_id = v_uid
    WHERE t.id = p_thread_id;

    IF v_company_id IS NULL THEN
        RAISE EXCEPTION 'Нет доступа к диалогу';
    END IF;

    IF NOT public.check_permission(v_uid, 'chat', 'create') THEN
        RAISE EXCEPTION 'Нет права писать в чат';
    END IF;

    INSERT INTO public.chat_messages (thread_id, company_id, author_kind, author_user_id, body)
    VALUES (p_thread_id, v_company_id, 'user', v_uid, v_body)
    RETURNING public.chat_messages.id, public.chat_messages.created_at
    INTO v_message_id, v_created_at;

    -- Первое сообщение задаёт название диалога; вручную заданное не трогаем.
    UPDATE public.chat_threads t
    SET last_message_at = v_created_at,
        title = coalesce(t.title, left(v_body, 60))
    WHERE t.id = p_thread_id;

    RETURN QUERY
    SELECT
        m.id,
        m.author_kind,
        m.author_user_id,
        public.chat_author_name(m.author_user_id) AS author_name,
        m.body,
        m.created_at
    FROM public.chat_messages m
    WHERE m.id = v_message_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.chat_is_member(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.chat_author_name(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.chat_thread_create(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.chat_thread_list(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.chat_thread_delete(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.chat_thread_messages(UUID, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.chat_message_add_user(UUID, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.chat_is_member(UUID) FROM anon;
REVOKE ALL ON FUNCTION public.chat_author_name(UUID) FROM anon;
REVOKE ALL ON FUNCTION public.chat_thread_create(UUID, TEXT) FROM anon;
REVOKE ALL ON FUNCTION public.chat_thread_list(UUID) FROM anon;
REVOKE ALL ON FUNCTION public.chat_thread_delete(UUID) FROM anon;
REVOKE ALL ON FUNCTION public.chat_thread_messages(UUID, INT) FROM anon;
REVOKE ALL ON FUNCTION public.chat_message_add_user(UUID, TEXT) FROM anon;

-- ---------------------------------------------------------------------------
-- Модуль прав «ГТ Чат»
-- ---------------------------------------------------------------------------
INSERT INTO public.app_modules (code, name, icon_key, sort_order, is_active)
VALUES ('chat', 'ГТ Чат', 'chat', 12, true)
ON CONFLICT (code) DO UPDATE
SET
    name = EXCLUDED.name,
    icon_key = EXCLUDED.icon_key,
    sort_order = EXCLUDED.sort_order,
    is_active = true;

-- Чат нужен всем: выдаём права всем ролям, чтобы у сотрудников раздел
-- не пропал. Снять право можно в «Управлении ролями».
-- Уникальность в role_permissions — (role_id, module_code, permission_code),
-- компания в проверке прав не участвует.
INSERT INTO public.role_permissions (role_id, company_id, module_code, permission_code, is_enabled)
SELECT
    r.id,
    r.company_id,
    'chat'::text,
    perm.permission_code,
    true
FROM public.roles r
CROSS JOIN (VALUES ('read'), ('create'), ('delete')) AS perm(permission_code)
ON CONFLICT (role_id, module_code, permission_code) DO NOTHING;

COMMIT;
