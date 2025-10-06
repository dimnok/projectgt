-- Создание таблицы версий приложения (единая версия для всех платформ)
CREATE TABLE IF NOT EXISTS app_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  current_version TEXT NOT NULL,
  minimum_version TEXT NOT NULL,
  force_update BOOLEAN DEFAULT false,
  update_message TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Комментарии для документации
COMMENT ON TABLE app_versions IS 'Управление версиями приложения (единая версия для всех платформ)';
COMMENT ON COLUMN app_versions.current_version IS 'Текущая последняя версия приложения';
COMMENT ON COLUMN app_versions.minimum_version IS 'Минимальная поддерживаемая версия';
COMMENT ON COLUMN app_versions.force_update IS 'Принудительное обновление включено';
COMMENT ON COLUMN app_versions.update_message IS 'Сообщение для пользователя об обновлении';

-- RLS политики
ALTER TABLE app_versions ENABLE ROW LEVEL SECURITY;

-- Все аутентифицированные пользователи могут читать версию
CREATE POLICY "Все могут читать версию приложения"
  ON app_versions FOR SELECT
  TO authenticated
  USING (true);

-- Только администраторы могут изменять версию (проверка через таблицу profiles)
CREATE POLICY "Только админы могут изменять версию"
  ON app_versions FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Начальные данные (одна запись для всех платформ)
INSERT INTO app_versions (current_version, minimum_version, force_update, update_message)
VALUES ('1.0.1', '1.0.1', false, 'Пожалуйста, обновите приложение до последней версии')
ON CONFLICT DO NOTHING;

-- Включить Realtime для таблицы
ALTER PUBLICATION supabase_realtime ADD TABLE app_versions;
