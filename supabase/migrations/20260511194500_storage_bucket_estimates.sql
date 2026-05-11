-- Bucket `estimates` в Storage: исходные Excel ДС (`addendums/...`),
-- импорт сметы и удаление файлов ревизий (см. estimate_data_source).

INSERT INTO storage.buckets (id, name, public)
SELECT 'estimates', 'estimates', false
WHERE NOT EXISTS (
  SELECT 1 FROM storage.buckets WHERE id = 'estimates'
);

DROP POLICY IF EXISTS "estimates_bucket_select" ON storage.objects;
DROP POLICY IF EXISTS "estimates_bucket_insert" ON storage.objects;
DROP POLICY IF EXISTS "estimates_bucket_update" ON storage.objects;
DROP POLICY IF EXISTS "estimates_bucket_delete" ON storage.objects;

CREATE POLICY "estimates_bucket_select"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'estimates'
  AND public.check_permission(auth.uid(), 'estimates', 'read')
);

CREATE POLICY "estimates_bucket_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'estimates'
  AND (
    public.check_permission(auth.uid(), 'estimates', 'create')
    OR public.check_permission(auth.uid(), 'estimates', 'import')
  )
);

CREATE POLICY "estimates_bucket_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'estimates'
  AND public.check_permission(auth.uid(), 'estimates', 'update')
)
WITH CHECK (
  bucket_id = 'estimates'
  AND public.check_permission(auth.uid(), 'estimates', 'update')
);

CREATE POLICY "estimates_bucket_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'estimates'
  AND public.check_permission(auth.uid(), 'estimates', 'delete')
);
