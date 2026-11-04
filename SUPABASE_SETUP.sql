-- ROAD TRIP 2027 — shared group flight board, private confirmation numbers.
-- Run in your Supabase project's SQL Editor. This does not expose booking references.
create table if not exists public.trip_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 120),
  added_at timestamptz not null default now()
);
create table if not exists public.trip_flights (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  traveler_name text not null check (char_length(traveler_name) between 1 and 120),
  airline text not null check (char_length(airline) between 1 and 120),
  flight_number text not null check (char_length(flight_number) between 2 and 20),
  departure_date date not null,
  departure_time time,
  departure_airport text not null check (char_length(departure_airport) between 3 and 5),
  arrival_airport text not null check (char_length(arrival_airport) between 3 and 5),
  leg text not null default 'outbound' check (leg in ('outbound','return','other')),
  notes text not null default '' check (char_length(notes) <= 400),
  created_at timestamptz not null default now()
);
create table if not exists public.trip_flight_confirmations (
  flight_id uuid primary key references public.trip_flights(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  confirmation text not null check (char_length(confirmation) between 1 and 50)
);
create index if not exists trip_flights_date_idx on public.trip_flights(departure_date);
alter table public.trip_members enable row level security;
alter table public.trip_flights enable row level security;
alter table public.trip_flight_confirmations enable row level security;

create or replace function public.is_roadtrip_member()
returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.trip_members m where m.user_id=(select auth.uid()));
$$;
revoke all on function public.is_roadtrip_member() from public;
grant execute on function public.is_roadtrip_member() to authenticated;

drop policy if exists "members see group" on public.trip_members;
create policy "members see group" on public.trip_members for select to authenticated
using (public.is_roadtrip_member());

drop policy if exists "group reads flights" on public.trip_flights;
create policy "group reads flights" on public.trip_flights for select to authenticated
using (public.is_roadtrip_member());
drop policy if exists "owners insert flights" on public.trip_flights;
create policy "owners insert flights" on public.trip_flights for insert to authenticated
with check (public.is_roadtrip_member() and owner_id=(select auth.uid()));
drop policy if exists "owners update flights" on public.trip_flights;
create policy "owners update flights" on public.trip_flights for update to authenticated
using (public.is_roadtrip_member() and owner_id=(select auth.uid()))
with check (public.is_roadtrip_member() and owner_id=(select auth.uid()));
drop policy if exists "owners delete flights" on public.trip_flights;
create policy "owners delete flights" on public.trip_flights for delete to authenticated
using (public.is_roadtrip_member() and owner_id=(select auth.uid()));

drop policy if exists "owner reads own code" on public.trip_flight_confirmations;
create policy "owner reads own code" on public.trip_flight_confirmations for select to authenticated
using (public.is_roadtrip_member() and owner_id=(select auth.uid()));
drop policy if exists "owner adds code for own flight" on public.trip_flight_confirmations;
create policy "owner adds code for own flight" on public.trip_flight_confirmations for insert to authenticated
with check (public.is_roadtrip_member() and owner_id=(select auth.uid())
 and exists(select 1 from public.trip_flights f where f.id=flight_id and f.owner_id=(select auth.uid())));
drop policy if exists "owner updates own code" on public.trip_flight_confirmations;
create policy "owner updates own code" on public.trip_flight_confirmations for update to authenticated
using (public.is_roadtrip_member() and owner_id=(select auth.uid()))
with check (public.is_roadtrip_member() and owner_id=(select auth.uid())
 and exists(select 1 from public.trip_flights f where f.id=flight_id and f.owner_id=(select auth.uid())));
drop policy if exists "owner removes own code" on public.trip_flight_confirmations;
create policy "owner removes own code" on public.trip_flight_confirmations for delete to authenticated
using (public.is_roadtrip_member() and owner_id=(select auth.uid()));

-- Approve members ONLY from the trusted Supabase Dashboard SQL Editor:
-- insert into public.trip_members(user_id,display_name)
-- values ('VERIFIED_AUTH_USER_UUID','Couple A') on conflict(user_id) do update set display_name=excluded.display_name;
-- Public anon keys are safe only with these row-level security policies.
-- Existing trip_bookings (legacy) is not used by this new flights-only app.
