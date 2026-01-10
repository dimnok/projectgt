-- Миграция для внедрения фундамента Multi-tenancy
-- Создает таблицы companies, company_members и обновляет profiles

-- 1. Создание таблицы компаний (заменяет/расширяет логику company_profile)
CREATE TABLE IF NOT EXISTS public.companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_full TEXT NOT NULL,
    name_short TEXT NOT NULL,
    logo_url TEXT,
    website TEXT,
    email TEXT,
    phone TEXT,
    activity_description TEXT,
    inn TEXT,
    kpp TEXT,
    ogrn TEXT,
    okpo TEXT,
    legal_address TEXT,
    actual_address TEXT,
    director_name TEXT,
    director_position TEXT,
    director_basis TEXT,
    director_phone TEXT,
    chief_accountant_name TEXT,
    chief_accountant_phone TEXT,
    contact_person TEXT,
    taxation_system TEXT,
    is_vat_payer BOOLEAN DEFAULT false,
    vat_rate NUMERIC DEFAULT 0,
    
    -- Системные поля для Multi-tenancy
    owner_id UUID REFERENCES public.profiles(id),
    invitation_code TEXT UNIQUE,
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Включение RLS для компаний
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;

-- 2. Создание таблицы участников компаний
CREATE TABLE IF NOT EXISTS public.company_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role_id UUID REFERENCES public.roles(id), -- Ссылка на роль в конкретной компании
    is_owner BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    joined_at TIMESTAMPTZ DEFAULT now(),
    
    UNIQUE(company_id, user_id)
);

-- Включение RLS для участников
ALTER TABLE public.company_members ENABLE ROW LEVEL SECURITY;

-- 3. Обновление таблицы профилей для запоминания последней компании
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'profiles' AND column_name = 'last_company_id') THEN
        ALTER TABLE public.profiles ADD COLUMN last_company_id UUID REFERENCES public.companies(id);
    END IF;
END $$;

-- 4. Перенос данных из старой таблицы company_profile (если она существует)
DO $$
DECLARE
    first_user_id UUID;
    comp_id UUID;
BEGIN
    -- Проверяем, существует ли старая таблица и есть ли в ней данные
    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE table_name = 'company_profile') THEN
        
        -- Получаем ID первого администратора или пользователя для назначения владельцем
        SELECT id INTO first_user_id FROM public.profiles ORDER BY created_at ASC LIMIT 1;
        
        -- Переносим данные
        FOR comp_id IN 
            INSERT INTO public.companies (
                name_full, name_short, logo_url, website, email, phone, 
                activity_description, inn, kpp, ogrn, okpo, 
                legal_address, actual_address, director_name, 
                director_position, director_basis, director_phone, 
                chief_accountant_name, chief_accountant_phone, 
                contact_person, taxation_system, is_vat_payer, vat_rate,
                owner_id, invitation_code
            )
            SELECT 
                name_full, name_short, logo_url, website, email, phone, 
                activity_description, inn, kpp, ogrn, okpo, 
                legal_address, actual_address, director_name, 
                director_position, director_basis, director_phone, 
                chief_accountant_name, chief_accountant_phone, 
                contact_person, taxation_system, is_vat_payer, vat_rate,
                first_user_id, 'GT-' || upper(substring(replace(gen_random_uuid()::text, '-', ''), 1, 8))
            FROM public.company_profile
            RETURNING id
        LOOP
            -- Создаем запись участника для каждой перенесенной компании
            IF first_user_id IS NOT NULL THEN
                INSERT INTO public.company_members (company_id, user_id, is_owner, is_active)
                VALUES (comp_id, first_user_id, true, true);
                
                -- Устанавливаем как последнюю активную компанию
                UPDATE public.profiles SET last_company_id = comp_id WHERE id = first_user_id;
            END IF;
        END LOOP;
    END IF;
END $$;

-- 5. Базовые RLS политики

-- Компании: пользователь видит компанию, если он её участник
CREATE POLICY "Users can view companies they are members of" ON public.companies
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.company_members
            WHERE company_id = public.companies.id AND user_id = auth.uid() AND is_active = true
        )
    );

-- Компании: владелец может обновлять данные
CREATE POLICY "Owners can update their companies" ON public.companies
    FOR UPDATE
    USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());

-- Участники: пользователь видит список участников своей компании
CREATE POLICY "Members can view other members of the same company" ON public.company_members
    FOR SELECT
    USING (
        company_id IN (
            SELECT company_id FROM public.company_members WHERE user_id = auth.uid() AND is_active = true
        )
    );

-- 6. Комментарии к таблицам
COMMENT ON TABLE public.companies IS 'Справочник организаций в системе (Multi-tenancy)';
COMMENT ON TABLE public.company_members IS 'Связь пользователей с компаниями и их роли внутри компании';

