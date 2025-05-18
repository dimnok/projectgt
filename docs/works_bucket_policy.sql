-- Политики для работы с фотографиями смен/работ (works bucket)
-- Политика для загрузки фотографий смен/работ
CREATE POLICY "Upload work photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'works' 
  AND auth.role() = 'authenticated'
);

-- Политика для обновления фотографий смен/работ
CREATE POLICY "Update work photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'works' 
  AND auth.role() = 'authenticated'
);

-- Политика для удаления фотографий смен/работ
CREATE POLICY "Delete work photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'works' 
  AND auth.role() = 'authenticated'
);

-- Политика для чтения фотографий смен/работ
CREATE POLICY "Read work photos"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'works' 
  AND auth.role() = 'authenticated'
); 