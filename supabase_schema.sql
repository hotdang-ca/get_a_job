-- Create the jobs table
create table public.jobs (
  id uuid not null default gen_random_uuid(),
  title text not null,
  company text,
  location text,
  pay_range text,
  source text,
  closing_date timestamp with time zone,
  created_at timestamp with time zone not null default now(),
  status text not null default 'To Apply',
  description text,
  cover_letter text,
  resume_url text,
  constraint jobs_pkey primary key (id)
);

-- Enable Row Level Security (RLS)
alter table public.jobs enable row level security;

-- Create a policy to allow all operations for the 'anon' role
-- This is required because the app is set up to not require authentication
create policy "Allow all operations for anon"
on public.jobs
for all
to anon
using (true)
with check (true);
