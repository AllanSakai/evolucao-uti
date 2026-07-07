create table if not exists public.user_medications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  medication_id text not null,
  name text not null,
  dose text not null,
  presentation text not null,
  use_type text not null,
  route text not null,
  administered_quantity text not null,
  frequency text not null,
  dispensing_quantity text not null default '',
  notes text not null default '',
  updated_at timestamptz not null default now(),
  unique (user_id, medication_id)
);

alter table public.user_medications enable row level security;

drop policy if exists "Usuario le seus proprios medicamentos"
  on public.user_medications;
drop policy if exists "Usuario cria seus proprios medicamentos"
  on public.user_medications;
drop policy if exists "Usuario atualiza seus proprios medicamentos"
  on public.user_medications;
drop policy if exists "Usuario apaga seus proprios medicamentos"
  on public.user_medications;

create policy "Usuario le seus proprios medicamentos"
  on public.user_medications
  for select
  using (auth.uid() = user_id);

create policy "Usuario cria seus proprios medicamentos"
  on public.user_medications
  for insert
  with check (auth.uid() = user_id);

create policy "Usuario atualiza seus proprios medicamentos"
  on public.user_medications
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Usuario apaga seus proprios medicamentos"
  on public.user_medications
  for delete
  using (auth.uid() = user_id);
