-- Selective rollout: switch a user from Flutter to the web app.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS prefer_web_app boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.profiles.prefer_web_app IS
  'Если true, клиент Flutter показывает экран перехода на веб-приложение.';

CREATE OR REPLACE FUNCTION public.prevent_unauthorized_prefer_web_app()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.prefer_web_app IS NOT DISTINCT FROM NEW.prefer_web_app THEN
    RETURN NEW;
  END IF;

  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF public.check_permission(auth.uid(), 'users', 'update')
     OR public.is_super_admin(auth.uid()) THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION
    'Только супер-админ или руководитель может переключать пользователя на новую версию'
    USING ERRCODE = '42501';
END;
$$;

DROP TRIGGER IF EXISTS prevent_unauthorized_prefer_web_app ON public.profiles;

CREATE TRIGGER prevent_unauthorized_prefer_web_app
  BEFORE UPDATE OF prefer_web_app ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_unauthorized_prefer_web_app();
