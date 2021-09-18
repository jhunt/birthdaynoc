--
-- schema.sql
--
-- part of the @birthdaynoc project
-- @birthdaynoc is Copyright (c) 2020, James Hunt
--
-- https://birthdaynoc.jameshunt.us
--
-- This database schema is defined for the Tweet-authoring
-- parts of the @birthdaynoc system.  It defines the means
-- of storing allocation dates in a format that works for
-- the context-free grammar generator, mostly.
--

CREATE TABLE IF NOT EXISTS countries (
	code CHAR(3) NOT NULL PRIMARY KEY,
	name TEXT,
	flag TEXT
);

CREATE TABLE IF NOT EXISTS ranges (
	network  VARCHAR(15) NOT NULL UNIQUE,
	mask     INTEGER     NOT NULL CHECK (mask > 0 AND mask <= 32),
	n        INTEGER     NOT NULL CHECK (n > 0 AND n < 4294967296),
	birthday DATE        NOT NULL,
	country  CHAR(3)     NOT NULL
	                     REFERENCES countries(code)
	                     ON DELETE RESTRICT
	                     ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS dates (
  mm INTEGER NOT NULL,
  dd INTEGER NOT NULL,
  mmdd CHAR(4)  NOT NULL UNIQUE
);
TRUNCATE TABLE dates;

WITH days AS (SELECT generate_series(1, 31) AS d)
  INSERT INTO dates (mm, dd, mmdd)
    (SELECT 1, d, concat('01', lpad(d::text, 2, '0')) FROM days);

WITH days AS (SELECT generate_series(1, 29) AS d)
  INSERT INTO dates (mm, dd, mmdd)
    (SELECT 2, d, concat('02', lpad(d::text, 2, '0')) FROM days);

WITH days AS (SELECT generate_series(1, 31) AS d)
  INSERT INTO dates (mm, dd, mmdd)
    (SELECT 3, d, concat('03', lpad(d::text, 2, '0')) FROM days);

WITH days AS (SELECT generate_series(1, 30) AS d)
  INSERT INTO dates (mm, dd, mmdd)
    (SELECT 4, d, concat('04', lpad(d::text, 2, '0')) FROM days);

WITH days AS (SELECT generate_series(1, 31) AS d)
  INSERT INTO dates (mm, dd, mmdd)
    (SELECT 5, d, concat('05', lpad(d::text, 2, '0')) FROM days);

WITH days AS (SELECT generate_series(1, 30) AS d)
  INSERT INTO dates (mm, dd, mmdd)
    (SELECT 6, d, concat('06', lpad(d::text, 2, '0')) FROM days);

WITH days AS (SELECT generate_series(1, 31) AS d)
  INSERT INTO dates (mm, dd, mmdd)
    (SELECT 7, d, concat('07', lpad(d::text, 2, '0')) FROM days);

WITH days AS (SELECT generate_series(1, 31) AS d)
  INSERT INTO dates (mm, dd, mmdd)
    (SELECT 8, d, concat('08', lpad(d::text, 2, '0')) FROM days);

WITH days AS (SELECT generate_series(1, 30) AS d)
  INSERT INTO dates (mm, dd, mmdd)
    (SELECT 9, d, concat('09', lpad(d::text, 2, '0')) FROM days);

WITH days AS (SELECT generate_series(1, 31) AS d)
  INSERT INTO dates (mm, dd, mmdd)
    (SELECT 10, d, concat('10', lpad(d::text, 2, '0')) FROM days);

WITH days AS (SELECT generate_series(1, 30) AS d)
  INSERT INTO dates (mm, dd, mmdd)
    (SELECT 11, d, concat('11', lpad(d::text, 2, '0')) FROM days);

WITH days AS (SELECT generate_series(1, 31) AS d)
  INSERT INTO dates (mm, dd, mmdd)
    (SELECT 12, d, concat('12', lpad(d::text, 2, '0')) FROM days);

CREATE OR REPLACE FUNCTION bday(d DATE)
RETURNS TABLE (network TEXT, mask INTEGER, n INTEGER, year INTEGER, age INTEGER, country TEXT)
AS
$$
  SELECT network, mask, n,
         date_part('year', birthday)::integer AS year,
         (date_part('year', NOW()) - date_part('year', birthday))::integer AS age,
         country::text
    FROM ranges
   WHERE date_part('month', birthday) = date_part('month', d)
     AND date_part('day',   birthday) = date_part('day',   d);
$$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION bday(mm INTEGER, dd INTEGER)
RETURNS TABLE (network TEXT, mask INTEGER, n INTEGER, year INTEGER, age INTEGER, country TEXT)
AS
$$
  SELECT bday(make_date(1996, mm, dd));
$$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION bday(d TIMESTAMP)
RETURNS TABLE (network TEXT, mask INTEGER, n INTEGER, year INTEGER, age INTEGER, country TEXT)
AS
$$
  SELECT * FROM bday(d::date);
$$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION bday(d TIMESTAMP WITH TIME ZONE)
RETURNS TABLE (network TEXT, mask INTEGER, n INTEGER, year INTEGER, age INTEGER, country TEXT)
AS
$$
  SELECT * FROM bday(d::date);
$$
LANGUAGE sql;

CREATE OR REPLACE FUNCTION randomip(net TEXT, spread INTEGER)
RETURNS TEXT
AS
$$
BEGIN
  RETURN host(net::inet + FLOOR(RANDOM() * (spread - 2) + 1)::integer);
END;
$$
LANGUAGE 'plpgsql' STRICT;

CREATE OR REPLACE FUNCTION source_material()
RETURNS TABLE (network TEXT, mask TEXT, n INTEGER, mm INTEGER, dd INTEGER, year INTEGER, age INTEGER, country TEXT, randip TEXT)
AS
$$
  SELECT CONCAT(b.network, '/', b.mask),
         CONCAT('/', b.mask),
         b.n,
         d.mm, d.dd, b.year,
         b.age,
         b.country,
         randomip(b.network, b.n)
    FROM dates d, bday(d.mm, d.dd) AS b
   ORDER BY d.mmdd ASC;
$$
LANGUAGE sql;
