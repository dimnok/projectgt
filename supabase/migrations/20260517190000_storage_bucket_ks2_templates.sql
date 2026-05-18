-- Bucket `ks2_templates` в Storage: шаблоны унифицированных форм КС-2 (и при необходимости
-- сопутствующие файлы). Заполнение через Edge Functions (service_role); пользователям —
-- чтение при праве на договоры, запись шаблонов — при праве update по модулю contracts.

INSERT INTO storage.buckets (id, name, public)
SELECT 'ks2_templates', 'ks2_templates', false
WHERE NOT EXISTS (
  SELECT 1 FROM storage.buckets WHERE id = 'ks2_templates'
);

DROP POLICY IF EXISTS "ks2_templates_bucket_select" ON storage.objects;
DROP POLICY IF EXISTS "ks2_templates_bucket_insert" ON storage.objects;
DROP POLICY IF EXISTS "ks2_templates_bucket_update" ON storage.objects;
DROP POLICY IF EXISTS "ks2_templates_bucket_delete" ON storage.objects;

CREATE POLICY "ks2_templates_bucket_select"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'ks2_templates'
  AND public.check_permission(auth.uid(), 'contracts', 'read')
);

CREATE POLICY "ks2_templates_bucket_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'ks2_templates'
  AND public.check_permission(auth.uid(), 'contracts', 'update')
);

CREATE POLICY "ks2_templates_bucket_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'ks2_templates'
  AND public.check_permission(auth.uid(), 'contracts', 'update')
)
WITH CHECK (
  bucket_id = 'ks2_templates'
  AND public.check_permission(auth.uid(), 'contracts', 'update')
);

CREATE POLICY "ks2_templates_bucket_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'ks2_templates'
  AND public.check_permission(auth.uid(), 'contracts', 'update')
);
