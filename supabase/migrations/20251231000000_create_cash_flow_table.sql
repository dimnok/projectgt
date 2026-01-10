-- Создание таблицы справочника статей движения денежных средств
CREATE TABLE IF NOT EXISTS public.cash_flow_categories (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    name text NOT NULL,
    operation_type text NOT NULL, -- 'income' / 'expense' / 'both'
    is_active boolean NOT NULL DEFAULT true,
    sort_order integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    
    CONSTRAINT cash_flow_categories_pkey PRIMARY KEY (id),
    CONSTRAINT cash_flow_categories_operation_type_check CHECK (operation_type = ANY (ARRAY['income'::text, 'expense'::text, 'both'::text]))
);

-- Включение RLS для категорий
ALTER TABLE public.cash_flow_categories ENABLE ROW LEVEL SECURITY;

-- Создание таблицы движения денежных средств (Cash Flow)
CREATE TABLE IF NOT EXISTS public.cash_flow (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    date date NOT NULL DEFAULT CURRENT_DATE,
    type text NOT NULL, -- 'income' / 'expense'
    amount numeric NOT NULL DEFAULT 0,
    object_id uuid NULL,
    contract_id uuid NULL,
    contractor_id uuid NULL,
    category_id uuid NULL,
    comment text NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid NULL,
    
    CONSTRAINT cash_flow_pkey PRIMARY KEY (id),
    CONSTRAINT cash_flow_type_check CHECK (type = ANY (ARRAY['income'::text, 'expense'::text])),
    CONSTRAINT cash_flow_object_id_fkey FOREIGN KEY (object_id) REFERENCES public.objects(id) ON DELETE SET NULL,
    CONSTRAINT cash_flow_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contracts(id) ON DELETE SET NULL,
    CONSTRAINT cash_flow_contractor_id_fkey FOREIGN KEY (contractor_id) REFERENCES public.contractors(id) ON DELETE SET NULL,
    CONSTRAINT cash_flow_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.cash_flow_categories(id) ON DELETE SET NULL,
    CONSTRAINT cash_flow_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL
);

-- Комментарии к колонкам таблицы cash_flow
COMMENT ON TABLE public.cash_flow IS 'Движение денежных средств (приходы и расходы)';
COMMENT ON COLUMN public.cash_flow.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN public.cash_flow.date IS 'Дата платежа';
COMMENT ON COLUMN public.cash_flow.type IS 'Тип операции (income - приход, expense - расход)';
COMMENT ON COLUMN public.cash_flow.amount IS 'Сумма операции';
COMMENT ON COLUMN public.cash_flow.object_id IS 'Ссылка на объект';
COMMENT ON COLUMN public.cash_flow.contract_id IS 'Ссылка на договор';
COMMENT ON COLUMN public.cash_flow.contractor_id IS 'Ссылка на контрагента';
COMMENT ON COLUMN public.cash_flow.category_id IS 'Ссылка на статью движения ДС';
COMMENT ON COLUMN public.cash_flow.comment IS 'Комментарий к платежу';
COMMENT ON COLUMN public.cash_flow.created_at IS 'Дата и время создания записи';
COMMENT ON COLUMN public.cash_flow.created_by IS 'Ссылка на профиль пользователя, создавшего запись';

-- Включение RLS для основной таблицы
ALTER TABLE public.cash_flow ENABLE ROW LEVEL SECURITY;

-- Базовые политики RLS (чтение всем авторизованным пользователям, запись админам)
-- Примечание: В реальном проекте политики могут быть более строгими
CREATE POLICY "Allow read access for all authenticated users" ON public.cash_flow
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow read access for all authenticated users" ON public.cash_flow_categories
    FOR SELECT TO authenticated USING (true);

-- Добавление модуля в справочник модулей (для управления правами)
INSERT INTO public.app_modules (code, name, icon_key, sort_order, is_active)
VALUES ('cash_flow', 'Cash Flow', 'money_dollar_circle', 95, true)
ON CONFLICT (code) DO UPDATE 
SET name = EXCLUDED.name, 
    icon_key = EXCLUDED.icon_key,
    sort_order = EXCLUDED.sort_order;

