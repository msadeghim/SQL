
select day,round(100.0 * count(*) filter ( where freq >= 5 )/ count(*), 2) as L5
from (
         select d.day::date as day, user_id, count(distinct t.date_day) as freq
         from generate_series(current_date - 15, current_date, interval '1 day') d(day)
         join laravel.user_last_activity t on t.date_day between d.day::date - 30 and d.day::date
         group by d.day::date, user_id
     ) d
group by d.day
