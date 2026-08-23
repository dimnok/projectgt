# 🗑 Удаление модуля «ИИ-план по договору» (AiContractPlan)

**Дата удаления из приложения:** 2 августа 2026  
**Дата удаления с сервера:** 23 августа 2026  
**Статус:** ⛔ Удалён из приложения и с сервера

---

## 📌 Что было удалено

Из клиентской части (Flutter) полностью вычищены все файлы и ссылки (2 августа 2026):

- `lib/features/home/presentation/widgets/ai_contract_plan_widget.dart` — виджет центрального блока.
- `lib/features/home/presentation/providers/ai_contract_plan_provider.dart` — Riverpod-провайдер.
- `lib/features/home/domain/entities/ai_contract_plan.dart` — Freezed-модель (+ `.freezed.dart`, `.g.dart`).
- Импорты и карточки-обёртки в `home_desktop_dashboard.dart` и `home_mobile_dashboard.dart`.
- `supabase/functions/analyze-contract-plan/index.ts` — локальная копия Edge Function.
- Прежняя документация `docs/infrastructure/ai_contract_plan.md` (заменена этим файлом-уведомлением).

С self-hosted Supabase (`api.progt.ru`) 23 августа 2026 удалена папка Edge Function `analyze-contract-plan`. Сервис `functions` перезапущен.

Причина удаления: блок больше не нужен бизнесу; кроме того, Edge Function падала с ошибкой `OpenRouter API Error: "Access denied by security policy."`.

---

## Чек-лист очистки

- [x] Удалить модуль из приложения (2.08.2026).
- [x] Удалить локальную копию Edge Function (2.08.2026).
- [x] Удалить Edge Function `analyze-contract-plan` на `api.progt.ru` (23.08.2026).
- [x] Удалить Edge Function `get-daily-tip` на `api.progt.ru` (23.08.2026).
- [ ] (Опционально) Удалить секрет `OPENROUTER_API_KEY` — после снятия `analyze-contract-plan` и `get-daily-tip` больше ни одна функция на сервере его не читает.

---

## 📝 История

- **12 мая 2026** — модуль реализован (Edge Function + Flutter-виджет на главной).
- **2 августа 2026** — модуль полностью удалён из приложения; функция на сервере помечена к удалению.
- **23 августа 2026** — функция удалена с сервера.
