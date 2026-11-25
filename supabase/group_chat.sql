-- Group chat. Apply once in the Supabase SQL Editor of the REAL project
-- (PrivilegeFitness), after groups_phase1.sql, groups_moderation_fix.sql and
-- groups_avatar.sql. Safe to re-run. It adds one table, two functions and
-- turns on realtime for the new table; it changes no existing data.
--
-- Rules enforced by the database (the app only displays them):
--   * Only active members of a group can read or send messages.
--   * Chat must be switched on by the owner (groups.chat_enabled).
--   * Banned, removed or departed members lose access immediately.
--   * Messages from people you blocked (or who blocked you) are hidden.
--   * 1 to 1000 characters; at most 20 messages per minute per account.
--   * The author, or an unblocked owner/moderator, can delete a message.
--
-- Realtime note: the table keeps the default replica identity on purpose. A
-- DELETE event then carries only the message id, never the deleted text.
begin;

create table if not exists public.group_messages (
 id uuid primary key default gen_random_uuid(),
 group_id uuid not null references public.groups(id) on delete cascade,
 author_id uuid not null references public.profiles(id) on delete cascade,
 body text not null check (length(btrim(body)) between 1 and 1000),
 created_at timestamptz not null default now()
);
comment on table public.group_messages is
 'Group chat messages; written only by group_send_message and readable only by active members while chat is enabled.';
create index if not exists group_messages_feed_idx
 on public.group_messages(group_id, created_at desc, id desc);
create index if not exists group_messages_author_idx
 on public.group_messages(author_id, created_at desc);

alter table public.group_messages enable row level security;
revoke all on public.group_messages from public, anon, authenticated;
grant select on public.group_messages to authenticated;
grant all on public.group_messages to service_role;

drop policy if exists group_messages_read on public.group_messages;
create policy group_messages_read on public.group_messages for select to authenticated using (
 public.group_is_member(group_id)
 and exists(select 1 from public.groups g where g.id = group_id and g.chat_enabled)
 and (author_id = auth.uid() or not public.community_is_blocked(author_id)));

create or replace function public.group_send_message(p_group uuid, p_body text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare g public.groups%rowtype; result uuid; clean text := btrim(coalesce(p_body, ''));
begin
 if not public.group_is_member(p_group) then raise exception 'Membership required'; end if;
 select * into g from public.groups where id = p_group;
 if not found or not g.chat_enabled then raise exception 'Chat is not enabled'; end if;
 if length(clean) < 1 or length(clean) > 1000 then
  raise exception 'Message must be 1 to 1000 characters';
 end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text, 2));
 if (select count(*) from public.group_messages
     where author_id = auth.uid() and created_at > now() - interval '1 minute') >= 20 then
  raise exception 'Chat rate limit';
 end if;
 insert into public.group_messages(group_id, author_id, body)
 values(p_group, auth.uid(), clean) returning id into result;
 return result;
end $$;
comment on function public.group_send_message(uuid, text) is
 'Sends a chat message as an active member while chat is enabled; limited to 20 messages per minute per account.';

create or replace function public.group_delete_message(p_message uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare m public.group_messages%rowtype;
begin
 if not public.is_registered_user() then raise exception 'Sign in required'; end if;
 select * into m from public.group_messages where id = p_message;
 if not found or not public.group_is_member(m.group_id)
   or (m.author_id <> auth.uid() and (not public.group_is_moderator(m.group_id)
       or public.community_is_blocked(m.author_id))) then
  raise exception 'Not permitted';
 end if;
 delete from public.group_messages where id = p_message;
end $$;
comment on function public.group_delete_message(uuid) is
 'Lets the author, or an unblocked owner or moderator, delete a chat message.';

revoke all on function public.group_send_message(uuid, text), public.group_delete_message(uuid)
 from public, anon;
grant execute on function public.group_send_message(uuid, text), public.group_delete_message(uuid)
 to authenticated;

do $$
begin
 if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
  if not exists (select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public'
      and tablename = 'group_messages') then
   alter publication supabase_realtime add table public.group_messages;
  end if;
 end if;
end $$;

commit;
