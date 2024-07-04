select type, count(type) as tc from titles group by type order by tc asc;
