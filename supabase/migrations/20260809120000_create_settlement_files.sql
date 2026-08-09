-- Файлы счетов взаиморасчётов: метаданные в PostgreSQL, объекты в Storage bucket `settlement_files`.

BEGIN;

CREATE TABLE IF NOT EXISTS public.settlement_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    settlement_operation_id UUID NOT NULL
        REFERENCES public.settlement_operations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    size BIGINT NOT NULL CHECK (size >= 0),
    type TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES auth.users(id)
);

CREATE INDEX IF NOT EXISTS idx_settlement_files_operation
    ON public.settlement_files (settlement_operation_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_settlement_files_company
    ON public.settlement_files (company_id);

COMMENT ON TABLE public.settlement_files IS
    'Вложения к счетам взаиморасчётов (PDF, сканы и прочие документы).';

ALTER TABLE public.settlement_files ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Strict SELECT for settlement_files"
    ON public.settlement_files;
CREATE POLICY "Strict SELECT for settlement_files"
ON public.settlement_files FOR SELECT
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'settlements', 'read')
);

DROP POLICY IF EXISTS "Strict INSERT for settlement_files"
    ON public.settlement_files;
CREATE POLICY "Strict INSERT for settlement_files"
ON public.settlement_files FOR INSERT
TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'settlements', 'update')
    AND EXISTS (
        SELECT 1
        FROM public.settlement_operations o
        WHERE o.id = settlement_operation_id
          AND o.company_id = settlement_files.company_id
    )
);

DROP POLICY IF EXISTS "Strict DELETE for settlement_files"
    ON public.settlement_files;
CREATE POLICY "Strict DELETE for settlement_files"
ON public.settlement_files FOR DELETE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'settlements', 'update')
);

-- Приватный bucket: {company_id}/{operation_id}/{timestamp}_{safe_name}
INSERT INTO storage.buckets (id, name, public)
SELECT 'settlement_files', 'settlement_files', false
WHERE NOT EXISTS (
    SELECT 1 FROM storage.buckets WHERE id = 'settlement_files'
);

DROP POLICY IF EXISTS "settlement_files_bucket_select" ON storage.objects;
CREATE POLICY "settlement_files_bucket_select"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'settlement_files'
    AND (storage.foldername(name))[1]::uuid IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'settlements', 'read')
);

DROP POLICY IF EXISTS "settlement_files_bucket_insert" ON storage.objects;
CREATE POLICY "settlement_files_bucket_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'settlement_files'
    AND (storage.foldername(name))[1]::uuid IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'settlements', 'update')
);

DROP POLICY IF EXISTS "settlement_files_bucket_delete" ON storage.objects;
CREATE POLICY "settlement_files_bucket_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'settlement_files'
    AND (storage.foldername(name))[1]::uuid IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'settlements', 'update')
);

COMMIT;
