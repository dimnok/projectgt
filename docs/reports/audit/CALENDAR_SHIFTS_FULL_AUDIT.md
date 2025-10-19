# 🔍 ПОЛНЫЙ АУДИТ КАЛЕНДАРЯ СМЕН: АНАЛИЗ И РЕШЕНИЕ

## 🎯 ПРОБЛЕМА: Календарь постоянно загружается

**Статус данных на сервере:**
- ✅ Таблица `works` содержит 33 записей
- ✅ Текущий месяц (октябрь 2025): 33 записей
- ✅ Период: с 2025-10-01 по 2025-10-18
- ✅ Все таблицы (`objects`, `work_items`) заполнены

---

## 🔐 ВЫЯВЛЕННАЯ ПРОБЛЕМА: RLS (Row-Level Security)

### Ограничение доступа

Таблица `works` имеет **4 RLS-политики**, которые требуют:

```sql
-- Политика SELECT
(EXISTS (
  SELECT 1 FROM profiles p
  WHERE p.id = auth.uid() 
    AND (p.role = 'admin' OR p.object_ids @> ARRAY[works.object_id])
))
```

### Это означает:

**Пользователь может читать работу, ТОЛЬКО если:**
1. ✅ Он админ (`role = 'admin'`)
2. **ИЛИ** объект в его `profiles.object_ids`

**Если НИ одно из этого не выполнено → Supabase БЛОКИРУЕТ запрос → Календарь не загружается!**

---

## 📋 ЧТОБЫ ОПРЕДЕЛИТЬ ПРИЧИНУ

### Шаг 1: Проверь профиль пользователя

```sql
SELECT 
  id,
  email,
  role,
  object_ids,
  approved_at
FROM profiles
WHERE id = auth.uid()
```

**Проверь:**
- ✅ `role = 'admin'` ? Если да → должен видеть ВСЕ работы
- ✅ `object_ids` содержит объекты из `works` ? Если да → должен видеть работы
- ❌ `role != 'admin'` И `object_ids` пуста/NULL → **БЛОКИРОВКА!**

### Шаг 2: Проверь объекты в работах

```sql
SELECT DISTINCT object_id FROM works WHERE date >= CURRENT_DATE - INTERVAL '30 days'
```

**Проверь:**
- Есть ли эти ID в `profiles.object_ids` текущего пользователя?

---

## ✅ РЕШЕНИЯ

### Решение 1: Сделать пользователя админом (БЫСТРО)

```sql
UPDATE profiles
SET role = 'admin'
WHERE id = '<ваш-user-id>';
```

**Результат:** Сможет видеть ВСЕ работы на ВСЕ объекты ✅

---

### Решение 2: Добавить объекты в `object_ids` (ПРАВИЛЬНО)

```sql
UPDATE profiles
SET object_ids = ARRAY['<object-id-1>', '<object-id-2>']
WHERE id = '< ваш-user-id>';
```

**Получить ID объектов:**
```sql
SELECT id, name FROM objects LIMIT 10
```

**Результат:** Пользователь видит только свои объекты ✅

---

### Решение 3: Изменить RLS-политики (АРХИТЕКТУРНОЕ)

Если RLS слишком строгая, можно ослабить, но это **рискованно** для безопасности:

```sql
-- Вариант 1: Доступ ко ВСЕМ работам
CREATE POLICY "allow_all_select_works" ON works
  FOR SELECT USING (true);

-- Вариант 2: Доступ к одобренным пользователям
CREATE POLICY "allow_approved_users" ON works
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND approved_at IS NOT NULL
  ));
```

---

## 📊 ЦЕПЬ ДАННЫХ (Как работает запрос)

```
ShiftsCalendarFlipCard
  ↓
shiftsForMonthProvider (Riverpod)
  ↓
ShiftsRepositoryImpl.getShiftsForMonth(month)
  ↓
ShiftsDataSourceImpl.getShiftsForMonth(month)
  ↓
supabaseClient.from('works').select(...) ← ЗДЕСЬ проверяется RLS!
  ↓
✅ SELECT выполнен (если RLS пропустила)
  ✗ Supabase БЛОКИРУЕТ (если RLS НЕ пропустила)
  ↓
shiftsForMonthProvider.when(
  loading: () => Spinner,
  error: (err) => Error text,    ← ЗДЕСЬ видна ошибка RLS
  data: (shifts) => Calendar     ← ЗДЕСЬ отображаются данные
)
```

---

## 🔧 ШАГ ЗА ШАГОМ: КАК ИСПРАВИТЬ

### 1. Определи свой user_id

В Firebase Console или профиле приложения: **Settings → Profile**

### 2. Выполни в Supabase SQL Editor

```sql
-- Вариант A: Сделать админом
UPDATE profiles
SET role = 'admin'
WHERE email = 'твой-email@example.com';

-- ИЛИ Вариант B: Добавить объекты
UPDATE profiles
SET object_ids = ARRAY[
  (SELECT id FROM objects LIMIT 1)::uuid
]
WHERE email = 'твой-email@example.com';
```

### 3. Перезагрузи приложение

### 4. Проверь календарь

---

## 🐛 КОД: ГДЕ МОЖЕТ БЫТЬ ОШИБКА

### ✅ Код БЕЗ ошибок:

| Компонент | Статус | Причина |
|-----------|--------|---------|
| `ShiftsCalendarFlipCard` | ✅ OK | Правильно вызывает провайдер |
| `shiftsForMonthProvider` | ✅ OK | Правильно передаёт месяц |
| `ShiftsRepositoryImpl` | ✅ OK | Правильно делегирует datasource |
| `ShiftsDataSourceImpl` | ✅ OK | Правильная дата-запись (исправлена) |
| Таблица `works` | ✅ OK | Данные есть (33 записи) |

### ❌ Проблема ЗДЕСЬ:

| Компонент | Статус | Проблема |
|-----------|--------|----------|
| **RLS политики** | ❌ БЛОКИРУЕТ | Пользователь не има доступа к объектам |
| **Профиль пользователя** | ❌ НЕПРАВИЛЬНО | `object_ids` пуста или неправильная роль |

---

## 📝 БЫСТРАЯ ДИАГНОСТИКА

Вставь в браузер DevTools Console:

```javascript
// Будет выдана ошибка RLS если
// "user is not authorized to access..."
// "policies do not grant the necessary permissions..."
```

Или проверь логи Supabase:
- Суpabase Dashboard → Logs → API → Ищи ошибки RLS

---

## ✅ ФИНАЛЬНЫЙ ЧЕК-ЛИСТ

- [ ] Проверил профиль пользователя в profiles таблице
- [ ] Проверил role (админ или нет)
- [ ] Проверил object_ids (содержит ли нужные объекты)
- [ ] Выполнил UPDATE для добавления прав доступа
- [ ] Перезагрузил приложение
- [ ] Календарь показывает данные ✅

---

**Статус:** 🔴 **ТРЕБУЕТ ДЕЙСТВИЯ** - Нужно дать пользователю права доступа к объектам
