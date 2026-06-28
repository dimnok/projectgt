-- Усиление RLS заявлений: company scope в Storage и проверка employee_id.

BEGIN;

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
