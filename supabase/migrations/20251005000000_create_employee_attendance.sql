-- Миграция: Создание таблицы для учёта рабочего времени сотрудников вне смен
-- Дата: 05.10.2025
-- Описание: Таблица для учёта постоянного персонала объектов и офисных сотрудников

-- Создание таблицы employee_attendance
CREATE TABLE IF NOT EXISTS employee_attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  object_id UUID NOT NULL REFERENCES objects(id) ON DELETE RESTRICT,
  date DATE NOT NULL,
  hours NUMERIC NOT NULL DEFAULT 8 CHECK (hours >= 0 AND hours <= 24),
  attendance_type TEXT NOT NULL DEFAULT 'work' CHECK (attendance_type IN ('work', 'vacation', 'sick_leave', 'business_trip', 'day_off')),
  comment TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Уникальный индекс: один сотрудник - одна запись в день на объекте
  CONSTRAINT unique_employee_object_date UNIQUE(employee_id, object_id, date)
);

-- Индексы для быстрого поиска
CREATE INDEX IF NOT EXISTS idx_employee_attendance_employee ON employee_attendance(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_attendance_object ON employee_attendance(object_id);
CREATE INDEX IF NOT EXISTS idx_employee_attendance_date ON employee_attendance(date);
CREATE INDEX IF NOT EXISTS idx_employee_attendance_type ON employee_attendance(attendance_type);
CREATE INDEX IF NOT EXISTS idx_employee_attendance_employee_date ON employee_attendance(employee_id, date);

-- Комментарии
COMMENT ON TABLE employee_attendance IS 'Учёт рабочего времени сотрудников вне смен: постоянный персонал объектов, офисные сотрудники. Расходы на ФОТ учитываются по объектам.';
COMMENT ON COLUMN employee_attendance.employee_id IS 'ID сотрудника';
COMMENT ON COLUMN employee_attendance.object_id IS 'ID объекта (включая служебные: Офис, Склад)';
COMMENT ON COLUMN employee_attendance.date IS 'Дата работы';
COMMENT ON COLUMN employee_attendance.hours IS 'Количество отработанных часов (0-24)';
COMMENT ON COLUMN employee_attendance.attendance_type IS 'Тип посещаемости: work (работа), vacation (отпуск), sick_leave (больничный), business_trip (командировка), day_off (выходной)';
COMMENT ON COLUMN employee_attendance.comment IS 'Комментарий к записи';
COMMENT ON COLUMN employee_attendance.created_by IS 'Кто создал запись';

-- Триггер для автоматического обновления updated_at
CREATE TRIGGER update_employee_attendance_updated_at
  BEFORE UPDATE ON employee_attendance
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Включаем RLS
ALTER TABLE employee_attendance ENABLE ROW LEVEL SECURITY;

-- Политика: Админы видят все записи
CREATE POLICY "Admins can view all attendance records"
  ON employee_attendance FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Политика: Пользователи видят записи для своих объектов
CREATE POLICY "Users can view attendance for their objects"
  ON employee_attendance FOR SELECT
  USING (
    object_id = ANY(
      SELECT unnest(object_ids) FROM profiles WHERE id = auth.uid()
    )
  );

-- Политика: Пользователи видят свои собственные записи
CREATE POLICY "Users can view their own attendance"
  ON employee_attendance FOR SELECT
  USING (
    employee_id IN (
      SELECT e.id FROM employees e
      WHERE EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid()
        AND p.employee_id = e.id
      )
    )
  );

-- Политика: Админы и ответственные за объекты могут создавать записи
CREATE POLICY "Admins and object managers can insert attendance"
  ON employee_attendance FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND (
        profiles.role = 'admin'
        OR object_id = ANY(profiles.object_ids)
      )
    )
  );

-- Политика: Админы и ответственные за объекты могут обновлять записи
CREATE POLICY "Admins and object managers can update attendance"
  ON employee_attendance FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND (
        profiles.role = 'admin'
        OR object_id = ANY(profiles.object_ids)
      )
    )
  );

-- Политика: Только админы могут удалять записи
CREATE POLICY "Only admins can delete attendance"
  ON employee_attendance FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Функция для массового заполнения рабочих дней
CREATE OR REPLACE FUNCTION fill_employee_attendance(
  p_employee_id UUID,
  p_object_id UUID,
  p_start_date DATE,
  p_end_date DATE,
  p_hours NUMERIC DEFAULT 8,
  p_skip_weekends BOOLEAN DEFAULT TRUE,
  p_created_by UUID DEFAULT auth.uid()
)
RETURNS INTEGER AS $$
DECLARE
  v_date DATE;
  v_count INTEGER := 0;
BEGIN
  v_date := p_start_date;
  
  WHILE v_date <= p_end_date LOOP
    -- Пропускаем выходные, если указано
    IF p_skip_weekends AND EXTRACT(DOW FROM v_date) IN (0, 6) THEN
      v_date := v_date + 1;
      CONTINUE;
    END IF;
    
    -- Вставляем запись (игнорируем, если уже существует)
    INSERT INTO employee_attendance (
      employee_id, 
      object_id, 
      date, 
      hours, 
      attendance_type,
      created_by
    )
    VALUES (
      p_employee_id, 
      p_object_id, 
      v_date, 
      p_hours, 
      'work',
      p_created_by
    )
    ON CONFLICT (employee_id, object_id, date) DO NOTHING;
    
    v_count := v_count + 1;
    v_date := v_date + 1;
  END LOOP;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION fill_employee_attendance IS 'Автоматическое заполнение рабочих дней для сотрудника на указанном объекте в диапазоне дат. Возвращает количество созданных записей.';

