select (premiered / 10) as decade || '0s', count(*) as cnt 
from titles 
where premiered is not null 
group by decade
order by cnt desc;
