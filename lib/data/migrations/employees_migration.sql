-- Миграция для создания таблицы сотрудников
CREATE TABLE IF NOT EXISTS employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  photo_url TEXT,
  last_name TEXT NOT NULL,
  first_name TEXT NOT NULL,
  middle_name TEXT,
  birth_date TIMESTAMP WITH TIME ZONE,
  birth_place TEXT,
  citizenship TEXT,
  phone TEXT,
  clothing_size TEXT,
  shoe_size TEXT,
  height TEXT,
  employment_date TIMESTAMP WITH TIME ZONE,
  employment_type TEXT NOT NULL DEFAULT 'official',
  position TEXT,
  hourly_rate NUMERIC(10, 2),
  status TEXT NOT NULL DEFAULT 'working',
  facility TEXT,
  passport_series TEXT,
  passport_number TEXT,
  passport_issued_by TEXT,
  passport_issue_date TIMESTAMP WITH TIME ZONE,
  passport_department_code TEXT,
  registration_address TEXT,
  inn TEXT,
  snils TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row-Level Security (RLS)
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

-- Политика для аутентифицированных пользователей: все могут просматривать сотрудников
CREATE POLICY "Users can view employees"
  ON employees FOR SELECT
  USING (auth.role() = 'authenticated');

-- Политика для администраторов: только администраторы могут создавать/обновлять/удалять
CREATE POLICY "Only admins can create employees" 
  ON employees FOR INSERT 
  WITH CHECK (auth.role() = 'authenticated' AND (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Only admins can update employees" 
  ON employees FOR UPDATE 
  USING (auth.role() = 'authenticated' AND (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Only admins can delete employees" 
  ON employees FOR DELETE 
  USING (auth.role() = 'authenticated' AND (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- Индексы для часто используемых полей
CREATE INDEX IF NOT EXISTS idx_employees_name ON employees (last_name, first_name);
CREATE INDEX IF NOT EXISTS idx_employees_status ON employees (status);
CREATE INDEX IF NOT EXISTS idx_employees_position ON employees (position); 