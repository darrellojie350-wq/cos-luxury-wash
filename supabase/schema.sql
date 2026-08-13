-- CO's Luxury Wash — Supabase schema
-- Run in supabase SQL editor. Replace RLS policies as needed for production.

-- Profiles (extends auth.users)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  email text,
  phone text,
  avatar_url text,
  wallet_balance numeric default 0,
  created_at timestamptz default now()
);
alter table public.profiles enable row level security;
create policy "own profile" on public.profiles for select using (auth.uid() = id);
create policy "update own profile" on public.profiles for update using (auth.uid() = id);
create policy "insert own profile" on public.profiles for insert with check (auth.uid() = id);

-- Services
create table if not exists public.services (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  icon text,
  category text,
  price_per_bag numeric default 1500,
  sort int default 0,
  is_active boolean default true
);
insert into public.services (name, description, icon, category, price_per_bag, sort) values
 ('Wash & Fold','For everyday clothes','laundry','wash',1500,1),
 ('Shoes Cleaning','Special care for shoes','shoe','shoes',2500,2),
 ('Bedding & Linens','Sheets, duvet, curtains','bed','bedding',3500,3),
 ('Others','Bags, hats, accessories','bag','other',1200,4)
on conflict do nothing;

-- Addresses
create table if not exists public.addresses (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  label text,
  full_address text not null,
  is_default boolean default false,
  created_at timestamptz default now()
);
alter table public.addresses enable row level security;
create policy "own addresses" on public.addresses for all using (auth.uid() = user_id);

-- Orders
create table if not exists public.orders (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  service_id uuid references public.services(id),
  status text default 'booked',
  bags int default 1,
  pickup_address text,
  pickup_date text,
  pickup_time text,
  delivery_address text,
  delivery_date text,
  delivery_time text,
  ride_fee numeric default 0,
  laundry_total numeric default 0,
  payment_method text,
  ride_payment_status text default 'unpaid',
  laundry_payment_status text default 'unpaid',
  rider_id uuid,
  created_at timestamptz default now()
);
alter table public.orders enable row level security;
create policy "own orders" on public.orders for all using (auth.uid() = user_id);

-- Order status history
create table if not exists public.order_status_history (
  id uuid default gen_random_uuid() primary key,
  order_id uuid references public.orders(id) on delete cascade,
  status text,
  note text,
  created_at timestamptz default now()
);
alter table public.order_status_history enable row level security;
create policy "own history" on public.order_status_history for select using (true);

-- Payments
create table if not exists public.payments (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id),
  order_id uuid references public.orders(id) on delete set null,
  amount numeric,
  method text,
  type text, -- 'ride' | 'laundry'
  status text default 'pending',
  reference text,
  created_at timestamptz default now()
);
alter table public.payments enable row level security;
create policy "own payments" on public.payments for select using (auth.uid() = user_id);
create policy "insert own payments" on public.payments for insert with check (auth.uid() = user_id);

-- Wallet transactions
create table if not exists public.wallet_transactions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id),
  amount numeric,
  type text, -- 'topup' | 'debit' | 'refund'
  description text,
  created_at timestamptz default now()
);
alter table public.wallet_transactions enable row level security;
create policy "own txns" on public.wallet_transactions for all using (auth.uid() = user_id);

-- Riders
create table if not exists public.riders (
  id uuid default gen_random_uuid() primary key,
  name text,
  phone text,
  rating numeric default 5,
  is_available boolean default true
);
insert into public.riders (name, phone, rating, is_available) values ('Tunde Okoye','0803 555 0192',4.9,true) on conflict do nothing;

-- increment wallet helper
create or replace function public.increment_wallet(amount numeric)
returns void language plpgsql security definer as $$
begin
  update public.profiles set wallet_balance = coalesce(wallet_balance,0) + amount
  where id = auth.uid();
  insert into public.wallet_transactions (user_id, amount, type, description)
  values (auth.uid(), amount, 'topup', 'Wallet top-up');
end;
$$;