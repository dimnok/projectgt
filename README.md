# ProjectGT

**Многофункциональное Flutter-приложение для управления строительными проектами.**  
Clean Architecture, Supabase, строгий минимализм, поддержка iOS/Android/Web.

---

## 📖 Оглавление

- [Описание](#описание)
- [Архитектура и принципы](#архитектура-и-принципы)
- [Структура проекта](#структура-проекта)
- [Модули](#модули)
- [Технологии и зависимости](#технологии-и-зависимости)
- [Правила и стандарты](#правила-и-стандарты)
- [Инструкции по запуску](#инструкции-по-запуску)
- [Документация и ссылки](#документация-и-ссылки)
- [Контакты и поддержка](#контакты-и-поддержка)
- [Примечания](#примечания)

---

## 📝 Описание

ProjectGT — современное Flutter-приложение для автоматизации строительных и подрядных процессов. Использует Supabase как backend, реализует Clean Architecture, поддерживает строгий чёрно-белый минимализм, светлую и тёмную тему, кроссплатформенность (iOS, Android, Web).

---

## 🧱 Архитектура и принципы

- **Clean Architecture**: разделение на слои (domain, data, presentation, features, core)
- **Riverpod**: управление состоянием и DI
- **Freezed**: иммутабельные модели
- **Supabase**: backend, аутентификация, хранение файлов, RLS
- **PlutoGrid**: работа с таблицами
- **Адаптивный UI**: поддержка всех платформ

Подробнее: [docs/architecture.md](docs/architecture.md)

---

## 🗂️ Структура проекта

<details>
<summary>lib/</summary>

- **core/** — общие компоненты, DI, утилиты ([docs/architecture.md](docs/architecture.md))
- **data/** — источники данных, модели, репозитории, миграции ([docs/architecture.md](docs/architecture.md))
- **domain/** — бизнес-сущности, интерфейсы репозиториев, usecases ([docs/architecture.md](docs/architecture.md))
- **features/** — функциональные модули (auth, employees, contractors, contracts, objects, estimates, works, fot, timesheet, profile)
- **presentation/** — глобальные состояния, темы, виджеты
</details>

<details>
<summary>docs/</summary>

- [README.md](docs/README.md) — оглавление и навигация по документации
- [architecture.md](docs/architecture.md) — архитектура и структура
- [tech_stack.md](docs/tech_stack.md) — используемые технологии
- [development_guide.md](docs/development_guide.md) — рекомендации по стилю, UI/UX, best practices
- [auth_system.md](docs/auth_system.md) — аутентификация и профили
- [api_reference.md](docs/api_reference.md) — справочник по API и провайдерам
- [database_structure.md](docs/database_structure.md) — структура БД Supabase
- [contractors_module.md](docs/contractors_module.md) — модуль контрагентов
- [contracts_module.md](docs/contracts_module.md) — модуль договоров
- [employees_module.md](docs/employees_module.md) — модуль сотрудников
- [estimates_module.md](docs/estimates_module.md) — модуль смет
- [fot_module.md](docs/fot_module.md) — модуль ФОТ (payroll)
- [objects_module.md](docs/objects_module.md) — модуль объектов
- [profile_module.md](docs/profile_module.md) — модуль профиля
- [works_module.md](docs/works_module.md) — модуль смен/работ
- [timesheet_module.md](docs/timesheet_module.md) — модуль табеля
- [works_bucket_policy.sql](docs/works_bucket_policy.sql) — политики доступа к фото смен
</details>

---

## 🧩 Модули

- **Контрагенты** ([docs/contractors_module.md](docs/contractors_module.md)): управление юридическими лицами, интеграция с договорами.
- **Договоры** ([docs/contracts_module.md](docs/contracts_module.md)): учёт договоров, связи с объектами и контрагентами.
- **Сотрудники** ([docs/employees_module.md](docs/employees_module.md)): кадровый учёт, мультивыбор объектов, загрузка фото.
- **Сметы** ([docs/estimates_module.md](docs/estimates_module.md)): импорт/экспорт Excel, детализация по позициям.
- **ФОТ** ([docs/fot_module.md](docs/fot_module.md)): расчёт зарплаты, премии, штрафы, выплаты.
- **Объекты** ([docs/objects_module.md](docs/objects_module.md)): управление строительными объектами, командировочные.
- **Профиль** ([docs/profile_module.md](docs/profile_module.md)): роли, аватар, интеграция с Supabase Auth.
- **Смены/Работы** ([docs/works_module.md](docs/works_module.md)): учёт смен, работ, материалов, часов.
- **Табель** ([docs/timesheet_module.md](docs/timesheet_module.md)): аналитика по отработанным часам, интеграция с другими модулями.

---

## ⚙️ Технологии и зависимости

- **Flutter** (>=3.0.0)
- **Dart** (>=3.0.0)
- **supabase_flutter**
- **riverpod, hooks_riverpod**
- **freezed, json_serializable**
- **go_router**
- **pluto_grid**
- **excel, csv, file_picker**
- **flutter_svg, flutter_dotenv, logger**

Подробнее: [docs/tech_stack.md](docs/tech_stack.md)

---

## 📝 Правила и стандарты

- **Clean Architecture**: строгое разделение слоёв, DI через Riverpod.
- **UI/UX**: строгий чёрно-белый минимализм, поддержка светлой/тёмной темы, Semantics, адаптивность.
- **Работа с БД**: все операции через слой data, миграции в data/migrations, Supabase RLS.
- **Тестирование**: покрытие бизнес-логики и интеграций, тесты в test/.
- **Безопасность**: RLS, хранение ключей только в .env, не коммитить секреты.
- **CI/CD**: поддержка автогенерации моделей, линтинг, профилирование.
- **Документация**: поддерживать docs/ в актуальном состоянии, ссылки на все модули и схемы.

**Best practices и подробности:**  
- [docs/development_guide.md](docs/development_guide.md)  
- [docs/architecture.md](docs/architecture.md)

---

## 🚀 Инструкции по запуску

1. **Установка зависимостей**
   ```bash
   flutter pub get
   ```

2. **Генерация моделей**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Настройка .env**
   - Скопируйте `.env.example` → `.env`
   - Укажите свои ключи Supabase

4. **Запуск приложения**
   ```bash
   flutter run
   ```

5. **Генерация документации**
   ```bash
   ./tools/generate_docs.sh
   # Открыть docs/api/index.html в браузере
   ```

---

## 📚 Документация и ссылки

- [Полная документация (docs/README.md)](docs/README.md)
- [Архитектура](docs/architecture.md)
- [Технологический стек](docs/tech_stack.md)
- [Руководство по разработке](docs/development_guide.md)
- [Система аутентификации](docs/auth_system.md)
- [API Reference](docs/api_reference.md)
- [Структура БД](docs/database_structure.md)
- [Модули](#модули)
- [Политики хранения фото смен](docs/works_bucket_policy.sql)

---

## 🧑‍💻 Контакты и поддержка

- Вопросы и предложения — через Issues или Pull Requests.
- Для новых разработчиков — обязательно изучить [docs/README.md](docs/README.md) и [docs/development_guide.md](docs/development_guide.md) перед началом работы.

---

## 🏷️ Примечания

- Все автогенерируемые файлы (`*.g.dart`, `*.freezed.dart`) не коммитятся.
- SQL-миграции — в `lib/data/migrations/`.
- Для расширения — добавляйте новые модули по аналогии с существующими.

---

**Весь проект документирован и поддерживается в актуальном состоянии.  
Для любого вопроса — см. раздел "Документация и ссылки".**
