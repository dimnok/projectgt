-- Разрешить загрузку файлов счетов пользователям с правом prepare_invoice
-- (ранее INSERT в Storage требовал только purchase_requests.create).

BEGIN;

DROP POLICY IF EXISTS "purchase_requests_bucket_insert" ON storage.objects;
CREATE POLICY "purchase_requests_bucket_insert"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
    bucket_id = 'purchase_requests'
    AND (storage.foldername(name))[1]::uuid IN (SELECT public.get_my_company_ids())
    AND (
        public.check_permission(auth.uid(), 'purchase_requests', 'create')
        OR public.check_permission(auth.uid(), 'purchase_requests', 'prepare_invoice')
        OR public.check_permission(auth.uid(), 'purchase_requests', 'payment')
        OR public.check_permission(auth.uid(), 'purchase_requests', 'receive')
    )
);

COMMIT;
