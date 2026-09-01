create table if not exists users (
    id uuid primary key,
    phone_number varchar(32) not null unique,
    display_name varchar(64) not null,
    avatar_emoji varchar(8) not null default '邻',
    bio varchar(160) not null default '',
    password_hash varchar(128),
    active_mode varchar(16) not null,
    credit_score numeric(10, 2) not null default 80.00,
    creator_enabled boolean not null default true,
    runner_enabled boolean not null default true,
    community_name varchar(64),
    building_name varchar(64),
    room_mask varchar(32),
    notifications_enabled boolean not null default true,
    privacy_masked boolean not null default true,
    community_verified boolean not null default false,
    community_id uuid,
    system_role varchar(16) not null default 'USER',
    account_status varchar(16) not null default 'ACTIVE',
    version bigint not null default 0,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now()
);

alter table users add column if not exists avatar_emoji varchar(8) not null default '邻';
alter table users add column if not exists bio varchar(160) not null default '';
alter table users add column if not exists password_hash varchar(128);
alter table users add column if not exists community_name varchar(64);
alter table users add column if not exists building_name varchar(64);
alter table users add column if not exists room_mask varchar(32);
alter table users add column if not exists notifications_enabled boolean not null default true;
alter table users add column if not exists privacy_masked boolean not null default true;
alter table users add column if not exists community_verified boolean not null default false;
alter table users add column if not exists system_role varchar(16) not null default 'USER';
alter table users add column if not exists account_status varchar(16) not null default 'ACTIVE';
alter table users add column if not exists version bigint not null default 0;
alter table users add column if not exists location_latitude double precision;
alter table users add column if not exists location_longitude double precision;

create table if not exists communities (
    id uuid primary key,
    name varchar(64) not null unique,
    latitude double precision not null,
    longitude double precision not null,
    service_radius_meters integer not null default 500,
    active boolean not null default true,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now()
);

create table if not exists community_buildings (
    id uuid primary key,
    community_id uuid not null,
    name varchar(64) not null,
    latitude double precision not null,
    longitude double precision not null,
    sort_order integer not null default 0,
    active boolean not null default true,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint uk_community_building unique (community_id, name),
    constraint fk_community_building_community foreign key (community_id) references communities(id)
);
create index if not exists idx_communities_active_location on communities(active, latitude, longitude);
create index if not exists idx_community_buildings_community on community_buildings(community_id, active, sort_order);

create table if not exists auth_otp_codes (
    id uuid primary key,
    phone_number varchar(32) not null,
    purpose varchar(16) not null,
    otp_code varchar(6) not null,
    expires_at timestamp with time zone not null,
    consumed_at timestamp with time zone,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now()
);

create table if not exists auth_refresh_tokens (
    id uuid primary key,
    user_id uuid not null,
    token_hash varchar(64) not null unique,
    expires_at timestamp with time zone not null,
    revoked_at timestamp with time zone,
    replaced_by_token_id uuid,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint fk_refresh_token_user foreign key (user_id) references users(id)
);

create table if not exists wallets (
    id uuid primary key,
    user_id uuid not null,
    wallet_type varchar(16) not null,
    available_balance numeric(12, 2) not null default 0,
    frozen_balance numeric(12, 2) not null default 0,
    version bigint not null default 0,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint uk_wallet_user_type unique (user_id, wallet_type),
    constraint fk_wallet_user foreign key (user_id) references users(id)
);

create table if not exists wallet_transactions (
    id uuid primary key,
    user_id uuid not null,
    transaction_type varchar(24) not null,
    amount numeric(12, 2) not null,
    delta_available numeric(12, 2) not null,
    delta_frozen numeric(12, 2) not null,
    available_balance numeric(12, 2) not null,
    frozen_balance numeric(12, 2) not null,
    reference_type varchar(24) not null,
    reference_id uuid not null,
    idempotency_key varchar(160) not null unique,
    description varchar(200) not null default '',
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint fk_wallet_transaction_user foreign key (user_id) references users(id)
);

create table if not exists tasks (
    id uuid primary key,
    creator_id uuid not null,
    runner_id uuid,
    task_type varchar(32) not null,
    status varchar(32) not null,
    title varchar(120) not null,
    description varchar(1000) not null,
    pickup_latitude double precision not null,
    pickup_longitude double precision not null,
    dropoff_latitude double precision not null,
    dropoff_longitude double precision not null,
    pickup_floor integer not null,
    dropoff_floor integer not null,
    pickup_has_elevator boolean not null default true,
    dropoff_has_elevator boolean not null default true,
    weight_kg numeric(10, 2) not null default 0,
    weather_surcharge numeric(10, 2) not null default 0,
    base_fee numeric(10, 2) not null default 2.00,
    suggested_tip numeric(10, 2) not null default 0,
    escrow_amount numeric(10, 2) not null default 0,
    photo_proof_token varchar(128),
    community_id uuid,
    accepted_at timestamp with time zone,
    completed_at timestamp with time zone,
    version bigint not null default 0,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint fk_task_creator foreign key (creator_id) references users(id),
    constraint fk_task_runner foreign key (runner_id) references users(id)
);

alter table tasks add column if not exists community_id uuid;
alter table tasks add column if not exists version bigint not null default 0;
alter table tasks add column if not exists is_public boolean not null default true;
alter table tasks add column if not exists task_code varchar(12);
create unique index if not exists uk_tasks_task_code on tasks(task_code);

create table if not exists ad_slots (
    id uuid primary key,
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
    starts_at timestamp with time zone,
    ends_at timestamp with time zone,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now()
);
create index if not exists idx_ad_slots_placement_active on ad_slots(placement, active, sort_order);

create table if not exists orders (
    id uuid primary key,
    task_id uuid not null,
    creator_id uuid not null,
    runner_id uuid not null,
    status varchar(32) not null,
    gross_amount numeric(10, 2) not null default 0,
    platform_fee numeric(10, 2) not null default 0,
    runner_payout numeric(10, 2) not null default 0,
    settled_at timestamp with time zone,
    version bigint not null default 0,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint uk_order_task unique (task_id),
    constraint fk_order_task foreign key (task_id) references tasks(id),
    constraint fk_order_creator foreign key (creator_id) references users(id),
    constraint fk_order_runner foreign key (runner_id) references users(id)
);

alter table orders add column if not exists version bigint not null default 0;

create table if not exists pools (
    id uuid primary key,
    creator_id uuid not null,
    community_id uuid,
    title varchar(120) not null,
    store_name varchar(120) not null,
    category varchar(32) not null default '社区拼单',
    summary varchar(200) not null default '',
    pickup_point varchar(120) not null default '',
    status varchar(16) not null,
    freight_fee numeric(10, 2) not null default 0,
    delivery_fee numeric(10, 2) not null default 0,
    target_participants integer not null default 2,
    current_participants integer not null default 1,
    countdown_minutes integer not null default 20,
    shared_fee_per_user numeric(10, 2) not null default 0,
    version bigint not null default 0,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint fk_pool_creator foreign key (creator_id) references users(id)
);

alter table pools add column if not exists version bigint not null default 0;

alter table pools add column if not exists category varchar(32) not null default '社区拼单';
alter table pools add column if not exists summary varchar(200) not null default '';
alter table pools add column if not exists pickup_point varchar(120) not null default '';
alter table pools add column if not exists countdown_minutes integer not null default 20;

create table if not exists pool_members (
    id uuid primary key,
    pool_id uuid not null,
    user_id uuid not null,
    quantity integer not null default 1,
    item_amount numeric(10, 2) not null default 0,
    shared_fee_share numeric(10, 2) not null default 0,
    active boolean not null default true,
    version bigint not null default 0,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint uk_pool_member unique (pool_id, user_id),
    constraint fk_pool_member_pool foreign key (pool_id) references pools(id),
    constraint fk_pool_member_user foreign key (user_id) references users(id)
);

alter table pool_members add column if not exists version bigint not null default 0;
alter table wallets add column if not exists version bigint not null default 0;

create table if not exists chats (
    id uuid primary key,
    task_id uuid,
    sender_id uuid not null,
    receiver_id uuid not null,
    body varchar(2000) not null,
    read_at timestamp with time zone,
    version bigint not null default 0,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint fk_chat_task foreign key (task_id) references tasks(id),
    constraint fk_chat_sender foreign key (sender_id) references users(id),
    constraint fk_chat_receiver foreign key (receiver_id) references users(id),
    constraint ck_chat_parties check (sender_id <> receiver_id)
);

create index if not exists idx_chats_task_created on chats(task_id, created_at);
create index if not exists idx_chats_participants on chats(sender_id, receiver_id, created_at);
alter table chats add column if not exists version bigint not null default 0;

create table if not exists reviews (
    id uuid primary key,
    task_id uuid not null,
    from_user_id uuid not null,
    to_user_id uuid not null,
    rating smallint not null,
    comment varchar(500),
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint uk_review_task_from unique (task_id, from_user_id),
    constraint ck_review_rating check (rating between 1 and 5),
    constraint ck_review_parties check (from_user_id <> to_user_id),
    constraint fk_review_task foreign key (task_id) references tasks(id),
    constraint fk_review_from_user foreign key (from_user_id) references users(id),
    constraint fk_review_to_user foreign key (to_user_id) references users(id)
);

create index if not exists idx_reviews_to_user_created on reviews(to_user_id, created_at);
alter table reviews add column if not exists version bigint not null default 0;

create table if not exists dispute_tickets (
    id uuid primary key,
    task_id uuid not null,
    opened_by uuid not null,
    against_user_id uuid not null,
    reason varchar(64) not null,
    description varchar(1000) not null,
    proof_token varchar(128),
    status varchar(16) not null default 'OPEN',
    resolution_note varchar(1000),
    resolved_by uuid,
    resolved_at timestamp with time zone,
    version bigint not null default 0,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    constraint uk_dispute_task_opener unique (task_id, opened_by),
    constraint ck_dispute_status check (status in ('OPEN', 'UNDER_REVIEW', 'RESOLVED', 'REJECTED')),
    constraint ck_dispute_parties check (opened_by <> against_user_id),
    constraint fk_dispute_task foreign key (task_id) references tasks(id),
    constraint fk_dispute_opener foreign key (opened_by) references users(id),
    constraint fk_dispute_against foreign key (against_user_id) references users(id),
    constraint fk_dispute_resolver foreign key (resolved_by) references users(id)
);

create index if not exists idx_dispute_status_created on dispute_tickets(status, created_at);
create index if not exists idx_dispute_parties on dispute_tickets(opened_by, against_user_id, created_at desc);

create index if not exists idx_auth_otp_phone_created on auth_otp_codes(phone_number, created_at desc);
create index if not exists idx_refresh_token_user on auth_refresh_tokens(user_id);
create index if not exists idx_refresh_token_expiry on auth_refresh_tokens(expires_at);
create index if not exists idx_tasks_status_runner on tasks(status, runner_id);
create index if not exists idx_tasks_pickup_location on tasks(pickup_latitude, pickup_longitude);
create index if not exists idx_pools_status on pools(status);
create index if not exists idx_pool_members_pool_id on pool_members(pool_id);
create index if not exists idx_wallet_transactions_user_created on wallet_transactions(user_id, created_at desc);
create index if not exists idx_wallet_transactions_reference on wallet_transactions(reference_type, reference_id);

-- Keep the database as the final guard for money, location and workflow invariants.
do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ck_users_credit_score') then
        alter table users add constraint ck_users_credit_score check (credit_score between 0 and 100);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_wallets_balances') then
        alter table wallets add constraint ck_wallets_balances check (available_balance >= 0 and frozen_balance >= 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_tasks_coordinates') then
        alter table tasks add constraint ck_tasks_coordinates check (
            pickup_latitude between -90 and 90 and pickup_longitude between -180 and 180 and
            dropoff_latitude between -90 and 90 and dropoff_longitude between -180 and 180
        );
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_tasks_amounts') then
        alter table tasks add constraint ck_tasks_amounts check (
            base_fee >= 0 and weight_kg >= 0 and weather_surcharge >= 0 and
            suggested_tip >= 0 and escrow_amount >= 0
        );
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_pools_participants') then
        alter table pools add constraint ck_pools_participants check (
            target_participants > 0 and current_participants between 0 and target_participants
        );
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_pool_members_values') then
        alter table pool_members add constraint ck_pool_members_values check (quantity > 0 and item_amount >= 0 and shared_fee_share >= 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_wallet_transactions_amounts') then
        alter table wallet_transactions add constraint ck_wallet_transactions_amounts check (
            amount >= 0 and available_balance >= 0 and frozen_balance >= 0
        );
    end if;
end $$;
