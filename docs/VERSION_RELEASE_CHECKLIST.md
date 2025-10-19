# ✅ Чек-лист релиза версии

**Дата создания:** 16 октября 2025

---

## 🚀 КАК ВЫПУСТИТЬ НОВУЮ ВЕРСИЮ

### Способ 1️⃣: АВТОМАТИЧЕСКИЙ (рекомендуется)

```bash
# 1. Обнови версию в pubspec.yaml
nano pubspec.yaml
# Измени: version: 1.0.3+23 → version: 1.0.4+24

# 2. Запусти скрипт синхронизации
bash scripts/update_version.sh

# Готово! Скрипт обновит 3 места одновременно:
# ✅ app_constants.dart (1.0.4)
# ✅ app_versions в БД (1.0.4)
# Сохранит время и ошибки!
```

**Что делает скрипт:**
- Парсит версию из `pubspec.yaml`
- Обновляет `lib/core/constants/app_constants.dart`
- Обновляет `current_version` в БД через Supabase
- Показывает результат с проверкой

---

### Способ 2️⃣: РУЧНОЙ (если скрипт не работает)

**Шаг 1:** Обнови `pubspec.yaml`
```yaml
version: 1.0.4+24  # Было: 1.0.3+23
```

**Шаг 2:** Обнови `lib/core/constants/app_constants.dart`
```dart
static const String appVersion = '1.0.4';  // Было: 1.0.3
```

**Шаг 3:** Обнови БД вручную
```sql
UPDATE app_versions 
SET current_version = '1.0.4',
    updated_at = now()
WHERE id = '383c87f5-11b5-4d6f-8074-ca8fda7c1bc6';
```

---

## ⚠️ ВАЖНО: ЧТО ПРОИЗОЙДЕТ?

### ❌ ЕСЛИ НЕ СИНХРОНИЗИРОВАТЬ:
```
pubspec.yaml:            1.0.4
app_constants.dart:      1.0.3 ❌ УСТАРЕЛА!
БД current_version:      1.0.3 ❌ УСТАРЕЛА!

Результат: Пользователи 1.0.3 будут ЗАБЛОКИРОВАНЫ!
```

### ✅ ЕСЛИ СИНХРОНИЗИРОВАТЬ:
```
pubspec.yaml:            1.0.4
app_constants.dart:      1.0.4 ✅
БД current_version:      1.0.4 ✅

Результат: Все работает правильно!
```

---

## 🔄 АВТОМАТИЗАЦИЯ С GIT HOOKS

Добавь скрипт в git hook чтобы не забывать:

```bash
# Создать pre-commit hook
mkdir -p .git/hooks

cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Проверяем если изменилась версия в pubspec.yaml
if git diff --cached pubspec.yaml | grep -q "^+version:"; then
    echo "⚠️  Обнаружено изменение версии в pubspec.yaml"
    echo "Запусти: bash scripts/update_version.sh"
    exit 1
fi
EOF

chmod +x .git/hooks/pre-commit
```

---

## 📋 ПОЛНЫЙ ЧЕК-ЛИСТ РЕЛИЗА

- [ ] Убедитесь что все баги исправлены
- [ ] Протестируйте на двух устройствах
- [ ] Обновите версию в `pubspec.yaml`: `1.0.X+YY`
- [ ] Запустите скрипт: `bash scripts/update_version.sh`
- [ ] Проверьте что все 3 места обновлены:
  - [ ] `app_constants.dart` (версия совпадает)
  - [ ] БД `app_versions.current_version` (версия совпадает)
- [ ] Закоммитьте изменения: `git add . && git commit -m "Release v1.0.X"`
- [ ] Создайте GitHub Release с тегом: `v1.0.X`
- [ ] Выгрузите на App Store / Google Play / Web
- [ ] Установите `minimum_version` если нужна блокировка
- [ ] Отправьте уведомление команде

---

## 💡 СОВЕТЫ

**Q: Когда обновлять `minimum_version`?**
- Когда нашли критический баг
- Когда старая версия несовместима с новой логикой
- Обычно НЕ нужно обновлять при обычном релизе

**Q: `current_version` vs `minimum_version`?**
- `current_version` — информационная, показывает последнюю доступную
- `minimum_version` — блокирует версии ниже этого значения

**Q: Скрипт не работает?**
- Проверьте что supabase CLI установлена: `supabase --version`
- Или обновите вручную по Способу 2️⃣

---

**Последнее обновление:** 16 октября 2025
**Статус:** ✅ Готово к использованию
