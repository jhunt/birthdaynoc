--
-- test.sql
--
-- part of the @birthdaynoc project
-- @birthdaynoc is Copyright (c) 2020, James Hunt
--
-- https://birthdaynoc.jameshunt.us
--
-- Want to test out the bday(date) and
-- randomip(net, count) functions?  Me too.
--

SELECT *, randomip(network, n) FROM bday(NOW());
