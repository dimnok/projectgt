-- Super-admin may update/delete closed works (same as company owner).
CREATE OR REPLACE FUNCTION public.check_work_editable(target_work_id uuid, user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  work_record record;
  is_company_owner BOOLEAN;
BEGIN
  SELECT * INTO work_record FROM public.works WHERE id = target_work_id;
  IF work_record IS NULL THEN
    RETURN true;
  END IF;

  IF public.is_super_admin(check_work_editable.user_id) THEN
    RETURN true;
  END IF;

  SELECT cm.is_owner INTO is_company_owner
  FROM public.company_members cm
  WHERE cm.user_id = check_work_editable.user_id
    AND cm.company_id = work_record.company_id
    AND cm.is_active = true;

  IF is_company_owner = true THEN
    RETURN true;
  END IF;

  IF work_record.opened_by != user_id THEN
    RETURN false;
  END IF;

  IF work_record.status = 'closed' THEN
    RETURN false;
  END IF;

  RETURN true;
END;
$function$;
