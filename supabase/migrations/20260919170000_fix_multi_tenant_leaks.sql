-- Закрытие утечек данных между компаниями (multi-tenant изоляция).
--
-- Что исправляется:
--   1. Представления отдавали строки ВСЕХ компаний (созданы «от имени владельца»)
--      и были доступны анонимно. Добавляем фильтр по компаниям пользователя;
--      служебный доступ (service_role) сохранён для серверных выгрузок.
--   2. Таблицы receipts, company_bank_accounts, company_documents имели правила,
--      разрешавшие доступ всем вошедшим. Удаляем их — остаются правила «по своей компании».
--   3. purchase_request_number_seq была без защиты. Включаем RLS и убираем права.
--
-- Миграция идемпотентна: повторный запуск ничего не ломает.

-- =====================================================================
-- 1. Представления: фильтр по компаниям пользователя + закрытие анонима
-- =====================================================================

revoke all on public.estimates_with_contracts from anon;
revoke all on public.v_kit_components_detailed from anon;
revoke all on public.v_materials_grouped_by_estimate from anon;
revoke all on public.v_materials_with_usage from anon;
revoke all on public.v_work_items_expanded from anon;

do $$
declare
  v_views text[] := array[
    'estimates_with_contracts',
    'v_kit_components_detailed',
    'v_materials_grouped_by_estimate',
    'v_materials_with_usage',
    'v_work_items_expanded'
  ];
  v_name text;
  v_def text;
  v_sql text;
begin
  foreach v_name in array v_views loop
    select pg_get_viewdef(format('public.%I', v_name)::regclass, true) into v_def;
    v_def := btrim(v_def);
    if right(v_def, 1) = ';' then
      v_def := rtrim(left(v_def, length(v_def) - 1));
    end if;

    -- уже обёрнуто ранее — пропускаем
    if position('get_my_company_ids' in v_def) > 0 then
      continue;
    end if;

    v_sql := format(
      'create or replace view public.%I as select * from (%s) as src '
      'where auth.role() = ''service_role'' '
      'or src.company_id in (select company_id from public.get_my_company_ids())',
      v_name, v_def
    );
    execute v_sql;
  end loop;
end $$;

-- =====================================================================
-- 2. Удаление правил «доступ всем вошедшим»
-- =====================================================================

drop policy if exists "receipts_select" on public.receipts;
drop policy if exists "receipts_insert" on public.receipts;

drop policy if exists "Allow read for all authorized users" on public.company_bank_accounts;
drop policy if exists "Allow insert for all authorized users" on public.company_bank_accounts;
drop policy if exists "Allow update for all authorized users" on public.company_bank_accounts;
drop policy if exists "Allow delete for all authorized users" on public.company_bank_accounts;

drop policy if exists "Allow read for all authorized users" on public.company_documents;
drop policy if exists "Allow insert for all authorized users" on public.company_documents;
drop policy if exists "Allow update for all authorized users" on public.company_documents;
drop policy if exists "Allow delete for all authorized users" on public.company_documents;

-- =====================================================================
-- 3. Счётчик номеров заявок: включаем защиту
-- =====================================================================

alter table public.purchase_request_number_seq enable row level security;
revoke all on public.purchase_request_number_seq from anon, authenticated;
