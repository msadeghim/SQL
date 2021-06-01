with a as (
    select day::Date as day,
           count(distinct user_id) filter ( where paid_at >= day - interval '1 day' ) as DAU,
           count(distinct user_id) filter ( where paid_at >= day - interval '1 week' ) as WAU,
           count(distinct user_id) filter ( where paid_at >= day - interval '1 month' ) as MAU
    from generate_series(current_date-60, current_date, interval '1 day') d(day)
    join laravel.payment_invoices pi
    on pi.paid_at >= day - interval '1 month' and pi.paid_at < day
    where pi.status = 2999 and pi.verified_at notnull
    group by day
)
select *,
       round(100.0*DAU/WAU,2) as "DAU/WAU Percent",
       round(100.0*DAU/MAU,2) as "DAU/MAU Percent",
       round(100.0*WAU/MAU,2) as "WAU/MAU Percent"
from a
