--test query
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
select jmonth, count(distinct pi.user_id) as MAU
from laravel.payment_invoices pi
join jmonth j on pi.paid_at >= s and pi.paid_at < e
where pi.status = 2999 and pi.verified_at notnull
group by jmonth
order by jmonth
