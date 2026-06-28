-- Заявления сотрудников: метаданные + подписанные сканы в Storage bucket `employee_applications`.

BEGIN;

CREATE TABLE IF NOT EXISTS public.employee_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  application_type text NOT NULL
    CHECK (application_type IN ('vacation', 'unpaid_leave')),
  start_date date NOT NULL,
  end_date date,
  duration_days integer NOT NULL CHECK (duration_days > 0),
  scan_name text NOT NULL,
  scan_path text NOT NULL,
  scan_size bigint NOT NULL DEFAULT 0,
  scan_type text NOT NULL DEFAULT 'application/pdf',
  created_by uuid NOT NULL REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_employee_applications_employee_id
  ON public.employee_applications (employee_id);

CREATE INDEX IF NOT EXISTS idx_employee_applications_company_employee
  ON public.employee_applications (company_id, employee_id, created_at DESC);

ALTER TABLE public.employee_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "employee_applications_select" ON public.employee_applications;
CREATE POLICY "employee_applications_select"
ON public.employee_applications FOR SELECT
TO public
USING (
  company_id IN (SELECT get_my_company_ids())
  AND (
    check_permission(uid(), 'employees', 'read')
    OR employee_id = (SELECT employee_id FROM public.profiles WHERE id = uid())
  )
);

DROP POLICY IF EXISTS "employee_applications_insert" ON public.employee_applications;
CREATE POLICY "employee_applications_insert"
ON public.employee_applications FOR INSERT
TO public
WITH CHECK (
  company_id IN (SELECT get_my_company_ids())
  AND EXISTS (
    SELECT 1 FROM public.employees e
    WHERE e.id = employee_id AND e.company_id = employee_applications.company_id
  )
  AND (
    check_permission(uid(), 'employees', 'update')
    OR employee_id = (SELECT employee_id FROM public.profiles WHERE id = uid())
  )
);

DROP POLICY IF EXISTS "employee_applications_delete" ON public.employee_applications;
CREATE POLICY "employee_applications_delete"
ON public.employee_applications FOR DELETE
TO public
USING (
  company_id IN (SELECT get_my_company_ids())
  AND check_permission(uid(), 'employees', 'update')
);

-- Приватный bucket для подписанных сканов заявлений.
INSERT INTO storage.buckets (id, name, public)
SELECT 'employee_applications', 'employee_applications', false
WHERE NOT EXISTS (
  SELECT 1 FROM storage.buckets WHERE id = 'employee_applications'
);

DROP POLICY IF EXISTS "employee_applications_bucket_select" ON storage.objects;
CREATE POLICY "employee_applications_bucket_select"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'employee_applications'
  AND (storage.foldername(name))[1]::uuid IN (SELECT get_my_company_ids())
  AND (
    public.check_permission(auth.uid(), 'employees', 'read')
    OR (storage.foldername(name))[2] = (
      SELECT employee_id::text FROM public.profiles WHERE id = auth.uid()
    )
  )
);

DROP POLICY IF EXISTS "employee_applications_bucket_insert" ON storage.objects;
CREATE POLICY "employee_applications_bucket_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'employee_applications'
  AND (storage.foldername(name))[1]::uuid IN (SELECT get_my_company_ids())
  AND (
    public.check_permission(auth.uid(), 'employees', 'update')
    OR (storage.foldername(name))[2] = (
      SELECT employee_id::text FROM public.profiles WHERE id = auth.uid()
    )
  )
);

DROP POLICY IF EXISTS "employee_applications_bucket_delete" ON storage.objects;
CREATE POLICY "employee_applications_bucket_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'employee_applications'
  AND (storage.foldername(name))[1]::uuid IN (SELECT get_my_company_ids())
  AND public.check_permission(auth.uid(), 'employees', 'update')
);

COMMIT;
