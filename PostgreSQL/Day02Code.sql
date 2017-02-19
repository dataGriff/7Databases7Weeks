/*
Insert more test data into events

SELECT * FROM events;

SELECT * FROM venues;
*/ /*Insert some more data for aggregates*/
INSERT INTO EVENTS (title,
                    starts,
                    ends,
                    venue_id)
VALUES ('Moby',
        '2012-02-06 21:00',
        '2012-02-06 23:00' ,
          (SELECT venue_id
           FROM venues
           WHERE name = 'Crystal Ballroom' ) ), ('Wedding',
                                                 '2012-02-26 21:00',
                                                 '2012-02-26 23:00' ,
                                                   (SELECT venue_id
                                                    FROM venues
                                                    WHERE name = 'Voodo Donuts' ) ), ('Valentines Day',
                                                                                      '2012-02-14 00:00',
                                                                                      '2012-02-14 23:59',
                                                                                      NULL );

/*Count aggregate with LIKE*/
SELECT COUNT (title)
FROM EVENTS
WHERE title LIKE '%Day%';

/*Count is a BIGINT*/ /*Min and Max Aggregate*/
SELECT MIN(starts),
       MAX(ends),
       MIN(ends)
FROM EVENTS
INNER JOIN venues ON events.venue_id = venues.venue_id
WHERE venues.name = 'Crystal Ballroom';

/*tells you the aggregate and data type in column output*/ /*Group By*/
SELECT venue_id,
       COUNT(*)
FROM EVENTS
GROUP BY venue_id;

/*HAVING*/
SELECT venue_id,
       COUNT(*)
FROM EVENTS
GROUP BY venue_id
HAVING COUNT(*) >=2
AND venue_id IS NOT NULL;

/*GROUP BY no aggregage and DISTINCT*/
SELECT venue_id
FROM EVENTS
GROUP BY venue_id;


SELECT DISTINCT venue_id
FROM EVENTS;

/*Window Functions
SELECT * FROM events;*/
SELECT title,
       COUNT(*) OVER (PARTITION BY venue_id)
FROM EVENTS
ORDER BY venue_id;

/*counts number of events at same venue as event being pulled back*/ /*Transactions*/ BEGIN TRANSACTION;


DELETE
FROM EVENTS;


ROLLBACK;


SELECT *
FROM EVENTS;

/*nothing happened as rolled back*/ /*classic bank transaction example to ensure done properly*/ /*
BEGIN TRANSACTION;
UPDATE account SET total=total+5000.0 WHERE account_id=1337;
UPDATE account SET total=total-5000.0 WHERE account_id=45887;
END;
*/ /*
Stored Routines
Performance advantages over huge architectureal costs..?
Vendor lock if business logic in the database.. shame as database
can be good place to store it
Surely still vendor lock in other products anyway
*/ /*
Function (procedure) takes in parameters
Returns boolean of whether inserted or not
Finds venue id from venues table
Returns a message (raise notice) of the venue id if it is found
Language is declared at the end as postgre supports 3 languages
https://www.postgresql.org/docs/9.1/static/plpgsql.html
plpgsql
Tcl, perl and Python
Also extensions written for
Ruby, Java, PHP, Scheme and others...
https://www.postgresql.org/docs/9.1/static/app-createlang.html
*/
CREATE OR REPLACE FUNCTION add_event(title text, starts TIMESTAMP, ends TIMESTAMP, venue text, postal varchar(9), country char(2)) RETURNS boolean AS $$
DECLARE
  did_insert boolean := false;
  found_count integer;
  the_venue_id integer;
BEGIN
  SELECT venue_id INTO the_venue_id
  FROM venues v
  WHERE v.postal_code=postal AND v.country_code=country AND v.name ILIKE venue
  LIMIT 1;

  IF the_venue_id IS NULL THEN
    INSERT INTO venues (name, postal_code, country_code)
    VALUES (venue, postal, country)
    RETURNING venue_id INTO the_venue_id;

    did_insert := true;
  END IF;

  -- Note: not an “error”, as in some programming languages
  RAISE NOTICE 'Venue found %', the_venue_id;

  INSERT INTO events (title, starts, ends, venue_id)
  VALUES (title, starts, ends, the_venue_id);

  RETURN did_insert;
END;
$$ LANGUAGE plpgsql;

/*
Execute procedure
*/
SELECT add_event('House PArty','2012-05-03 23:00', '2012-05-04 02:00', 'Run''a House', '97205','us');

/*returns true as did insert*/ /*
                 See if could install pytho in books database
                 */
CREATE EXTENSION plpythonu;

/*error as not in library*/
CREATE EXTENSION plpython3;

/*still error
                       so downloaded latest python
                       https://www.python.org/
                       attempted to understand this...
                       http://stackoverflow.com/questions/24216627/how-to-install-pl-python-on-postgresql-9-3-x64-windows-7/24218449#24218449
                       */
CREATE EXTENSION plpython3u;

/*
                       ERROR:  could not load library "C:/Program Files/PostgreSQL/9.6/lib/plpython3.dll": The specified module could not be found.
but it is in here... C:\Program Files\PostgreSQL\9.6\lib
                       */ /*
                       then gave up as didnt want to download all pythons..
                       http://stackoverflow.com/questions/39800075/error-during-create-extension-plpython3u-on-postgresql-9-6-0
                       */ /*
        Triggers - Using a log table and procedure
        https://www.postgresql.org/docs/9.1/static/triggers.html
        */ /*
   Create Log Table
   */
CREATE TABLE logs( event_id INTEGER, old_title VARCHAR(255),
                                               old_starts TIMESTAMP,
                                                          old_ends TIMESTAMP,
                                                                   logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP );

/*
   Create procedure that will be executed by trigger
   */
CREATE OR REPLACE FUNCTION log_event() RETURNS TRIGGER AS $$
DECLARE
BEGIN
  INSERT INTO logs (event_id, old_title, old_starts, old_ends)
  VALUES (OLD.event_id, OLD.title, OLD.starts, OLD.ends);
  RAISE NOTICE 'Someone just changed event #%', OLD.event_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/*
Create Trigger
*/
CREATE TRIGGER log_events AFTER
UPDATE ON EVENTS
FOR EACH ROW EXECUTE PROCEDURE log_event();

/*
Execute an Update and check logs to see trigger has worked
and also see notice

Notices appear in messages

SELECT * FROM events;
*/
UPDATE EVENTS
SET ends = '2012-05-04 01:00:00'
WHERE title = 'House PArty';


SELECT event_id,
       old_title,
       old_ends,
       logged_at
FROM logs;

/*Trigger logs change*/ 

/*
Views
*/

CREATE VIEW holidays 
AS
SELECT event_id AS holiday_id, title AS name, starts AS date
FROM events
WHERE title LIKE '%Day%' AND venue_id IS NULL;

SELECT * FROM holidays;

/*Queries view and formats date*/
SELECT 
name, to_char(date, 'Month DD, YYYY') AS date
FROM holidays
WHERE date <= '2012-04-01';

/*Add a text array of colours to events table then add this to view*/
-- array data type cool
ALTER TABLE events
ADD colors TEXT ARRAY;

/*update views to have colors*/
CREATE OR REPLACE VIEW holidays 
AS
SELECT event_id AS holiday_id, title AS name, starts AS date, colors
FROM events
WHERE title LIKE '%Day%' AND venue_id IS NULL;

SELECT * FROM holidays;

-- can't update views directly...

/*
PostgreSQL execution path...
1. Client passes query in
2. Parser Converts to Query Tree
3. Query Tree gets rewritten based on rules
4. New query tree gets optimised in the planner
5. Executed and returned to client
*/

EXPLAIN VERBOSE
SELECT * FROM holidays;

EXPLAIN VERBOSE
SELECT event_id AS holiday_id, title AS name, starts AS date, colors
FROM events
WHERE title LIKE '%Day%' AND venue_id IS NULL;

/*
can see both of these are identical in their explanation
*/

/*
In order to UPDATE a view need to create a RULE which tells 
query tree what to do 
*/
CREATE RULE update_holidays AS ON UPDATE TO holidays DO INSTEAD
  UPDATE events
  SET title = NEW.name,
      starts = NEW.date,
      colors = NEW.colors
  WHERE title = OLD.name;
  
  /*
  can then update view directly
  */
  UPDATE holidays SET colors = '{"red","green"}' WHERE name = 'Christmas Day';
  
  /*
  Create rule for insert
  */
  CREATE RULE insert_holidays AS ON INSERT TO holidays DO INSTEAD
INSERT INTO Events (title, starts, colors)
VALUES( NEW.name,
       NEW.date,
       NEW.colors);
       
       SELECT * FROM holidays;
       
       /*
       Crosstab (Pivot)
       */
       
       /*First just have a look at data by year and month*/
       SELECT 
       extract(year from starts) AS year,
       extract(month from starts) as month, count(*)
       FROM events
       GROUP BY year, month
       ORDER BY year, month;
       
       -- need this to use crosstab
       CREATE EXTENSION tablefunc;
       
       -- need temp table to store numbers for cross tab months in the next query
       -- just makes it easier
       CREATE TEMPORARY TABLE month_count(month INT);
       INSERT INTO month_count VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12);
       
       -- Builds a calendar of how many events exist in a year
       -- need the add so postgres knows what the datatypes of output is 
SELECT * FROM crosstab(
  'SELECT extract(year from starts) as year, extract(month from starts) as month, count(*) FROM events GROUP BY year, month',
	'SELECT * FROM month_count'
) AS (
  year int,
  jan int, feb int, mar int, apr int, may int, jun int, jul int, aug int, sep int, oct int, nov int, dec int
);
-- BOOM returns data pivoted, one row for 2012 with some aggregates in some of the months

/*
Homework

1. https://www.postgresql.org/docs/9.5/static/tutorial-agg.html
2. https://www.navicat.com/products/navicat-for-postgresql
		https://wiki.postgresql.org/wiki/Community_Guide_to_PostgreSQL_GUI_Tools
            
*/

/*
Homework 1 - rule that does deletes by setting active flag to false
*/
CREATE RULE deletes_venues AS ON DELETE TO venues DO INSTEAD
  UPDATE venues
  SET active = FALSE 
  WHERE venue_id = OLD.venue_id;
  
  SELECT * FROM venues;

/*
Homework 2 - temp table not best way to do months in the pivot
use generate_series(a,b) instead
*/
SELECT * FROM crosstab(
  'SELECT extract(year from starts) as year, extract(month from starts) as month, count(*) FROM events GROUP BY year, month',
	'SELECT generate_series(1,12)'
) AS (
  year int,
  jan int, feb int, mar int, apr int, may int, jun int, jul int, aug int, sep int, oct int, nov int, dec int
);

/*
Homework 3 - build picot that displays every day in single month
       SELECT * FROM events;
       used month of feb
*/

-- created temp table of week day names to use later
       CREATE TEMPORARY TABLE weekday_names(weekday text);
       INSERT INTO weekday_names VALUES ('sunday'), ('monday'), ('tuesday'), ('wednesday'), 
       ('thursday'), ('friday'), ('saturday');
       
-- just looking at what should be getting, 4 events   
       SELECT  extract(week from starts) as week,to_char(starts, 'day') as day, count(*) FROM events
    WHERE extract(month from starts) = 2
    GROUP BY week, day;
       
       
       -- creating SQL and ensuring full month by using generate series
       select i::date 
       , count(event_id)
       from generate_series('01-FEB-2012', 
  '28-FEB-2012', '1 day'::interval) i
  LEFT JOIN (
      SELECT event_id, starts FROM events
    WHERE extract(month from starts) = 2
      ) as t ON
      t.starts::date = i -- need to cast to date as different times
      GROUP BY i::date ;
      
      -- now take out week and week day name from above
      -- read to go into crosstab at the end
             select extract(week from i::date) as week
             ,to_char(i::date, 'day') as day
       , count(event_id) as events
       from generate_series('01-FEB-2012', 
  '28-FEB-2012', '1 day'::interval) i
  LEFT JOIN (
      SELECT event_id, starts FROM events
    WHERE extract(month from starts) = 2
      ) as t ON
      t.starts::date = i -- need to cast to date as different times
          GROUP BY week, day
          ORDER BY week;
          
          -- DOES NOT WORK 
SELECT * FROM crosstab(
  '                       select extract(week from i::date) as week
             ,to_char(i::date, ''day'') as day
       , count(event_id) as events
       from generate_series(''01-FEB-2012'', 
  ''28-FEB-2012'', ''1 day''::interval) i
  LEFT JOIN (
      SELECT event_id, starts FROM events
    WHERE extract(month from starts) = 2
      ) as t ON
      t.starts::date = i -- need to cast to date as different times
          GROUP BY week, day;'
    ,'SELECT * FROM generate_series(0, 6)') 
AS (
  week int,
sunday int, monday int, tuesday int
    , wednesday int, thursday int, friday int, saturday int
);


-- Need to put query result into temp table
       CREATE TEMPORARY TABLE temptab(week int, day int, events int);
       insert into temptab
       (
           week, day, events
          )
          
SELECT 
    extract(WEEK from i) as week 
    ,extract(DOW from i) as day
    ,coalesce(count(event_id),0) as events FROM 
    generate_series('01-FEB-2012', 
  '28-FEB-2012', '1 day'::interval) i
  LEFT JOIN
    events t ON
      t.starts::date = i
       and extract(month from starts) = 2
    GROUP BY  week, day
    ORDER BY week, day;


-- then output - VOILA!
SELECT *
FROM crosstab(
    'SELECT 
   * FROM temptab'
    ,'SELECT * FROM generate_series(0, 6)') 
AS 
    (
     week int
     ,Sunday int, Monday int, Tuesday int, Wednesday int
     ,Thursday int, Friday int, Saturday int) 
ORDER BY week;









