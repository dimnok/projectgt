-- Подпись пользователя (ФИО) в user_tokens для удобного просмотра в БД.
ALTER TABLE public.user_tokens
  ADD COLUMN IF NOT EXISTS user_display_name text;

COMMENT ON COLUMN public.user_tokens.user_display_name IS
  'Кэш ФИО из profiles (short_name или full_name) на момент сохранения токена';

-- Заполнить существующие активные токены
UPDATE public.user_tokens ut
SET user_display_name = COALESCE(
  NULLIF(trim(p.short_name), ''),
  NULLIF(trim(p.full_name), '')
)
FROM public.profiles p
WHERE p.id = ut.user_id
  AND (ut.user_display_name IS NULL OR ut.user_display_name = '');
