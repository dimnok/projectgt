-- Миграция для добавления политик доступа к фотографиям сотрудников в хранилище Supabase

-- Обновление политики загрузки аватаров для фотографий сотрудников
-- Разрешаем пользователям с ролью admin загружать фотографии в папку employees
CREATE POLICY "Upload employee avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' 
  AND (storage.foldername(name))[1] = 'employees'
  AND auth.role() = 'authenticated' 
  AND (
    -- Проверяем, что пользователь имеет роль admin
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  )
);

-- Политика для обновления фотографий сотрудников
CREATE POLICY "Update employee avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' 
  AND (storage.foldername(name))[1] = 'employees'
  AND auth.role() = 'authenticated' 
  AND (
    -- Проверяем, что пользователь имеет роль admin
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  )
);

-- Политика для удаления фотографий сотрудников
CREATE POLICY "Delete employee avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' 
  AND (storage.foldername(name))[1] = 'employees'
  AND auth.role() = 'authenticated' 
  AND (
    -- Проверяем, что пользователь имеет роль admin
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  )
);

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