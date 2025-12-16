-- Создание типа статуса для КС-2
create type ks2_status as enum ('draft', 'signed', 'paid');

-- Создание таблицы Актов КС-2
create table public.ks2_acts (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid references public.contracts(id) not null,
  number text not null,
  date date not null default current_date,
  period_from date not null,
  period_to date not null,
  status ks2_status not null default 'draft',
  total_amount numeric default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  created_by uuid references auth.users(id)
);

-- Включение RLS
alter table public.ks2_acts enable row level security;

-- Политики доступа (стандартные для authenticated)
create policy "Enable read access for authenticated users" on public.ks2_acts
  for select using (auth.role() = 'authenticated');

create policy "Enable insert for authenticated users" on public.ks2_acts
  for insert with check (auth.role() = 'authenticated');

create policy "Enable update for authenticated users" on public.ks2_acts
  for update using (auth.role() = 'authenticated');

create policy "Enable delete for authenticated users" on public.ks2_acts
  for delete using (auth.role() = 'authenticated');

-- Добавление связи в таблицу работ
alter table public.work_items
add column ks2_id uuid references public.ks2_acts(id);

-- Индексы для быстрого поиска
create index idx_work_items_ks2_id on public.work_items(ks2_id);
create index idx_ks2_acts_contract_id on public.ks2_acts(contract_id);

