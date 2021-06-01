
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
, purchase_nbr0 as (
    select id, user_id, paid_at,
           row_number() over (partition by user_id order by paid_at) as rnk
    from laravel.payment_invoices
    where status = 2999
    and verified_at notnull
    and deleted_at isnull
)
, purchase_nbr as (
    select pi.*,
           (quantity*price+delivery_cost) as amount
    from purchase_nbr0 pi
    join laravel.payment_invoice_items pii
    on pi.id = pii.invoice_id and pii.deleted_at isnull and pii.vendor_product_discount < 2000000 and pii.vendor_id <> 266
)
, jmonth_userid as (
    select j.month_nbr, j.jmonth,
           pi.user_id,
           round(sum(amount)/10) as amount,
           min(rnk) as rnk,
           max(jmonth)
           over(partition by user_id
               order by month_nbr
               range between 1 preceding and 1 preceding) as backward_cheking,
           max(jmonth)
           over(partition by user_id
               order by month_nbr
               range between 1 following and 1 following) as forward_cheking
    from purchase_nbr pi
    join jmonth j on pi.paid_at >= j.s and pi.paid_at < j.e
    group by j.month_nbr, j.jmonth, pi.user_id
)
, lable as (
    select month_nbr, jmonth, user_id, amount,
           case when rnk = 1 then 'new'
                when rnk > 1 and backward_cheking notnull then 'retained'
                when rnk > 1 and backward_cheking isnull then 'resurrected' end as NewRetRes,
           case when forward_cheking isnull then 'churned' else 'retained' end as NextChuRet
    from jmonth_userid
)
, churnAmount as (
    select month_nbr, jmonth, -sum(amount) as churn
    from lable
    where NextChuRet = 'churned'
    group by month_nbr, jmonth
)
, extraContra as (
    select cur.month_nbr, cur.jmonth,
           sum(case when cur.amount - pre.amount < 0 then 0 else cur.amount - pre.amount end) as extraction,
           sum(case when cur.amount - pre.amount < 0 then cur.amount - pre.amount else 0 end) as contraction
    from lable pre
    join lable cur
    on pre.user_id = cur.user_id
    and pre.NextChuRet = 'retained'
    and cur.NewRetRes = 'retained'
    and pre.month_nbr + 1 = cur.month_nbr
    group by cur.month_nbr, cur.jmonth
)
, newResRetained as (
    select month_nbr, jmonth,
           sum(amount) filter ( where NewRetRes = 'new' ) as new,
           sum(amount) filter ( where NewRetRes = 'resurrected' ) as resurrected,
           sum(amount) filter ( where NewRetRes = 'retained' ) as retained
    from lable
    group by month_nbr, jmonth
)
, k as (
select nr.jmonth,
       nr.new+ nr.resurrected+ec.extraction+ ec.contraction+ca.churn as value
from newResRetained nr
join extraContra ec on nr.month_nbr = ec.month_nbr
join churnAmount ca on ca.month_nbr+1 = nr.month_nbr
union all
select '0intial', 2886863476
)
select jmonth,
       sum(value) over(order by jmonth) as cumsum
from k
order by jmonth
