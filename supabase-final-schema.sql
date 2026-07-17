-- Canonical production schema for antigravity-project-planner
-- Apply this file when provisioning, restoring, or reconciling Supabase.
-- Keep this file updated whenever production tables, policies, or functions change.

create extension if not exists pgcrypto;

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  room_id text not null unique,
  title text not null default '제목 없는 프로젝트',
  snapshot_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.document_versions (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references public.documents(id) on delete cascade,
  saved_by_user_id uuid not null references auth.users(id) on delete cascade,
  snapshot_json jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.document_collaborators (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references public.documents(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  unique (document_id, user_id)
);

create index if not exists documents_owner_user_id_idx on public.documents(owner_user_id);
create index if not exists documents_updated_at_idx on public.documents(updated_at desc);
create index if not exists document_versions_document_id_idx on public.document_versions(document_id);
create index if not exists document_collaborators_user_id_idx on public.document_collaborators(user_id);
create index if not exists document_collaborators_document_id_idx on public.document_collaborators(document_id);

alter table public.documents enable row level security;
alter table public.document_versions enable row level security;
alter table public.document_collaborators enable row level security;

drop policy if exists "Users can read documents they collaborate on" on public.documents;
drop policy if exists "Users can insert own documents" on public.documents;
drop policy if exists "Users can update documents they collaborate on" on public.documents;
drop policy if exists "Owners can delete own documents" on public.documents;

create policy "Users can read documents they collaborate on"
on public.documents
for select
to authenticated
using (
  owner_user_id = auth.uid()
  or exists (
    select 1
    from public.document_collaborators dc
    where dc.document_id = documents.id
      and dc.user_id = auth.uid()
  )
);

create policy "Users can insert own documents"
on public.documents
for insert
to authenticated
with check (
  owner_user_id = auth.uid()
);

create policy "Users can update documents they collaborate on"
on public.documents
for update
to authenticated
using (
  owner_user_id = auth.uid()
  or exists (
    select 1
    from public.document_collaborators dc
    where dc.document_id = documents.id
      and dc.user_id = auth.uid()
  )
)
with check (
  owner_user_id = auth.uid()
  or exists (
    select 1
    from public.document_collaborators dc
    where dc.document_id = documents.id
      and dc.user_id = auth.uid()
  )
);

create policy "Owners can delete own documents"
on public.documents
for delete
to authenticated
using (
  owner_user_id = auth.uid()
);

drop policy if exists "Users can read own collaborator rows" on public.document_collaborators;

create policy "Users can read own collaborator rows"
on public.document_collaborators
for select
to authenticated
using (
  user_id = auth.uid()
);

drop policy if exists "Users can read versions of collaborated documents" on public.document_versions;
drop policy if exists "Users can insert versions of collaborated documents" on public.document_versions;

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
        d.owner_user_id = auth.uid()
        or exists (
          select 1
          from public.document_collaborators dc
          where dc.document_id = d.id
            and dc.user_id = auth.uid()
        )
      )
  )
);

create policy "Users can insert versions of collaborated documents"
on public.document_versions
for insert
to authenticated
with check (
  saved_by_user_id = auth.uid()
  and exists (
    select 1
    from public.documents d
    where d.id = document_versions.document_id
      and (
        d.owner_user_id = auth.uid()
        or exists (
          select 1
          from public.document_collaborators dc
          where dc.document_id = d.id
            and dc.user_id = auth.uid()
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
