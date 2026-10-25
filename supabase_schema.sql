-- KUMBARA Supabase schema (jalankan di SQL Editor project Supabase)
create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'admin' check (role in ('admin')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(),
  level text not null check (level in ('sd13','sd46','smp','sma')),
  question_type text not null check (question_type in ('mc','tf')),
  question text not null,
  options jsonb,
  correct_answer jsonb not null,
  explanation text not null default '',
  active boolean not null default true,
  created_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.game_sessions (
  id uuid primary key default gen_random_uuid(),
  game_mode text not null check (game_mode in ('classic','quick')),
  level text not null check (level in ('sd13','sd46','smp','sma')),
  winner_name text,
  players jsonb not null default '[]'::jsonb,
  questions_asked integer not null default 0 check (questions_asked >= 0),
  answers_correct integer not null default 0 check (answers_correct >= 0),
  special_cells integer not null default 0 check (special_cells >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.feedbacks (
  id uuid primary key default gen_random_uuid(),
  participant_name text not null check (char_length(participant_name) between 1 and 80),
  level text not null check (level in ('sd13','sd46','smp','sma')),
  game_rating smallint not null check (game_rating between 1 and 5),
  design_rating smallint not null check (design_rating between 1 and 5),
  learning_rating smallint not null check (learning_rating between 1 and 5),
  ease_rating smallint not null check (ease_rating between 1 and 5),
  suggestion text not null default '',
  question_suggestion jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor uuid references auth.users(id),
  action text not null,
  table_name text not null,
  record_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;
alter table public.questions enable row level security;
alter table public.game_sessions enable row level security;
alter table public.feedbacks enable row level security;
alter table public.audit_logs enable row level security;

-- Role checker: only active admin accounts.
create or replace function public.is_kumbara_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.admin_users a
    where a.user_id = (select auth.uid()) and a.role = 'admin' and a.active = true
  );
$$;
revoke all on function public.is_kumbara_admin() from public;
grant execute on function public.is_kumbara_admin() to authenticated;

-- Admin-only role list access. Never allow public role assignment.
drop policy if exists "admin can read own role" on public.admin_users;
create policy "admin can read own role" on public.admin_users for select to authenticated using (user_id = (select auth.uid()) and public.is_kumbara_admin());
drop policy if exists "admins manage questions" on public.questions;
create policy "public reads active questions" on public.questions for select to anon, authenticated using (active = true);
create policy "admins manage questions" on public.questions for all to authenticated using (public.is_kumbara_admin()) with check (public.is_kumbara_admin());
drop policy if exists "public can submit game sessions" on public.game_sessions;
create policy "public can submit game sessions" on public.game_sessions for insert to anon, authenticated with check (true);
drop policy if exists "admins read game sessions" on public.game_sessions;
create policy "admins read game sessions" on public.game_sessions for select to authenticated using (public.is_kumbara_admin());
drop policy if exists "public can submit feedback" on public.feedbacks;
create policy "public can submit feedback" on public.feedbacks for insert to anon, authenticated with check (true);
drop policy if exists "admins read feedback" on public.feedbacks;
create policy "admins read feedback" on public.feedbacks for select to authenticated using (public.is_kumbara_admin());
drop policy if exists "admins read audit logs" on public.audit_logs;
create policy "admins read audit logs" on public.audit_logs for select to authenticated using (public.is_kumbara_admin());
drop policy if exists "admins insert audit logs" on public.audit_logs;
create policy "admins insert audit logs" on public.audit_logs for insert to authenticated with check (public.is_kumbara_admin() and actor = (select auth.uid()));

grant select on public.questions to anon, authenticated;
grant insert on public.game_sessions, public.feedbacks to anon, authenticated;
grant select on public.game_sessions, public.feedbacks, public.audit_logs to authenticated;
grant select on public.admin_users to authenticated;
grant insert, update, delete on public.questions to authenticated;

-- IMPORTANT: after creating the first user in Authentication, insert that UUID here manually:
-- insert into public.admin_users (user_id, role, active) values ('AUTH_USER_UUID', 'admin', true);
-- Do not create an open public registration flow for admin accounts.
