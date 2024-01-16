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
	where m.director_id in (select id from person_selection)
	group by m.director_id
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
	group by actor_id
)
select
	p.id,
	p.name,
	p.birthdate,
	-- director stats
	coalesce(df.nb_directed_movies, 0) as nb_directed_movies,
	coalesce(df.total_directed_duration, 0) as total_directed_duration,
	df.first_directed_year,
	df.last_directed_year,
	-- 
	coalesce(af.nb_played_movies, 0) as nb_played_movies,
	coalesce(af.total_played_duration, 0) as total_played_duration,
	af.first_played_year,
	af.last_played_year
from 
	person_selection p
	left join director_filmography df on p.id = df.director_id
	left join actor_filmography af on p.id = af.actor_id
;

-- conf parameters: 
-- logging_collector: global
-- log_statement_stats: SQL queries

-- reload conf
select pg_reload_conf();





