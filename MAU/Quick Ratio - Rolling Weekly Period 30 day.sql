--Quick Ratio - Rolling Weekly Period 30 day (Backward Checking - Generic Solution)

with days as (
    select generate_series(date_trunc('week',current_date-90), date_trunc('week',current_date), interval '1 week') as day
)
, a as (
    select day::date as day,
           user_id
    from days
    join laravel.payment_invoices pi
    on pi.paid_at >= day - interval '60 day' and pi.paid_at < day - interval '30 day'
    and pi.status = 2999 and pi.verified_at notnull
    group by day, user_id
)
, b as (
    select day::date as day,
           user_id
    from days
    join laravel.payment_invoices pi
    on pi.paid_at >= day - interval '30 day' and pi.paid_at < day
    and pi.status = 2999 and pi.verified_at notnull
    group by day, user_id
)
select coalesce(a.day, b.day) as day,
       count(b.user_id) as active,
       count(*) filter ( where a.user_id isnull ) as "new+resurrected",
       count(*) filter ( where b.user_id isnull ) as churn,
       round(1.*count(*) filter ( where a.user_id isnull ) / count(*) filter ( where b.user_id isnull ) ,2) as "Quick Ratio"
from a
full outer join b
on a.day = b.day
and a.user_id = b.user_id
group by coalesce(a.day, b.day)
order by coalesce(a.day, b.day)
