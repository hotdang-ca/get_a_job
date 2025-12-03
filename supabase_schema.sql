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
  user_id uuid references auth.users(id) on delete cascade,
  position integer default 0,
  constraint jobs_pkey primary key (id)
);

-- Create the account_requests table
create table public.account_requests (
  id uuid not null default gen_random_uuid(),
  name text not null,
  phone text not null,
  email text not null,
  created_at timestamp with time zone not null default now(),
  status text not null default 'pending',
  constraint account_requests_pkey primary key (id)
);

-- Enable Row Level Security (RLS)
alter table public.jobs enable row level security;
alter table public.account_requests enable row level security;

-- Create policies for jobs table (authenticated users only)
create policy "Users can view their own jobs"
on public.jobs
for select
to authenticated
using (auth.uid() = user_id);

create policy "Users can insert their own jobs"
on public.jobs
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "Users can update their own jobs"
on public.jobs
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete their own jobs"
on public.jobs
for delete
to authenticated
using (auth.uid() = user_id);

-- Create policies for account_requests table (allow anonymous inserts)
create policy "Anyone can submit account requests"
on public.account_requests
for insert
to anon, authenticated
with check (true);

create policy "Only authenticated users can view account requests"
on public.account_requests
for select
to authenticated
using (true);

