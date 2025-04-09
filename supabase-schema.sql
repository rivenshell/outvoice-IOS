
-- This is the schema for the Supabase database.
-- DOCUMENTATION



-- Create profiles table that extends the auth.users table
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  email text unique not null,
  first_name text not null,
  last_name text not null,
  created_at timestamp with time zone default now() not null
);

-- Create a trigger to automatically create a profile when a new user signs up
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.profiles (id, email, first_name, last_name)
  values (new.id, new.email, '', '');
  return new;
end;
$$ language plpgsql security definer;

-- Set up the trigger on auth.users
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Create a secure RLS policy for the profiles table
alter table public.profiles enable row level security;

-- Create policy to allow users to view and update only their own profile
create policy "Users can view their own profile"
  on profiles for select
  using (auth.uid() = id);

create policy "Users can update their own profile"
  on profiles for update
  using (auth.uid() = id);

-- Create a public invoices table
create table public.invoices (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null,
  client_name text not null,
  invoice_number text not null,
  amount decimal not null,
  status text not null,
  due_date timestamp with time zone not null,
  created_at timestamp with time zone default now() not null
);

-- Set up RLS for invoices
alter table public.invoices enable row level security;

-- Create policies for invoice access
create policy "Users can view their own invoices"
  on invoices for select
  using (auth.uid() = user_id);

create policy "Users can insert their own invoices"
  on invoices for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own invoices"
  on invoices for update
  using (auth.uid() = user_id);

create policy "Users can delete their own invoices"
  on invoices for delete
  using (auth.uid() = user_id);
