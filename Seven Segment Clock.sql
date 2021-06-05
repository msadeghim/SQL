
with time as (
select unnest(array[
        date_part('hour',t)::int / 10
        ,date_part('hour',t)::int % 10
        ,date_part('minute',t)::int / 10
        ,date_part('minute',t)::int % 10
        ,date_part('second',t)::int / 10
        ,date_part('second',t)::int % 10
       ]) as val,
       unnest(array[0,1,2,3,4,5]) as pos
from (select now()::time) d(t)
)
, digits(d,row,col) as (
    values
        (0,1,1),(0,1,2),(0,1,3),(0,2,1),(0,2,3),(0,3,1),(0,3,3),(0,4,1),(0,4,3),(0,5,1),(0,5,2),(0,5,3),
        (1,1,3),(1,2,3),(1,3,3),(1,4,3),(1,5,3),
        (2,1,1),(2,1,2),(2,1,3),(2,2,3),(2,3,3),(2,3,2),(2,3,1),(2,4,1),(2,5,1),(2,5,2),(2,5,3),
        (3,1,1),(3,1,2),(3,1,3),(3,2,3),(3,3,1),(3,3,3),(3,4,3),(3,5,1),(3,5,2),(3,5,3),(3,3,2),
        (4,1,1),(4,1,3),(4,2,1),(4,2,3),(4,3,1),(4,3,3),(4,4,3),(4,5,3),(4,3,2),
        (5,1,1),(5,1,2),(5,1,3),(5,2,1),(5,3,1),(5,3,2),(5,3,3),(5,4,3),(5,5,1),(5,5,2),(5,5,3),
        (6,1,1),(6,1,2),(6,1,3),(6,2,1),(6,3,1),(6,3,3),(6,4,1),(6,4,3),(6,5,1),(6,5,2),(6,5,3),(6,3,2),
        (7,1,1),(7,1,2),(7,1,3),(7,3,3),(7,4,3),(7,5,3),(7,2,3),
        (8,1,1),(8,1,2),(8,1,3),(8,2,1),(8,2,3),(8,3,1),(8,3,3),(8,4,1),(8,4,3),(8,5,1),(8,5,2),(8,5,3),(8,3,2),
        (9,1,1),(9,1,2),(9,1,3),(9,2,1),(9,2,3),(9,3,1),(9,3,3),(9,4,3),(9,5,1),(9,5,2),(9,5,3),(9,3,2)
)
select row, col+4*pos as col, '.' as val
from time t
join digits d on t.val = d.d
union all select 2,4,','
union all select 2,8,','
union all select 2,12,','
union all select 2,16,','
union all select 2,20,','
order by row, col
