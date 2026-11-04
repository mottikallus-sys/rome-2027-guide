-- ROAD TRIP 2027 — one private group, fully shared bookings.
-- Every approved member can read all bookings and confirmation numbers.
-- Members can only create/edit/delete bookings they own.
create table if not exists public.trip_members (
 user_id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null check (char_length(display_name) between 1 and 120),
 added_at timestamptz not null default now()
);
create table if not exists public.trip_bookings (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references public.trip_members(user_id) on delete cascade,
 kind text not null check (kind in ('flight','hotel')),
 traveler_name text not null check (char_length(traveler_name) between 1 and 120),
 provider text not null check (char_length(provider) between 1 and 120),
 confirmation text not null check (char_length(confirmation) between 1 and 70),
 flight_number text not null default '' check (char_length(flight_number)<=90),
 start_date date not null,
 departure text not null default '' check (char_length(departure)<=160),
 arrival text not null default '' check (char_length(arrival)<=160),
 notes text not null default '' check (char_length(notes)<=400),
 created_at timestamptz not null default now()
);
create index if not exists idx_trip_bookings_start_date on public.trip_bookings(start_date);
alter table public.trip_members enable row level security;
alter table public.trip_bookings enable row level security;

-- Membership helper avoids circular RLS checks.
create or replace function public.is_roadtrip_member()
returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.trip_members m where m.user_id=(select auth.uid()));
$$;
revoke all on function public.is_roadtrip_member() from public;
grant execute on function public.is_roadtrip_member() to authenticated;

drop policy if exists "members see group" on public.trip_members;
create policy "members see group" on public.trip_members for select to authenticated
using (public.is_roadtrip_member());

drop policy if exists "members read all bookings" on public.trip_bookings;
create policy "members read all bookings" on public.trip_bookings for select to authenticated
using (public.is_roadtrip_member());

drop policy if exists "owners add bookings" on public.trip_bookings;
create policy "owners add bookings" on public.trip_bookings for insert to authenticated
with check (public.is_roadtrip_member() and owner_id=(select auth.uid()));

drop policy if exists "owners edit bookings" on public.trip_bookings;
create policy "owners edit bookings" on public.trip_bookings for update to authenticated
using (public.is_roadtrip_member() and owner_id=(select auth.uid()))
with check (public.is_roadtrip_member() and owner_id=(select auth.uid()));

drop policy if exists "owners delete bookings" on public.trip_bookings;
create policy "owners delete bookings" on public.trip_bookings for delete to authenticated
using (public.is_roadtrip_member() and owner_id=(select auth.uid()));

-- Membership changes are done by the organizer in the Supabase dashboard;
-- there is deliberately no browser-accessible membership insert policy.
-- After an invited traveler has signed in, get their id in auth.users and insert:
-- insert into public.trip_members(user_id,display_name)
-- values ('THE_VERIFIED_AUTH_USER_UUID','Traveler name');
