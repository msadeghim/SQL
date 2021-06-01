
with recursive a as (
    select t,
           1 as st,
           position(' ' in t)-1 as last
    from (values('629474961969 3175587 34999439354299 989255 82967 217923251711686898198 5311536121476281 ')) t(t)
    union all
    select t,
           last+2,
           position(' ' in substr(t,last+2))+last
    from a
    where last+2 < length(t)
)
select substr(t,st,last-st+1),st,last
from a
