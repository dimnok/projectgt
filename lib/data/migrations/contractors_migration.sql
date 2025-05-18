-- Миграция для таблицы contractors
create table if not exists contractors (
  id uuid primary key default gen_random_uuid(),
  logo_url text,
  full_name text not null,
  short_name text not null,
  inn text not null,
  director text not null,
  legal_address text not null,
  actual_address text not null,
  phone text not null,
  email text not null,
  type text not null check (type in ('customer', 'contractor', 'supplier')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists contractors_full_name_idx on contractors(full_name);
create index if not exists contractors_inn_idx on contractors(inn);

-- RLS политика (пример: только авторизованные могут читать)
alter table contractors enable row level security;
create policy "Allow read for authenticated" on contractors for select using (auth.role() = 'authenticated');
create policy "Allow insert for authenticated" on contractors for insert with check (auth.role() = 'authenticated');
create policy "Allow update for authenticated" on contractors for update using (auth.role() = 'authenticated');
create policy "Allow delete for authenticated" on contractors for delete using (auth.role() = 'authenticated'); 