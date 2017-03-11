-- Database: movies

-- DROP DATABASE movies;

CREATE DATABASE movies
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United Kingdom.1252'
    LC_CTYPE = 'English_United Kingdom.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

COMMENT ON DATABASE movies
    IS 'Movie query system';
    
    -- Need the following extensions for this database
    
    CREATE EXTENSION tablefunc;
    CREATE EXTENSION dict_xsyn;
    CREATE EXTENSION fuzzystrmatch; -- (levenshtein)
    CREATE EXTENSION pg_trgm; -- (show_trigram)
    CREATE EXTENSION cube;
    
    
    -- Create tables, keys and constraints
    
 CREATE TABLE genres (
	name text UNIQUE,
	position integer
);
CREATE TABLE  (
	movie_id SERIAL PRIMARY KEY,
	title text,
	genre cube
);
CREATE TABLE actors (
	actor_id SERIAL PRIMARY KEY,
	name text
);

CREATE TABLE movies_actors (
	movie_id integer REFERENCES movies NOT NULL,
	actor_id integer REFERENCES actors NOT NULL,
	UNIQUE (movie_id, actor_id)
);
CREATE INDEX movies_actors_movie_id ON movies_actors (movie_id);
CREATE INDEX movies_actors_actor_id ON movies_actors (actor_id);
CREATE INDEX movies_genres_cube ON movies USING gist (genre);

-- my queries to investigate

SELECT * FROM genres;
SELECT * FROM movies;
SELECT * FROM actors;
SELECT * FROM movies_actors ma
JOIN movies m ON 
m.movie_id = ma.movie_id
JOIN actors a ON 
a.actor_id = ma.actor_id
;

-- LIKE

SELECT * FROM movies WHERE title ILIKE 'stardust%';
-- 2 rows

SELECT * FROM movies WHERE title ILIKE 'stardust_%';
-- 1 row

-- REGEX
-- POSIX style in postgres
-- ! not matching
-- ~ operator
-- * case insensitive

SELECT COUNT(*) FROM movies WHERE title !~* '^the.*';

-- can create indexes to help on pattern searches

CREATE INDEX movies_title_pattern ON movies (lower(title) text_pattern_ops);

-- used text_pattern_ops as was using text 
-- can use varchar_pattern_ops etc for others

-- Levenshtein
-- How close values each character is to one and another

SELECT levenshtein('vat','fads');

-- 3 is score as two changed (+2) and one added (+1)
-- 0 would mean same

SELECT levenshtein('vat','fad') fad,
levenshtein('bat','fat') fad,
levenshtein('bat','bat')  bat;
-- 2 1 0

-- changes in case also cause a point so might want to convert to upper

SELECT movie_id, title
FROM movies
WHERE levenshtein(lower(title), lower ('a hard day nght')) <= 3;

-- 245,'A Hard Day's Night'

-- Trigram 
-- three consecutive chars from a string, as many as can

SELECT show_trgm('Avatar');
-- '["  a"," av","ar ","ata","ava","tar","vat"]'

-- Create index specifallay for searching like this 

CREATE INDEX movies_title_trigram ON movies
USING gist (title gist_trgm_ops);

-- aside - tried looking how to do variables.. hmmm
SET foo.moviesearch = 'Avatre';
SELECT show_trgm(current_setting('foo.moviesearch'));

SELECT title, show_trgm(title),show_trgm(current_setting('foo.moviesearch'))
FROM movies
WHERE title % current_setting('foo.moviesearch');

-- Full Text Searching

-- TSVector and TSQuery

-- first look at the default @@ behaviour

SELECT title
FROM movies
WHERE title @@ 'night & day';

/*
-- note brings back those with apostrophes
'A Hard Day's Night'
'Six Days Seven Nights'
'Long Day's Journey Into Night'
*/

-- which is equivalent to...

SELECT title
FROM movies
WHERE TO_TSVECTOR(title) @@ TO_TSQUERY('english', 'night & day');

-- splits into components called lexemes

SELECT TO_TSVECTOR('A Hard Day''s Night')
,TO_TSQUERY('english', 'night & day');

-- ''day':3 'hard':2 'night':5',''night' & 'day''

-- simple words are missed (e.g. a above)

SELECT *
FROM movies
WHERE title @@ TO_TSQUERY('english', 'a');
-- so now rows returned


SELECT TO_TSVECTOR('english','A Hard Day''s Night');
-- ''day':3 'hard':2 'night':5'
SELECT TO_TSVECTOR('simple','A Hard Day''s Night');
-- ''a':1 'day':3 'hard':2 'night':5 's':4'
-- second one has simple words too

-- Other Languages

SELECT ts_lexize('english_stem', 'Day''s');
-- '["day"]'

SELECT to_tsvector('german', 'was machst du gerade?');
-- ''gerad':4 'mach':2'

-- Indexing Lexemes

EXPLAIN
SELECT *
FROM movies
WHERE title @@ 'night & day';

/*
'Seq Scan on movies  (cost=0.00..815.86 rows=3 width=171)'
'  Filter: (title @@ 'night & day'::text)'
*/

-- seq scan on whole tale which is not good

-- so create index...
CREATE INDEX movies_title_searchable ON movies
USING gin(to_tsvector('english', title));

-- and plan becomes...
EXPLAIN
SELECT *
FROM movies
WHERE title @@ 'night & day';

/*
--nothing happened.. didnt use index

'Seq Scan on movies  (cost=0.00..815.86 rows=3 width=171)'
'  Filter: (title @@ 'night & day'::text)'
*/

-- now uses index
-- EXPLAIN is good to ensure indexes are used
EXPLAIN
SELECT *
FROM movies
WHERE to_tsvector('english',title) @@ 'night & day';
/*
'Bitmap Heap Scan on movies  (cost=20.00..24.26 rows=1 width=171)'
'  Recheck Cond: (to_tsvector('english'::regconfig, title) @@ '''night'' & ''day'''::tsquery)'
'  ->  Bitmap Index Scan on movies_title_searchable  (cost=0.00..20.00 rows=1 width=0)'
'        Index Cond: (to_tsvector('english'::regconfig, title) @@ '''night'' & ''day'''::tsquery)'

*/

-- Metafones

-- Can search for things that sound the same...

SELECT *
FROM actors
WHERE name = 'Broos Wils';

-- trigram no good

SELECT *
FROM actors
WHERE name %'Broos Wils'; 

-- Metafone of Aaron Eckhart us ARNKHRT

SELECT title
FROM movies NATURAL JOIN movies_actors NATURAL JOIN actors
WHERE metaphone(name,6) =  metaphone('Broos Wils',6);

-- NATURAL JOIN matches on matching column names
-- comes from fuzzystrmatch module which contains more...

SELECT name, metaphone(name,8) , dmetaphone(name) , dmetaphone_ALT(name) , soundex(name)  
FROM actors;

-- Cube
-- Each value is point in 18 dimensional space
-- Genre created earlier is cube as films have multiple genres

SELECT 
name, cube_ur_coord('(0,7,0,0,0,0,0,0,0,7,0,0,0,0,10,0,0,0)', position)  as score
FROM genres g
WHERE cube_ur_coord('(0,7,0,0,0,0,0,0,0,7,0,0,0,0,10,0,0,0)', position) > 0;

/*
'Adventure','7'
'Fantasy','7'
'SciFi','10'
*/

-- can look for films most similar to star wars...

SELECT 
*, cube_distance(genre,'(0,7,0,0,0,0,0,0,0,7,0,0,0,0,10,0,0,0)')  as dist
FROM movies
ORDER BY dist;

/*
1,'Star Wars','(0, 7, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 10, 0, 0, 0)','0'
532,'Star Wars: Episode V - The Empire Strikes Back','(0, 7, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 2, 10, 0, 0, 0)','2'
2862,'Avatar','(0, 7, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 5, 10, 0, 0, 0)','5'
1357,'Explorers','(0, 5, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 5, 0, 0, 0)','5.74456264653803'
696,'The Lost World','(0, 5, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 4, 0, 0, 0)','6.6332495807108'
193,'E.T. The Extra-Terrestrial','(0, 5, 0, 0, 0, 0, 0, 5, 0, 5, 0, 0, 0, 0, 5, 0, 0, 0)','7.61577310586391'
325,'Krull','(0, 5, 0, 0, 0, 0, 0, 5, 0, 5, 0, 0, 0, 0, 7, 0, 0, 0)','6.48074069840786'

...
*/

-- simple example - 2d square
-- cube_enlarge(cube, radius, dimensions)

SELECT cube_enlarge ('(1,1)',1,2);

/*
'(0, 0),(2, 2)'
*/

-- so lookin got films within five units of an 18 dimension cube (Star wars)

SELECT 
title, cube_distance(genre,'(0,7,0,0,0,0,0,0,0,7,0,0,0,0,10,0,0,0)')  as dist
FROM movies
WHERE cube_enlarge('(0,7,0,0,0,0,0,0,0,7,0,0,0,0,10,0,0,0)'::cube,5,18) @> genre
ORDER BY dist;

/*
'Star Wars','0'
'Star Wars: Episode V - The Empire Strikes Back','2'
'Avatar','5'
'Explorers','5.74456264653803'
'Krull','6.48074069840786'
'E.T. The Extra-Terrestrial','7.61577310586391'
*/

-- can use subselect to get genre of movie rather than hard code like star wars above

SELECT m.movie_id, m.title
FROM movies m, (SELECT genre, title FROM movies WHERE title = 'Mad Max') s
WHERE cube_enlarge(s.genre,5,18) @> m.genre AND s.title <> m.title
ORDER BY cube_distance(m.genre, s.genre)
LIMIT 10;

/*
1405,'Cyborg'
1391,'Escape from L.A.'
1192,'Mad Max Beyond Thunderdome'
1189,'Universal Soldier'
1222,'Soldier'
1362,'Johnny Mnemonic'
946,'Alive'
418,'Escape from New York'
1877,'The Last Starfighter'
1445,'The Rocketeer'

*/

/*
Homework Part 1
Create Procedure wheere input movie or actor and returns top 5 suggestions based on
movies actor has starred in or films with similar genres
*/

-- DROP FUNCTION move_suggest_top5(text,text); -- can't alter return type so have to drop
CREATE OR REPLACE FUNCTION move_suggest_top5 (movietitle text DEFAULT '', actorname text DEFAULT '')
RETURNS TABLE(
    title text
)
AS $$

BEGIN 
IF movietitle <> '' THEN
RETURN QUERY 

      SELECT  m.title
    FROM movies m , movies m2
     WHERE (movietitle <> '' AND m2.title = movietitle AND m.title <> m2.title)
     ORDER BY cube_distance(m.genre, m2.genre)
    LIMIT 5;
    END IF;
    
    IF actorname <> '' THEN
RETURN QUERY 

      SELECT  m.title
    FROM movies m
    JOIN movies_actors ma ON
    ma.movie_id = m.movie_id
    JOIN actors a ON
    a.actor_id = ma.actor_id
    WHERE a.name = actorname
    LIMIT 5;
    END IF;

 END;
 $$
 
LANGUAGE 'plpgsql';

    SELECT move_suggest_top5('Star Wars'); -- where multiple columns comes back in one column in brackets
    SELECT * FROM  move_suggest_top5('Star Wars'); -- returns as result set
       SELECT move_suggest_top5('','Bruce Willis'); -- where multiple columns comes back in one column in brackets
     SELECT * FROM move_suggest_top5('','Bruce Willis'); -- returns as result set
    

/*
Homework Part 2
Expand movies database to track user comments and extract kewyords, cross reference
with actors last names and find most talked about actors
*/












 