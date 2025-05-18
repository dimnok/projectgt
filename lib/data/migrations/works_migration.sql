-- Миграция для создания таблиц модуля работ (works)

-- Таблица для смен (works)
CREATE TABLE IF NOT EXISTS works (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  object_id UUID REFERENCES objects(id),
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Таблица для работ в смене (work_items)
CREATE TABLE IF NOT EXISTS work_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  work_id UUID NOT NULL REFERENCES works(id) ON DELETE CASCADE,
  section TEXT NOT NULL,
  floor TEXT NOT NULL,
  estimate_id UUID REFERENCES estimates(id),
  name TEXT NOT NULL,
  system TEXT NOT NULL,
  subsystem TEXT NOT NULL,
  unit TEXT NOT NULL,
  quantity NUMERIC NOT NULL,
  price NUMERIC,
  total NUMERIC,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Таблица для материалов в смене (work_materials)
CREATE TABLE IF NOT EXISTS work_materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  work_id UUID NOT NULL REFERENCES works(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  unit TEXT NOT NULL,
  quantity NUMERIC NOT NULL,
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Таблица для часов сотрудников в смене (work_hours)
CREATE TABLE IF NOT EXISTS work_hours (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  work_id UUID NOT NULL REFERENCES works(id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES employees(id),
  hours NUMERIC NOT NULL,
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row-Level Security (RLS)
ALTER TABLE works ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_hours ENABLE ROW LEVEL SECURITY;

-- RLS-политики для таблицы works
CREATE POLICY "Users can view works"
  ON works FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert works"
  ON works FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update their works"
  ON works FOR UPDATE
  USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete their works"
  ON works FOR DELETE
  USING (auth.role() = 'authenticated');

-- RLS-политики для таблицы work_items
CREATE POLICY "Users can view work_items"
  ON work_items FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert work_items"
  ON work_items FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update their work_items"
  ON work_items FOR UPDATE
  USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete their work_items"
  ON work_items FOR DELETE
  USING (auth.role() = 'authenticated');

-- RLS-политики для таблицы work_materials
CREATE POLICY "Users can view work_materials"
  ON work_materials FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert work_materials"
  ON work_materials FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update their work_materials"
  ON work_materials FOR UPDATE
  USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete their work_materials"
  ON work_materials FOR DELETE
  USING (auth.role() = 'authenticated');

-- RLS-политики для таблицы work_hours
CREATE POLICY "Users can view work_hours"
  ON work_hours FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert work_hours"
  ON work_hours FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update their work_hours"
  ON work_hours FOR UPDATE
  USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete their work_hours"
  ON work_hours FOR DELETE
  USING (auth.role() = 'authenticated');

-- Индексы для оптимизации запросов
CREATE INDEX IF NOT EXISTS work_items_work_id_idx ON work_items(work_id);
CREATE INDEX IF NOT EXISTS work_materials_work_id_idx ON work_materials(work_id);
CREATE INDEX IF NOT EXISTS work_hours_work_id_idx ON work_hours(work_id);
CREATE INDEX IF NOT EXISTS work_hours_employee_id_idx ON work_hours(employee_id); 