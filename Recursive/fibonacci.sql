--fibonacci
with recursive fib as (
    select 0 as lvl,
           1::numeric as  fib_nbr,
           1::numeric as next_fib_nbr
    union
    select lvl + 1,
           next_fib_nbr,
           fib_nbr + next_fib_nbr
    from fib
    where lvl < 1000
)
select *
from fib;
