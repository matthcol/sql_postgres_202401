-- implicit indexes: unique constraint (primary key, unique)
-- btree index (1 column)
-- bitmap index (composite pk or unique)

--predicate =
select 
	id,
	title,
	year
from movies
where id = 5257;

select * from pg_index;

select * from pg_class 
where relkind = 'i'  -- i: index, r: table, S: sequence, v: view ... 
-- and relowner = ...
;


select 
	id,
	title,
	year
from movies
where title = 'The Man Who Knew Too Much';

select 
	id,
	title,
	year
from movies
where 
	title = 'The Man Who Knew Too Much'
	and year = 1956;
	
select 
	id,
	title,
	year
from movies
where year = 1997;

-- no index on column duration
select 
	id,
	title,
	year
from movies
where duration >= 180;

-- other predicates
-- varchar: like, dictionary order
-- numeric: <, >, between, ...
select 
	title
from movies
where title like 'The Man Who Knew Too %';

select 
	title
from movies
where title ilike 'The Man Who Knew Too %';

-- NB: see collate to improve usage of index with like, <, >
select 
	*
from movies
where title ilike 'The Man Who Knew Too %';

select datname, 
       datcollate
from pg_database;

select 
	title
from movies
where title ilike '%episode%';

select 
	*
from movies
where title ilike '%episode%';

-- drop index uniq_movies:
alter table movies drop constraint uniq_movies;
create index idx_movies_title on movies(title);

select
	m.title, 
	m.year,
	p.name
from
	movies m
	join persons p on m.director_id = p.id
where 
	p.name = 'Quentin Tarantino'  -- filter on table persons directly
order by m.year;

create index idx_movies_director on movies(director_id); -- btree
drop index idx_movies_director;

select 
	year % 10 as year_decade,
	year / 10 as decade,
	title,
	year
from movies
where year / 10 = 198
order by year_decade;

create index idx_movies_decade on movies((year / 10));
drop index idx_movies_decade;
create index idx_movies_decade on movies using BRIN ((year / 10)) ;
drop index idx_movies_decade;
	


select
	m.title,
	m.year,
	d.name as director,
	a.name as actor,
	p.role
from 
	movies m
	inner join persons d on m.director_id = d.id
	inner join play p on p.movie_id = m.id
	inner join persons a on p.actor_id = a.id
where 
	-- m.title like 'Hot Fuzz'
	d.name = 'Edgar Wright'
order by a.name;

select
	m.title,
	m.year,
	d.name as director,
	a.name as actor,
	p.role
from 
	persons a
	inner join play p on p.actor_id = a.id
	inner join movies m on p.movie_id = m.id
	inner join persons d on m.director_id = d.id
where 
	-- m.title like 'Hot Fuzz'
	d.name = 'Edgar Wright'
order by a.name;

select
	m.title,
	m.year,
	g.genre,
	d.name as director,
	a.name as actor,
	p.role
from 
	persons a
	inner join play p on p.actor_id = a.id
	inner join movies m on p.movie_id = m.id
	inner join persons d on m.director_id = d.id
	inner join have_genre g on g.movie_id = m.id
where 
	-- m.title like 'Hot Fuzz'
	d.name = 'Edgar Wright'
order by a.name;

select
	m.title,
	m.year,
	g.genre,
	d.name as director,
	a.name as actor,
	p.role
from 
	persons a
	inner join play p on p.actor_id = a.id
	inner join movies m on p.movie_id = m.id
	inner join persons d on m.director_id = d.id
	inner join have_genre g on g.movie_id = m.id
where 
	m.duration >= 100
	and m.year between 1990 and 2009
	and p.role = 'James Bond'
	and d.name = 'Martin Campbell'
	and g.genre in ('Thriller', 'Comedy')
order by a.name;


select 
	m.director_id,
	count(m.id) as nb_directed_movies
from movies m
group by m.director_id;

select 
	d.id,
	d.name, -- ok because DF d.id -> d.name
	count(m.id) as nb_directed_movies
from 
	movies m
	join persons d on m.director_id = d.id
group by d.id;

select 
	p.id,
	p.name, -- ok because DF d.id -> d.name
	p.birthdate, -- ok because DF d.id -> d.birthdate
	count(m.id) as nb_directed_movies,
	coalesce(sum(m.duration), 0) as total_directed_duration,
	min(m.year) as first_directed_year,
	max(m.year) as last_directed_year,
	string_agg(m.title, ', ' order by m.year)  as directed_filmography 
from 
	persons p
	left outer join movies m on m.director_id = p.id
where p.name in (
	'Clint Eastwood',
	'Quentin Tarantino',
	'Alfred Hitchcock',
	'Steve McQueen',
	'Simon Pegg'
)
group by p.id;

select * from persons where birthdate = null; -- no results
select * from persons where birthdate is null; -- results

with person_selection as (
	select * 
	from persons p
	where p.name in (
		'Clint Eastwood',
		'Quentin Tarantino',
		'Alfred Hitchcock',
		'Steve McQueen',
		'Simon Pegg'
	)
),
director_filmography as (
	select 
		m.director_id,
		count(m.id) as nb_directed_movies,
		coalesce(sum(m.duration), 0) as total_directed_duration,
		min(m.year) as first_directed_year,
		max(m.year) as last_directed_year,
		string_agg(m.title, ', ' order by m.year)  as directed_filmography 
	from  movies m 
	where m.director in (select id from person_selection)
),
actor_filmography as (
	select 
		pl.actor_id,
		count(m.id) as nb_played_movies,
		coalesce(sum(m.duration), 0) as total_played_duration,
		min(m.year) as first_played_year,
		max(m.year) as last_played_year,
		string_agg(m.title, ', ' order by m.year)  as played_filmography 
	from  movies m join play pl on pl.movie_id = m.id
	where pl.actor_id in (select id from person_selection)
)
select
	p.id,
	p.name,
	p.birthdate,
	df.*,
	af.*
from 
	person_selection p
	left join director_filmography df on p.id = df.director_id
	left join actor_filmography af on p.id = af.actor_id
;

select *
from persons p
where exists (select * from movies where director_id = p.id)
and not exists (select * from play where actor_id = p.id);

select current_timestamp;

-- statistics:
-- doc: https://www.postgresql.org/docs/16/monitoring-stats.html

-- recompute stats on a table
analyze movies;
-- recompute stats on all database
analyze;

-- summary stat table on columns
SELECT attname, inherited, n_distinct,
       array_to_string(most_common_vals, E'\n') as most_common_vals
FROM pg_stats
WHERE tablename = 'movies';

select * from pg_stats;



-- NB: see dashboard and statistics on GUI PGAdmin IV


-- transaction
begin;

update persons set  birthdate = current_date
where name = 'Simon Pegg';

select * from persons
where name = 'Simon Pegg';

update persons set  birthdate = '2000-04-02'
where name = 'Quentin Tarantino';

-- locks on transactions
select * from pg_locks where relation = (select oid from pg_class where relname = 'persons')
order by pid; -- pid = 123


select * from pg_stat_activity where pid = 123; -- oid session = "16384"

-- en cours : RowExclusiveLock + AccessShareLock
-- en attente : RowExclusiveLock + ExclusiveLock

-- kill session by pid
select pg_terminate_backend('123');
select pg_terminate_backend('12876'); -- sûr d'arreter
select pg_cancel_backend('12876');  -- trop gentil 

commit;













