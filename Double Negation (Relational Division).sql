
select id, name
from laravel.users u
where not exists (
    select *
    from laravel.categories a
    where a.parent_id = 0
    and a.enabled
    and not exists (
            select *
            from laravel.payment_invoice_items pii
            join laravel.payment_invoices pi
            on pii.invoice_id = pi.id
            and pii.deleted_at isnull
            and pi.status = 2999
            and pi.verified_at notnull
            join laravel.products p on p.id = product_id
            join laravel.categories ca on ca.id = p.category_id
            join laravel.categories cb on cb.id = ca.parent_id
            join laravel.categories cc on cc.id = cb.parent_id
            where cc.id = a.id
            and u.id = pi.user_id
        )
    )
