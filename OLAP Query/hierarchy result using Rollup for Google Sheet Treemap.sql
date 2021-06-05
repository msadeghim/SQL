
select split_part(concat_ws(',',c.title,c2.title,c3.title,'root'),',',1) as category,
       split_part(concat_ws(',',c.title,c2.title,c3.title,'root'),',',2) as parent,
       round(sum(quantity*pii.price+delivery_cost)/10) as gmv
from laravel.payment_invoice_items pii
join laravel.payment_invoices pi
on pii.invoice_id = pi.id
and pii.deleted_at isnull
and pi.status = 2999
and pi.deleted_at isnull
and pii.vendor_id <> 266
and pi.verified_at notnull
and pii.vendor_product_discount < 2000000
join laravel.products p on p.id = product_id
join laravel.categories c on c.id = p.category_id
join laravel.categories c2 on c2.id = c.parent_id
join laravel.categories c3 on c3.id = c2.parent_id
where pi.paid_at > current_date - 30
and c3.enabled and c2.enabled and c.enabled
group by rollup(c3.title, c2.title, c.title)
