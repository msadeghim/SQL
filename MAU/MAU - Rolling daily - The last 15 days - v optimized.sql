--MAU - Rolling daily - The last 15 days
--v optimized
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
    from (
            select generate_series(current_date-45, current_date-30, interval '1 day') as day
            union all
            select generate_series(current_date-15, current_date, interval '1 day') as day
         ) d
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
where day >= current_date - interval '15 day'
