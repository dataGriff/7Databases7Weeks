

## Links

[CommandLinePostgres](https://www.youtube.com/watch?v=fD7x8hd9yE4)
[PGAdminDoc](https://www.pgadmin.org/docs4/dev/index.html)
[PostgreGUIs](https://wiki.postgresql.org/wiki/Community_Guide_to_PostgreSQL_GUI_Tools)
[MatchFull](https://www.postgresql.org/docs/9.3/static/sql-createtable.html)
[SQLFormatter](https://sqlformat.org/)

## Command line stuff

* Open SQL Shell command line with postgres installation
* to change connection
```
\connect databasename
```
* to see language configurations
```
\dF
```
* to see dictionary
```
 \dFd
```

# PGAdmin4

* Click on SQL tab and any object gives SQL
* Has CREATE or REPLACE command
* Dashboard for activity monitor
* Dependencies and dependents of objects
* Can edit properties with more tabs, one of which is generate SQL
* Keeps history of queries automatically
* when you execut equeries in a row they UNION together automatically in query output

# General
* Syntax is case-sensitive by default
* Fails whole batch of CREATE and INSERT if referential integrity not maintained in INSEERT
* ctrl+Space for auto complete
* [QueryTool](https://www.pgadmin.org/docs4/dev/query_tool.html)
* F7 and explain tab for query plan
* Commenting is same as SQL -- and /* but only /* changes colour of syntax
* Data output shows data types as well as col names
* only shows latest result set if do two
* stopwords found here C:\\Program Files\\PostgreSQL\\9.6\\share\\tsearch_data

# Day 1

## CRUD
* Create, Read, Update and Delete
* Relational database is different to others as can JOIN objects together

# Day 2

## Aggregates
