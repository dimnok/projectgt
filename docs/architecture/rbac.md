# Users / Companies / Roles / Permissions (RBAC v3)

## 0) Цель
Единая, расширяемая и безопасная модель доступа для SaaS решения.

---

## 1) Ключевые принципы
1. **Изоляция данных**: Каждая запись принадлежит компании через `company_id`.
2. **Разделение уровней**:
   - Платформа (разработчик через service role).
   - Компания (бизнес-логика).
   - Права (атомарные действия).
3. **Безопасность**: На клиенте нет супер-админов, всё через RLS.

---

## 2) Иерархия и Роли

### 2.1 Системные роли (System Roles)
Определяются полем `system_role` в таблице `company_members`. Не редактируются в UI:
- **Owner**: Владелец компании (1 чел). Полный доступ + опасные операции (биллинг, удаление).
- **Admin**: Администратор (макс 2 чел). Полный доступ к модулям, но не может удалить компанию или владельца.

### 2.2 Кастомные роли (Custom Roles)
Создаются владельцем в таблице `roles`. Роль = набор прав (Permissions). Привязываются через `role_id` в `company_members`.

### 2.3 Права (Permissions)
Формат: `module.action.scope` (например, `contracts.read.all`).
- **Scope (Область):**
  - `all` — вся компания.
  - `object` — только свои объекты.
  - `own` — только свои записи.

---

## 3) Безопасность и RLS (Технически)

Для изоляции данных используется функция `SECURITY DEFINER`, разрывающая рекурсию:

```sql
CREATE OR REPLACE FUNCTION public.get_my_company_ids()
RETURNS TABLE (company_id UUID) AS $$
BEGIN
    RETURN QUERY
    SELECT cm.company_id 
    FROM public.company_members cm 
    WHERE cm.user_id = auth.uid() AND cm.is_active = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Применение в политиках:**
```sql
-- Для обычных таблиц (с company_id)
USING (company_id IN (SELECT public.get_my_company_ids()))

-- Для таблицы profiles (без company_id)
USING (
  id = auth.uid() 
  OR 
  id IN (
    SELECT cm.user_id FROM company_members cm 
    WHERE cm.company_id IN (SELECT company_id FROM company_members WHERE user_id = auth.uid())
  )
)
```

---

## 4) Инструкция по подключению нового модуля

При создании новой таблицы/фичи:

1. **БД:** Добавить `company_id UUID REFERENCES companies(id) NOT NULL`.
2. **RLS:** Включить RLS и применить политику через `get_my_company_ids()`.
3. **Domain:** Добавить `companyId` в Entity.
4. **Data:** 
   - Обновить Model (JSON mapping).
   - В Repository всегда добавлять `.eq('company_id', activeCompanyId)`.
5. **Presentation:** Получать `activeCompanyId` из Riverpod провайдера.

---

## 5) Ограничения (Инварианты)
- **Нельзя остаться без Owner**: передача прав только через атомарную Edge Function.
- **Лимит Admin**: проверка при назначении (по умолчанию макс 2).
- **Запрет эскалации**: пользователь не может назначить роль выше своей.
- **Управление участниками**: Обновление ролей и статуса (is_active) производится в таблице `company_members` Владельцем или Админом компании. Напрямую через таблицу `profiles` эти поля больше не обновляются.

Подробная документация по БД: `docs/database_structure.md`
