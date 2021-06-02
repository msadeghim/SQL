--MRR Rolling daily - The last 10 days
--v1 range frame window function
with purchase_nbr0 as (
    select id, user_id, paid_at,
           row_number() over (partition by user_id order by paid_at) as rnk
    from laravel.payment_invoices
    where status = 2999
    and verified_at notnull
    and deleted_at isnull
)
, jmonth_userid as (
    select day::date as day,
           pi.user_id,
           round(sum(quantity*price+delivery_cost)/10) as amount,
           min(rnk) as rnk,
           count(count(*))
           over(partition by pi.user_id order by day::date
               range between interval '30 day' preceding and interval '30 day' preceding ) as backward_cheking,
           count(count(*))
           over(partition by pi.user_id order by day::date
               range between interval '30 day' following and interval '30 day' following ) as forward_cheking
    from (
        select generate_series(current_date-40,current_date-30,interval'1 day') a
        union all
        select generate_series(current_date-10,current_date,interval'1 day') a
         ) d(day)
    join purchase_nbr0 pi on pi.paid_at >= day - interval '30 day' and pi.paid_at < day
    join laravel.payment_invoice_items pii
    on pi.id = pii.invoice_id and pii.deleted_at isnull and pii.vendor_product_discount < 2000000 and pii.vendor_id <> 266
    group by day::date, pi.user_id
)
, lable as (
    select day, user_id, amount,
           case when rnk = 1 then 'new'
                when rnk > 1 and backward_cheking > 0 then 'retained'
                when rnk > 1 and backward_cheking = 0 then 'resurrected' end as NewRetRes,
           case when forward_cheking = 0 then 'churned' else 'retained' end as NextChuRet
    from jmonth_userid
)
, churnAmount as (
    select day, -sum(amount) as churn
    from lable
    where NextChuRet = 'churned'
    group by day
)
, extraContra as (
    select cur.day,
           sum(case when cur.amount - pre.amount < 0 then 0 else cur.amount - pre.amount end) as extraction,
           sum(case when cur.amount - pre.amount < 0 then cur.amount - pre.amount else 0 end) as contraction
    from lable pre
    join lable cur
    on pre.user_id = cur.user_id
    and pre.NextChuRet = 'retained'
    and cur.NewRetRes = 'retained'
    and pre.day + 30 = cur.day
    group by cur.day
)
, newResRetained as (
    select day,
           sum(amount) filter ( where NewRetRes = 'new' ) as new,
           sum(amount) filter ( where NewRetRes = 'resurrected' ) as resurrected,
           sum(amount) filter ( where NewRetRes = 'retained' ) as retained
    from lable
    group by day
)
select nr.day,
       nr.new, nr.resurrected, nr.retained,
       nr.new+nr.resurrected+nr.retained as gmv,
       ec.extraction, ec.contraction,
       ca.churn
from newResRetained nr
join extraContra ec on nr.day = ec.day
join churnAmount ca on ca.day+30 = nr.day
where nr.day > current_date - 10
order by nr.day
