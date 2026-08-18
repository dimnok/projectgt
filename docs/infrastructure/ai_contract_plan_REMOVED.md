# 🗑 Удаление модуля «ИИ-план по договору» (AiContractPlan)

**Дата удаления:** 2 августа 2026
**Статус:** ⛔ Удалён из приложения / ⚠️ Функция ещё развёрнута на сервере

---

## 📌 Что было удалено

Из клиентской части (Flutter) полностью вычищены все файлы и ссылки:

- `lib/features/home/presentation/widgets/ai_contract_plan_widget.dart` — виджет центрального блока.
- `lib/features/home/presentation/providers/ai_contract_plan_provider.dart` — Riverpod-провайдер.
- `lib/features/home/domain/entities/ai_contract_plan.dart` — Freezed-модель (+ `.freezed.dart`, `.g.dart`).
- Импорты и карточки-обёртки в `home_desktop_dashboard.dart` и `home_mobile_dashboard.dart`.
- `supabase/functions/analyze-contract-plan/index.ts` — локальная копия Edge Function.
- Прежняя документация `docs/infrastructure/ai_contract_plan.md` (заменена этим файлом-уведомлением).

Причина удаления: блок больше не нужен бизнесу; кроме того, Edge Function падала с ошибкой `OpenRouter API Error: "Access denied by security policy."`.

---

## ⚠️ ВАЖНО: остаток на сервере (требует ручной очистки)

Локально файл функции удалён, **но на self-hosted Supabase (`api.progt.ru`) Edge Function `analyze-contract-plan` всё ещё развёрнута и продолжает работать** при прямом обращении. Её нужно удалить с сервера.

### Что нужно сделать

Удалить функцию на сервере одним из способов:

- Через Supabase CLI (при наличии доступа к self-hosted инстансу):
  ```bash
  supabase functions delete analyze-contract-plan --project-ref <project-ref>
  ```
- Либо вручную через админ-панель Supabase → Edge Functions → `analyze-contract-plan` → Delete.

### Дополнительно (опционально)

После удаления функции можно также убрать больше не нужный секрет, **если** им не пользуется другая функция:

- `OPENROUTER_API_KEY` — **удалён** вместе с функцией `get-daily-tip` (совет дня, 18 августа 2026). Секрет можно убрать из Supabase Secrets, если не используется в других местах.

### Чек-лист очистки сервера

- [ ] Удалить Edge Function `analyze-contract-plan` на `api.progt.ru`.
- [ ] Проверить, что никто больше не обращается к `analyze-contract-plan` (логи Supabase → Edge Functions).
- [ ] (Опционально) Удалить секрет `OPENROUTER_API_KEY` — `get-daily-tip` удалён 18.08.2026.

---

## 📝 История

- **12 мая 2026** — модуль реализован (Edge Function + Flutter-виджет на главной).
- **2 августа 2026** — модуль полностью удалён из приложения; функция на сервере помечена к удалению.
