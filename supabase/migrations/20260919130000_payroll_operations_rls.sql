-- Права на операции ФОТ: вместо «любой участник компании» — право payroll.*.
--
-- Чтение: payroll.read видит всю компанию; сотрудник без этого права видит
-- только свои строки (employee_id своего профиля) — иначе в приложении
-- ломается экран «Финансовая информация».
-- Запись: insert/update/delete — только payroll.create/update/delete.

ALTER TABLE public.payroll_bonus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_penalty ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_payout ENABLE ROW LEVEL SECURITY;

-- Снимаем все прежние политики этих таблиц. Permissive-политики складываются
-- по OR, поэтому оставшаяся старая политика сохранила бы открытый доступ.
DO $$
DECLARE
  policy record;
BEGIN
  FOR policy IN
    SELECT tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('payroll_bonus', 'payroll_penalty', 'payroll_payout')
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.%I',
      policy.policyname,
      policy.tablename
    );
  END LOOP;
END;
$$;

-- payroll_bonus
CREATE POLICY "payroll_bonus_select" ON public.payroll_bonus
  FOR SELECT TO authenticated
  USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND (
      public.check_permission(auth.uid(), 'payroll', 'read')
      OR employee_id = (
        SELECT p.employee_id FROM public.profiles p WHERE p.id = auth.uid()
      )
    )
  );

CREATE POLICY "payroll_bonus_insert" ON public.payroll_bonus
  FOR INSERT TO authenticated
  WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'payroll', 'create')
  );

CREATE POLICY "payroll_bonus_update" ON public.payroll_bonus
  FOR UPDATE TO authenticated
  USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'payroll', 'update')
  )
  WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'payroll', 'update')
  );

CREATE POLICY "payroll_bonus_delete" ON public.payroll_bonus
  FOR DELETE TO authenticated
  USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'payroll', 'delete')
  );

-- payroll_penalty
CREATE POLICY "payroll_penalty_select" ON public.payroll_penalty
  FOR SELECT TO authenticated
  USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND (
      public.check_permission(auth.uid(), 'payroll', 'read')
      OR employee_id = (
        SELECT p.employee_id FROM public.profiles p WHERE p.id = auth.uid()
      )
    )
  );

CREATE POLICY "payroll_penalty_insert" ON public.payroll_penalty
  FOR INSERT TO authenticated
  WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'payroll', 'create')
  );

CREATE POLICY "payroll_penalty_update" ON public.payroll_penalty
  FOR UPDATE TO authenticated
  USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'payroll', 'update')
  )
  WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'payroll', 'update')
  );

CREATE POLICY "payroll_penalty_delete" ON public.payroll_penalty
  FOR DELETE TO authenticated
  USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'payroll', 'delete')
  );

-- payroll_payout
CREATE POLICY "payroll_payout_select" ON public.payroll_payout
  FOR SELECT TO authenticated
  USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND (
      public.check_permission(auth.uid(), 'payroll', 'read')
      OR employee_id = (
        SELECT p.employee_id FROM public.profiles p WHERE p.id = auth.uid()
      )
    )
  );

CREATE POLICY "payroll_payout_insert" ON public.payroll_payout
  FOR INSERT TO authenticated
  WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'payroll', 'create')
  );

CREATE POLICY "payroll_payout_update" ON public.payroll_payout
  FOR UPDATE TO authenticated
  USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'payroll', 'update')
  )
  WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'payroll', 'update')
  );

CREATE POLICY "payroll_payout_delete" ON public.payroll_payout
  FOR DELETE TO authenticated
  USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'payroll', 'delete')
  );
