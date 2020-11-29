--
-- coverage.sql
--
-- part of the @birthdaynoc project
-- @birthdaynoc is Copyright (c) 2020, James Hunt
--
-- https://birthdaynoc.jameshunt.us
--
-- This SQL "script" does some coverage analysis on the
-- raw IPv4 allocation day-sets, to ensure that we have
-- adequate Tweet material for every day of the year,
-- including leap day and all major holidays!
--

CREATE TEMPORARY TABLE tallies (
	mmdd CHAR(4) NOT NULL
);
INSERT INTO tallies
  SELECT TO_CHAR(r.birthday, 'MMDD')
    FROM ranges r;

CREATE TEMPORARY TABLE coverage (
	n INTEGER NOT NULL,
	mmdd CHAR(4) NOT NULL
);
INSERT INTO coverage (n, mmdd)
SELECT COUNT(d.mmdd) AS n, d.mmdd
  FROM tallies t LEFT JOIN dates d
    ON d.mmdd = t.mmdd
  GROUP BY d.mmdd
  ORDER BY d.mmdd ASC;

CREATE TEMPORARY TABLE mm (m INTEGER);
INSERT INTO mm (m) SELECT n FROM coverage ORDER BY n ASC OFFSET 182 LIMIT 1;
UPDATE mm SET m = (m + (SELECT n FROM coverage ORDER BY n ASC OFFSET 183 LIMIT 1)) / 2;

\t
SELECT '';
SELECT '';
SELECT '';
SELECT 'day-set summaries:';
      SELECT 0 AS i, 'total allocations:'       AS what,   SUM(n) AS n FROM coverage
UNION SELECT 2 AS i, 'full day-sets:'           AS what, COUNT(n) AS n FROM coverage WHERE n > 0
UNION SELECT 1 AS i, 'empty day-sets:'          AS what, COUNT(n) AS n FROM coverage WHERE n = 0
UNION SELECT 3 AS i, 'smallest single day-set:' AS what,   MIN(n) AS n FROM coverage
UNION SELECT 4 AS i, 'largest single day-set:'  AS what,   MAX(n) AS n FROM coverage
UNION SELECT 5 AS i, 'median day-set:'          AS what,       m  AS n FROM mm
ORDER BY i ASC;

SELECT 'least-populated day-sets:';
SELECT mmdd, n FROM coverage ORDER BY n ASC, mmdd ASC LIMIT 5;

SELECT 'most-populated day-sets:';
SELECT mmdd, n FROM coverage ORDER BY n DESC, mmdd ASC LIMIT 5;
