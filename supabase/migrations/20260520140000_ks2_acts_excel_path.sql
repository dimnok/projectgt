-- Путь к сгенерированному Excel акта КС-2 в Storage (bucket ks2_documents).
ALTER TABLE public.ks2_acts
  ADD COLUMN IF NOT EXISTS excel_path TEXT;

COMMENT ON COLUMN public.ks2_acts.excel_path IS
  'Путь к файлу формы КС-2 (.xlsx) в Storage (bucket ks2_documents).';

INSERT INTO storage.buckets (id, name, public)
SELECT 'ks2_documents', 'ks2_documents', false
WHERE NOT EXISTS (
  SELECT 1 FROM storage.buckets WHERE id = 'ks2_documents'
);

DROP POLICY IF EXISTS "Authenticated users can read KS2 documents" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload KS2 documents" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete KS2 documents" ON storage.objects;

CREATE POLICY "Authenticated users can read KS2 documents"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'ks2_documents');

CREATE POLICY "Authenticated users can upload KS2 documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'ks2_documents');

CREATE POLICY "Authenticated users can delete KS2 documents"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'ks2_documents');
