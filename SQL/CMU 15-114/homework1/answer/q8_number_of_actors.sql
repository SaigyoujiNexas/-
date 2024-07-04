with crew_contain_mark as(
select distinct(title_id) from 
    crew
    where person_id = (select person_id from people where
    name == 'Mark Hamill' and born == 1951)
)
select count(distinct(crew.person_id))
from crew
where crew.title_id in crew_contain_mark and 
(crew.category == "actor" or crew.category == "actress");

