with av(average_rating) as (
    select sum(rating *votes) / sum(votes)
    from ratings
    join titles
    on titles.title_id == ratings.title_id and titles.type == "movie"
),
mn(min_rating) as (select 25000.0)
select 
    primary_title,
((votes / (votes + min_rating)) * rating + (min_rating / (votes + min_rating)) * average_rating) as weighted_rating
    from ratings, av, mn
join titles
on titles.title_id == ratings.title_id and titles.type == "movie"
order by weighted_rating desc
limit 250;
