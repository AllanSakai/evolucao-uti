alter table public.user_medications
  add column if not exists usage_tips text not null default '';

alter table public.user_prescription_protocols
  add column if not exists usage_tips text not null default '';
