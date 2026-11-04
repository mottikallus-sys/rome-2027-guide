-- ROAD TRIP 2027 — one private group access code, no email sign-in.
-- RUN ONCE in your own Supabase SQL Editor AFTER SUPABASE_SETUP.sql.
-- It generates a new 20-character PRIVATE code in the final query result.
-- Save the code privately. Running this script again will rotate that code.
-- Anonymous authentication must be enabled in Authentication > Sign In / Providers.

create table if not exists public.trip_guest_access (
  singleton boolean primary key default true check (singleton),
  salt text not null,
  code_hash text not null
);
alter table public.trip_guest_access enable row level security;
-- Nobody using a public browser API can read this table.
revoke all on public.trip_guest_access from public, anon, authenticated;

-- Membership is only granted after comparing the private code server-side.
-- This function uses Supabase Auth's automatically created anonymous user ID.
create or replace function public.roadtrip_join_with_code(p_code text,p_name text)
returns boolean language plpgsql security definer set search_path = '' as $$
declare stored record;
begin
  if (select auth.uid()) is null then return false; end if;
  if length(btrim(coalesce(p_code,''))) < 12
    or length(btrim(coalesce(p_name,''))) < 1
    or length(btrim(coalesce(p_name,''))) > 120 then return false; end if;
  select salt,code_hash into stored
  from public.trip_guest_access where singleton=true;
  if not found then return false; end if;
  if md5(upper(btrim(p_code)) || stored.salt) <> stored.code_hash then return false; end if;

  insert into public.trip_members(user_id,display_name)
  values ((select auth.uid()), btrim(p_name))
  on conflict (user_id) do update set display_name=excluded.display_name;
  return true;
end;
$$;
revoke all on function public.roadtrip_join_with_code(text,text) from public, anon;
grant execute on function public.roadtrip_join_with_code(text,text) to authenticated;

-- Only the Supabase SQL Editor administrator can generate/rotate the code.
create or replace function public.roadtrip_rotate_code()
returns text language plpgsql security definer set search_path = '' as $$
declare new_code text; new_salt text;
begin
  new_code := upper(substr(replace(gen_random_uuid()::text,'-',''),1,20));
  new_salt := gen_random_uuid()::text;
  insert into public.trip_guest_access(singleton,salt,code_hash)
  values(true,new_salt,md5(new_code || new_salt))
  on conflict(singleton) do update set salt=excluded.salt,code_hash=excluded.code_hash;
  return new_code;
end;
$$;
revoke all on function public.roadtrip_rotate_code() from public, anon, authenticated;

-- The value returned in Results is your new PRIVATE GROUP CODE.
-- Copy it to a private place, not GitHub or a public chat.
select public.roadtrip_rotate_code() as private_group_code;
