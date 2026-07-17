-- CS2 Nade Guide — shared tactics schema (SPEC.md).
-- Applied 2026-07-17 via Supabase MCP as migrations: shared_tactics,
-- storage_shared_images, harden_rls_auto_enable. Kept in sync here for
-- reference; re-runnable if the project is ever recreated.
-- The backend only ever holds auth + individually shared tactics; the user's
-- library never touches it.

create table if not exists shared_tactics (
  id          uuid primary key default gen_random_uuid(),
  short_code  text unique not null,
  owner_id    uuid not null references auth.users(id),
  map         text not null,
  side        text not null,
  type        text not null,
  title       text not null,
  notes       text default '',
  payload     jsonb not null,        -- image paths + normalized transforms
  created_at  timestamptz default now()
);

create index if not exists shared_tactics_owner_id_idx on shared_tactics (owner_id);

alter table shared_tactics enable row level security;

-- anyone can read a shared tactic by code (public share)
drop policy if exists read_shared on shared_tactics;
create policy read_shared on shared_tactics
  for select using (true);

-- only the authenticated owner can create/delete their own
drop policy if exists insert_own on shared_tactics;
create policy insert_own on shared_tactics
  for insert to authenticated
  with check ((select auth.uid()) = owner_id);

drop policy if exists delete_own on shared_tactics;
create policy delete_own on shared_tactics
  for delete to authenticated
  using ((select auth.uid()) = owner_id);

-- Storage: public-read bucket for shared images; authenticated users write
-- only under their own user-id prefix (paths are <owner_id>/<code>/<role>.jpg).
insert into storage.buckets (id, name, public)
values ('shared-images', 'shared-images', true)
on conflict (id) do nothing;

-- The broad select policy lets ShareService download via the storage API and
-- intentionally makes every shared image world-readable, matching read_shared
-- above. The security advisor flags that it also allows listing the bucket;
-- accepted, since paths only contain owner ids + short codes that the public
-- shared_tactics table exposes anyway.
drop policy if exists "shared images public read" on storage.objects;
create policy "shared images public read" on storage.objects
  for select using (bucket_id = 'shared-images');

drop policy if exists "shared images owner write" on storage.objects;
create policy "shared images owner write" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'shared-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "shared images owner delete" on storage.objects;
create policy "shared images owner delete" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'shared-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- Advisor remediation: the platform's rls_auto_enable() event-trigger function
-- is SECURITY DEFINER in the exposed public schema; revoke public EXECUTE so
-- it is not reachable via /rest/v1/rpc (event triggers don't need the grant).
revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
