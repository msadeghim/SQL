with a as (
    select pi.id,
           pi.user_id,
           pi.paid_at,
           amount,
           sum(quantity*price+delivery_cost) as gmv
    from laravel.payment_invoices pi
    join laravel.payment_invoice_items pii
    on pi.id = pii.invoice_id and pi.status = 2999 and pii.deleted_at isnull and pi.verified_at notnull and pii.vendor_product_discount < 2000000 and pii.vendor_id <> 266
    where amount >= 0 and paid_at > current_date - interval '3 month'
    group by pi.id
)
, data as (
    select user_id,
           date_part('epoch', justify_interval( (now() at time zone 'asia/tehran')-max(paid_at)))::int / (60*60*24) as  recency,
           count(*) as frequency,
           sum(amount+coalesce(cre,0)) as monetary,
           sum(gmv) as gmv
    from a pi
    left join (select invoice_id, sum(charged_amount) as cre
                from laravel.spent_credits s
                join laravel.credits c on c.id = s.credit_id
                where c.credit_type = 3533 and s.applied_at NOTNULL
                and c.deleted_at isnull
                group by invoice_id ) s
    on s.invoice_id = pi.id
    group by user_id
--     having count(*) > 1
), quantiles as (
    select
           percentile_disc(.25) within group ( order by recency ) as recency_quant1,
           percentile_disc(.50) within group ( order by recency ) as recency_quant2,
           percentile_disc(.75) within group ( order by recency ) as recency_quant3,

           percentile_disc(.24) within group ( order by frequency ) as frequency_quant1,
           percentile_disc(.50) within group ( order by frequency ) as frequency_quant2,
           percentile_disc(.75) within group ( order by frequency ) as frequency_quant3,

           percentile_disc(.25) within group ( order by monetary ) as monetary_quant1,
           percentile_disc(.50) within group ( order by monetary ) as monetary_quant2,
           percentile_disc(.75) within group ( order by monetary ) as monetary_quant3
    from data
)
, scores as (
    select data.*,
           case when recency <= recency_quant1 then 1
                when recency <= recency_quant2 then 2
                when recency <= recency_quant3 then 3
                else 4 end as recency_score,
           case when frequency <= frequency_quant1 then 1
                when frequency <= frequency_quant2 then 2
                when frequency <= frequency_quant3 then 3
                else 4 end as frequency_score,
           case when monetary <= monetary_quant1 then 1
                when monetary <= monetary_quant2 then 2
                when monetary <= monetary_quant3 then 3
                else 4 end as monetary_score
    from data, quantiles
)
, segment as (
    select *, concat(recency_score, frequency_score, monetary_score) as "RFM concat score"
    from scores
)
select *
from segment s
