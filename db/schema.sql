-- 1. Dominios
create table if not exists public.countries (
  code text primary key,
  name text not null
);

create table if not exists public.categories (
  id bigint generated always as identity primary key,
  name text not null unique
);

-- 2. Comercial
create table if not exists public.products (
  id bigint generated always as identity primary key,
  name text not null,
  category_id bigint not null references public.categories(id),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  created_at timestamptz default now()
);

create table if not exists public.customers (
  id bigint generated always as identity primary key,
  name text not null,
  email text,
  country_code text references public.countries(code),
  created_at timestamptz default now()
);

create table if not exists public.invoices (
  id bigint generated always as identity primary key,
  customer_id bigint not null references public.customers(id),
  invoice_date date not null default current_date,
  total_amount numeric(14,2) not null default 0,
  created_at timestamptz default now()
);

create table if not exists public.invoice_lines (
  id bigint generated always as identity primary key,
  invoice_id bigint not null references public.invoices(id) on delete cascade,
  product_id bigint not null references public.products(id),
  quantity numeric(12,2) not null check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  line_total numeric(14,2) not null check (line_total >= 0)
);









create or replace function public.invoice_line_before_insert()
returns trigger language plpgsql as $$
begin
  if new.unit_price is null then
    select unit_price into new.unit_price from public.products p where p.id = new.product_id;
  end if;
  new.line_total := round((new.quantity * new.unit_price)::numeric, 2);
  return new;
end;
$$;

create trigger trg_invoice_line_before_ins
before insert on public.invoice_lines
for each row execute function public.invoice_line_before_insert();













create table if not exists public.user_allowed_country (
  user_id uuid not null,
  country_code text not null references public.countries(code),
  primary key (user_id, country_code)
);

create table if not exists public.user_allowed_category (
  user_id uuid not null,
  category_id bigint not null references public.categories(id),
  primary key (user_id, category_id)
);








alter table public.products enable row level security;
alter table public.customers enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_lines enable row level security;




create policy products_by_user_category_select
  on public.products for select
  to authenticated
  using (exists (
    select 1 from public.user_allowed_category u
    where u.user_id = auth.uid() and u.category_id = products.category_id
  ));

create policy products_by_user_category_insert
  on public.products for insert
  to authenticated
  with check (exists (
    select 1 from public.user_allowed_category u
    where u.user_id = auth.uid() and u.category_id = products.category_id
  ));

create policy products_by_user_category_update
on public.products for update
to authenticated
using (exists (
 select 1 from public.user_allowed_category u
 where u.user_id = auth.uid() and u.category_id = products.category_id
))
with check (exists (
 select 1 from public.user_allowed_category u
 where u.user_id = auth.uid() and u.category_id = products.category_id
));

create policy products_by_user_category_delete
on public.products for delete
to authenticated
using (exists (
 select 1 from public.user_allowed_category u
 where u.user_id = auth.uid() and u.category_id = products.category_id
));








create policy customers_by_user_country_select
  on public.customers for select
  to authenticated
  using (exists (
    select 1 from public.user_allowed_country u
    where u.user_id = auth.uid() and u.country_code = customers.country_code
  ));






create policy invoices_by_user_country_select
on public.invoices for select
to authenticated
using (exists (
 select 1
 from public.customers c
 join public.user_allowed_country u
 on u.country_code = c.country_code and u.user_id = auth.uid()
 where c.id = invoices.customer_id
));

create policy "invoices_by_user_country_insert"
on public.invoices
for insert
to authenticated
with check (exists (
  select 1
  from public.customers c
  join public.user_allowed_country u
    on u.country_code = c.country_code 
   and u.user_id = auth.uid()
  where c.id = invoices.customer_id
));

create policy "invoices_by_user_country_update"
on public.invoices
for update
to authenticated
using (
  exists (
    select 1
    from public.customers c
    join public.user_allowed_country u
      on u.country_code = c.country_code
     and u.user_id = auth.uid()
    where c.id = invoices.customer_id
  )
)
with check (
  exists (
    select 1
    from public.customers c
    join public.user_allowed_country u
      on u.country_code = c.country_code
     and u.user_id = auth.uid()
    where c.id = invoices.customer_id
  )
);




create policy "lines_by_country_and_category_select"
on public.invoice_lines for select
to authenticated
using (
 exists (
 select 1
 from public.invoices i
 join public.customers c on c.id = i.customer_id
 join public.user_allowed_country uc
 on uc.country_code = c.country_code and uc.user_id = auth.uid()
 where i.id = invoice_lines.invoice_id
 )
 and
 exists (
 select 1
 from public.products p
 join public.user_allowed_category ug
 on ug.category_id = p.category_id and ug.user_id = auth.uid()
 where p.id = invoice_lines.product_id
 )
);


create policy "lines_by_country_and_category_cud"
on public.invoice_lines for all
to authenticated
using (
 exists (
 select 1
 from public.invoices i
 join public.customers c on c.id = i.customer_id
 join public.user_allowed_country uc
 on uc.country_code = c.country_code and uc.user_id = auth.uid()
 where i.id = invoice_lines.invoice_id
 )
 and
 exists (
 select 1
 from public.products p
 join public.user_allowed_category ug
 on ug.category_id = p.category_id and ug.user_id = auth.uid()
 where p.id = invoice_lines.product_id
 )
)
with check (
 exists (
 select 1
 from public.invoices i
 join public.customers c on c.id = i.customer_id
 join public.user_allowed_country uc
 on uc.country_code = c.country_code and uc.user_id = auth.uid()
 where i.id = invoice_lines.invoice_id
 )
 and
 exists (
 select 1
 from public.products p
 join public.user_allowed_category ug
 on ug.category_id = p.category_id and ug.user_id = auth.uid()
 where p.id = invoice_lines.product_id
 )
);




insert into public.countries (code, name) values ('CR','Costa Rica'),('US','United States');
insert into public.categories (name) values ('Electronics'),('Furniture');

insert into public.products (name, category_id, unit_price) values ('Phone', 1, 299.99), ('Chair', 2, 45.00);

insert into public.customers (name, email, country_code) values ('ACME CR','acme@cr.com','CR'), ('Globex US','sales@globex.com','US');














create or replace function public.create_invoice(
  customer_id bigint,
  items jsonb  -- [{product_id:1, quantity:2, unit_price:39.9}, ...]
) returns jsonb
language plpgsql security invoker
as $$
declare
  v_invoice_id bigint;
  v_item jsonb;
  v_product_price numeric(12,2);
  v_unit_price numeric(12,2);
  v_line_total numeric(14,2);
  v_total numeric(14,2) := 0;
begin
  -- create invoice
  insert into public.invoices(customer_id) values (customer_id) returning id into v_invoice_id;

  -- iterate items
  for v_item in select * from jsonb_array_elements(items) loop
    v_product_price := (select unit_price from public.products where id = (v_item->>'product_id')::bigint);
    if v_product_price is null then
      raise exception 'product not found %', v_item;
    end if;

    -- unit_price: use provided or product price at moment
    if (v_item ? 'unit_price') then
      v_unit_price := round((v_item->>'unit_price')::numeric,2);
    else
      v_unit_price := v_product_price;
    end if;

    v_line_total := round(((v_item->>'quantity')::numeric * v_unit_price)::numeric, 2);

    insert into public.invoice_lines(invoice_id, product_id, quantity, unit_price, line_total)
    values (v_invoice_id, (v_item->>'product_id')::bigint, (v_item->>'quantity')::numeric, v_unit_price, v_line_total);

    v_total := v_total + v_line_total;
  end loop;

  -- update invoice total
  update public.invoices set total_amount = v_total where id = v_invoice_id;

  return jsonb_build_object('invoice_id', v_invoice_id, 'total', v_total);
exception when others then
  -- any error rollback automatic in plpgsql if unhandled; raise to client
  raise;
end;
$$;






create or replace view public.v_sales_fact as
select i.id as invoice_id, i.invoice_date, c.country_code, c.name as customer_name,
       i.total_amount
from public.invoices i
join public.customers c on c.id = i.customer_id;

create or replace view public.v_sales_by_category as
select p.category_id, cat.name as category_name, sum(il.line_total) as sales_total
from public.invoice_lines il
join public.products p on p.id = il.product_id
join public.categories cat on cat.id = p.category_id
group by p.category_id, cat.name;

create or replace view public.v_sales_by_country as
select c.country_code, sum(il.line_total) as sales_total
from public.invoice_lines il
join public.invoices i on i.id = il.invoice_id
join public.customers c on c.id = i.customer_id
group by c.country_code;

create or replace view public.v_top_products_30d as
select 
    p.id as product_id,
    p.name as product_name,
    c.name as category_name,
    sum(il.quantity) as total_quantity,
    sum(il.line_total) as total_sales
from public.invoice_lines il
join public.invoices i on i.id = il.invoice_id
join public.products p on p.id = il.product_id
join public.categories c on c.id = p.category_id
where i.invoice_date >= current_date - interval '30 days'
group by p.id, p.name, c.name
order by total_quantity desc;



-- supón user_cr_uuid y user_us_uuid
--insert into public.user_allowed_country (user_id, country_code) values ('3ac54144-633d-4b23-a486-1d1a9166c07d','CR');
--insert into public.user_allowed_category (user_id, category_id) values ('3ac54144-633d-4b23-a486-1d1a9166c07d', 1); -- electronics


--insert into public.user_allowed_country (user_id, country_code) values ('decf29c7-c2b4-4a47-9060-24de7473422f','US');
--insert into public.user_allowed_category (user_id, category_id) values ('decf29c7-c2b4-4a47-9060-24de7473422f', 2); -- furniture



