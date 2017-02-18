-- Database: book
 -- DROP DATABASE book;

CREATE DATABASE book WITH OWNER = postgres ENCODING = 'UTF8' LC_COLLATE = 'English_United Kingdom.1252' LC_CTYPE = 'English_United Kingdom.1252' TABLESPACE = pg_default CONNECTION LIMIT = -1;

COMMENT ON DATABASE book IS 'Book database for 7 databases in 7 weeks';


CREATE TABLE Countries (country_code CHAR(2) PRIMARY KEY,
                                                     country_name text UNIQUE);


INSERT INTO countries (country_code, country_name)
VALUES('us',
       'United States') , ('mx',
                           'Mexico') , ('au',
                                        'Australia') , ('gb',
                                                        'United Kingdom') , ('de',
                                                                             'Germany') , ('LL',
                                                                                           'Loompaland');


SELECT *
FROM Countries;


DELETE
FROM Countries
WHERE country_code = 'll';


SELECT *
FROM countries;


SELECT *
FROM cities;


UPDATE cities
SET Postal_code = '97205'
WHERE name = 'Portland';

/*
JOIN is what makes relational different to NoSQL
*/
SELECT cities.*,
       country_name
FROM cities
INNER JOIN countries ON cities.country_code = countries.country_code;

/*returns 1 row*/
CREATE TABLE venues(venue_id SERIAL PRIMARY KEY, /*SERIAL is IDENTITY (auto increment)*/ name VARCHAR(255),
                                                                                              street_address TEXT, TYPE char(7) CHECK (TYPE IN ('public',
                                                                                                                                                'private')) DEFAULT 'public',
                                                                                                                                                                    postal_code VARCHAR(9),
                                                                                                                                                                                country_code CHAR(2),
                    FOREIGN KEY (country_code,
                                 postal_code) REFERENCES cities (country_code, postal_code) MATCH FULL);


INSERT INTO venues (name, postal_code, country_code)
VALUES('Crystal Ballroom',
       '97205',
       'us');


SELECT *
FROM venues;


SELECT v.venue_id,
       v.name,
       c.name
FROM venues v
INNER JOIN cities c ON v.postal_code = c.postal_code
AND v.country_Code = c.country_code;

/*you can return the id after insert using RETURNING*/
INSERT INTO venues (name, postal_code, country_code)
VALUES('Voodo Donuts',
       '97205',
       'us') RETURNING venue_id;

/*
Outer Joins
*/ /*Create Events Table*/
CREATE TABLE EVENTS (event_id SERIAL PRIMARY KEY,
                                             title TEXT, starts TIMESTAMP,
                                                                ends TIMESTAMP,
                                                                     venue_id INT REFERENCES venues);


INSERT INTO EVENTS (title,
                    starts,
                    ends,
                    venue_id)
VALUES('LARP Club',
       '2012-02-15 17:30:00',
       '2012-02-15 19:30:00',
       2) ,('April Fools Day',
            '2012-04-01 00:00:00',
            '2012-04-01 00:00:00',
            NULL) ,('Christmas Day',
                    '2012-12-25 00:00:00',
                    '2012-12-25 23:59:00',
                    NULL)
SELECT *
FROM EVENTS;

/*
        INNER JOIN
        */
SELECT e.title,
       v.name
FROM EVENTS e
INNER JOIN venues v ON e.venue_id = v.venue_id;

/*
        LEFT JOIN
        */
SELECT e.title,
       v.name
FROM EVENTS e
LEFT JOIN venues v ON e.venue_id = v.venue_id;

/*
        RIGHT JOIN
        */
SELECT e.title,
       v.name
FROM EVENTS e
RIGHT JOIN venues v ON e.venue_id = v.venue_id;

/*
        FULL JOIN
        */
SELECT e.title,
       v.name
FROM EVENTS e
FULL JOIN venues v ON e.venue_id = v.venue_id;

/*
Indexes
Using UNIQUE keyword will force an index
HASH index means each value must be unique
btree indexes are better for more complex critieria like > or < etc
Foreign Key constraint also quto creates index on target column
*/
CREATE INDEX events_title ON EVENTS USING hash(title);


SELECT *
FROM EVENTS
WHERE starts >= '2012-04-01';


CREATE INDEX events_starts ON EVENTS USING btree(starts);


SELECT *
FROM EVENTS
WHERE starts >= '2012-04-01';

/*
 DO
 1. Select all table we create and only those form pg_class
 2. Write query that finds country name of the LARP club event
 3. Alter venues table to contain boolean column called active with default of TRUE
 */ --1
 --2

SELECT co.country_name
FROM EVENTS e
JOIN venues v ON v.venue_id = e.venue_id
JOIN cities c ON c.postal_code = v.postal_code
JOIN countries co ON co.country_code = c.country_code;

--3

ALTER TABLE venues ADD active BOOLEAN DEFAULT TRUE;

