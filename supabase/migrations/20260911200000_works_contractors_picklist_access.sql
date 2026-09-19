-- Разрешение на чтение контрагентов с типом 'contractor' (подрядчики)
-- для пользователей с правами на модуль «Работы» (works.read / create / update).
-- Это позволяет прорабу выбирать подрядчика в смене без открытия доступа
-- ко всему разделу «Контрагенты» (contractors.read).

DROP POLICY IF EXISTS "contractors_select" ON public.contractors;

CREATE POLICY "contractors_select"
ON public.contractors
FOR SELECT
TO public
USING (
  company_id IN (SELECT public.get_my_company_ids())
  AND (
    public.check_permission(uid(), 'contractors', 'read')
    OR (
      type = 'contractor'
      AND (
        public.check_permission(uid(), 'works', 'read')
        OR public.check_permission(uid(), 'works', 'create')
        OR public.check_permission(uid(), 'works', 'update')
      )
    )
  )
);
