with jmonth as (
    select *,
           lead(s,1,bi.j2g('1401-01-01')) over(order by s) as e
    from (select concat_ws('-',y::text,lpad(m::text,2,'0')) as jmonth,
                 bi.j2g(concat_ws('-',y::text,lpad(m::text,2,'0'),'01')) as s,
                 row_number() over (order by y, m) as month_nbr
            from generate_series(1398,1400) y(y)
                ,generate_series(1,12) m(m)
            where concat_ws('-',y::text,lpad(m::text,2,'0')) >= '1398-12'
        ) d
)
select jmonth, sum(quantity*price+delivery_cost)/10 as gmv
from laravel.payment_invoices pi
join laravel.payment_invoice_items pii
on pi.id = pii.invoice_id and pi.status = 2999 and pii.deleted_at isnull and pi.verified_at notnull and pii.vendor_product_discount < 2000000 and pii.vendor_id <> 266
join jmonth on paid_at >= s and paid_at < e
group by jmonth
order by jmonth
