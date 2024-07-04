select 
cast(premiered / 10 * 10 as text) || 's' as decade,
round(cast(count(*) as real) / (select count(*) from titles) * 100.0, 4) as percentage
    from titles
where premiered is not null
group by decade
order by percentage desc, decade asc;
