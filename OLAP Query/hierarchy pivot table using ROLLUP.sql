
with a as (
    select
           concat_ws('-',c3.title,c2.title,c1.title) as category,
           coalesce((paid_at::date)::text,'total') as day,
           round(sum(quantity*pii.price+pii.delivery_cost)/10000) as gmv
    from laravel.payment_invoices pi
    join laravel.payment_invoice_items pii
    on pi.id = pii.invoice_id and pi.status = 2999 and pii.deleted_at isnull and pi.verified_at notnull
    join laravel.products p on p.id = pii.product_id
    join laravel.categories c1 on c1.id = p.category_id
    join laravel.categories c2 on c2.id = c1.parent_id
    join laravel.categories c3 on c3.id = c2.parent_id
    where paid_at >= current_date - 3
    group by rollup(c3.title,c2.title,c1.title), rollup(paid_at::date)
)
select case when category='' then 'total' else category end, day, gmv
from a
order by 1,2
