
with jmonth as (
    select *,
           lead(s,1,bi.j2g('1400-01-01')) over(order by s) as e,
           row_number() over (order by jmonth) as nbr
    from (select concat_ws('-',y::text,lpad(m::text,2,'0')) as jmonth,
                 bi.j2g(concat_ws('-',y::text,lpad(m::text,2,'0'),'01')) as s
    from generate_series(1399,1399) y(y)
         ,generate_series(1,12) m(m)) d
)
select coalesce(j.jmonth, 'sub total') as jmonth,
       coalesce(c3.title, 'sub total') as cat_title,
       round(sum(quantity*pii.price+pii.delivery_cost)/10) as gmv_toman
from laravel.payment_invoices pi
join laravel.payment_invoice_items pii
on pi.id = pii.invoice_id and pi.status = 2999 and pii.deleted_at isnull and pi.verified_at notnull
join laravel.products p on p.id = pii.product_id
join laravel.categories c1 on c1.id = p.category_id
join laravel.categories c2 on c2.id = c1.parent_id
join laravel.categories c3 on c3.id = c2.parent_id
join jmonth j on paid_at >= j.s and paid_at < j.e
group by cube (j.jmonth, c3.title)
order by j.jmonth, c3.title
