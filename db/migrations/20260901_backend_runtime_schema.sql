-- Canonical runtime schema for the Spring Boot application.
-- Run this on a fresh Supabase database. Do not run it together with the
-- earlier auth.users/profiles-only design; the application uses its own
-- users table and JWT session service.

begin;

create extension if not exists pgcrypto;

create table if not exists public.users (
    id uuid primary key default gen_random_uuid(),
    phone_number varchar(32) not null unique,
    display_name varchar(64) not null,
    avatar_emoji varchar(8) not null default '邻',
    bio varchar(160) not null default '',
    password_hash varchar(128),
    active_mode varchar(16) not null default 'CREATOR'
        check (active_mode in ('CREATOR', 'RUNNER')),
    credit_score numeric(10, 2) not null default 80.00
        check (credit_score between 0 and 100),
    creator_enabled boolean not null default true,
    runner_enabled boolean not null default true,
    community_name varchar(64),
    building_name varchar(64),
    room_mask varchar(32),
    notifications_enabled boolean not null default true,
    privacy_masked boolean not null default true,
    community_verified boolean not null default false,
    community_id uuid,
    system_role varchar(16) not null default 'USER'
        check (system_role in ('USER', 'ADMIN')),
    account_status varchar(16) not null default 'ACTIVE'
        check (account_status in ('ACTIVE', 'SUSPENDED', 'CLOSED')),
    version bigint not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table public.users add column if not exists location_latitude double precision;
alter table public.users add column if not exists location_longitude double precision;

create table if not exists public.communities (
    id uuid primary key,
    name varchar(64) not null unique,
    latitude double precision not null check (latitude between -90 and 90),
    longitude double precision not null check (longitude between -180 and 180),
    service_radius_meters integer not null default 500 check (service_radius_meters between 100 and 5000),
    active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.community_buildings (
    id uuid primary key,
    community_id uuid not null references public.communities(id) on delete cascade,
    name varchar(64) not null,
    latitude double precision not null check (latitude between -90 and 90),
    longitude double precision not null check (longitude between -180 and 180),
    sort_order integer not null default 0,
    active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uk_community_building unique (community_id, name)
);
create index if not exists idx_communities_active_location
    on public.communities(active, latitude, longitude);
create index if not exists idx_community_buildings_community
    on public.community_buildings(community_id, active, sort_order);

insert into public.communities (
    id, name, latitude, longitude, service_radius_meters, active
) values
    ('99999999-9999-9999-9999-999999999999', '春和里社区', 31.2304, 121.4737, 500, true),
    ('88888888-8888-8888-8888-888888888888', '滨江雅苑', 31.2328, 121.4761, 500, true),
    ('77777777-7777-7777-7777-777777777777', '梧桐花园', 31.2279, 121.4708, 500, true)
on conflict (id) do update set
    name = excluded.name,
    latitude = excluded.latitude,
    longitude = excluded.longitude,
    service_radius_meters = excluded.service_radius_meters,
    active = excluded.active,
    updated_at = now();

insert into public.community_buildings (
    id, community_id, name, latitude, longitude, sort_order, active
) values
    ('10000000-0000-0000-0000-000000000003', '99999999-9999-9999-9999-999999999999', '3号楼', 31.2300, 121.4739, 3, true),
    ('10000000-0000-0000-0000-000000000005', '99999999-9999-9999-9999-999999999999', '5号楼', 31.2303, 121.4735, 5, true),
    ('10000000-0000-0000-0000-000000000007', '99999999-9999-9999-9999-999999999999', '7号楼', 31.2310, 121.4743, 7, true),
    ('20000000-0000-0000-0000-000000000001', '88888888-8888-8888-8888-888888888888', 'A座', 31.2325, 121.4758, 1, true),
    ('20000000-0000-0000-0000-000000000002', '88888888-8888-8888-8888-888888888888', 'B座', 31.2330, 121.4763, 2, true),
    ('30000000-0000-0000-0000-000000000001', '77777777-7777-7777-7777-777777777777', '1号楼', 31.2277, 121.4705, 1, true),
    ('30000000-0000-0000-0000-000000000002', '77777777-7777-7777-7777-777777777777', '2号楼', 31.2281, 121.4711, 2, true)
on conflict on constraint uk_community_building do update set
    latitude = excluded.latitude,
    longitude = excluded.longitude,
    sort_order = excluded.sort_order,
    active = excluded.active,
    updated_at = now();

create table if not exists public.auth_otp_codes (
    id uuid primary key default gen_random_uuid(),
    phone_number varchar(32) not null,
    purpose varchar(16) not null check (purpose in ('LOGIN', 'REGISTER')),
    otp_code varchar(6) not null,
    expires_at timestamptz not null,
    consumed_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.auth_refresh_tokens (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users(id) on delete cascade,
    token_hash varchar(64) not null unique,
    expires_at timestamptz not null,
    revoked_at timestamptz,
    replaced_by_token_id uuid,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.wallets (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users(id) on delete cascade,
    wallet_type varchar(16) not null check (wallet_type in ('CREATOR', 'RUNNER')),
    available_balance numeric(12, 2) not null default 0 check (available_balance >= 0),
    frozen_balance numeric(12, 2) not null default 0 check (frozen_balance >= 0),
    version bigint not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uk_wallet_user_type unique (user_id, wallet_type)
);

create table if not exists public.tasks (
    id uuid primary key default gen_random_uuid(),
    creator_id uuid not null references public.users(id) on delete restrict,
    runner_id uuid references public.users(id) on delete set null,
    community_id uuid,
    task_type varchar(32) not null check (task_type in ('PACKAGE_PICKUP', 'ERRAND', 'POOL')),
    status varchar(32) not null default 'OPEN'
        check (status in ('OPEN', 'ACCEPTED', 'PICKED_UP', 'ARRIVED', 'COMPLETED', 'CANCELLED')),
    title varchar(120) not null check (char_length(btrim(title)) > 0),
    description varchar(1000) not null default '',
    pickup_latitude double precision not null check (pickup_latitude between -90 and 90),
    pickup_longitude double precision not null check (pickup_longitude between -180 and 180),
    dropoff_latitude double precision not null check (dropoff_latitude between -90 and 90),
    dropoff_longitude double precision not null check (dropoff_longitude between -180 and 180),
    pickup_floor integer not null default 1 check (pickup_floor between 1 and 99),
    dropoff_floor integer not null default 1 check (dropoff_floor between 1 and 99),
    pickup_has_elevator boolean not null default true,
    dropoff_has_elevator boolean not null default true,
    weight_kg numeric(10, 2) not null default 0 check (weight_kg >= 0),
    weather_surcharge numeric(10, 2) not null default 0 check (weather_surcharge >= 0),
    base_fee numeric(10, 2) not null default 2.00 check (base_fee >= 0),
    suggested_tip numeric(10, 2) not null default 0 check (suggested_tip >= 0),
    escrow_amount numeric(10, 2) not null default 0 check (escrow_amount >= 0),
    photo_proof_token varchar(128),
    accepted_at timestamptz,
    completed_at timestamptz,
    version bigint not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint ck_task_parties check (runner_id is null or creator_id <> runner_id)
);

alter table public.tasks
    add column if not exists is_public boolean not null default true;
alter table public.tasks
    add column if not exists task_code varchar(12);
create unique index if not exists uk_tasks_task_code
    on public.tasks(task_code)
    where task_code is not null;

create table if not exists public.ad_slots (
    id uuid primary key default gen_random_uuid(),
    placement varchar(32) not null,
    label varchar(24) not null default '社区推荐',
    title varchar(120) not null,
    subtitle varchar(240) not null default '',
    action_label varchar(32) not null default '查看',
    action_route varchar(160) not null default '',
    accent_hex varchar(7) not null default '#2257D9',
    image_url varchar(500),
    active boolean not null default true,
    sort_order integer not null default 0,
    starts_at timestamptz,
    ends_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index if not exists idx_ad_slots_placement_active
    on public.ad_slots(placement, active, sort_order);

create table if not exists public.orders (
    id uuid primary key default gen_random_uuid(),
    task_id uuid not null unique references public.tasks(id) on delete cascade,
    creator_id uuid not null references public.users(id) on delete restrict,
    runner_id uuid not null references public.users(id) on delete restrict,
    status varchar(32) not null default 'ACCEPTED'
        check (status in ('ACCEPTED', 'PICKED_UP', 'ARRIVED', 'COMPLETED')),
    gross_amount numeric(10, 2) not null default 0 check (gross_amount >= 0),
    platform_fee numeric(10, 2) not null default 0 check (platform_fee >= 0),
    runner_payout numeric(10, 2) not null default 0 check (runner_payout >= 0),
    settled_at timestamptz,
    version bigint not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint ck_order_parties check (creator_id <> runner_id)
);

create table if not exists public.pools (
    id uuid primary key default gen_random_uuid(),
    creator_id uuid not null references public.users(id) on delete restrict,
    community_id uuid,
    title varchar(120) not null check (char_length(btrim(title)) > 0),
    store_name varchar(120) not null,
    category varchar(32) not null default '社区拼单',
    summary varchar(200) not null default '',
    pickup_point varchar(120) not null default '',
    status varchar(16) not null default 'OPEN'
        check (status in ('OPEN', 'FULL', 'CLOSED')),
    freight_fee numeric(10, 2) not null default 0 check (freight_fee >= 0),
    delivery_fee numeric(10, 2) not null default 0 check (delivery_fee >= 0),
    target_participants integer not null default 2 check (target_participants > 0),
    current_participants integer not null default 1
        check (current_participants between 0 and target_participants),
    countdown_minutes integer not null default 20 check (countdown_minutes >= 0),
    shared_fee_per_user numeric(10, 2) not null default 0 check (shared_fee_per_user >= 0),
    version bigint not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.pool_members (
    id uuid primary key default gen_random_uuid(),
    pool_id uuid not null references public.pools(id) on delete cascade,
    user_id uuid not null references public.users(id) on delete cascade,
    quantity integer not null default 1 check (quantity > 0),
    item_amount numeric(10, 2) not null default 0 check (item_amount >= 0),
    shared_fee_share numeric(10, 2) not null default 0 check (shared_fee_share >= 0),
    active boolean not null default true,
    version bigint not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uk_pool_member unique (pool_id, user_id)
);

create table if not exists public.wallet_transactions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users(id) on delete cascade,
    transaction_type varchar(24) not null
        check (transaction_type in ('ESCROW_FREEZE', 'ESCROW_RELEASE', 'ESCROW_REFUND', 'RUNNER_PAYOUT', 'PLATFORM_FEE')),
    amount numeric(12, 2) not null check (amount >= 0),
    delta_available numeric(12, 2) not null,
    delta_frozen numeric(12, 2) not null,
    available_balance numeric(12, 2) not null check (available_balance >= 0),
    frozen_balance numeric(12, 2) not null check (frozen_balance >= 0),
    reference_type varchar(24) not null,
    reference_id uuid not null,
    idempotency_key varchar(160) not null unique,
    description varchar(200) not null default '',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.chats (
    id uuid primary key default gen_random_uuid(),
    task_id uuid references public.tasks(id) on delete cascade,
    sender_id uuid not null references public.users(id) on delete cascade,
    receiver_id uuid not null references public.users(id) on delete cascade,
    body varchar(2000) not null check (char_length(btrim(body)) > 0),
    read_at timestamptz,
    version bigint not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint ck_chat_parties check (sender_id <> receiver_id)
);

create table if not exists public.reviews (
    id uuid primary key default gen_random_uuid(),
    task_id uuid not null references public.tasks(id) on delete cascade,
    from_user_id uuid not null references public.users(id) on delete cascade,
    to_user_id uuid not null references public.users(id) on delete cascade,
    rating smallint not null check (rating between 1 and 5),
    comment varchar(500),
    version bigint not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uk_review_task_from unique (task_id, from_user_id),
    constraint ck_review_parties check (from_user_id <> to_user_id)
);

alter table public.reviews
    add column if not exists version bigint not null default 0;

create table if not exists public.dispute_tickets (
    id uuid primary key default gen_random_uuid(),
    task_id uuid not null references public.tasks(id) on delete cascade,
    opened_by uuid not null references public.users(id) on delete cascade,
    against_user_id uuid not null references public.users(id) on delete cascade,
    reason varchar(64) not null,
    description varchar(1000) not null,
    proof_token varchar(128),
    status varchar(16) not null default 'OPEN'
        check (status in ('OPEN', 'UNDER_REVIEW', 'RESOLVED', 'REJECTED')),
    resolution_note varchar(1000),
    resolved_by uuid references public.users(id) on delete set null,
    resolved_at timestamptz,
    version bigint not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uk_dispute_task_opener unique (task_id, opened_by),
    constraint ck_dispute_parties check (opened_by <> against_user_id)
);

create index if not exists idx_dispute_status_created
    on public.dispute_tickets(status, created_at);
create index if not exists idx_dispute_parties
    on public.dispute_tickets(opened_by, against_user_id, created_at desc);

create index if not exists idx_tasks_open_location
    on public.tasks(status, runner_id, pickup_latitude, pickup_longitude);
create index if not exists idx_tasks_creator_created
    on public.tasks(creator_id, created_at desc);
create index if not exists idx_tasks_runner_created
    on public.tasks(runner_id, created_at desc);
create index if not exists idx_orders_creator_status
    on public.orders(creator_id, status, created_at desc);
create index if not exists idx_orders_runner_status
    on public.orders(runner_id, status, created_at desc);
create index if not exists idx_pools_feed
    on public.pools(status, created_at desc);
create index if not exists idx_pool_members_pool
    on public.pool_members(pool_id, active, created_at desc);
create index if not exists idx_wallet_transactions_user
    on public.wallet_transactions(user_id, created_at desc);
create index if not exists idx_wallet_transactions_reference
    on public.wallet_transactions(reference_type, reference_id);
create index if not exists idx_chats_participants
    on public.chats(sender_id, receiver_id, created_at desc);
create index if not exists idx_chats_task
    on public.chats(task_id, created_at desc);

create index if not exists idx_reviews_to_user_created
    on public.reviews(to_user_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

do $$
declare
    table_name text;
begin
    foreach table_name in array array[
        'users', 'auth_otp_codes', 'auth_refresh_tokens', 'wallets', 'tasks',
    'orders', 'pools', 'pool_members', 'wallet_transactions', 'chats', 'reviews', 'dispute_tickets'
        , 'ad_slots', 'communities', 'community_buildings'
    ] loop
        execute format('drop trigger if exists %I_updated_at on public.%I', table_name, table_name);
        execute format(
            'create trigger %I_updated_at before update on public.%I for each row execute function public.set_updated_at()',
            table_name, table_name
        );
    end loop;
end $$;

-- The Spring service connects with the database owner. Direct Supabase client
-- mutations stay denied; the backend API is the trusted business boundary.
create or replace function public.is_runtime_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select coalesce(auth.role() = 'service_role', false)
        or exists (
            select 1 from public.users u
            where u.id = auth.uid()
              and u.system_role = 'ADMIN'
              and u.account_status = 'ACTIVE'
        );
$$;

alter table public.users enable row level security;
alter table public.auth_otp_codes enable row level security;
alter table public.auth_refresh_tokens enable row level security;
alter table public.wallets enable row level security;
alter table public.tasks enable row level security;
alter table public.orders enable row level security;
alter table public.pools enable row level security;
alter table public.pool_members enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.chats enable row level security;
alter table public.reviews enable row level security;
alter table public.dispute_tickets enable row level security;
alter table public.ad_slots enable row level security;
alter table public.communities enable row level security;
alter table public.community_buildings enable row level security;

drop policy if exists communities_public_select on public.communities;
create policy communities_public_select on public.communities
for select to anon, authenticated using (active = true);
drop policy if exists community_buildings_public_select on public.community_buildings;
create policy community_buildings_public_select on public.community_buildings
for select to anon, authenticated using (active = true);

drop policy if exists ad_slots_active_select on public.ad_slots;
create policy ad_slots_active_select on public.ad_slots
for select to authenticated
using (
    active = true
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at > now())
);
drop policy if exists ad_slots_admin_all on public.ad_slots;
create policy ad_slots_admin_all on public.ad_slots
for all to authenticated
using (public.is_runtime_admin())
with check (public.is_runtime_admin());

drop policy if exists users_self_select on public.users;
drop policy if exists users_self_update on public.users;
create policy users_self_select on public.users
for select to authenticated
using (id = auth.uid() or public.is_runtime_admin());

drop policy if exists auth_otp_deny_client on public.auth_otp_codes;
create policy auth_otp_deny_client on public.auth_otp_codes for all to authenticated
using (false) with check (false);
drop policy if exists auth_refresh_deny_client on public.auth_refresh_tokens;
create policy auth_refresh_deny_client on public.auth_refresh_tokens for all to authenticated
using (false) with check (false);

drop policy if exists wallets_self_select on public.wallets;
create policy wallets_self_select on public.wallets for select to authenticated
using (user_id = auth.uid() or public.is_runtime_admin());
drop policy if exists wallet_transactions_self_select on public.wallet_transactions;
create policy wallet_transactions_self_select on public.wallet_transactions for select to authenticated
using (user_id = auth.uid() or public.is_runtime_admin());

drop policy if exists tasks_community_select on public.tasks;
drop policy if exists tasks_party_update on public.tasks;
create policy tasks_community_select on public.tasks
for select to authenticated
using (
    public.is_runtime_admin()
    or creator_id = auth.uid()
    or runner_id = auth.uid()
    or exists (
        select 1
        from public.users viewer
        where viewer.id = auth.uid()
          and viewer.account_status = 'ACTIVE'
          and viewer.community_id is not null
          and viewer.community_id = tasks.community_id
    )
);

drop policy if exists orders_party_select on public.orders;
drop policy if exists orders_party_update on public.orders;
create policy orders_party_select on public.orders
for select to authenticated
using (creator_id = auth.uid() or runner_id = auth.uid() or public.is_runtime_admin());

drop policy if exists pools_community_select on public.pools;
create policy pools_community_select on public.pools
for select to authenticated
using (
    public.is_runtime_admin()
    or creator_id = auth.uid()
    or exists (
        select 1
        from public.users viewer
        where viewer.id = auth.uid()
          and viewer.account_status = 'ACTIVE'
          and viewer.community_id is not null
          and viewer.community_id = pools.community_id
    )
);
drop policy if exists pool_members_self_select on public.pool_members;
create policy pool_members_self_select on public.pool_members for select to authenticated
using (
    user_id = auth.uid()
    or public.is_runtime_admin()
    or exists (
        select 1
        from public.pools p
        where p.id = pool_members.pool_id
          and p.creator_id = auth.uid()
    )
);

drop policy if exists chats_party_select on public.chats;
drop policy if exists chats_sender_insert on public.chats;
create policy chats_party_select on public.chats
for select to authenticated
using (sender_id = auth.uid() or receiver_id = auth.uid() or public.is_runtime_admin());

drop policy if exists reviews_party_select on public.reviews;
drop policy if exists reviews_self_insert on public.reviews;
create policy reviews_party_select on public.reviews
for select to authenticated
using (from_user_id = auth.uid() or to_user_id = auth.uid() or public.is_runtime_admin());

drop policy if exists disputes_party_select on public.dispute_tickets;
create policy disputes_party_select on public.dispute_tickets
for select to authenticated
using (opened_by = auth.uid() or against_user_id = auth.uid() or public.is_runtime_admin());

do $$
declare
    table_name text;
begin
    if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
        foreach table_name in array array[
            'public.tasks', 'public.orders', 'public.pools', 'public.chats',
            'public.wallet_transactions', 'public.reviews', 'public.dispute_tickets'
        ] loop
            begin
                execute format('alter publication supabase_realtime add table %s', table_name);
            exception
                when duplicate_object then null;
            end;
        end loop;
    end if;
end $$;

commit;
