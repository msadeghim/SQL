
with recursive data (tid, item) as (
    select distinct pi.id, tag_id
    from laravel.payment_invoices pi
    join laravel.payment_invoice_items pii
    on pi.id = pii.invoice_id and pi.status = 2999 and pii.deleted_at isnull and pi.verified_at notnull and pii.vendor_product_discount < 2000000 and pii.vendor_id <> 266
    join bi.dailyoff_products dp on dp.product_id = pii.product_id and pi.paid_at between dp.created_at and dp.created_at+interval'25 hours' and type=0
    join lateral (select tr.tag_id
                  from laravel.tag_relations tr
                  join laravel.tags t on t.id = tr.tag_id and t.level = 3377 and tr.deleted_at isnull
                  where tr.entity_id = pii.product_id and tr.entity_type_id=2971
                  order by length(t.title)
                  limit 1) d on true
    where paid_at::date >= current_date-30
)
, agg_data as (
    select tid, array_agg(item order by item) as items, count(*) as cnt
    from data
    group by tid
)
, rec as (
    select array[item] as itemset, 1 as k, count(*) as frequency
    from data
    group by item
    having count(*) >= 50 -- min_supp
    union
    select *
    from (
             with rec_inner
                  as ( -- Workaround of error: recursive reference to query "rec" must not appear more than once
                 select * from rec
             )
             , calculate as (
                 select array_append(r1.itemset, r2.itemset[r1.k]) as itemset, r1.k + 1 as k, count(*) as frequency
                 from rec_inner r1 /*joining*/
                 join rec_inner r2
                 on r1.itemset[1:r1.k - 1] = r2.itemset[1:r1.k - 1]
                 and r1.itemset[r1.k] < r2.itemset[r1.k]
                 join rec_inner r3 /*pruning*/
                 on array_append(r1.itemset, r2.itemset[r1.k]) @> r3.itemset
                 group by array_append(r1.itemset, r2.itemset[r1.k]), r1.k
                 having count(*) = factorial(r1.k+1) / factorial(r1.k)
             )
             select j.itemset, j.k, count(*) as frequency
             from calculate j
             join agg_data a
             on a.cnt >= j.k and a.items @> j.itemset
             group by j.itemset, j.k
             having count(*) >= 5 /*min_supp*/
         ) d
)
select *
from rec
order by k
