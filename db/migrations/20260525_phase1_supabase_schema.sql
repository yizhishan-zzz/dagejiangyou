-- Phase 1: Supabase PostgreSQL schema + RLS
-- Project: 社群单位“微物流”拼单与任务众包平台
-- Notes:
-- 1. public.profiles is the business-domain user table mapped 1:1 to auth.users.
-- 2. Sensitive data is split into private detail tables so RLS can isolate exact phone/unit/address fields.
-- 3. This migration is intended for a fresh Supabase project with PostGIS and Storage enabled.

begin;

create extension if not exists pgcrypto;
create extension if not exists postgis;
create extension if not exists btree_gist;

do $$ begin
  create type public.app_mode as enum ('creator', 'runner');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.verification_status as enum ('pending', 'approved', 'rejected', 'suspended');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.user_access_status as enum ('active', 'restricted', 'suspended');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.community_verification_type as enum (
    'property_staff',
    'neighbor_invite',
    'lease_doc',
    'owner_doc',
    'face_check',
    'manual_review'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.community_verification_status as enum ('pending', 'approved', 'rejected', 'expired');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.building_type as enum ('residential', 'store', 'service_point', 'gate', 'other');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.compensation_model as enum ('fixed', 'tiered', 'negotiable');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.task_type as enum (
    'express_pickup',
    'food_pickup',
    'grocery_pickup',
    'mutual_aid',
    'universal_errand',
    'group_buy_assist',
    'document_delivery',
    'medicine_pickup'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.task_status as enum (
    'draft',
    'open',
    'accepted',
    'in_progress',
    'awaiting_confirmation',
    'completed',
    'cancelled',
    'disputed',
    'expired'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.task_payment_status as enum ('pending', 'escrowed', 'partially_released', 'released', 'refunded', 'failed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.order_status as enum (
    'pending_acceptance',
    'accepted',
    'picked_up',
    'in_transit',
    'delivered',
    'completed',
    'cancelled',
    'disputed',
    'refunded'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.pool_status as enum (
    'open',
    'locked',
    'full',
    'runner_assigned',
    'purchasing',
    'delivering',
    'completed',
    'cancelled',
    'expired',
    'disputed'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.pool_member_status as enum ('joined', 'paid', 'cancelled', 'refunded', 'fulfilled');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.pool_split_strategy as enum ('equal', 'quantity_weighted', 'amount_weighted', 'custom');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.chat_thread_type as enum ('direct', 'order', 'pool', 'system');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.message_type as enum ('text', 'image', 'order_status_card', 'system', 'voice', 'proof');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.wallet_kind as enum ('creator', 'runner', 'escrow');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.wallet_tx_type as enum (
    'topup',
    'withdrawal',
    'freeze',
    'unfreeze',
    'payout',
    'reward',
    'refund',
    'penalty',
    'manual_adjustment',
    'advance_payment'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.wallet_tx_direction as enum ('credit', 'debit');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.wallet_tx_status as enum ('pending', 'posted', 'cancelled', 'failed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.escrow_status as enum ('frozen', 'partially_released', 'released', 'refunded', 'cancelled');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.review_subject_type as enum ('order', 'pool');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.dispute_status as enum ('open', 'under_review', 'awaiting_evidence', 'resolved', 'rejected', 'escalated');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.dispute_target_type as enum ('order', 'pool');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.attachment_type as enum ('delivery_proof', 'receipt_scan', 'chat_media', 'dispute_evidence', 'verification_doc');
exception when duplicate_object then null; end $$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create or replace function public.mask_phone(p_phone text)
returns text
language sql
immutable
as $$
  select case
    when p_phone is null or btrim(p_phone) = '' then null
    when length(regexp_replace(p_phone, '\D', '', 'g')) >= 7 then
      left(regexp_replace(p_phone, '\D', '', 'g'), 3) || '****' || right(regexp_replace(p_phone, '\D', '', 'g'), 4)
    else '****'
  end;
$$;

create or replace function public.mask_unit(p_unit text)
returns text
language sql
immutable
as $$
  select case
    when p_unit is null or btrim(p_unit) = '' then null
    when char_length(p_unit) <= 2 then '**'
    when char_length(p_unit) <= 4 then left(p_unit, 1) || repeat('*', greatest(char_length(p_unit) - 2, 1)) || right(p_unit, 1)
    else left(p_unit, 2) || repeat('*', greatest(char_length(p_unit) - 4, 2)) || right(p_unit, 2)
  end;
$$;

create or replace function public.calculate_floor_surcharge(
  p_pickup_floor integer,
  p_dropoff_floor integer,
  p_pickup_has_elevator boolean,
  p_dropoff_has_elevator boolean
)
returns numeric(12,2)
language sql
immutable
as $$
  select round(
    (
      greatest(coalesce(p_pickup_floor, 1) - 2, 0) * case when coalesce(p_pickup_has_elevator, true) then 0 else 0.80 end
    ) +
    (
      greatest(coalesce(p_dropoff_floor, 1) - 2, 0) * case when coalesce(p_dropoff_has_elevator, true) then 0 else 0.80 end
    ),
    2
  )::numeric(12,2);
$$;

create or replace function public.calculate_weight_surcharge(
  p_weight_kg numeric,
  p_volume_level numeric
)
returns numeric(12,2)
language sql
immutable
as $$
  select round(
    (greatest(coalesce(p_weight_kg, 0) - 2, 0) * 0.60) +
    (greatest(coalesce(p_volume_level, 0) - 1, 0) * 0.40),
    2
  )::numeric(12,2);
$$;

create or replace function public.calculate_suggested_reward(
  p_base_fee numeric,
  p_pickup_floor integer,
  p_dropoff_floor integer,
  p_pickup_has_elevator boolean,
  p_dropoff_has_elevator boolean,
  p_weight_kg numeric,
  p_volume_level numeric,
  p_weather_surcharge numeric
)
returns numeric(12,2)
language sql
immutable
as $$
  select round(
    coalesce(p_base_fee, 0) +
    public.calculate_floor_surcharge(p_pickup_floor, p_dropoff_floor, p_pickup_has_elevator, p_dropoff_has_elevator) +
    public.calculate_weight_surcharge(p_weight_kg, p_volume_level) +
    coalesce(p_weather_surcharge, 0),
    2
  )::numeric(12,2);
$$;

create table if not exists public.communities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  city text,
  district text,
  address_text text,
  center_point geography(point, 4326) not null,
  service_radius_m integer not null default 500 check (service_radius_m between 100 and 1000),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.community_buildings (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities(id) on delete cascade,
  building_code text not null,
  building_name text not null,
  building_type public.building_type not null default 'residential',
  location geography(point, 4326) not null,
  entrance_point geography(point, 4326),
  floor_count integer not null default 1 check (floor_count > 0),
  has_elevator boolean not null default false,
  micro_cluster_code text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (community_id, building_code)
);

create table if not exists public.building_adjacencies (
  building_id uuid not null references public.community_buildings(id) on delete cascade,
  neighbor_building_id uuid not null references public.community_buildings(id) on delete cascade,
  walk_distance_m integer not null check (walk_distance_m > 0 and walk_distance_m <= 500),
  created_at timestamptz not null default now(),
  primary key (building_id, neighbor_building_id),
  check (building_id <> neighbor_building_id)
);

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  community_id uuid references public.communities(id) on delete set null,
  display_name text not null default '新用户',
  avatar_url text,
  bio text,
  phone_masked text,
  unit_masked text,
  default_building_id uuid references public.community_buildings(id) on delete set null,
  role_mode public.app_mode not null default 'creator',
  creator_enabled boolean not null default true,
  runner_enabled boolean not null default true,
  creator_status public.verification_status not null default 'approved',
  runner_status public.verification_status not null default 'pending',
  community_verification_status public.community_verification_status not null default 'pending',
  credit_score numeric(5,2) not null default 85.00 check (credit_score between 0 and 100),
  creator_completed_count integer not null default 0 check (creator_completed_count >= 0),
  runner_completed_count integer not null default 0 check (runner_completed_count >= 0),
  creator_cancelled_count integer not null default 0 check (creator_cancelled_count >= 0),
  runner_cancelled_count integer not null default 0 check (runner_cancelled_count >= 0),
  dispute_count integer not null default 0 check (dispute_count >= 0),
  access_status public.user_access_status not null default 'active',
  restricted_until timestamptz,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (char_length(btrim(display_name)) > 0)
);

create table if not exists public.user_private_profiles (
  user_id uuid primary key references public.profiles(user_id) on delete cascade,
  phone_e164 text not null unique,
  real_name text,
  building_id uuid references public.community_buildings(id) on delete set null,
  apartment_unit text,
  apartment_floor integer check (apartment_floor is null or apartment_floor > 0),
  detail_address text,
  emergency_contact_name text,
  emergency_contact_phone text,
  id_card_last4 text,
  trust_level integer not null default 0 check (trust_level between 0 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.app_user_roles (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  role_name text not null check (role_name in ('admin', 'moderator', 'support', 'community_manager')),
  granted_by uuid references public.profiles(user_id) on delete set null,
  granted_at timestamptz not null default now(),
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.community_verification_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  community_id uuid not null references public.communities(id) on delete cascade,
  building_id uuid references public.community_buildings(id) on delete set null,
  verification_type public.community_verification_type not null,
  status public.community_verification_status not null default 'pending',
  submitted_payload jsonb not null default '{}'::jsonb,
  review_note text,
  reviewed_by uuid references public.profiles(user_id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities(id) on delete restrict,
  creator_id uuid not null references public.profiles(user_id) on delete restrict,
  accepted_runner_id uuid references public.profiles(user_id) on delete set null,
  task_type public.task_type not null,
  compensation_model public.compensation_model not null default 'fixed',
  status public.task_status not null default 'draft',
  payment_status public.task_payment_status not null default 'pending',
  title text not null,
  description text,
  pickup_building_id uuid references public.community_buildings(id) on delete set null,
  dropoff_building_id uuid references public.community_buildings(id) on delete set null,
  pickup_point geography(point, 4326) not null,
  dropoff_point geography(point, 4326) not null,
  pickup_public_label text not null,
  dropoff_public_label text not null,
  pickup_floor integer not null default 1 check (pickup_floor > 0),
  dropoff_floor integer not null default 1 check (dropoff_floor > 0),
  pickup_has_elevator boolean not null default true,
  dropoff_has_elevator boolean not null default true,
  weight_kg numeric(8,2) not null default 0 check (weight_kg >= 0),
  volume_level numeric(8,2) not null default 0 check (volume_level >= 0),
  item_count integer not null default 1 check (item_count > 0),
  estimated_distance_m integer not null default 0 check (estimated_distance_m >= 0),
  base_fee numeric(12,2) not null default 0 check (base_fee >= 0),
  floor_surcharge numeric(12,2) not null default 0 check (floor_surcharge >= 0),
  weight_surcharge numeric(12,2) not null default 0 check (weight_surcharge >= 0),
  weather_surcharge numeric(12,2) not null default 0 check (weather_surcharge >= 0),
  advance_payment_amount numeric(12,2) not null default 0 check (advance_payment_amount >= 0),
  suggested_reward numeric(12,2) not null default 0 check (suggested_reward >= 0),
  final_reward numeric(12,2) not null default 0 check (final_reward >= 0),
  escrow_amount numeric(12,2) not null default 0 check (escrow_amount >= 0),
  requires_receipt_scan boolean not null default false,
  requires_delivery_photo boolean not null default true,
  needed_by_at timestamptz,
  expires_at timestamptz,
  accepted_at timestamptz,
  delivered_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (char_length(btrim(title)) > 0),
  check (creator_id <> coalesce(accepted_runner_id, '00000000-0000-0000-0000-000000000000'::uuid)),
  check (expires_at is null or needed_by_at is null or expires_at >= needed_by_at)
);

create table if not exists public.task_private_details (
  task_id uuid primary key references public.tasks(id) on delete cascade,
  creator_contact_name text,
  creator_contact_phone text,
  pickup_contact_name text,
  pickup_contact_phone text,
  dropoff_contact_name text,
  dropoff_contact_phone text,
  pickup_detail_address text,
  dropoff_detail_address text,
  pickup_unit text,
  dropoff_unit text,
  door_access_note text,
  private_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null unique references public.tasks(id) on delete cascade,
  community_id uuid not null references public.communities(id) on delete restrict,
  creator_id uuid not null references public.profiles(user_id) on delete restrict,
  runner_id uuid not null references public.profiles(user_id) on delete restrict,
  status public.order_status not null default 'pending_acceptance',
  escrow_status public.escrow_status not null default 'frozen',
  quote_amount numeric(12,2) not null default 0 check (quote_amount >= 0),
  advance_payment_amount numeric(12,2) not null default 0 check (advance_payment_amount >= 0),
  final_amount numeric(12,2) not null default 0 check (final_amount >= 0),
  platform_fee numeric(12,2) not null default 0 check (platform_fee >= 0),
  runner_income numeric(12,2) not null default 0 check (runner_income >= 0),
  delivery_proof_required boolean not null default true,
  cancellation_reason text,
  delivered_at timestamptz,
  confirmed_at timestamptz,
  settled_at timestamptz,
  cancelled_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (creator_id <> runner_id)
);

create table if not exists public.pools (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities(id) on delete restrict,
  creator_id uuid not null references public.profiles(user_id) on delete restrict,
  pickup_runner_id uuid references public.profiles(user_id) on delete set null,
  status public.pool_status not null default 'open',
  split_strategy public.pool_split_strategy not null default 'quantity_weighted',
  title text not null,
  description text,
  store_name text not null,
  store_public_label text not null,
  store_building_id uuid references public.community_buildings(id) on delete set null,
  store_point geography(point, 4326),
  target_member_count integer not null default 2 check (target_member_count >= 2),
  min_member_count integer not null default 2 check (min_member_count >= 1),
  current_member_count integer not null default 1 check (current_member_count >= 0),
  total_quantity integer not null default 0 check (total_quantity >= 0),
  goods_estimated_total numeric(12,2) not null default 0 check (goods_estimated_total >= 0),
  freight_estimated_total numeric(12,2) not null default 0 check (freight_estimated_total >= 0),
  runner_reward_total numeric(12,2) not null default 0 check (runner_reward_total >= 0),
  advance_payment_required boolean not null default true,
  join_deadline timestamptz not null,
  purchase_deadline timestamptz,
  delivery_deadline timestamptz,
  completed_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (char_length(btrim(title)) > 0),
  check (char_length(btrim(store_name)) > 0),
  check (min_member_count <= target_member_count),
  check (purchase_deadline is null or purchase_deadline >= join_deadline),
  check (delivery_deadline is null or delivery_deadline >= coalesce(purchase_deadline, join_deadline))
);

create table if not exists public.pool_private_details (
  pool_id uuid primary key references public.pools(id) on delete cascade,
  store_contact_name text,
  store_contact_phone text,
  store_detail_address text,
  creator_note_private text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.pool_members (
  id uuid primary key default gen_random_uuid(),
  pool_id uuid not null references public.pools(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  status public.pool_member_status not null default 'joined',
  quantity integer not null default 1 check (quantity > 0),
  goods_amount_estimate numeric(12,2) not null default 0 check (goods_amount_estimate >= 0),
  advance_paid_amount numeric(12,2) not null default 0 check (advance_paid_amount >= 0),
  final_goods_amount numeric(12,2) not null default 0 check (final_goods_amount >= 0),
  final_freight_share numeric(12,2) not null default 0 check (final_freight_share >= 0),
  final_runner_reward_share numeric(12,2) not null default 0 check (final_runner_reward_share >= 0),
  refund_amount numeric(12,2) not null default 0 check (refund_amount >= 0),
  member_note text,
  joined_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (pool_id, user_id)
);

create table if not exists public.chat_threads (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities(id) on delete restrict,
  thread_type public.chat_thread_type not null,
  created_by uuid not null references public.profiles(user_id) on delete restrict,
  task_id uuid references public.tasks(id) on delete cascade,
  order_id uuid unique references public.orders(id) on delete cascade,
  pool_id uuid references public.pools(id) on delete cascade,
  title text,
  last_message_at timestamptz,
  last_message_preview text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (thread_type = 'order' and order_id is not null) or
    (thread_type = 'pool' and pool_id is not null) or
    (thread_type in ('direct', 'system') and order_id is null and pool_id is null)
  )
);

create table if not exists public.chat_participants (
  thread_id uuid not null references public.chat_threads(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  muted boolean not null default false,
  last_read_at timestamptz,
  joined_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  primary key (thread_id, user_id)
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.chat_threads(id) on delete cascade,
  sender_id uuid not null references public.profiles(user_id) on delete restrict,
  message_type public.message_type not null default 'text',
  content text,
  media_bucket text,
  media_object_path text,
  status_card_payload jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  edited_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  wallet_kind public.wallet_kind not null,
  currency_code char(3) not null default 'CNY',
  available_balance numeric(14,2) not null default 0 check (available_balance >= 0),
  frozen_balance numeric(14,2) not null default 0 check (frozen_balance >= 0),
  lifetime_income numeric(14,2) not null default 0 check (lifetime_income >= 0),
  lifetime_spent numeric(14,2) not null default 0 check (lifetime_spent >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, wallet_kind)
);

create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid not null references public.wallets(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  direction public.wallet_tx_direction not null,
  tx_type public.wallet_tx_type not null,
  status public.wallet_tx_status not null default 'posted',
  amount numeric(14,2) not null check (amount > 0),
  balance_after numeric(14,2),
  reference_type text not null default 'manual',
  reference_id uuid,
  counterparty_user_id uuid references public.profiles(user_id) on delete set null,
  task_id uuid references public.tasks(id) on delete set null,
  order_id uuid references public.orders(id) on delete set null,
  pool_id uuid references public.pools(id) on delete set null,
  note text,
  idempotency_key text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.escrow_locks (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities(id) on delete restrict,
  creator_id uuid not null references public.profiles(user_id) on delete restrict,
  runner_id uuid references public.profiles(user_id) on delete set null,
  task_id uuid unique references public.tasks(id) on delete set null,
  order_id uuid unique references public.orders(id) on delete set null,
  pool_id uuid references public.pools(id) on delete set null,
  amount numeric(14,2) not null check (amount > 0),
  status public.escrow_status not null default 'frozen',
  frozen_at timestamptz not null default now(),
  released_at timestamptz,
  refunded_at timestamptz,
  cancelled_at timestamptz,
  created_tx_id uuid references public.wallet_transactions(id) on delete set null,
  released_tx_id uuid references public.wallet_transactions(id) on delete set null,
  refund_tx_id uuid references public.wallet_transactions(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  subject_type public.review_subject_type not null,
  order_id uuid references public.orders(id) on delete cascade,
  pool_id uuid references public.pools(id) on delete cascade,
  from_user_id uuid not null references public.profiles(user_id) on delete cascade,
  to_user_id uuid not null references public.profiles(user_id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  punctuality_rating smallint check (punctuality_rating between 1 and 5),
  communication_rating smallint check (communication_rating between 1 and 5),
  quality_rating smallint check (quality_rating between 1 and 5),
  tags text[] not null default '{}'::text[],
  comment text,
  is_anonymous boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (from_user_id <> to_user_id),
  check (
    (subject_type = 'order' and order_id is not null and pool_id is null) or
    (subject_type = 'pool' and pool_id is not null and order_id is null)
  )
);

create table if not exists public.dispute_tickets (
  id uuid primary key default gen_random_uuid(),
  target_type public.dispute_target_type not null,
  order_id uuid references public.orders(id) on delete cascade,
  pool_id uuid references public.pools(id) on delete cascade,
  opened_by uuid not null references public.profiles(user_id) on delete restrict,
  against_user_id uuid references public.profiles(user_id) on delete set null,
  community_id uuid not null references public.communities(id) on delete restrict,
  status public.dispute_status not null default 'open',
  reason_code text not null,
  summary text not null,
  detail text,
  requested_refund_amount numeric(12,2) not null default 0 check (requested_refund_amount >= 0),
  chat_thread_id uuid references public.chat_threads(id) on delete set null,
  assigned_admin_id uuid references public.profiles(user_id) on delete set null,
  resolution_note text,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (target_type = 'order' and order_id is not null and pool_id is null) or
    (target_type = 'pool' and pool_id is not null and order_id is null)
  )
);

create table if not exists public.attachments (
  id uuid primary key default gen_random_uuid(),
  attachment_type public.attachment_type not null,
  bucket_id text not null,
  object_path text not null,
  uploaded_by uuid not null references public.profiles(user_id) on delete restrict,
  community_id uuid references public.communities(id) on delete set null,
  task_id uuid references public.tasks(id) on delete cascade,
  order_id uuid references public.orders(id) on delete cascade,
  pool_id uuid references public.pools(id) on delete cascade,
  message_id uuid references public.chat_messages(id) on delete cascade,
  review_id uuid references public.reviews(id) on delete cascade,
  verification_request_id uuid references public.community_verification_requests(id) on delete cascade,
  dispute_id uuid references public.dispute_tickets(id) on delete cascade,
  mime_type text,
  file_size_bytes bigint check (file_size_bytes is null or file_size_bytes >= 0),
  ocr_text text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (bucket_id, object_path),
  check (num_nonnulls(task_id, order_id, pool_id, message_id, review_id, verification_request_id, dispute_id) >= 1)
);

create unique index if not exists uq_active_app_user_roles
  on public.app_user_roles(user_id, role_name)
  where revoked_at is null;

create unique index if not exists uq_pending_community_verification
  on public.community_verification_requests(user_id, community_id)
  where status = 'pending';

create unique index if not exists uq_wallet_transactions_idempotency_key
  on public.wallet_transactions(idempotency_key)
  where idempotency_key is not null;

create unique index if not exists uq_review_order_from_to
  on public.reviews(order_id, from_user_id, to_user_id)
  where order_id is not null;

create unique index if not exists uq_review_pool_from_to
  on public.reviews(pool_id, from_user_id, to_user_id)
  where pool_id is not null;

create index if not exists idx_communities_center_point on public.communities using gist (center_point);
create index if not exists idx_community_buildings_location on public.community_buildings using gist (location);
create index if not exists idx_community_buildings_entrance_point on public.community_buildings using gist (entrance_point);
create index if not exists idx_community_buildings_community on public.community_buildings(community_id, micro_cluster_code);
create index if not exists idx_building_adjacencies_neighbor on public.building_adjacencies(neighbor_building_id);
create index if not exists idx_profiles_community on public.profiles(community_id, access_status, credit_score desc);
create index if not exists idx_profiles_default_building on public.profiles(default_building_id);
create index if not exists idx_private_profiles_building on public.user_private_profiles(building_id);
create index if not exists idx_verification_requests_user on public.community_verification_requests(user_id, status, created_at desc);
create index if not exists idx_tasks_open_market on public.tasks(community_id, status, needed_by_at, created_at desc);
create index if not exists idx_tasks_creator on public.tasks(creator_id, status, created_at desc);
create index if not exists idx_tasks_runner on public.tasks(accepted_runner_id, status, created_at desc);
create index if not exists idx_tasks_pickup_point on public.tasks using gist (pickup_point);
create index if not exists idx_tasks_dropoff_point on public.tasks using gist (dropoff_point);
create index if not exists idx_orders_creator on public.orders(creator_id, status, created_at desc);
create index if not exists idx_orders_runner on public.orders(runner_id, status, created_at desc);
create index if not exists idx_orders_task on public.orders(task_id);
create index if not exists idx_pools_feed on public.pools(community_id, status, join_deadline, created_at desc);
create index if not exists idx_pools_store_point on public.pools using gist (store_point);
create index if not exists idx_pool_members_user on public.pool_members(user_id, status, created_at desc);
create index if not exists idx_chat_threads_order on public.chat_threads(order_id);
create index if not exists idx_chat_threads_pool on public.chat_threads(pool_id);
create index if not exists idx_chat_threads_last_message on public.chat_threads(last_message_at desc);
create index if not exists idx_chat_messages_thread_created on public.chat_messages(thread_id, created_at desc);
create index if not exists idx_chat_messages_sender on public.chat_messages(sender_id, created_at desc);
create index if not exists idx_wallets_user_kind on public.wallets(user_id, wallet_kind);
create index if not exists idx_wallet_transactions_user on public.wallet_transactions(user_id, created_at desc);
create index if not exists idx_wallet_transactions_wallet on public.wallet_transactions(wallet_id, created_at desc);
create index if not exists idx_escrow_locks_creator on public.escrow_locks(creator_id, status, created_at desc);
create index if not exists idx_escrow_locks_runner on public.escrow_locks(runner_id, status, created_at desc);
create index if not exists idx_reviews_to_user on public.reviews(to_user_id, created_at desc);
create index if not exists idx_dispute_tickets_community on public.dispute_tickets(community_id, status, created_at desc);
create index if not exists idx_dispute_tickets_opened_by on public.dispute_tickets(opened_by, created_at desc);
create index if not exists idx_attachments_order on public.attachments(order_id);
create index if not exists idx_attachments_task on public.attachments(task_id);
create index if not exists idx_attachments_pool on public.attachments(pool_id);
create index if not exists idx_attachments_message on public.attachments(message_id);
create index if not exists idx_attachments_dispute on public.attachments(dispute_id);

create or replace function public.caller_can_impersonate()
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select coalesce(auth.role() = 'service_role', false)
    or exists (
      select 1
      from public.app_user_roles r
      where r.user_id = auth.uid()
        and r.role_name in ('admin', 'moderator', 'support')
        and r.revoked_at is null
    );
$$;

create or replace function public.resolve_actor_user_id(p_user_id uuid default auth.uid())
returns uuid
language sql
stable
security definer
set search_path = public, extensions
as $$
  select case
    when public.caller_can_impersonate() then coalesce(p_user_id, auth.uid())
    else auth.uid()
  end;
$$;

create or replace function public.current_profile_community_id(p_user_id uuid default auth.uid())
returns uuid
language sql
stable
security definer
set search_path = public, extensions
as $$
  select p.community_id
  from public.profiles p
  where p.user_id = public.resolve_actor_user_id(p_user_id);
$$;

create or replace function public.is_user_active(p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1
    from public.profiles p
    where p.user_id = public.resolve_actor_user_id(p_user_id)
      and p.access_status = 'active'
      and (p.restricted_until is null or p.restricted_until <= now())
  );
$$;

create or replace function public.has_any_role(p_user_id uuid default auth.uid(), p_roles text[] default array[]::text[])
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1
    from public.app_user_roles r
    where r.user_id = public.resolve_actor_user_id(p_user_id)
      and r.role_name = any (p_roles)
      and r.revoked_at is null
  );
$$;

create or replace function public.is_admin(p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select coalesce(auth.role() = 'service_role', false)
    or public.has_any_role(public.resolve_actor_user_id(p_user_id), array['admin', 'moderator', 'support']);
$$;

create or replace function public.is_same_community(p_community_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select p_community_id is not null and p_community_id = public.current_profile_community_id(public.resolve_actor_user_id(p_user_id));
$$;

create or replace function public.is_task_party(p_task_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1
    from public.tasks t
    where t.id = p_task_id
      and (
        t.creator_id = public.resolve_actor_user_id(p_user_id)
        or t.accepted_runner_id = public.resolve_actor_user_id(p_user_id)
      )
  ) or public.is_admin(public.resolve_actor_user_id(p_user_id));
$$;

create or replace function public.can_view_task_private(p_task_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1
    from public.tasks t
    where t.id = p_task_id
      and (
        t.creator_id = public.resolve_actor_user_id(p_user_id)
        or t.accepted_runner_id = public.resolve_actor_user_id(p_user_id)
      )
  ) or public.is_admin(public.resolve_actor_user_id(p_user_id));
$$;

create or replace function public.is_order_party(p_order_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1
    from public.orders o
    where o.id = p_order_id
      and (
        o.creator_id = public.resolve_actor_user_id(p_user_id)
        or o.runner_id = public.resolve_actor_user_id(p_user_id)
      )
  ) or public.is_admin(public.resolve_actor_user_id(p_user_id));
$$;

create or replace function public.is_pool_party(p_pool_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1
    from public.pools p
    where p.id = p_pool_id
      and (
        p.creator_id = public.resolve_actor_user_id(p_user_id)
        or p.pickup_runner_id = public.resolve_actor_user_id(p_user_id)
      )
  )
  or exists (
    select 1
    from public.pool_members pm
    where pm.pool_id = p_pool_id
      and pm.user_id = public.resolve_actor_user_id(p_user_id)
      and pm.status in ('joined', 'paid', 'fulfilled')
  )
  or public.is_admin(public.resolve_actor_user_id(p_user_id));
$$;

create or replace function public.is_thread_participant(p_thread_id uuid, p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1
    from public.chat_participants cp
    where cp.thread_id = p_thread_id
      and cp.user_id = public.resolve_actor_user_id(p_user_id)
  ) or public.is_admin(public.resolve_actor_user_id(p_user_id));
$$;

create or replace function public.can_access_storage_object(
  p_bucket_id text,
  p_name text,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public, storage, extensions
as $$
  select exists (
    select 1
    from public.attachments a
    left join public.chat_messages cm on cm.id = a.message_id
    left join public.reviews r on r.id = a.review_id
    left join public.community_verification_requests cvr on cvr.id = a.verification_request_id
    left join public.dispute_tickets dt on dt.id = a.dispute_id
    where a.bucket_id = p_bucket_id
      and a.object_path = p_name
      and (
        a.uploaded_by = public.resolve_actor_user_id(p_user_id)
        or public.is_admin(public.resolve_actor_user_id(p_user_id))
        or (a.task_id is not null and public.is_task_party(a.task_id, p_user_id))
        or (a.order_id is not null and public.is_order_party(a.order_id, p_user_id))
        or (a.pool_id is not null and public.is_pool_party(a.pool_id, p_user_id))
        or (a.message_id is not null and public.is_thread_participant(cm.thread_id, p_user_id))
        or (a.review_id is not null and (
          r.from_user_id = public.resolve_actor_user_id(p_user_id)
          or r.to_user_id = public.resolve_actor_user_id(p_user_id)
        ))
        or (a.verification_request_id is not null and (
          cvr.user_id = public.resolve_actor_user_id(p_user_id)
          or public.is_admin(public.resolve_actor_user_id(p_user_id))
        ))
        or (a.dispute_id is not null and (
          dt.opened_by = public.resolve_actor_user_id(p_user_id)
          or dt.against_user_id = public.resolve_actor_user_id(p_user_id)
          or public.is_admin(public.resolve_actor_user_id(p_user_id))
        ))
      )
  );
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  insert into public.profiles (
    user_id,
    display_name,
    phone_masked,
    last_seen_at
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', '新用户'),
    public.mask_phone(new.phone),
    now()
  )
  on conflict (user_id) do nothing;

  insert into public.user_private_profiles (
    user_id,
    phone_e164
  )
  values (
    new.id,
    coalesce(new.phone, 'pending:' || new.id::text)
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create or replace function public.sync_profile_mask_fields()
returns trigger
language plpgsql
as $$
begin
  update public.profiles
  set
    phone_masked = public.mask_phone(new.phone_e164),
    unit_masked = public.mask_unit(new.apartment_unit),
    default_building_id = coalesce(new.building_id, default_building_id),
    updated_at = now()
  where user_id = new.user_id;

  return new;
end;
$$;

create or replace function public.protect_profile_system_fields()
returns trigger
language plpgsql
as $$
begin
  if current_setting('app.bypass_profile_guard', true) = '1' then
    return new;
  end if;

  if not public.is_admin(auth.uid()) then
    if
      new.creator_status is distinct from old.creator_status
      or new.runner_status is distinct from old.runner_status
      or new.community_verification_status is distinct from old.community_verification_status
      or new.credit_score is distinct from old.credit_score
      or new.creator_completed_count is distinct from old.creator_completed_count
      or new.runner_completed_count is distinct from old.runner_completed_count
      or new.creator_cancelled_count is distinct from old.creator_cancelled_count
      or new.runner_cancelled_count is distinct from old.runner_cancelled_count
      or new.dispute_count is distinct from old.dispute_count
      or new.access_status is distinct from old.access_status
      or new.restricted_until is distinct from old.restricted_until
    then
      raise exception 'System-managed profile fields cannot be modified directly';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.protect_verification_review_fields()
returns trigger
language plpgsql
as $$
begin
  if not public.is_admin(auth.uid()) then
    if
      new.status is distinct from old.status
      or new.review_note is distinct from old.review_note
      or new.reviewed_by is distinct from old.reviewed_by
      or new.reviewed_at is distinct from old.reviewed_at
    then
      raise exception 'Verification review fields are admin-managed';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.enforce_task_geofence_and_pricing()
returns trigger
language plpgsql
as $$
declare
  v_radius integer;
  v_distance integer;
begin
  select c.service_radius_m
    into v_radius
  from public.communities c
  where c.id = new.community_id;

  if v_radius is null then
    raise exception 'Invalid community_id for task %', new.id;
  end if;

  if new.pickup_building_id is not null and not exists (
    select 1
    from public.community_buildings b
    where b.id = new.pickup_building_id
      and b.community_id = new.community_id
  ) then
    raise exception 'pickup_building_id must belong to the same community';
  end if;

  if new.dropoff_building_id is not null and not exists (
    select 1
    from public.community_buildings b
    where b.id = new.dropoff_building_id
      and b.community_id = new.community_id
  ) then
    raise exception 'dropoff_building_id must belong to the same community';
  end if;

  v_distance := ceil(st_distance(new.pickup_point, new.dropoff_point))::integer;

  if v_distance > v_radius then
    raise exception 'Task distance %m exceeds community service radius %m', v_distance, v_radius;
  end if;

  new.estimated_distance_m := v_distance;
  new.floor_surcharge := public.calculate_floor_surcharge(
    new.pickup_floor,
    new.dropoff_floor,
    new.pickup_has_elevator,
    new.dropoff_has_elevator
  );
  new.weight_surcharge := public.calculate_weight_surcharge(
    new.weight_kg,
    new.volume_level
  );
  new.suggested_reward := public.calculate_suggested_reward(
    new.base_fee,
    new.pickup_floor,
    new.dropoff_floor,
    new.pickup_has_elevator,
    new.dropoff_has_elevator,
    new.weight_kg,
    new.volume_level,
    new.weather_surcharge
  );

  if coalesce(new.final_reward, 0) = 0 then
    new.final_reward := new.suggested_reward;
  end if;

  new.escrow_amount := round(new.final_reward + new.advance_payment_amount, 2);
  return new;
end;
$$;

create or replace function public.enforce_order_consistency()
returns trigger
language plpgsql
as $$
declare
  v_task public.tasks%rowtype;
begin
  select *
    into v_task
  from public.tasks t
  where t.id = new.task_id;

  if not found then
    raise exception 'task_id % does not exist', new.task_id;
  end if;

  if v_task.accepted_runner_id is null and new.runner_id is null then
    raise exception 'Runner must be assigned before creating an order';
  end if;

  new.community_id := v_task.community_id;
  new.creator_id := v_task.creator_id;
  new.runner_id := coalesce(new.runner_id, v_task.accepted_runner_id);

  if v_task.accepted_runner_id is not null and new.runner_id <> v_task.accepted_runner_id then
    raise exception 'Order runner must match task.accepted_runner_id';
  end if;

  if coalesce(new.quote_amount, 0) = 0 then
    new.quote_amount := v_task.final_reward;
  end if;

  if coalesce(new.advance_payment_amount, 0) = 0 then
    new.advance_payment_amount := v_task.advance_payment_amount;
  end if;

  if coalesce(new.final_amount, 0) = 0 then
    new.final_amount := round(new.quote_amount + new.advance_payment_amount, 2);
  end if;

  new.runner_income := greatest(round(new.final_amount - new.platform_fee, 2), 0);
  return new;
end;
$$;

create or replace function public.protect_order_financial_fields()
returns trigger
language plpgsql
as $$
begin
  if not public.is_admin(auth.uid()) then
    if
      new.task_id is distinct from old.task_id
      or new.community_id is distinct from old.community_id
      or new.creator_id is distinct from old.creator_id
      or new.runner_id is distinct from old.runner_id
      or new.quote_amount is distinct from old.quote_amount
      or new.advance_payment_amount is distinct from old.advance_payment_amount
      or new.final_amount is distinct from old.final_amount
      or new.platform_fee is distinct from old.platform_fee
      or new.runner_income is distinct from old.runner_income
      or new.escrow_status is distinct from old.escrow_status
    then
      raise exception 'Order financial and identity fields are backend-managed';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.sync_task_from_order_status()
returns trigger
language plpgsql
as $$
begin
  update public.tasks
  set
    accepted_runner_id = new.runner_id,
    status = case new.status
      when 'pending_acceptance' then 'accepted'
      when 'accepted' then 'accepted'
      when 'picked_up' then 'in_progress'
      when 'in_transit' then 'in_progress'
      when 'delivered' then 'awaiting_confirmation'
      when 'completed' then 'completed'
      when 'cancelled' then 'cancelled'
      when 'disputed' then 'disputed'
      when 'refunded' then 'cancelled'
      else status
    end,
    payment_status = case
      when new.escrow_status in ('frozen', 'partially_released') then 'escrowed'
      when new.escrow_status = 'released' then 'released'
      when new.escrow_status = 'refunded' then 'refunded'
      else payment_status
    end,
    accepted_at = coalesce(accepted_at, case when new.status in ('pending_acceptance', 'accepted') then now() end),
    delivered_at = coalesce(case when new.status = 'delivered' then now() end, delivered_at),
    completed_at = coalesce(case when new.status = 'completed' then now() end, completed_at),
    cancelled_at = coalesce(case when new.status in ('cancelled', 'refunded') then now() end, cancelled_at),
    updated_at = now()
  where id = new.task_id;

  return new;
end;
$$;

create or replace function public.enforce_pool_consistency()
returns trigger
language plpgsql
as $$
declare
  v_building public.community_buildings%rowtype;
begin
  if new.store_building_id is not null then
    select *
      into v_building
    from public.community_buildings b
    where b.id = new.store_building_id;

    if not found or v_building.community_id <> new.community_id then
      raise exception 'store_building_id must belong to the same community';
    end if;

    if new.store_point is null then
      new.store_point := coalesce(v_building.entrance_point, v_building.location);
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.refresh_pool_counters()
returns trigger
language plpgsql
as $$
declare
  v_pool_id uuid;
begin
  v_pool_id := coalesce(new.pool_id, old.pool_id);

  update public.pools p
  set
    current_member_count = coalesce((
      select count(*)
      from public.pool_members pm
      where pm.pool_id = v_pool_id
        and pm.status in ('joined', 'paid', 'fulfilled')
    ), 0),
    total_quantity = coalesce((
      select sum(pm.quantity)
      from public.pool_members pm
      where pm.pool_id = v_pool_id
        and pm.status in ('joined', 'paid', 'fulfilled')
    ), 0),
    status = case
      when p.status in ('completed', 'cancelled', 'expired', 'disputed') then p.status
      when coalesce((
        select count(*)
        from public.pool_members pm
        where pm.pool_id = v_pool_id
          and pm.status in ('joined', 'paid', 'fulfilled')
      ), 0) >= p.target_member_count then 'full'
      when p.status = 'full' then 'open'
      else p.status
    end,
    updated_at = now()
  where p.id = v_pool_id;

  return null;
end;
$$;

create or replace function public.protect_pool_member_fields()
returns trigger
language plpgsql
as $$
begin
  if not public.is_admin(auth.uid()) then
    if
      new.pool_id is distinct from old.pool_id
      or new.user_id is distinct from old.user_id
    then
      raise exception 'Pool member identity fields are immutable';
    end if;

    if not exists (
      select 1
      from public.pools p
      where p.id = old.pool_id
        and (p.creator_id = auth.uid() or p.pickup_runner_id = auth.uid())
    ) then
      if
        new.status is distinct from old.status
        and not (old.status in ('joined', 'paid') and new.status = 'cancelled')
      then
        raise exception 'Pool member status transitions are backend-managed';
      end if;

      if
        new.advance_paid_amount is distinct from old.advance_paid_amount
        or new.final_goods_amount is distinct from old.final_goods_amount
        or new.final_freight_share is distinct from old.final_freight_share
        or new.final_runner_reward_share is distinct from old.final_runner_reward_share
        or new.refund_amount is distinct from old.refund_amount
      then
        raise exception 'Pool settlement fields are backend-managed';
      end if;
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.refresh_chat_thread_snapshot()
returns trigger
language plpgsql
as $$
begin
  update public.chat_threads
  set
    last_message_at = new.created_at,
    last_message_preview = left(
      case
        when new.message_type = 'text' then coalesce(new.content, '')
        when new.message_type = 'image' then '[image]'
        when new.message_type = 'voice' then '[voice]'
        when new.message_type = 'proof' then '[proof]'
        when new.message_type = 'order_status_card' then '[status]'
        else coalesce(new.content, '[system]')
      end,
      80
    ),
    updated_at = now()
  where id = new.thread_id;

  return new;
end;
$$;

create or replace function public.protect_review_identity_fields()
returns trigger
language plpgsql
as $$
begin
  if not public.is_admin(auth.uid()) then
    if
      new.subject_type is distinct from old.subject_type
      or new.order_id is distinct from old.order_id
      or new.pool_id is distinct from old.pool_id
      or new.from_user_id is distinct from old.from_user_id
      or new.to_user_id is distinct from old.to_user_id
    then
      raise exception 'Review identity fields are immutable';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.protect_chat_thread_identity_fields()
returns trigger
language plpgsql
as $$
begin
  if not public.is_admin(auth.uid()) then
    if
      new.community_id is distinct from old.community_id
      or new.thread_type is distinct from old.thread_type
      or new.created_by is distinct from old.created_by
      or new.task_id is distinct from old.task_id
      or new.order_id is distinct from old.order_id
      or new.pool_id is distinct from old.pool_id
    then
      raise exception 'Chat thread identity fields are immutable';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.protect_dispute_identity_fields()
returns trigger
language plpgsql
as $$
begin
  if not public.is_admin(auth.uid()) then
    if
      new.status is distinct from old.status
      or
      new.target_type is distinct from old.target_type
      or new.order_id is distinct from old.order_id
      or new.pool_id is distinct from old.pool_id
      or new.opened_by is distinct from old.opened_by
      or new.against_user_id is distinct from old.against_user_id
      or new.community_id is distinct from old.community_id
      or new.assigned_admin_id is distinct from old.assigned_admin_id
      or new.resolution_note is distinct from old.resolution_note
      or new.resolved_at is distinct from old.resolved_at
    then
      raise exception 'Dispute identity and resolution fields are protected';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.protect_chat_participant_identity_fields()
returns trigger
language plpgsql
as $$
begin
  if not public.is_admin(auth.uid()) then
    if
      new.thread_id is distinct from old.thread_id
      or new.user_id is distinct from old.user_id
    then
      raise exception 'Chat participant identity fields are immutable';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.protect_chat_message_identity_fields()
returns trigger
language plpgsql
as $$
begin
  if not public.is_admin(auth.uid()) then
    if
      new.thread_id is distinct from old.thread_id
      or new.sender_id is distinct from old.sender_id
      or new.message_type is distinct from old.message_type
      or new.media_bucket is distinct from old.media_bucket
      or new.media_object_path is distinct from old.media_object_path
    then
      raise exception 'Chat message identity fields are immutable';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.protect_attachment_identity_fields()
returns trigger
language plpgsql
as $$
begin
  if not public.is_admin(auth.uid()) then
    if
      new.attachment_type is distinct from old.attachment_type
      or new.bucket_id is distinct from old.bucket_id
      or new.object_path is distinct from old.object_path
      or new.uploaded_by is distinct from old.uploaded_by
      or new.community_id is distinct from old.community_id
      or new.task_id is distinct from old.task_id
      or new.order_id is distinct from old.order_id
      or new.pool_id is distinct from old.pool_id
      or new.message_id is distinct from old.message_id
      or new.review_id is distinct from old.review_id
      or new.verification_request_id is distinct from old.verification_request_id
      or new.dispute_id is distinct from old.dispute_id
    then
      raise exception 'Attachment identity fields are immutable';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.record_order_completion()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'completed' and old.status is distinct from 'completed' then
    perform set_config('app.bypass_profile_guard', '1', true);
    update public.profiles
    set creator_completed_count = creator_completed_count + 1,
        updated_at = now()
    where user_id = new.creator_id;

    perform set_config('app.bypass_profile_guard', '1', true);
    update public.profiles
    set runner_completed_count = runner_completed_count + 1,
        updated_at = now()
    where user_id = new.runner_id;
  end if;

  if new.status = 'cancelled' and old.status is distinct from 'cancelled' then
    perform set_config('app.bypass_profile_guard', '1', true);
    update public.profiles
    set creator_cancelled_count = creator_cancelled_count + 1,
        updated_at = now()
    where user_id = new.creator_id;

    perform set_config('app.bypass_profile_guard', '1', true);
    update public.profiles
    set runner_cancelled_count = runner_cancelled_count + 1,
        updated_at = now()
    where user_id = new.runner_id;
  end if;

  return new;
end;
$$;

create or replace function public.recalculate_credit_score(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_avg_rating numeric;
  v_review_count integer;
  v_open_disputes integer;
  v_score numeric(5,2);
begin
  perform set_config('app.bypass_profile_guard', '1', true);

  select avg(r.rating)::numeric, count(*)
    into v_avg_rating, v_review_count
  from public.reviews r
  where r.to_user_id = p_user_id
    and r.created_at >= now() - interval '180 days';

  select count(*)
    into v_open_disputes
  from public.dispute_tickets d
  where (d.opened_by = p_user_id or d.against_user_id = p_user_id)
    and d.status in ('open', 'under_review', 'awaiting_evidence', 'escalated');

  if coalesce(v_review_count, 0) = 0 then
    v_score := greatest(0, 85 - (coalesce(v_open_disputes, 0) * 5));
  else
    v_score := greatest(
      0,
      least(
        100,
        round((coalesce(v_avg_rating, 4.0) * 18) + least(v_review_count, 10) - (coalesce(v_open_disputes, 0) * 5), 2)
      )
    );
  end if;

  update public.profiles p
  set
    credit_score = v_score,
    dispute_count = coalesce(v_open_disputes, 0),
    access_status = case
      when p.access_status = 'suspended' then 'suspended'
      when v_score < 60 then 'restricted'
      else 'active'
    end,
    updated_at = now()
  where p.user_id = p_user_id;
end;
$$;

create or replace function public.sync_credit_score_from_reviews()
returns trigger
language plpgsql
as $$
begin
  if tg_op in ('INSERT', 'UPDATE') then
    perform public.recalculate_credit_score(new.to_user_id);
  end if;

  if tg_op in ('UPDATE', 'DELETE') then
    perform public.recalculate_credit_score(old.to_user_id);
  end if;

  return null;
end;
$$;

create or replace function public.sync_credit_score_from_disputes()
returns trigger
language plpgsql
as $$
begin
  if tg_op in ('INSERT', 'UPDATE') then
    perform public.recalculate_credit_score(new.opened_by);
    if new.against_user_id is not null then
      perform public.recalculate_credit_score(new.against_user_id);
    end if;
  end if;

  if tg_op in ('UPDATE', 'DELETE') then
    perform public.recalculate_credit_score(old.opened_by);
    if old.against_user_id is not null then
      perform public.recalculate_credit_score(old.against_user_id);
    end if;
  end if;

  return null;
end;
$$;

create trigger trg_communities_updated_at
before update on public.communities
for each row execute function public.set_updated_at();

create trigger trg_community_buildings_updated_at
before update on public.community_buildings
for each row execute function public.set_updated_at();

create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger trg_profiles_protect_system_fields
before update on public.profiles
for each row execute function public.protect_profile_system_fields();

create trigger trg_private_profiles_updated_at
before update on public.user_private_profiles
for each row execute function public.set_updated_at();

create trigger trg_verification_requests_protect_review_fields
before update on public.community_verification_requests
for each row execute function public.protect_verification_review_fields();

create trigger trg_verification_requests_updated_at
before update on public.community_verification_requests
for each row execute function public.set_updated_at();

create trigger trg_tasks_pricing_and_geofence
before insert or update on public.tasks
for each row execute function public.enforce_task_geofence_and_pricing();

create trigger trg_tasks_updated_at
before update on public.tasks
for each row execute function public.set_updated_at();

create trigger trg_task_private_details_updated_at
before update on public.task_private_details
for each row execute function public.set_updated_at();

create trigger trg_orders_consistency
before insert or update on public.orders
for each row execute function public.enforce_order_consistency();

create trigger trg_orders_protect_financial_fields
before update on public.orders
for each row execute function public.protect_order_financial_fields();

create trigger trg_orders_updated_at
before update on public.orders
for each row execute function public.set_updated_at();

create trigger trg_orders_sync_task
after insert or update on public.orders
for each row execute function public.sync_task_from_order_status();

create trigger trg_orders_record_completion
after update on public.orders
for each row execute function public.record_order_completion();

create trigger trg_pools_consistency
before insert or update on public.pools
for each row execute function public.enforce_pool_consistency();

create trigger trg_pools_updated_at
before update on public.pools
for each row execute function public.set_updated_at();

create trigger trg_pool_private_details_updated_at
before update on public.pool_private_details
for each row execute function public.set_updated_at();

create trigger trg_pool_members_updated_at
before update on public.pool_members
for each row execute function public.set_updated_at();

create trigger trg_pool_members_protect_fields
before update on public.pool_members
for each row execute function public.protect_pool_member_fields();

create trigger trg_pool_members_refresh_counters_insert
after insert on public.pool_members
for each row execute function public.refresh_pool_counters();

create trigger trg_pool_members_refresh_counters_update
after update on public.pool_members
for each row execute function public.refresh_pool_counters();

create trigger trg_pool_members_refresh_counters_delete
after delete on public.pool_members
for each row execute function public.refresh_pool_counters();

create trigger trg_chat_threads_updated_at
before update on public.chat_threads
for each row execute function public.set_updated_at();

create trigger trg_chat_threads_protect_identity_fields
before update on public.chat_threads
for each row execute function public.protect_chat_thread_identity_fields();

create trigger trg_chat_participants_protect_identity_fields
before update on public.chat_participants
for each row execute function public.protect_chat_participant_identity_fields();

create trigger trg_chat_messages_updated_at
before update on public.chat_messages
for each row execute function public.set_updated_at();

create trigger trg_chat_messages_protect_identity_fields
before update on public.chat_messages
for each row execute function public.protect_chat_message_identity_fields();

create trigger trg_chat_messages_refresh_thread
after insert on public.chat_messages
for each row execute function public.refresh_chat_thread_snapshot();

create trigger trg_wallets_updated_at
before update on public.wallets
for each row execute function public.set_updated_at();

create trigger trg_escrow_locks_updated_at
before update on public.escrow_locks
for each row execute function public.set_updated_at();

create trigger trg_reviews_updated_at
before update on public.reviews
for each row execute function public.set_updated_at();

create trigger trg_reviews_protect_identity_fields
before update on public.reviews
for each row execute function public.protect_review_identity_fields();

create trigger trg_reviews_credit_score_insert
after insert on public.reviews
for each row execute function public.sync_credit_score_from_reviews();

create trigger trg_reviews_credit_score_update
after update on public.reviews
for each row execute function public.sync_credit_score_from_reviews();

create trigger trg_reviews_credit_score_delete
after delete on public.reviews
for each row execute function public.sync_credit_score_from_reviews();

create trigger trg_dispute_tickets_updated_at
before update on public.dispute_tickets
for each row execute function public.set_updated_at();

create trigger trg_disputes_protect_identity_fields
before update on public.dispute_tickets
for each row execute function public.protect_dispute_identity_fields();

create trigger trg_disputes_credit_score_insert
after insert on public.dispute_tickets
for each row execute function public.sync_credit_score_from_disputes();

create trigger trg_disputes_credit_score_update
after update on public.dispute_tickets
for each row execute function public.sync_credit_score_from_disputes();

create trigger trg_disputes_credit_score_delete
after delete on public.dispute_tickets
for each row execute function public.sync_credit_score_from_disputes();

create trigger trg_attachments_updated_at
before update on public.attachments
for each row execute function public.set_updated_at();

create trigger trg_attachments_protect_identity_fields
before update on public.attachments
for each row execute function public.protect_attachment_identity_fields();

create trigger trg_private_profiles_sync_masks
after insert or update on public.user_private_profiles
for each row execute function public.sync_profile_mask_fields();

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

grant usage on schema public to anon, authenticated, service_role;
grant select on public.communities, public.community_buildings, public.building_adjacencies to anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;
grant execute on all functions in schema public to service_role;
revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on function public.current_profile_community_id(uuid) to authenticated;
grant execute on function public.is_user_active(uuid) to authenticated;
grant execute on function public.has_any_role(uuid, text[]) to authenticated;
grant execute on function public.is_admin(uuid) to authenticated;
grant execute on function public.is_same_community(uuid, uuid) to authenticated;
grant execute on function public.is_task_party(uuid, uuid) to authenticated;
grant execute on function public.can_view_task_private(uuid, uuid) to authenticated;
grant execute on function public.is_order_party(uuid, uuid) to authenticated;
grant execute on function public.is_pool_party(uuid, uuid) to authenticated;
grant execute on function public.is_thread_participant(uuid, uuid) to authenticated;
grant execute on function public.can_access_storage_object(text, text, uuid) to authenticated;

alter table public.communities enable row level security;
alter table public.community_buildings enable row level security;
alter table public.building_adjacencies enable row level security;
alter table public.profiles enable row level security;
alter table public.user_private_profiles enable row level security;
alter table public.app_user_roles enable row level security;
alter table public.community_verification_requests enable row level security;
alter table public.tasks enable row level security;
alter table public.task_private_details enable row level security;
alter table public.orders enable row level security;
alter table public.pools enable row level security;
alter table public.pool_private_details enable row level security;
alter table public.pool_members enable row level security;
alter table public.chat_threads enable row level security;
alter table public.chat_participants enable row level security;
alter table public.chat_messages enable row level security;
alter table public.wallets enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.escrow_locks enable row level security;
alter table public.reviews enable row level security;
alter table public.dispute_tickets enable row level security;
alter table public.attachments enable row level security;

create policy communities_read_active
on public.communities
for select
to anon, authenticated
using (is_active = true);

create policy communities_admin_write
on public.communities
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy community_buildings_read_active
on public.community_buildings
for select
to anon, authenticated
using (
  is_active = true
  and exists (
    select 1 from public.communities c
    where c.id = community_id
      and c.is_active = true
  )
);

create policy community_buildings_admin_write
on public.community_buildings
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy building_adjacencies_read
on public.building_adjacencies
for select
to anon, authenticated
using (true);

create policy building_adjacencies_admin_write
on public.building_adjacencies
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy profiles_read_same_community
on public.profiles
for select
to authenticated
using (
  user_id = auth.uid()
  or public.is_admin()
  or (community_id is not null and community_id = public.current_profile_community_id())
);

create policy profiles_insert_self
on public.profiles
for insert
to authenticated
with check (user_id = auth.uid());

create policy profiles_update_self
on public.profiles
for update
to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

create policy private_profiles_self_only
on public.user_private_profiles
for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy private_profiles_insert_self
on public.user_private_profiles
for insert
to authenticated
with check (user_id = auth.uid() or public.is_admin());

create policy private_profiles_update_self
on public.user_private_profiles
for update
to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

create policy app_user_roles_read_self
on public.app_user_roles
for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy app_user_roles_admin_write
on public.app_user_roles
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy community_verifications_read_owner
on public.community_verification_requests
for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy community_verifications_insert_owner
on public.community_verification_requests
for insert
to authenticated
with check (
  user_id = auth.uid()
  and public.is_user_active()
  and community_id is not null
);

create policy community_verifications_update_owner_or_admin
on public.community_verification_requests
for update
to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

create policy tasks_read_market_and_parties
on public.tasks
for select
to authenticated
using (
  community_id = public.current_profile_community_id()
  and (
    status = 'open'
    or creator_id = auth.uid()
    or accepted_runner_id = auth.uid()
    or public.is_admin()
  )
);

create policy tasks_insert_creator
on public.tasks
for insert
to authenticated
with check (
  creator_id = auth.uid()
  and public.is_user_active()
  and community_id = public.current_profile_community_id()
);

create policy tasks_update_parties
on public.tasks
for update
to authenticated
using (
  creator_id = auth.uid()
  or accepted_runner_id = auth.uid()
  or public.is_admin()
)
with check (
  creator_id = auth.uid()
  or accepted_runner_id = auth.uid()
  or public.is_admin()
);

create policy tasks_delete_creator
on public.tasks
for delete
to authenticated
using (
  (creator_id = auth.uid() and status in ('draft', 'open'))
  or public.is_admin()
);

create policy task_private_read_parties
on public.task_private_details
for select
to authenticated
using (public.can_view_task_private(task_id));

create policy task_private_insert_creator
on public.task_private_details
for insert
to authenticated
with check (
  exists (
    select 1
    from public.tasks t
    where t.id = task_id
      and t.creator_id = auth.uid()
  ) or public.is_admin()
);

create policy task_private_update_parties
on public.task_private_details
for update
to authenticated
using (
  exists (
    select 1
    from public.tasks t
    where t.id = task_id
      and t.creator_id = auth.uid()
  ) or public.is_admin()
)
with check (
  exists (
    select 1
    from public.tasks t
    where t.id = task_id
      and t.creator_id = auth.uid()
  ) or public.is_admin()
);

create policy orders_read_parties
on public.orders
for select
to authenticated
using (public.is_order_party(id));

create policy orders_insert_creator
on public.orders
for insert
to authenticated
with check (
  public.is_user_active()
  and exists (
    select 1
    from public.tasks t
    where t.id = task_id
      and t.creator_id = auth.uid()
      and t.community_id = public.current_profile_community_id()
  )
);

create policy orders_update_parties
on public.orders
for update
to authenticated
using (creator_id = auth.uid() or runner_id = auth.uid() or public.is_admin())
with check (creator_id = auth.uid() or runner_id = auth.uid() or public.is_admin());

create policy pools_read_market_and_parties
on public.pools
for select
to authenticated
using (
  community_id = public.current_profile_community_id()
  and (
    status in ('open', 'locked', 'full', 'runner_assigned', 'purchasing', 'delivering')
    or creator_id = auth.uid()
    or pickup_runner_id = auth.uid()
    or public.is_pool_party(id)
    or public.is_admin()
  )
);

create policy pools_insert_creator
on public.pools
for insert
to authenticated
with check (
  creator_id = auth.uid()
  and public.is_user_active()
  and community_id = public.current_profile_community_id()
);

create policy pools_update_parties
on public.pools
for update
to authenticated
using (creator_id = auth.uid() or pickup_runner_id = auth.uid() or public.is_admin())
with check (creator_id = auth.uid() or pickup_runner_id = auth.uid() or public.is_admin());

create policy pool_private_read_parties
on public.pool_private_details
for select
to authenticated
using (public.is_pool_party(pool_id));

create policy pool_private_insert_creator
on public.pool_private_details
for insert
to authenticated
with check (
  exists (
    select 1
    from public.pools p
    where p.id = pool_id
      and p.creator_id = auth.uid()
  ) or public.is_admin()
);

create policy pool_private_update_parties
on public.pool_private_details
for update
to authenticated
using (
  exists (
    select 1
    from public.pools p
    where p.id = pool_id
      and (p.creator_id = auth.uid() or p.pickup_runner_id = auth.uid())
  ) or public.is_admin()
)
with check (
  exists (
    select 1
    from public.pools p
    where p.id = pool_id
      and (p.creator_id = auth.uid() or p.pickup_runner_id = auth.uid())
  ) or public.is_admin()
);

create policy pool_members_read_parties
on public.pool_members
for select
to authenticated
using (
  user_id = auth.uid()
  or public.is_admin()
  or exists (
    select 1
    from public.pools p
    where p.id = pool_id
      and (p.creator_id = auth.uid() or p.pickup_runner_id = auth.uid())
  )
);

create policy pool_members_insert_self
on public.pool_members
for insert
to authenticated
with check (
  user_id = auth.uid()
  and public.is_user_active()
  and exists (
    select 1
    from public.pools p
    where p.id = pool_id
      and p.community_id = public.current_profile_community_id()
      and p.status = 'open'
  )
);

create policy pool_members_update_parties
on public.pool_members
for update
to authenticated
using (
  user_id = auth.uid()
  or public.is_admin()
  or exists (
    select 1
    from public.pools p
    where p.id = pool_id
      and (p.creator_id = auth.uid() or p.pickup_runner_id = auth.uid())
  )
)
with check (
  user_id = auth.uid()
  or public.is_admin()
  or exists (
    select 1
    from public.pools p
    where p.id = pool_id
      and (p.creator_id = auth.uid() or p.pickup_runner_id = auth.uid())
  )
);

create policy chat_threads_read_participants
on public.chat_threads
for select
to authenticated
using (public.is_thread_participant(id));

create policy chat_threads_insert_creator
on public.chat_threads
for insert
to authenticated
with check (
  created_by = auth.uid()
  and public.is_user_active()
  and community_id = public.current_profile_community_id()
  and (
    (thread_type = 'order' and order_id is not null and public.is_order_party(order_id))
    or (thread_type = 'pool' and pool_id is not null and public.is_pool_party(pool_id))
    or (thread_type = 'direct' and order_id is null and pool_id is null)
    or (thread_type = 'system' and public.is_admin())
  )
);

create policy chat_threads_update_participants
on public.chat_threads
for update
to authenticated
using (created_by = auth.uid() or public.is_admin())
with check (created_by = auth.uid() or public.is_admin());

create policy chat_participants_read_participants
on public.chat_participants
for select
to authenticated
using (public.is_thread_participant(thread_id));

create policy chat_participants_insert_self_or_creator
on public.chat_participants
for insert
to authenticated
with check (
  public.is_admin()
  or exists (
    select 1
    from public.chat_threads ct
    where ct.id = thread_id
      and ct.created_by = auth.uid()
  )
  or (
    user_id = auth.uid()
    and exists (
      select 1
      from public.chat_threads ct
      where ct.id = thread_id
        and (
          (ct.order_id is not null and public.is_order_party(ct.order_id))
          or (ct.pool_id is not null and public.is_pool_party(ct.pool_id))
        )
    )
  )
);

create policy chat_participants_update_self
on public.chat_participants
for update
to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

create policy chat_messages_read_participants
on public.chat_messages
for select
to authenticated
using (public.is_thread_participant(thread_id));

create policy chat_messages_insert_sender
on public.chat_messages
for insert
to authenticated
with check (
  sender_id = auth.uid()
  and public.is_user_active()
  and public.is_thread_participant(thread_id)
);

create policy chat_messages_update_sender
on public.chat_messages
for update
to authenticated
using (sender_id = auth.uid() or public.is_admin())
with check (sender_id = auth.uid() or public.is_admin());

create policy wallets_read_self
on public.wallets
for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy wallets_admin_write
on public.wallets
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy wallet_transactions_read_self
on public.wallet_transactions
for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy wallet_transactions_admin_write
on public.wallet_transactions
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy escrow_locks_read_parties
on public.escrow_locks
for select
to authenticated
using (
  creator_id = auth.uid()
  or runner_id = auth.uid()
  or public.is_admin()
);

create policy escrow_locks_admin_write
on public.escrow_locks
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy reviews_read_same_community
on public.reviews
for select
to authenticated
using (
  public.is_admin()
  or exists (
    select 1
    from public.profiles p
    where p.user_id = to_user_id
      and p.community_id = public.current_profile_community_id()
  )
);

create policy reviews_insert_author
on public.reviews
for insert
to authenticated
with check (
  from_user_id = auth.uid()
  and public.is_user_active()
  and (
    (subject_type = 'order' and public.is_order_party(order_id))
    or
    (subject_type = 'pool' and public.is_pool_party(pool_id))
  )
);

create policy reviews_update_author
on public.reviews
for update
to authenticated
using (from_user_id = auth.uid() or public.is_admin())
with check (from_user_id = auth.uid() or public.is_admin());

create policy dispute_tickets_read_parties
on public.dispute_tickets
for select
to authenticated
using (
  opened_by = auth.uid()
  or against_user_id = auth.uid()
  or public.is_admin()
);

create policy dispute_tickets_insert_parties
on public.dispute_tickets
for insert
to authenticated
with check (
  opened_by = auth.uid()
  and public.is_user_active()
  and community_id = public.current_profile_community_id()
  and (
    (target_type = 'order' and public.is_order_party(order_id))
    or
    (target_type = 'pool' and public.is_pool_party(pool_id))
  )
);

create policy dispute_tickets_update_parties
on public.dispute_tickets
for update
to authenticated
using (opened_by = auth.uid() or against_user_id = auth.uid() or public.is_admin())
with check (opened_by = auth.uid() or against_user_id = auth.uid() or public.is_admin());

create policy attachments_read_authorized
on public.attachments
for select
to authenticated
using (
  uploaded_by = auth.uid()
  or public.is_admin()
  or (task_id is not null and public.is_task_party(task_id))
  or (order_id is not null and public.is_order_party(order_id))
  or (pool_id is not null and public.is_pool_party(pool_id))
  or (message_id is not null and exists (
    select 1
    from public.chat_messages cm
    where cm.id = message_id
      and public.is_thread_participant(cm.thread_id)
  ))
  or (review_id is not null and exists (
    select 1
    from public.reviews r
    where r.id = review_id
      and (r.from_user_id = auth.uid() or r.to_user_id = auth.uid())
  ))
  or (verification_request_id is not null and exists (
    select 1
    from public.community_verification_requests cvr
    where cvr.id = verification_request_id
      and cvr.user_id = auth.uid()
  ))
  or (dispute_id is not null and exists (
    select 1
    from public.dispute_tickets d
    where d.id = dispute_id
      and (d.opened_by = auth.uid() or d.against_user_id = auth.uid())
  ))
);

create policy attachments_insert_authorized
on public.attachments
for insert
to authenticated
with check (
  uploaded_by = auth.uid()
  and public.is_user_active()
  and (
    (task_id is not null and public.is_task_party(task_id))
    or (order_id is not null and public.is_order_party(order_id))
    or (pool_id is not null and public.is_pool_party(pool_id))
    or (message_id is not null and exists (
      select 1
      from public.chat_messages cm
      where cm.id = message_id
        and public.is_thread_participant(cm.thread_id)
    ))
    or (review_id is not null and exists (
      select 1
      from public.reviews r
      where r.id = review_id
        and (r.from_user_id = auth.uid() or r.to_user_id = auth.uid())
    ))
    or (verification_request_id is not null and exists (
      select 1
      from public.community_verification_requests cvr
      where cvr.id = verification_request_id
        and cvr.user_id = auth.uid()
    ))
    or (dispute_id is not null and exists (
      select 1
      from public.dispute_tickets d
      where d.id = dispute_id
        and (d.opened_by = auth.uid() or d.against_user_id = auth.uid())
    ))
  )
);

create policy attachments_update_authorized
on public.attachments
for update
to authenticated
using (uploaded_by = auth.uid() or public.is_admin())
with check (uploaded_by = auth.uid() or public.is_admin());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('delivery-proofs', 'delivery-proofs', false, 10485760, array['image/jpeg', 'image/png', 'image/webp']),
  ('chat-media', 'chat-media', false, 10485760, array['image/jpeg', 'image/png', 'image/webp', 'audio/mpeg', 'audio/ogg']),
  ('dispute-evidence', 'dispute-evidence', false, 15728640, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('verification-docs', 'verification-docs', false, 15728640, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do nothing;

create policy storage_authenticated_upload
on storage.objects
for insert
to authenticated
with check (
  bucket_id in ('delivery-proofs', 'chat-media', 'dispute-evidence', 'verification-docs')
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy storage_authorized_read
on storage.objects
for select
to authenticated
using (
  bucket_id in ('delivery-proofs', 'chat-media', 'dispute-evidence', 'verification-docs')
  and public.can_access_storage_object(bucket_id, name)
);

create policy storage_owner_update
on storage.objects
for update
to authenticated
using (
  bucket_id in ('delivery-proofs', 'chat-media', 'dispute-evidence', 'verification-docs')
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.is_admin()
  )
)
with check (
  bucket_id in ('delivery-proofs', 'chat-media', 'dispute-evidence', 'verification-docs')
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.is_admin()
  )
);

create policy storage_owner_delete
on storage.objects
for delete
to authenticated
using (
  bucket_id in ('delivery-proofs', 'chat-media', 'dispute-evidence', 'verification-docs')
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.is_admin()
  )
);

create or replace function public.find_open_tasks_within_radius(
  p_center geography(point, 4326),
  p_radius_m integer default 500
)
returns table (
  task_id uuid,
  title text,
  task_type public.task_type,
  pickup_public_label text,
  dropoff_public_label text,
  final_reward numeric(12,2),
  distance_to_pickup_m integer,
  estimated_distance_m integer,
  cluster_code text,
  needed_by_at timestamptz,
  created_at timestamptz
)
language sql
stable
set search_path = public, extensions
as $$
  select
    t.id,
    t.title,
    t.task_type,
    t.pickup_public_label,
    t.dropoff_public_label,
    t.final_reward,
    ceil(st_distance(t.pickup_point, p_center))::integer as distance_to_pickup_m,
    t.estimated_distance_m,
    coalesce(cb.micro_cluster_code, st_geohash(t.pickup_point::geometry, 8)) as cluster_code,
    t.needed_by_at,
    t.created_at
  from public.tasks t
  left join public.community_buildings cb on cb.id = t.pickup_building_id
  where t.status = 'open'
    and t.community_id = public.current_profile_community_id()
    and st_dwithin(t.pickup_point, p_center, greatest(1, least(p_radius_m, 500)))
  order by distance_to_pickup_m asc, t.needed_by_at nulls last, t.created_at desc;
$$;

create or replace function public.find_active_pools_within_radius(
  p_center geography(point, 4326),
  p_radius_m integer default 500
)
returns table (
  pool_id uuid,
  title text,
  store_name text,
  store_public_label text,
  current_member_count integer,
  target_member_count integer,
  goods_estimated_total numeric(12,2),
  freight_estimated_total numeric(12,2),
  join_deadline timestamptz,
  distance_to_store_m integer
)
language sql
stable
set search_path = public, extensions
as $$
  select
    p.id,
    p.title,
    p.store_name,
    p.store_public_label,
    p.current_member_count,
    p.target_member_count,
    p.goods_estimated_total,
    p.freight_estimated_total,
    p.join_deadline,
    ceil(st_distance(p.store_point, p_center))::integer as distance_to_store_m
  from public.pools p
  where p.status in ('open', 'locked', 'full', 'runner_assigned', 'purchasing', 'delivering')
    and p.community_id = public.current_profile_community_id()
    and p.store_point is not null
    and st_dwithin(p.store_point, p_center, greatest(1, least(p_radius_m, 500)))
  order by distance_to_store_m asc, p.join_deadline asc, p.created_at desc;
$$;

grant execute on function public.find_open_tasks_within_radius(geography, integer) to authenticated;
grant execute on function public.find_active_pools_within_radius(geography, integer) to authenticated;

do $$
declare
  v_table text;
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    foreach v_table in array array[
      'public.tasks',
      'public.orders',
      'public.pools',
      'public.chat_messages',
      'public.wallet_transactions',
      'public.dispute_tickets'
    ]
    loop
      begin
        execute format('alter publication supabase_realtime add table %s', v_table);
      exception
        when duplicate_object then null;
      end;
    end loop;
  end if;
end $$;

commit;
