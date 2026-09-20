-- Взаиморасчёты: автора записи проставляет база.
--
-- Было: веб отдельно спрашивал пользователя у сервиса авторизации — это лишний
-- сетевой запрос на каждую оплату и каждый загруженный файл, — и присылал
-- created_by сам. У счетов created_by при этом не заполнялся вовсе.
-- Стало: значение по умолчанию auth.uid(). Автор всегда настоящий (взят из
-- проверенного токена запроса), а клиенту не нужно ни спрашивать пользователя,
-- ни присылать его идентификатор.

BEGIN;

ALTER TABLE public.settlement_operations
    ALTER COLUMN created_by SET DEFAULT auth.uid();

ALTER TABLE public.settlement_payments
    ALTER COLUMN created_by SET DEFAULT auth.uid();

ALTER TABLE public.settlement_files
    ALTER COLUMN created_by SET DEFAULT auth.uid();

COMMENT ON COLUMN public.settlement_operations.created_by IS
    'Автор записи. Проставляется базой: auth.uid() запроса.';
COMMENT ON COLUMN public.settlement_payments.created_by IS
    'Автор записи. Проставляется базой: auth.uid() запроса.';
COMMENT ON COLUMN public.settlement_files.created_by IS
    'Автор записи. Проставляется базой: auth.uid() запроса.';

COMMIT;
