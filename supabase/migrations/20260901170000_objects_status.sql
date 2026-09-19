-- Статус строительного объекта: активный, приостановлен, завершён.
DO $$ BEGIN
  CREATE TYPE public.object_status AS ENUM ('active', 'paused', 'completed');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

ALTER TABLE public.objects
  ADD COLUMN IF NOT EXISTS status public.object_status NOT NULL DEFAULT 'active';

COMMENT ON COLUMN public.objects.status IS 'Статус объекта: active (Активный), paused (Приостановлен), completed (Завершён).';

CREATE INDEX IF NOT EXISTS objects_company_id_status_idx
  ON public.objects (company_id, status);
