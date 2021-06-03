--Churn Ratio - Rolling Weekly  Period 30 day (Backward Checking - Generic Solution)
with a as (
    select day::date as day,
           user_id
    from generate_series(date_trunc('week',current_date-90), date_trunc('week',current_date), interval '1 week') d(day)
    join laravel.payment_invoices pi
    on pi.paid_at >= day - interval '60 day' and pi.paid_at < day - interval '30 day'
    and pi.status = 2999 and pi.verified_at notnull
    group by day, user_id
)
select day,
       count(distinct a.user_id) filter ( where pi.user_id isnull ) as "Churn",
       count(distinct a.user_id) as "Active Period k-1",
       round(1.*count(distinct a.user_id) filter ( where pi.user_id isnull )/count(distinct a.user_id),2) as "Churn Ratio"
from a
left join laravel.payment_invoices pi
on paid_at >= day - interval '30 day' and paid_at < day
and pi.user_id = a.user_id
and status = 2999 and verified_at notnull
group by day
order by day
