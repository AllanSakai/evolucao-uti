create table if not exists public.user_prescription_protocols (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  protocol_id text not null,
  name text not null,
  medications jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now(),
  unique (user_id, protocol_id)
);

alter table public.user_prescription_protocols enable row level security;

drop policy if exists "Usuario le seus proprios protocolos"
  on public.user_prescription_protocols;
drop policy if exists "Usuario cria seus proprios protocolos"
  on public.user_prescription_protocols;
drop policy if exists "Usuario atualiza seus proprios protocolos"
  on public.user_prescription_protocols;
drop policy if exists "Usuario apaga seus proprios protocolos"
  on public.user_prescription_protocols;

create policy "Usuario le seus proprios protocolos"
  on public.user_prescription_protocols
  for select
  using (auth.uid() = user_id);

create policy "Usuario cria seus proprios protocolos"
  on public.user_prescription_protocols
  for insert
  with check (auth.uid() = user_id);

create policy "Usuario atualiza seus proprios protocolos"
  on public.user_prescription_protocols
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Usuario apaga seus proprios protocolos"
  on public.user_prescription_protocols
  for delete
  using (auth.uid() = user_id);
