-- Миграция: Проставить file_url для материалов, которые уже загружены в Storage
-- Дата: 2025-10-15

DO $$
DECLARE
  mat RECORD;
  storage_path TEXT;
  year_month TEXT;
  sanitized_contract TEXT;
  sanitized_receipt TEXT;
  updated_count INT := 0;
BEGIN
  -- Проходим по всем материалам без file_url
  FOR mat IN 
    SELECT DISTINCT 
      receipt_number, 
      receipt_date, 
      contract_number
    FROM materials
    WHERE file_url IS NULL
      AND receipt_number IS NOT NULL
      AND receipt_date IS NOT NULL
      AND contract_number IS NOT NULL
  LOOP
    -- Формируем год-месяц
    year_month := TO_CHAR(mat.receipt_date, 'YYYY-MM');
    
    -- Санитизируем contract_number (заменяем не-латиницу/цифры на _)
    sanitized_contract := REGEXP_REPLACE(mat.contract_number, '[^A-Za-z0-9._-]+', '_', 'g');
    
    -- Санитизируем receipt_number
    sanitized_receipt := REGEXP_REPLACE(mat.receipt_number, '[^A-Za-z0-9._-]+', '_', 'g');
    
    -- Ищем файл в storage.objects по паттерну
    SELECT name INTO storage_path
    FROM storage.objects
    WHERE bucket_id = 'receipts'
      AND name LIKE sanitized_contract || '/' || year_month || '/' || sanitized_receipt || '%'
    LIMIT 1;
    
    -- Если нашли - обновляем
    IF storage_path IS NOT NULL THEN
      UPDATE materials
      SET file_url = storage_path
      WHERE receipt_number = mat.receipt_number
        AND receipt_date = mat.receipt_date
        AND contract_number = mat.contract_number
        AND file_url IS NULL;
      
      updated_count := updated_count + 1;
    END IF;
  END LOOP;
  
  RAISE NOTICE 'Обновлено file_url для % накладных', updated_count;
END $$;

