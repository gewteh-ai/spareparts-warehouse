-- ============================================================================
-- Supabase setup for the Spare Parts Warehouse cloud version.
-- Run this ONCE in your Supabase project: SQL Editor -> New query -> paste -> Run.
-- ============================================================================

-- 1) The shared parts table. `fits` holds the compatible vehicles as JSON,
--    matching the app's data model (make/model/year/engine/trans/drive).
create table if not exists public.parts (
  id              bigint generated always as identity primary key,
  pn              text not null unique,          -- part number / SKU
  name            text not null,
  cat             text,                           -- category
  brand           text,
  price           numeric(10,2) default 0,        -- selling price (MYR)
  cost            numeric(10,2) default 0,
  oem             text,                           -- OEM / cross-ref number
  qty             int default 0,
  reorder         int default 0,                  -- low-stock threshold
  bin             text,
  engine_specific boolean default false,
  dimensions      text,                           -- optional size/spec note (e.g. length, OD, thread)
  fits            jsonb default '[]'::jsonb,      -- [{make,model,yFrom,yTo,engine,trans,drive}]
  updated_at      timestamptz default now()
);

-- 2) Row Level Security: only signed-in staff can read/write. The public
--    anon key alone cannot touch the data without a valid login.
alter table public.parts enable row level security;

drop policy if exists "staff read"   on public.parts;
drop policy if exists "staff insert" on public.parts;
drop policy if exists "staff update" on public.parts;
drop policy if exists "staff delete" on public.parts;

create policy "staff read"   on public.parts for select using (auth.role() = 'authenticated');
create policy "staff insert" on public.parts for insert with check (auth.role() = 'authenticated');
create policy "staff update" on public.parts for update using (auth.role() = 'authenticated');
create policy "staff delete" on public.parts for delete using (auth.role() = 'authenticated');

-- 3) Seed data (same examples as the prototype). Safe to delete later.
insert into public.parts (pn,name,cat,brand,price,cost,oem,qty,reorder,bin,engine_specific,fits) values
('TRE-555-1001','Tie Rod End (Outer)','Steering','555',85,52,'45046-09280',24,6,'A-12',false,
  '[{"make":"Ford","model":"Ranger","yFrom":2011,"yTo":2020,"engine":"","trans":"","drive":"4x4"},
    {"make":"Mazda","model":"BT-50","yFrom":2011,"yTo":2020,"engine":"","trans":"","drive":"4x4"}]'),
('TRE-CTR-2001','Tie Rod End (Outer)','Steering','CTR (economy)',62,38,'45046-09280',15,5,'A-13',false,
  '[{"make":"Ford","model":"Ranger","yFrom":2011,"yTo":2020,"engine":"","trans":"","drive":"4x4"},
    {"make":"Mazda","model":"BT-50","yFrom":2011,"yTo":2020,"engine":"","trans":"","drive":"4x4"}]'),
('STR-DENSO-2KD','Starter Motor','Electrical','Denso',480,350,'28100-30050',3,2,'E-04',true,
  '[{"make":"Toyota","model":"Hilux","yFrom":2005,"yTo":2015,"engine":"2KD","trans":"","drive":""},
    {"make":"Toyota","model":"Fortuner","yFrom":2005,"yTo":2015,"engine":"2KD","trans":"","drive":""}]'),
('CLK-EXEDY-HLX','Clutch Kit','Transmission','Exedy',640,470,'',2,2,'C-08',false,
  '[{"make":"Toyota","model":"Hilux","yFrom":2005,"yTo":2015,"engine":"2KD","trans":"Manual","drive":""}]'),
('BMP-FR-HLX-05','Front Bumper','Body','Aftermarket',320,210,'',4,1,'B-01',false,
  '[{"make":"Toyota","model":"Hilux","yFrom":2005,"yTo":2015,"engine":"","trans":"","drive":""}]')
on conflict (pn) do nothing;
