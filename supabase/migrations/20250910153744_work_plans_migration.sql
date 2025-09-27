-- Создание таблицы work_plans для хранения планов работ
CREATE TABLE IF NOT EXISTS public.work_plans (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,

    -- Пользователь, создавший план работ
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Дата плана работ
    date DATE NOT NULL,

    -- Объект, для которого создается план
    object_id UUID NOT NULL REFERENCES public.objects(id) ON DELETE CASCADE,

    -- Участок (опционально)
    section TEXT,

    -- Этаж (опционально)
    floor TEXT,

    -- Система работ
    system TEXT NOT NULL,

    -- Выбранные работы (массив ID из таблицы estimates)
    selected_works JSONB NOT NULL DEFAULT '[]'::jsonb,

    -- Комментарий к плану работ (опционально)
    comment TEXT,

    -- Приоритет плана (опционально)
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent'))
);

-- Создание индексов для оптимизации запросов
CREATE INDEX IF NOT EXISTS idx_work_plans_created_by ON public.work_plans(created_by);
CREATE INDEX IF NOT EXISTS idx_work_plans_date ON public.work_plans(date);
CREATE INDEX IF NOT EXISTS idx_work_plans_object_id ON public.work_plans(object_id);
CREATE INDEX IF NOT EXISTS idx_work_plans_system ON public.work_plans(system);
CREATE INDEX IF NOT EXISTS idx_work_plans_created_at ON public.work_plans(created_at DESC);

-- Индекс для поиска по массиву selected_works (JSONB)
CREATE INDEX IF NOT EXISTS idx_work_plans_selected_works ON public.work_plans USING gin(selected_works);

-- Триггер для автоматического обновления updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER handle_work_plans_updated_at
    BEFORE UPDATE ON public.work_plans
    FOR EACH ROW
    EXECUTE PROCEDURE public.handle_updated_at();

-- Row Level Security (RLS) политики
ALTER TABLE public.work_plans ENABLE ROW LEVEL SECURITY;

-- Политика: пользователи могут видеть планы работ только для объектов, к которым у них есть доступ
CREATE POLICY "Users can view work plans for their objects" ON public.work_plans
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND (profiles.object_ids IS NULL OR work_plans.object_id = ANY(profiles.object_ids))
        ) OR
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Политика: пользователи могут создавать планы работ только для объектов, к которым у них есть доступ
CREATE POLICY "Users can create work plans for their objects" ON public.work_plans
    FOR INSERT WITH CHECK (
        auth.uid() = created_by AND
        (
            EXISTS (
                SELECT 1 FROM public.profiles
                WHERE profiles.id = auth.uid()
                AND (profiles.object_ids IS NULL OR work_plans.object_id = ANY(profiles.object_ids))
            ) OR
            EXISTS (
                SELECT 1 FROM public.profiles
                WHERE profiles.id = auth.uid()
                AND profiles.role = 'admin'
            )
        )
    );

-- Политика: пользователи могут обновлять только свои планы работ
CREATE POLICY "Users can update their own work plans" ON public.work_plans
    FOR UPDATE USING (
        auth.uid() = created_by OR
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Политика: пользователи могут удалять только свои планы работ
CREATE POLICY "Users can delete their own work plans" ON public.work_plans
    FOR DELETE USING (
        auth.uid() = created_by OR
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Комментарии к таблице и столбцам
COMMENT ON TABLE public.work_plans IS 'Планы работ по объектам и системам';
COMMENT ON COLUMN public.work_plans.id IS 'Уникальный идентификатор плана работ';
COMMENT ON COLUMN public.work_plans.created_by IS 'Пользователь, создавший план работ';
COMMENT ON COLUMN public.work_plans.date IS 'Дата выполнения плана работ';
COMMENT ON COLUMN public.work_plans.object_id IS 'Объект, для которого создается план работ';
COMMENT ON COLUMN public.work_plans.section IS 'Участок объекта (опционально)';
COMMENT ON COLUMN public.work_plans.floor IS 'Этаж объекта (опционально)';
COMMENT ON COLUMN public.work_plans.system IS 'Система работ (электрика, сантехника и т.д.)';
COMMENT ON COLUMN public.work_plans.selected_works IS 'Массив выбранных работ (ID из таблицы estimates с дополнительными данными)';
COMMENT ON COLUMN public.work_plans.comment IS 'Комментарий к плану работ';
COMMENT ON COLUMN public.work_plans.priority IS 'Приоритет плана работ: low, normal, high, urgent';

-- Функция для получения планов работ пользователя
CREATE OR REPLACE FUNCTION public.get_user_work_plans(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_date_from DATE DEFAULT NULL,
    p_date_to DATE DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    date DATE,
    object_name TEXT,
    object_address TEXT,
    section TEXT,
    floor TEXT,
    system TEXT,
    works_count INTEGER,
    priority TEXT,
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        wp.id,
        wp.date,
        o.name as object_name,
        o.address as object_address,
        wp.section,
        wp.floor,
        wp.system,
        jsonb_array_length(wp.selected_works) as works_count,
        wp.priority,
        wp.comment,
        wp.created_at,
        wp.updated_at
    FROM public.work_plans wp
    JOIN public.objects o ON wp.object_id = o.id
    WHERE
        (wp.created_by = auth.uid() OR
         EXISTS (
             SELECT 1 FROM public.profiles
             WHERE profiles.id = auth.uid()
             AND profiles.role = 'admin'
         ) OR
         EXISTS (
             SELECT 1 FROM public.profiles
             WHERE profiles.id = auth.uid()
             AND (profiles.object_ids IS NULL OR wp.object_id = ANY(profiles.object_ids))
         ))
        AND (p_date_from IS NULL OR wp.date >= p_date_from)
        AND (p_date_to IS NULL OR wp.date <= p_date_to)
    ORDER BY wp.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

-- Функция для получения детальной информации о плане работ
CREATE OR REPLACE FUNCTION public.get_work_plan_details(work_plan_id UUID)
RETURNS TABLE (
    id UUID,
    date DATE,
    object_name TEXT,
    object_address TEXT,
    section TEXT,
    floor TEXT,
    system TEXT,
    selected_works JSONB,
    priority TEXT,
    comment TEXT,
    created_by_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        wp.id,
        wp.date,
        o.name as object_name,
        o.address as object_address,
        wp.section,
        wp.floor,
        wp.system,
        wp.selected_works,
        wp.priority,
        wp.comment,
        p.full_name as created_by_name,
        wp.created_at,
        wp.updated_at
    FROM public.work_plans wp
    JOIN public.objects o ON wp.object_id = o.id
    JOIN public.profiles p ON wp.created_by = p.id
    WHERE wp.id = work_plan_id
    AND (wp.created_by = auth.uid() OR
         EXISTS (
             SELECT 1 FROM public.profiles
             WHERE profiles.id = auth.uid()
             AND profiles.role = 'admin'
         ) OR
         EXISTS (
             SELECT 1 FROM public.profiles
             WHERE profiles.id = auth.uid()
             AND (profiles.object_ids IS NULL OR wp.object_id = ANY(profiles.object_ids))
         ));
END;
$$;
