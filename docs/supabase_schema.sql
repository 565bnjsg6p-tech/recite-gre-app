-- Recite cloud sync schema for Supabase.
-- Run this in the Supabase SQL editor after creating the project.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text not null default '',
  preferred_language text not null default 'english',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.study_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  language text not null default 'english',
  daily_new_words integer not null default 30,
  daily_review_limit integer not null default 80,
  exam_date date,
  settings_json jsonb not null default '{}'::jsonb,
  client_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, language)
);

create table if not exists public.word_cards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  language text not null default 'english',
  source_type text not null default 'personal',
  book_key text not null default '',
  word text not null,
  chinese_meaning text not null default '',
  english_meaning text not null default '',
  gre_focus text not null default '',
  roots_json jsonb not null default '[]'::jsonb,
  synonyms_json jsonb not null default '[]'::jsonb,
  antonyms_json jsonb not null default '[]'::jsonb,
  example text not null default '',
  memory_tip text not null default '',
  note text not null default '',
  tags_json jsonb not null default '[]'::jsonb,
  mastery integer not null default 0,
  due_at timestamptz not null default now(),
  review_count integer not null default 0,
  lapse_count integer not null default 0,
  ease_factor integer not null default 250,
  interval_days integer not null default 0,
  enrichment_status text not null default 'queued',
  client_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, language, source_type, book_key, word)
);

create table if not exists public.word_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  language text not null default 'english',
  book_key text not null,
  word text not null,
  chinese_meaning text not null default '',
  english_meaning text not null default '',
  gre_focus text not null default '',
  roots_json jsonb not null default '[]'::jsonb,
  synonyms_json jsonb not null default '[]'::jsonb,
  antonyms_json jsonb not null default '[]'::jsonb,
  example text not null default '',
  memory_tip text not null default '',
  note text not null default '',
  tags_json jsonb not null default '[]'::jsonb,
  mastery integer not null default 0,
  due_at timestamptz not null default now(),
  review_count integer not null default 0,
  lapse_count integer not null default 0,
  ease_factor integer not null default 250,
  interval_days integer not null default 0,
  enrichment_status text not null default 'dictionary',
  client_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, language, book_key, word)
);

create table if not exists public.review_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  word_card_id uuid references public.word_cards(id) on delete set null,
  local_word_id text,
  source_type text not null default '',
  book_key text not null default '',
  word text not null default '',
  rating text not null,
  reviewed_at timestamptz not null,
  client_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table public.word_cards
  add column if not exists ease_factor integer not null default 250;

alter table public.word_cards
  add column if not exists interval_days integer not null default 0;

alter table public.word_cards
  add column if not exists source_type text not null default 'personal';

alter table public.word_cards
  add column if not exists book_key text not null default '';

alter table public.review_logs
  add column if not exists source_type text not null default '';

alter table public.review_logs
  add column if not exists book_key text not null default '';

alter table public.review_logs
  add column if not exists word text not null default '';

do $$
begin
  if exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'word_cards'
      and constraint_name = 'word_cards_user_id_language_word_key'
  ) then
    alter table public.word_cards
      drop constraint word_cards_user_id_language_word_key;
  end if;

  if exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'word_cards'
      and constraint_name = 'word_cards_user_id_language_source_type_book_key_key'
  ) then
    alter table public.word_cards
      drop constraint word_cards_user_id_language_source_type_book_key_key;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.word_cards'::regclass
      and conname = 'word_cards_user_language_source_book_word_key'
  ) then
    drop index if exists public.word_cards_user_language_source_book_word_key;

    alter table public.word_cards
      add constraint word_cards_user_language_source_book_word_key
      unique (user_id, language, source_type, book_key, word);
  end if;
end $$;

-- Move existing cloud-synced book words into the lightweight progress table.
-- The full built-in dictionary stays in the app assets; Supabase keeps only
-- per-user study state, notes, tags, and optional AI-enriched content.
insert into public.word_progress (
  user_id,
  language,
  book_key,
  word,
  chinese_meaning,
  english_meaning,
  gre_focus,
  roots_json,
  synonyms_json,
  antonyms_json,
  example,
  memory_tip,
  note,
  tags_json,
  mastery,
  due_at,
  review_count,
  lapse_count,
  ease_factor,
  interval_days,
  enrichment_status,
  client_updated_at,
  created_at,
  updated_at,
  deleted_at
)
select
  user_id,
  language,
  book_key,
  word,
  chinese_meaning,
  english_meaning,
  gre_focus,
  roots_json,
  synonyms_json,
  antonyms_json,
  example,
  memory_tip,
  note,
  tags_json,
  mastery,
  due_at,
  review_count,
  lapse_count,
  ease_factor,
  interval_days,
  enrichment_status,
  client_updated_at,
  created_at,
  now() as updated_at,
  deleted_at
from public.word_cards
where source_type = 'book'
  and book_key <> ''
  and (
    review_count > 0
    or mastery > 0
    or lapse_count > 0
    or interval_days > 0
    or note <> ''
    or enrichment_status <> 'dictionary'
    or jsonb_array_length(roots_json) > 0
    or jsonb_array_length(synonyms_json) > 0
    or jsonb_array_length(antonyms_json) > 0
    or example <> ''
    or deleted_at is not null
  )
on conflict (user_id, language, book_key, word) do update set
  chinese_meaning = excluded.chinese_meaning,
  english_meaning = excluded.english_meaning,
  gre_focus = excluded.gre_focus,
  roots_json = excluded.roots_json,
  synonyms_json = excluded.synonyms_json,
  antonyms_json = excluded.antonyms_json,
  example = excluded.example,
  memory_tip = excluded.memory_tip,
  note = excluded.note,
  tags_json = excluded.tags_json,
  mastery = excluded.mastery,
  due_at = excluded.due_at,
  review_count = excluded.review_count,
  lapse_count = excluded.lapse_count,
  ease_factor = excluded.ease_factor,
  interval_days = excluded.interval_days,
  enrichment_status = excluded.enrichment_status,
  client_updated_at = excluded.client_updated_at,
  deleted_at = excluded.deleted_at;

create index if not exists profiles_user_active_idx
  on public.profiles (id)
  where deleted_at is null;

create index if not exists study_settings_user_updated_idx
  on public.study_settings (user_id, updated_at);

create index if not exists word_cards_user_updated_idx
  on public.word_cards (user_id, updated_at);

create index if not exists word_cards_user_due_idx
  on public.word_cards (user_id, due_at)
  where deleted_at is null;

create index if not exists word_progress_user_updated_idx
  on public.word_progress (user_id, updated_at);

create index if not exists word_progress_user_due_idx
  on public.word_progress (user_id, due_at)
  where deleted_at is null;

create index if not exists word_progress_user_book_word_idx
  on public.word_progress (user_id, book_key, word);

create index if not exists review_logs_user_updated_idx
  on public.review_logs (user_id, updated_at);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists study_settings_set_updated_at on public.study_settings;
create trigger study_settings_set_updated_at
before update on public.study_settings
for each row execute function public.set_updated_at();

drop trigger if exists word_cards_set_updated_at on public.word_cards;
create trigger word_cards_set_updated_at
before update on public.word_cards
for each row execute function public.set_updated_at();

drop trigger if exists word_progress_set_updated_at on public.word_progress;
create trigger word_progress_set_updated_at
before update on public.word_progress
for each row execute function public.set_updated_at();

drop trigger if exists review_logs_set_updated_at on public.review_logs;
create trigger review_logs_set_updated_at
before update on public.review_logs
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.study_settings enable row level security;
alter table public.word_cards enable row level security;
alter table public.word_progress enable row level security;
alter table public.review_logs enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select
using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles for insert
with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "study_settings_select_own" on public.study_settings;
create policy "study_settings_select_own"
on public.study_settings for select
using (auth.uid() = user_id);

drop policy if exists "study_settings_insert_own" on public.study_settings;
create policy "study_settings_insert_own"
on public.study_settings for insert
with check (auth.uid() = user_id);

drop policy if exists "study_settings_update_own" on public.study_settings;
create policy "study_settings_update_own"
on public.study_settings for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "word_cards_select_own" on public.word_cards;
create policy "word_cards_select_own"
on public.word_cards for select
using (auth.uid() = user_id);

drop policy if exists "word_cards_insert_own" on public.word_cards;
create policy "word_cards_insert_own"
on public.word_cards for insert
with check (auth.uid() = user_id);

drop policy if exists "word_cards_update_own" on public.word_cards;
create policy "word_cards_update_own"
on public.word_cards for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "word_progress_select_own" on public.word_progress;
create policy "word_progress_select_own"
on public.word_progress for select
using (auth.uid() = user_id);

drop policy if exists "word_progress_insert_own" on public.word_progress;
create policy "word_progress_insert_own"
on public.word_progress for insert
with check (auth.uid() = user_id);

drop policy if exists "word_progress_update_own" on public.word_progress;
create policy "word_progress_update_own"
on public.word_progress for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "review_logs_select_own" on public.review_logs;
create policy "review_logs_select_own"
on public.review_logs for select
using (auth.uid() = user_id);

drop policy if exists "review_logs_insert_own" on public.review_logs;
create policy "review_logs_insert_own"
on public.review_logs for insert
with check (auth.uid() = user_id);

drop policy if exists "review_logs_update_own" on public.review_logs;
create policy "review_logs_update_own"
on public.review_logs for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Force PostgREST to refresh its schema cache after column/constraint changes.
notify pgrst, 'reload schema';
