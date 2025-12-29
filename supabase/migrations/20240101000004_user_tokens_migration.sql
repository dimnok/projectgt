-- Create user_tokens table to store FCM tokens per user with RLS
create extension if not exists pgcrypto;

create table if not exists public.user_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('ios','android','web')),
  device_id text,
  device_model text,
  os_version text,
  app_version text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists user_tokens_token_unique on public.user_tokens(token);
create index if not exists user_tokens_user_id_idx on public.user_tokens(user_id);
create index if not exists user_tokens_active_idx on public.user_tokens(is_active);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create or replace trigger user_tokens_set_updated_at
before update on public.user_tokens
for each row execute function public.set_updated_at();

alter table public.user_tokens enable row level security;

drop policy if exists "Users can view own tokens" on public.user_tokens;
drop policy if exists "Users can insert own tokens" on public.user_tokens;
drop policy if exists "Users can update own tokens" on public.user_tokens;
drop policy if exists "Users can delete own tokens" on public.user_tokens;

create policy "Users can view own tokens"
  on public.user_tokens for select
  using (auth.uid() = user_id);

create policy "Users can insert own tokens"
  on public.user_tokens for insert
  with check (auth.uid() = user_id);

create policy "Users can update own tokens"
  on public.user_tokens for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own tokens"
  on public.user_tokens for delete
  using (auth.uid() = user_id);


