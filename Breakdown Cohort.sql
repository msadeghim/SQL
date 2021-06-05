with p as (
    select distinct pi.user_id,
                    date_trunc('month',pi.paid_at)::date as purchasemonth,
                    min(date_trunc('month',pi.paid_at)) over(partition by user_id)::date as first,
                    case when u.creation_tags @> array['app:web'] then 'web'
                         when u.creation_tags @> array['app:mobile'] then 'app'
                         else 'unknown' end as client
    from laravel.payment_invoices pi
    join laravel.users u on u.id = pi.user_id
    and pi.status = 2999 and pi.verified_at notnull
    where u.creation_tags notnull
)
, a as (
    select *, dense_rank()over(order by purchasemonth) as rnk
    from p
    where first >= '2020-01-01'
    and client <> 'unknown'
)
, b as (
    select first, client, count(distinct user_id) as tot
    from a
    group by first, client
)
select concat_ws('-',a.first,a.client) as cohort, rnk, 100.0*count(*)/max(tot) as per
from a
join b on a.first = b.first and a.client = b.client
where purchasemonth > a.first
group by cohort, rnk
order by cohort, rnk

