--MAU - Rolling once every 5 days - The last 90 days
with f as (
    select *, row_number() over (partition by user_id order by paid_at) as rnk
    from laravel.payment_invoices pi
    where pi.status = 2999 and pi.verified_at notnull
)
,a as (
    select day::date as day,
           user_id,
           min(rnk) as rnk,
           count(count(*)) over(partition by user_id order by day::date
               range between interval '30 day' preceding and interval '30 day' preceding ) as backward
    from generate_series('2021-02-01'::date+ interval '5 day' * ((current_date-'2021-06-01'::date)/5*5),
                        current_date, interval '5 day') d(day)
    join f pi on pi.paid_at >= day - interval '30 day' and pi.paid_at < day
    group by day::date, user_id
)
,b as (
    select day,
           count(*) as active,
           count(*) filter ( where backward > 0 ) as retained,
           count(*) filter ( where rnk =1 ) as new
    from a
    group by day
    order by day
)
, c as (
    select *,
           active - retained - new as resurrected,
           max(active) over(order by day range between interval '30 day' preceding and '30 day' preceding)
                    - retained as churn
    from b
)
select *
from c
where day >= current_date - interval '90 day'
order by day
