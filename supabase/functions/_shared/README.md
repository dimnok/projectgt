# Общий код Edge Functions

На self-hosted Supabase в рантайм попадает **только содержимое папки конкретной функции** (`ks2_operations/`, `export-ks2-form-header/` и т.д.).

Импорты вида `../_shared/...` **не работают** после деплоя.

Общие модули дублируйте внутрь каждой функции (например `ks2_preview.ts` в `ks2_operations/` и `export-ks2-form-header/`) и подключайте как `./ks2_preview.ts`.
