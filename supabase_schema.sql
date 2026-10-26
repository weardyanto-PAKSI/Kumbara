-- Skema penyimpanan cloud KUMBARA
-- Jalankan sekali di Supabase Dashboard > SQL Editor.

create table if not exists public.kumbara_question_banks (
  id text primary key,
  data jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.kumbara_feedback (
  id bigint primary key,
  data jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.kumbara_question_suggestions (
  id bigint primary key,
  data jsonb not null,
  created_at timestamptz not null default now()
);

alter table public.kumbara_question_banks enable row level security;
alter table public.kumbara_feedback enable row level security;
alter table public.kumbara_question_suggestions enable row level security;

-- Semua pengunjung boleh membaca bank soal untuk memainkan game.
drop policy if exists "Public can read KUMBARA question banks" on public.kumbara_question_banks;
create policy "Public can read KUMBARA question banks"
  on public.kumbara_question_banks for select to anon, authenticated using (true);

-- Hanya akun yang login melalui Supabase Auth boleh mengubah bank soal.
drop policy if exists "Authenticated users manage KUMBARA question banks" on public.kumbara_question_banks;
create policy "Authenticated users manage KUMBARA question banks"
  on public.kumbara_question_banks for all to authenticated using (true) with check (true);

-- Pemain tanpa login boleh mengirim feedback; hanya akun login boleh membaca/mengelola feedback.
drop policy if exists "Public can submit KUMBARA feedback" on public.kumbara_feedback;
create policy "Public can submit KUMBARA feedback"
  on public.kumbara_feedback for insert to anon, authenticated with check (true);
drop policy if exists "Authenticated users read KUMBARA feedback" on public.kumbara_feedback;
create policy "Authenticated users read KUMBARA feedback"
  on public.kumbara_feedback for select to authenticated using (true);
drop policy if exists "Authenticated users delete KUMBARA feedback" on public.kumbara_feedback;
create policy "Authenticated users delete KUMBARA feedback"
  on public.kumbara_feedback for delete to authenticated using (true);

-- Pemain boleh mengirim usulan; hanya akun login boleh membaca, menyetujui, menolak, atau menghapusnya.
drop policy if exists "Public can submit KUMBARA suggestions" on public.kumbara_question_suggestions;
create policy "Public can submit KUMBARA suggestions"
  on public.kumbara_question_suggestions for insert to anon, authenticated with check (true);
drop policy if exists "Authenticated users read KUMBARA suggestions" on public.kumbara_question_suggestions;
create policy "Authenticated users read KUMBARA suggestions"
  on public.kumbara_question_suggestions for select to authenticated using (true);
drop policy if exists "Authenticated users update KUMBARA suggestions" on public.kumbara_question_suggestions;
create policy "Authenticated users update KUMBARA suggestions"
  on public.kumbara_question_suggestions for update to authenticated using (true) with check (true);
drop policy if exists "Authenticated users delete KUMBARA suggestions" on public.kumbara_question_suggestions;
create policy "Authenticated users delete KUMBARA suggestions"
  on public.kumbara_question_suggestions for delete to authenticated using (true);

grant select on public.kumbara_question_banks to anon, authenticated;
grant insert, select, update, delete on public.kumbara_question_banks to authenticated;
grant insert on public.kumbara_feedback to anon, authenticated;
grant select, delete on public.kumbara_feedback to authenticated;
grant insert on public.kumbara_question_suggestions to anon, authenticated;
grant select, update, delete on public.kumbara_question_suggestions to authenticated;
