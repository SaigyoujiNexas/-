with mark_mov(title_id) as (
    select crew.title_id
    from crew
    where crew.person_id = (
    select people.person_id 
        from people
        where people.name == 'Mark Hamill' and born == 1951
    )
),
george_mov(title_id) as(
    select crew.title_id
    from crew
    where crew.person_id = (
    select people.person_id
        from people
        where people.name = 'George Lucas' and born = 1944
    )
),
common_mov(title_id) as(
    select t1.title_id
    from mark_mov t1
    join george_mov t2 on t1.title_id = t2.title_id
)
    select titles.primary_title
    from titles
join common_mov cm on titles.title_id = cm.title_id and titles.type == 'movie'
order by titles.primary_title asc;
