-- Исправленная миграция для добавления колонки excel_url в таблицу vors
-- Дата: 2026-02-01

-- 1. Добавляем колонку в ПРАВИЛЬНУЮ таблицу vors
ALTER TABLE public.vors 
ADD COLUMN IF NOT EXISTS excel_url TEXT;

-- 2. Создаем бакет для документов ВОР, если он не существует
INSERT INTO storage.buckets (id, name, public)
SELECT 'vor_documents', 'vor_documents', false
WHERE NOT EXISTS (
    SELECT 1 FROM storage.buckets WHERE id = 'vor_documents'
);

-- 3. Настраиваем политики доступа (RLS) для бакета vor_documents

-- Удаляем старые политики, если они были созданы по ошибке (для чистоты)
DROP POLICY IF EXISTS "Authenticated users can read VOR documents" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload VOR documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own VOR documents" ON storage.objects;

-- Создаем заново
CREATE POLICY "Authenticated users can read VOR documents"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'vor_documents');

CREATE POLICY "Authenticated users can upload VOR documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'vor_documents');

CREATE POLICY "Users can delete their own VOR documents"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'vor_documents');

COMMENT ON COLUMN public.vors.excel_url IS 'Путь к сгенерированному Excel-файлу в Storage';
