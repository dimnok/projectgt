-- Bucket файлов модуля ТМЦ.
INSERT INTO storage.buckets (id, name, public)
SELECT 'tmc', 'tmc', false
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'tmc');

DROP POLICY IF EXISTS "tmc_bucket_select" ON storage.objects;
DROP POLICY IF EXISTS "tmc_bucket_insert" ON storage.objects;
DROP POLICY IF EXISTS "tmc_bucket_update" ON storage.objects;
DROP POLICY IF EXISTS "tmc_bucket_delete" ON storage.objects;

CREATE POLICY "tmc_bucket_select"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'tmc' AND public.check_permission(auth.uid(), 'tmc', 'read'));

CREATE POLICY "tmc_bucket_insert"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'tmc'
  AND (
    public.check_permission(auth.uid(), 'tmc', 'create')
    OR public.check_permission(auth.uid(), 'tmc', 'update')
  )
);

CREATE POLICY "tmc_bucket_update"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'tmc' AND public.check_permission(auth.uid(), 'tmc', 'update'))
WITH CHECK (bucket_id = 'tmc' AND public.check_permission(auth.uid(), 'tmc', 'update'));

CREATE POLICY "tmc_bucket_delete"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'tmc' AND public.check_permission(auth.uid(), 'tmc', 'delete'));
