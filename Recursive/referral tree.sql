
with recursive rec_cte as
    (
        select id as node,
               0 as parent, -- toot
               0 as level, --root
               right('000000'||id::text, 6) as path
        from laravel.users
        where id = 826

        union

        select u.id as node,
               r.node as parent,
               r.level + 1 as level,
               r.path || '->' || right('000000'||id::text, 6) as path
        from rec_cte r
        join laravel.users u
        on u.referrer_user_id = r.node
    )
select case when level = 0 then right('000000'||node::text, 6)
            else repeat('        ',level-1) || repeat('     |_ ', 1) ||
                 right('000000'||node::text, 6) || '(' || level::text ||')' end as tree,
       --level,
       path
from rec_cte
order by path
