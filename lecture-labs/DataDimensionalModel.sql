select * from player_seasons;

DROP TYPE IF EXISTS season_stats CASCADE;
Create Type season_stats AS (
season INTEGER, 
gp INTEGER,
pts REAL, 
reb REAL,
ast REAL
)

DROP TABLE players
CREATE TABLE players (
	player_name TEXT, 
	height TEXT,
	college TEXT, 
	country TEXT, 
	draft_year TEXT,
	draft_round TEXT,
	draft_number TEXT,
	season_stats season_stats[],
	current_season INTEGER,
	PRIMARY KEY(player_name, current_season)
)



select MIN(season) FROM player_seasons



INSERT INTO players
with yesterday AS 
(
	SELECT * FROM players 
	WHERE current_season = 2000
), today AS ( SELECT * FROM player_seasons WHERE season = 2001)
SELECT 
COALESCE(t.player_name, y.player_name) as player_name,
COALESCE(t.height, y.height) as height,
COALESCE(t.country, y.country) as country,
COALESCE(t.college, y.college) as college,
COALESCE(t.draft_year, y.draft_year) as draft_year,
COALESCE(t.draft_round, y.draft_round) as draft_round,
COALESCE(t.draft_number, y.draft_number) as draft_number,
CASE WHEN y.season_stats is NULL THEN ARRAY[ROW(t.season, t.gp, t.pts, t.reb, t.ast)::season_stats] 
	WHEN t.season is NOT NULL THEN y.season_stats || ARRAY[ROW(t.season, t.gp ,t.pts, t.reb, t.ast)::season_stats] 
	ELSE y.season_stats
	END as season_stats,
COALESCE(t.season, y.current_season + 1) as current_season
FROM today t FULL OUTER JOIN yesterday y 
on t.player_name = y.player_name


select * from players where current_season = 2001
AND player_name = 'Michael Jordan'

select player_name, (UNNEST(season_stats)::season_stats).*  from players where current_season = 2001
AND player_name = 'Michael Jordan'


WITH unnested AS (
select player_name, UNNEST(season_stats) as season_stats
FROM players where current_season = 2001
--AND player_name = 'Michael Jordan'
)
SELECT player_name, (season_stats::season_stats).*
from unnested


Create Type scoring_class as ENUM('star', 'good', 'average', 'bad');


CREATE TABLE players (
	player_name TEXT, 
	height TEXT,
	college TEXT, 
	country TEXT, 
	draft_year TEXT,
	draft_round TEXT,
	draft_number TEXT,
	season_stats season_stats[],
	scoring_class scoring_class,
	years_since_last_season INTEGER, 
	current_season INTEGER,
	PRIMARY KEY(player_name, current_season)
)


INSERT INTO players
with yesterday AS 
(
	SELECT * FROM players 
	WHERE current_season = 2000
), today AS ( SELECT * FROM player_seasons WHERE season = 2001)
SELECT 
COALESCE(t.player_name, y.player_name) as player_name,
COALESCE(t.height, y.height) as height,
COALESCE(t.country, y.country) as country,
COALESCE(t.college, y.college) as college,
COALESCE(t.draft_year, y.draft_year) as draft_year,
COALESCE(t.draft_round, y.draft_round) as draft_round,
COALESCE(t.draft_number, y.draft_number) as draft_number,
CASE WHEN y.season_stats is NULL THEN ARRAY[ROW(t.season, t.gp, t.pts, t.reb, t.ast)::season_stats] 
	WHEN t.season is NOT NULL THEN y.season_stats || ARRAY[ROW(t.season, t.gp ,t.pts, t.reb, t.ast)::season_stats] 
	ELSE y.season_stats
	END as season_stats,
CASE  
	WHEN t.season is NOT NULL THEN 
	 CASE WHEN t.pts > 20 THEN 'star'
	 	  WHEN t.pts > 15 THEN 'good'
		  WHEN t.pts > 10 THEN 'average'
		  ELSE 'bad'
 	 END::scoring_class
	ELSE y.scoring_class
END as scoring_class,
CASE WHEN t.season IS NOT NULL THEN 0 
	ELSE  y.years_since_last_season + 1
	END as years_since_last_season,
COALESCE(t.season, y.current_season + 1) as current_season
FROM today t FULL OUTER JOIN yesterday y 
on t.player_name = y.player_name

select player_name,
(season_stats[CARDINALITY(season_stats)]::season_stats).pts/
CASE WHEN (season_stats[1]::season_stats).pts = 0 THEN 1
ELSE (season_stats[1]::season_stats).pts END

from players 
where current_season=2001 --and player_name = 'Michael Jordan'
ORDER BY 2 DESC


select player_name,
(season_stats[CARDINALITY(season_stats)]::season_stats).pts/
CASE WHEN (season_stats[1]::season_stats).pts = 0 THEN 1
ELSE (season_stats[1]::season_stats).pts END

from players 
where current_season=2001 --and player_name = 'Michael Jordan'
and scoring_class = 'star'