with recursive items as (
    select item from unnest(array['1','2','3','4']) d(item)
),
rcte as (
    select array[item] as item from items
    union
    select array_append(r.item,  i.item)
    from rcte r
    join items i
    on not (r.item @> array[i.item])
)
select * from rcte
