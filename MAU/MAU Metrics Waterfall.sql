
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
, purchase_nbr as (
    select user_id, paid_at,
           row_number() over (partition by user_id order by paid_at) as rnk
    from laravel.payment_invoices
    where status = 2999
    and verified_at notnull
    and deleted_at isnull
)
, customers as (--72309
    select count(*) as cnt
    from (
        select user_id
        from laravel.payment_invoices
        where status = 2999
        and verified_at notnull
        and deleted_at isnull
        group by user_id
        having min(paid_at) < bi.j2g('1398-12-01')
    ) d
)
, jmonth_userid as (
    select j.month_nbr, j.jmonth,
           pi.user_id,
           min(rnk) as rnk,
           max(jmonth)
           over(partition by user_id
               order by month_nbr
               range between 1 preceding and 1 preceding) as pre_month_purchase
    from purchase_nbr pi
    join jmonth j on pi.paid_at >= j.s and pi.paid_at < j.e
    group by j.month_nbr, j.jmonth, pi.user_id
)
, fil as (
    select jmonth,
           count(*) as tot_month_customer,
           count(*) filter ( where rnk = 1 ) as new_cnt,
           count(*) filter ( where rnk > 1 and pre_month_purchase notnull ) as retainded_cnt,
           count(*) filter ( where rnk > 1 and pre_month_purchase isnull ) as resurrected_cnt
    from jmonth_userid
    group by jmonth
)
, f as (
select *,
       (lag(tot_month_customer)over(order by jmonth)-retainded_cnt) as chrun_cnt
from fil)
select unnest(array[jmonth||' come',jmonth||' leave']) as type,
       unnest(array[new_cnt+resurrected_cnt,-1*chrun_cnt]) as cnt
from f
where jmonth >= '1399-02'
union all
select '1399-01 initial', 16677
order by type
