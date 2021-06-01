
with recursive a as (
    select  ' *********'
            '   *******'
            '** *******'
            '**    ****'
            '***** ****'
            '*****   **'
            '      ****'
            '* **  ****'
            '* ** *****'
            '*         ' as map,
           1 as pos,
           'start' as direction,
           0 as steps
    union
    select substr(map, 1, pos-1) || '*' || substr(map, pos+1),
           pos + k,
           direction || ' ' ||
               case k when -1 then 'left'
                      when 1 then 'right'
                      when -10 then 'up' else 'dowm' end::text,
           steps + 1
    from a
    , (values (-1), (1), (-10), (+10)) d(k)
    where pos <> 100
    and not ( k = -1 and (pos-1)%10 = 0 ) --left
    and not ( k = 1 and pos%10=0 ) -- right
    and not ( k = -10 and pos <= 10 ) --up
    and not ( k = 10 and pos > 90  )
    and not substr(map, pos+k, 1) = '*'
)
select steps,direction
from a
where pos=100
order by steps
limit 1
