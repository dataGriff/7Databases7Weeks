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
    CREATE EXTENSION fuzzystrmatch;
    CREATE EXTENSION pg_trgm;
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



 