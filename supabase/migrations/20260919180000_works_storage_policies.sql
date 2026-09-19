-- Хранилище «works»: сузить права на загрузку и удаление фото смен.
--
-- Было: несколько политик разрешали любому авторизованному пользователю
-- загружать и удалять любые фото в bucket `works` (без привязки к компании
-- и без проверки прав).
--
-- Стало: работаем только с объектами своей компании и только с правом
-- «работы» (изменение или удаление). Путь фото смены:
--   {object_id}/{DD-MM-YYYY}/{дата_время}_{morning|evening}.jpg

BEGIN;

DROP POLICY IF EXISTS "Delete objects from works bucket" ON storage.objects;
DROP POLICY IF EXISTS "works_delete" ON storage.objects;
DROP POLICY IF EXISTS "works_bucket_delete" ON storage.objects;
DROP POLICY IF EXISTS "Upload objects to works bucket" ON storage.objects;
DROP POLICY IF EXISTS "works_insert" ON storage.objects;
DROP POLICY IF EXISTS "works_bucket_insert" ON storage.objects;
DROP POLICY IF EXISTS "Update objects in works bucket" ON storage.objects;
DROP POLICY IF EXISTS "works_update" ON storage.objects;
DROP POLICY IF EXISTS "works_bucket_update" ON storage.objects;

CREATE POLICY "works_bucket_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'works'
    AND (storage.foldername(name))[1] IN (
        SELECT o.id::text
        FROM public.objects o
        WHERE o.company_id IN (SELECT public.get_my_company_ids())
    )
    AND (
        public.check_permission(auth.uid(), 'works', 'create')
        OR public.check_permission(auth.uid(), 'works', 'update')
    )
);

CREATE POLICY "works_bucket_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'works'
    AND (storage.foldername(name))[1] IN (
        SELECT o.id::text
        FROM public.objects o
        WHERE o.company_id IN (SELECT public.get_my_company_ids())
    )
    AND public.check_permission(auth.uid(), 'works', 'update')
)
WITH CHECK (
    bucket_id = 'works'
    AND (storage.foldername(name))[1] IN (
        SELECT o.id::text
        FROM public.objects o
        WHERE o.company_id IN (SELECT public.get_my_company_ids())
    )
    AND public.check_permission(auth.uid(), 'works', 'update')
);

CREATE POLICY "works_bucket_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'works'
    AND (storage.foldername(name))[1] IN (
        SELECT o.id::text
        FROM public.objects o
        WHERE o.company_id IN (SELECT public.get_my_company_ids())
    )
    AND (
        public.check_permission(auth.uid(), 'works', 'update')
        OR public.check_permission(auth.uid(), 'works', 'delete')
    )
);

COMMIT;
