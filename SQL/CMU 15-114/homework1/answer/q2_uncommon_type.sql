with types(type, runtime_minutes) as (
    select type, max(runtime_minutes)
    from titles
    group by type
)
select titles.type, titles.primary_title, titles.runtime_minutes 
from titles
join types
on titles.type = types.type and titles.runtime_minutes = types.runtime_minutes 
order by titles.type, titles.primary_title;
