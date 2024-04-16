with recursive split(genre, rest) as(
    select '', genres || ',' from title where genres != '\n'
    union all
    SELECT substr(rest, 0, instr(rest, ',')),
        substr(rest, instr(rest, ',') + 1)
        FROM split
        WHERE rest != '';
)
SELECT genre, count(*) as genre_count
    FROM split
    WHERE genre != ''
group by genre
order by genre_count desc;
