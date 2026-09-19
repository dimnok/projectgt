-- Списки выплат в профиле — за всё время. Дата перевода не означает «за этот месяц».

CREATE OR REPLACE FUNCTION public.get_my_profile_finance(
  p_year integer,
  p_month integer
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_employee_id uuid;
  v_company_id uuid;
  v_start date;
  v_end date;
  v_hours numeric := 0;
  v_base numeric := 0;
  v_trip numeric := 0;
  v_bonus numeric := 0;
  v_penalty numeric := 0;
  v_payout_month numeric := 0;
  v_net numeric := 0;
  v_balance numeric := 0;
  v_bonuses jsonb := '[]'::jsonb;
  v_penalties jsonb := '[]'::jsonb;
  v_payouts jsonb := '[]'::jsonb;
  v_hours_by_date jsonb := '[]'::jsonb;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;

  IF p_year < 2000 OR p_year > 2100 OR p_month < 1 OR p_month > 12 THEN
    RAISE EXCEPTION 'invalid period';
  END IF;

  v_start := make_date(p_year, p_month, 1);
  v_end := (v_start + interval '1 month')::date;

  SELECT p.employee_id, p.last_company_id
  INTO v_employee_id, v_company_id
  FROM public.profiles p
  WHERE p.id = v_uid;

  IF v_employee_id IS NULL OR v_company_id IS NULL THEN
    RETURN jsonb_build_object('linked', false);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.employees e
    WHERE e.id = v_employee_id AND e.company_id = v_company_id
  ) THEN
    RETURN jsonb_build_object('linked', false);
  END IF;

  WITH all_hours AS (
    SELECT w.date AS work_date, w.object_id AS obj_id, wh.hours AS work_hours
    FROM public.work_hours wh
    JOIN public.works w ON w.id = wh.work_id
    WHERE wh.employee_id = v_employee_id AND w.status = 'closed' AND w.company_id = v_company_id
      AND w.date >= v_start AND w.date < v_end
    UNION ALL
    SELECT ea.date AS work_date, ea.object_id AS obj_id, ea.hours AS work_hours
    FROM public.employee_attendance ea
    WHERE ea.employee_id = v_employee_id AND ea.company_id = v_company_id
      AND ea.date >= v_start AND ea.date < v_end
  )
  SELECT COALESCE(SUM(ah.work_hours), 0),
    COALESCE(SUM(ah.work_hours * COALESCE((
      SELECT er.hourly_rate FROM public.employee_rates er
      WHERE er.employee_id = v_employee_id AND ah.work_date >= er.valid_from
        AND (er.valid_to IS NULL OR ah.work_date <= er.valid_to) AND er.company_id = v_company_id
      ORDER BY er.valid_from DESC LIMIT 1
    ), 0)), 0)
  INTO v_hours, v_base FROM all_hours ah;

  WITH all_hours AS (
    SELECT w.date AS work_date, w.object_id AS obj_id, wh.hours AS work_hours
    FROM public.work_hours wh JOIN public.works w ON w.id = wh.work_id
    WHERE wh.employee_id = v_employee_id AND w.status = 'closed' AND w.company_id = v_company_id
      AND w.date >= v_start AND w.date < v_end
    UNION ALL
    SELECT ea.date AS work_date, ea.object_id AS obj_id, ea.hours AS work_hours
    FROM public.employee_attendance ea
    WHERE ea.employee_id = v_employee_id AND ea.company_id = v_company_id
      AND ea.date >= v_start AND ea.date < v_end
  )
  SELECT COALESCE(SUM(COALESCE((
    SELECT btr.rate FROM public.business_trip_rates btr
    WHERE btr.object_id = ah.obj_id AND btr.company_id = v_company_id
      AND (btr.employee_id = v_employee_id OR btr.employee_id IS NULL)
      AND ah.work_date >= btr.valid_from AND (btr.valid_to IS NULL OR ah.work_date <= btr.valid_to)
      AND ah.work_hours >= COALESCE(btr.minimum_hours, 0)
    ORDER BY btr.employee_id NULLS LAST, btr.valid_from DESC LIMIT 1
  ), 0)), 0)
  INTO v_trip FROM all_hours ah WHERE ah.obj_id IS NOT NULL;

  SELECT COALESCE(SUM(pb.amount), 0) INTO v_bonus FROM public.payroll_bonus pb
  WHERE pb.employee_id = v_employee_id AND pb.company_id = v_company_id AND pb.date >= v_start AND pb.date < v_end;

  SELECT COALESCE(SUM(pp.amount), 0) INTO v_penalty FROM public.payroll_penalty pp
  WHERE pp.employee_id = v_employee_id AND pp.company_id = v_company_id AND pp.date >= v_start AND pp.date < v_end;

  SELECT COALESCE(SUM(po.amount), 0) INTO v_payout_month FROM public.payroll_payout po
  WHERE po.employee_id = v_employee_id AND po.company_id = v_company_id AND po.payout_date >= v_start AND po.payout_date < v_end;

  v_net := v_base + v_trip + v_bonus - v_penalty;
  v_balance := public.calculate_single_employee_balance(v_employee_id, v_company_id);

  SELECT COALESCE(jsonb_agg(jsonb_build_object('date', pb.date, 'amount', pb.amount, 'reason', COALESCE(pb.reason, '')) ORDER BY pb.date DESC), '[]'::jsonb)
  INTO v_bonuses FROM public.payroll_bonus pb
  WHERE pb.employee_id = v_employee_id AND pb.company_id = v_company_id;

  SELECT COALESCE(jsonb_agg(jsonb_build_object('date', pp.date, 'amount', pp.amount, 'reason', COALESCE(pp.reason, '')) ORDER BY pp.date DESC), '[]'::jsonb)
  INTO v_penalties FROM public.payroll_penalty pp
  WHERE pp.employee_id = v_employee_id AND pp.company_id = v_company_id;

  SELECT COALESCE(jsonb_agg(jsonb_build_object('date', po.payout_date, 'amount', po.amount, 'comment', COALESCE(po.comment, '')) ORDER BY po.payout_date DESC), '[]'::jsonb)
  INTO v_payouts FROM public.payroll_payout po
  WHERE po.employee_id = v_employee_id AND po.company_id = v_company_id;

  WITH all_hours AS (
    SELECT w.date AS work_date, wh.hours AS work_hours
    FROM public.work_hours wh JOIN public.works w ON w.id = wh.work_id
    WHERE wh.employee_id = v_employee_id AND w.status = 'closed' AND w.company_id = v_company_id
      AND w.date >= v_start AND w.date < v_end
    UNION ALL
    SELECT ea.date AS work_date, ea.hours AS work_hours
    FROM public.employee_attendance ea
    WHERE ea.employee_id = v_employee_id AND ea.company_id = v_company_id
      AND ea.date >= v_start AND ea.date < v_end
  )
  SELECT COALESCE(jsonb_agg(jsonb_build_object('date', d.work_date, 'hours', d.hours_sum) ORDER BY d.work_date), '[]'::jsonb)
  INTO v_hours_by_date FROM (
    SELECT ah.work_date, SUM(ah.work_hours) AS hours_sum FROM all_hours ah GROUP BY ah.work_date
  ) d;

  RETURN jsonb_build_object(
    'linked', true, 'employee_id', v_employee_id, 'year', p_year, 'month', p_month,
    'hours', v_hours, 'base_salary', v_base, 'business_trip_total', v_trip,
    'bonuses_total', v_bonus, 'penalties_total', v_penalty, 'net_salary', v_net,
    'payouts_month', v_payout_month, 'month_delta', v_net - v_payout_month,
    'balance', COALESCE(v_balance, 0), 'bonuses', v_bonuses, 'penalties', v_penalties,
    'payouts', v_payouts, 'hours_by_date', v_hours_by_date
  );
END;
$$;

COMMENT ON FUNCTION public.get_my_profile_finance(integer, integer) IS
  'Финансы профиля: сводка месяца без выплат. Списки премий, штрафов и выплат — за всё время.';
