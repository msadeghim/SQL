with recursive set as (
    select item
    from unnest(array['a','b','c','d','e']) d(item)
)
, rec as (
    select array[item] as itemset
    from set
    union
    select array_append(r.itemset, s.item) as itemset
    from rec r
    join set s
    on r.itemset[array_length(r.itemset, 1)] < s.item
)
select itemset
from rec
order by array_length(itemset, 1)
