
--MAU - Rolling daily - The last 15 days
--(left) self join
with f as (
    select *, row_number() over (partition by user_id order by paid_at) as rnk
    from laravel.payment_invoices pi
    where pi.status = 2999 and pi.verified_at notnull
)
,a0 as (
    select day::date as day,
           user_id,
           min(rnk) as rnk
    from generate_series(current_date-interval '45 day', current_date, interval '1 day') d(day)
    join f pi on pi.paid_at >= day - interval '30 day' and pi.paid_at < day
    group by day::date, user_id
)
, a as (
    select cur.*,
           pre.user_id as backward
    from a0 cur
    left join a0 pre
    on cur.user_id = pre.user_id
    and pre.day+30 = cur.day
)
,b as (
    select day,
           count(*) as active,
           count(*) filter ( where backward notnull ) as retained,
           count(*) filter ( where rnk =1 ) as new
    from a
    group by day
    order by day
)
, c as (
    select b.*,
           b.active - b.retained - b.new as resurrected,
           bb.active - b.retained as churn
    from b
    join b bb on bb.day+30 = b.day
)
select *
from c
where day >= current_date - interval '15 day'
order by day
