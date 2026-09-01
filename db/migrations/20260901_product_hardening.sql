begin;

alter table if exists public.users
  add column if not exists system_role varchar(16) not null default 'USER',
  add column if not exists account_status varchar(16) not null default 'ACTIVE';

create table if not exists public.auth_refresh_tokens (
  id uuid primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  token_hash varchar(64) not null unique,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  replaced_by_token_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_refresh_token_user
  on public.auth_refresh_tokens(user_id);
create index if not exists idx_refresh_token_expiry
  on public.auth_refresh_tokens(expires_at);

alter table public.auth_refresh_tokens enable row level security;

drop policy if exists auth_refresh_tokens_deny_client on public.auth_refresh_tokens;
create policy auth_refresh_tokens_deny_client
on public.auth_refresh_tokens
for all
to authenticated
using (false)
with check (false);

commit;
