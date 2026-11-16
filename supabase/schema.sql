create extension if not exists pgcrypto;
create table if not exists public.wichtel_participants(
 id uuid primary key default gen_random_uuid(), name text not null check(char_length(name) between 1 and 70),
 wishlist text not null default '' check(char_length(wishlist)<=700), token_hash text not null unique,
 recipient_id uuid references public.wichtel_participants(id) on delete set null, created_at timestamptz not null default now()
);
create table if not exists public.wichtel_settings(id boolean primary key default true check(id),drawn_at timestamptz);
insert into public.wichtel_settings(id,drawn_at) values(true,null) on conflict(id) do nothing;
alter table public.wichtel_participants enable row level security;
alter table public.wichtel_settings enable row level security;
revoke all on public.wichtel_participants from anon,authenticated;
revoke all on public.wichtel_settings from anon,authenticated;

create or replace function public.register_wichtel_participant(p_name text,p_wishlist text,p_token_hash text) returns void
language plpgsql security definer set search_path=public as $$
begin
 perform pg_advisory_xact_lock(88442211);
 if (select drawn_at from public.wichtel_settings where id=true) is not null then raise exception 'Die Anmeldung ist bereits geschlossen.'; end if;
 insert into public.wichtel_participants(name,wishlist,token_hash) values(p_name,p_wishlist,p_token_hash);
end;$$;
revoke all on function public.register_wichtel_participant(text,text,text) from public,anon,authenticated;
grant execute on function public.register_wichtel_participant(text,text,text) to service_role;

create or replace function public.apply_wichtel_draw(p_assignments jsonb) returns void language plpgsql security definer set search_path=public as $$
declare total_count integer; assigned_count integer; unique_recipients integer; self_count integer;
begin
 perform pg_advisory_xact_lock(88442211);
 if (select drawn_at from public.wichtel_settings where id=true) is not null then raise exception 'Die Ziehung wurde bereits durchgeführt.'; end if;
 select count(*) into total_count from public.wichtel_participants;
 if total_count<2 then raise exception 'Mindestens zwei Teilnehmende erforderlich.'; end if;
 select count(*),count(distinct(value->>'recipient_id')),count(*) filter(where value->>'participant_id'=value->>'recipient_id') into assigned_count,unique_recipients,self_count from jsonb_array_elements(p_assignments);
 if assigned_count<>total_count or unique_recipients<>total_count or self_count<>0 then raise exception 'Ungültige oder unvollständige Zuordnung.'; end if;
 if exists(select 1 from jsonb_array_elements(p_assignments) a left join public.wichtel_participants p on p.id=(a->>'participant_id')::uuid left join public.wichtel_participants r on r.id=(a->>'recipient_id')::uuid where p.id is null or r.id is null) then raise exception 'Unbekannte Teilnehmer-ID.'; end if;
 update public.wichtel_participants p set recipient_id=(a->>'recipient_id')::uuid from jsonb_array_elements(p_assignments) a where p.id=(a->>'participant_id')::uuid;
 update public.wichtel_settings set drawn_at=now() where id=true;
end;$$;
create or replace function public.reset_wichtel_draw() returns void language plpgsql security definer set search_path=public as $$
begin perform pg_advisory_xact_lock(88442211); update public.wichtel_participants set recipient_id=null; update public.wichtel_settings set drawn_at=null where id=true; end;$$;
revoke all on function public.apply_wichtel_draw(jsonb) from public,anon,authenticated;
revoke all on function public.reset_wichtel_draw() from public,anon,authenticated;
grant execute on function public.apply_wichtel_draw(jsonb) to service_role;
grant execute on function public.reset_wichtel_draw() to service_role;
