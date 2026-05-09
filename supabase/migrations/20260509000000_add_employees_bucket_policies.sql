-- Добавление политик DELETE и UPDATE для бакета employees
CREATE POLICY "employees_bucket_delete"
ON storage.objects FOR DELETE
TO public
USING (
  bucket_id = 'employees' 
  AND check_permission(uid(), 'employees', 'update')
);

CREATE POLICY "employees_bucket_update"
ON storage.objects FOR UPDATE
TO public
USING (
  bucket_id = 'employees' 
  AND check_permission(uid(), 'employees', 'update')
);
