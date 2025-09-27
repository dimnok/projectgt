-- Добавление полей для ответственного и работников в таблицу work_plans
ALTER TABLE public.work_plans 
ADD COLUMN IF NOT EXISTS responsible_id UUID REFERENCES public.employees(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS worker_ids UUID[] DEFAULT ARRAY[]::UUID[];

-- Добавление комментариев к новым полям
COMMENT ON COLUMN public.work_plans.responsible_id IS 'ID ответственного сотрудника за выполнение плана работ';
COMMENT ON COLUMN public.work_plans.worker_ids IS 'Массив ID работников, назначенных на выполнение плана работ';

-- Добавление индексов для оптимизации запросов
CREATE INDEX IF NOT EXISTS idx_work_plans_responsible_id 
ON public.work_plans(responsible_id);

CREATE INDEX IF NOT EXISTS idx_work_plans_worker_ids 
ON public.work_plans USING GIN(worker_ids);
