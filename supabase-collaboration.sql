-- Legacy migration/work-in-progress SQL for collaboration setup.
-- Do not use this as the canonical production schema.
-- Use supabase-final-schema.sql for provisioning or restoring Supabase.

create table if not exists public.document_collaborators (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references public.documents(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  unique (document_id, user_id)
);

alter table public.document_collaborators enable row level security;

drop policy if exists "Users can read documents they collaborate on" on public.documents;
create policy "Users can read documents they collaborate on"
on public.documents
for select
to authenticated
using (
  owner_user_id = (select auth.uid())
  or exists (
    select 1
    from public.document_collaborators dc
    where dc.document_id = documents.id
      and dc.user_id = (select auth.uid())
  )
);

drop policy if exists "Users can update documents they collaborate on" on public.documents;
create policy "Users can update documents they collaborate on"
on public.documents
for update
to authenticated
using (
  owner_user_id = (select auth.uid())
  or exists (
    select 1
    from public.document_collaborators dc
    where dc.document_id = documents.id
      and dc.user_id = (select auth.uid())
  )
)
with check (
  owner_user_id = (select auth.uid())
  or exists (
    select 1
    from public.document_collaborators dc
    where dc.document_id = documents.id
      and dc.user_id = (select auth.uid())
  )
);

drop policy if exists "Users can read collaborator rows for their documents" on public.document_collaborators;
create policy "Users can read collaborator rows for their documents"
on public.document_collaborators
for select
to authenticated
using (
  user_id = (select auth.uid())
  or exists (
    select 1
    from public.documents d
    where d.id = document_collaborators.document_id
      and d.owner_user_id = (select auth.uid())
  )
);

drop policy if exists "Owners can manage collaborators for their documents" on public.document_collaborators;
create policy "Owners can manage collaborators for their documents"
on public.document_collaborators
for all
to authenticated
using (
  exists (
    select 1
    from public.documents d
    where d.id = document_collaborators.document_id
      and d.owner_user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.documents d
    where d.id = document_collaborators.document_id
      and d.owner_user_id = (select auth.uid())
  )
);

drop policy if exists "Users can read versions of collaborated documents" on public.document_versions;
create policy "Users can read versions of collaborated documents"
on public.document_versions
for select
to authenticated
using (
  exists (
    select 1
    from public.documents d
    where d.id = document_versions.document_id
      and (
        d.owner_user_id = (select auth.uid())
        or exists (
          select 1
          from public.document_collaborators dc
          where dc.document_id = d.id
            and dc.user_id = (select auth.uid())
        )
      )
  )
);

drop policy if exists "Users can insert versions of collaborated documents" on public.document_versions;
create policy "Users can insert versions of collaborated documents"
on public.document_versions
for insert
to authenticated
with check (
  saved_by_user_id = (select auth.uid())
  and exists (
    select 1
    from public.documents d
    where d.id = document_versions.document_id
      and (
        d.owner_user_id = (select auth.uid())
        or exists (
          select 1
          from public.document_collaborators dc
          where dc.document_id = d.id
            and dc.user_id = (select auth.uid())
        )
      )
  )
);

create or replace function public.join_document_by_room(p_room_id text)
returns table (
  id uuid,
  owner_user_id uuid,
  room_id text,
  title text,
  snapshot_json jsonb,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  target_document public.documents%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select *
  into target_document
  from public.documents
  where documents.room_id = p_room_id;

  if not found then
    return;
  end if;

  if target_document.owner_user_id <> auth.uid() then
    insert into public.document_collaborators (document_id, user_id)
    values (target_document.id, auth.uid())
    on conflict (document_id, user_id) do nothing;
  end if;

  return query
  select
    target_document.id,
    target_document.owner_user_id,
    target_document.room_id,
    target_document.title,
    target_document.snapshot_json,
    target_document.created_at,
    target_document.updated_at;
end;
$$;

grant execute on function public.join_document_by_room(text) to authenticated;
