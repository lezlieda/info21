-- 1) Write a function that returns the TransferredPoints table in a more human-readable form
--    Peer's nickname 1, Peer's nickname 2, number of transferred peer points.
--    The number is negative if peer 2 received more points from peer 1.

CREATE OR REPLACE FUNCTION fnc_readable_transfer_points()
RETURNS table(peer1 VARCHAR, peer2 VARCHAR, point_amount BIGINT) AS $$
BEGIN
    RETURN QUERY
    WITH t1 AS (SELECT CASE WHEN checking_peer > checked_peer THEN checking_peer ELSE checked_peer END,
                       CASE WHEN checking_peer > checked_peer THEN checked_peer ELSE checking_peer END,
                       CASE WHEN checking_peer > checked_peer THEN tp.points_amount ELSE -tp.points_amount END AS p_a
                FROM transferred_points tp)
    SELECT checking_peer, checked_peer, SUM(p_a)
    FROM t1
    GROUP BY checking_peer, checked_peer
    ORDER BY 1, 2;
END;
$$ LANGUAGE PLPGSQL;
SELECT * FROM fnc_readable_transfer_points();
SELECT * FROM transferred_points;

-- 2) Write a function that returns a table of the following form: user name,
--    name of the checked task, number of XP received

CREATE OR REPLACE FUNCTION fnc_xp_received()
RETURNS table(peer VARCHAR, task VARCHAR, xp INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT c.peer, c.task, xp.xp_amount
    FROM xp
    JOIN checks c
    ON c.id = xp.check_id
    ORDER BY 1, 2;
END;
$$ LANGUAGE PLPGSQL;

SELECT * FROM fnc_xp_received();

-- 3) Write a function that finds the peers who have not left campus for the whole day

CREATE OR REPLACE FUNCTION fnc_peers_not_left(p_date DATE)
RETURNS table(peer VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT nickname FROM peers
    EXCEPT
    SELECT tp.peer
    FROM time_tracking tp
    WHERE date = p_date AND state = 2
    ORDER BY 1;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION fnc_peers_not_left_alt(p_date DATE)
RETURNS table(peer VARCHAR) AS $$
BEGIN
    RETURN QUERY
    WITH t1 AS (SELECT tp.peer, COUNT(tp.peer) AS enters FROM time_tracking tp
                WHERE date = '2024-01-17' AND state = 1
                GROUP BY 1)
    SELECT t1.peer FROM t1 WHERE enters = 1;
END;
$$ LANGUAGE PLPGSQL;


SELECT * FROM time_tracking;

SELECT * FROM fnc_peers_not_left('2024-01-17');

SELECT * FROM fnc_peers_not_left_alt('2024-01-17');

-- 4) Calculate the change in the number of peer points of each peer using the TransferredPoints table
CREATE OR REPLACE PROCEDURE prc_peerpoints(INOUT curs refcursor) AS $$
BEGIN
    OPEN curs FOR
        WITH t1 AS (SELECT checking_peer, SUM(points_amount) AS received
                    FROM transferred_points
                    GROUP BY 1),
             t2 AS (SELECT checked_peer, SUM(points_amount) AS spent
                    FROM transferred_points
                    GROUP BY 1),
             t3 AS (SELECT p.nickname AS peer, 0 + COALESCE(t1.received, 0) - COALESCE(t2.spent, 0) AS points
                    FROM peers p
                    LEFT JOIN t1 ON p.nickname = t1.checking_peer
                    LEFT JOIN t2 ON p.nickname = t2.checked_peer)
        SELECT * FROM t3
        WHERE points != 0
        ORDER BY 2 DESC;
END;
$$ LANGUAGE PLPGSQL;

SELECT * FROM transferred_points;
BEGIN;
CALL prc_peerpoints('task_4');
FETCH ALL FROM task_4;
END;

-- 5) Calculate the change in the number of peer points of each peer using the table returned
--    by the first function from Part 3

CREATE OR REPLACE PROCEDURE prc_peerpoints_alt(INOUT curs refcursor) AS $$
BEGIN
    OPEN curs FOR
        WITH t1 AS (SELECT peer1, SUM(-point_amount) AS s1
               FROM fnc_readable_transfer_points()
               GROUP BY 1),
        t2 AS (SELECT peer2, SUM(point_amount) AS s2
               FROM fnc_readable_transfer_points()
               GROUP BY 1),
        t3 AS (SELECT p.nickname AS peer, 0 + COALESCE(t1.s1, 0) + COALESCE(t2.s2,0) AS points
               FROM peers p
               LEFT JOIN t1 ON p.nickname = t1.peer1
               LEFT JOIN t2 ON p.nickname = t2.peer2
              ORDER BY 2 DESC)
        SELECT * FROM t3 WHERE points != 0;
END;
$$ LANGUAGE PLPGSQL;

BEGIN;
CALL prc_peerpoints_alt('task_5');
FETCH ALL FROM task_5;
END;

-- 6) Find the most frequently checked task for each day
CREATE OR REPLACE PROCEDURE prc_frequent_tasks(INOUT curs refcursor) AS $$
BEGIN
    OPEN curs FOR
        WITH t1 AS (SELECT date AS d, task AS t, COUNT(task) AS cnt
                    FROM checks
                    GROUP BY 1, 2
                    ORDER BY 1),
              t2 AS (SELECT d, MAX(cnt)
                     FROM t1
                     GROUP BY 1)
        SELECT t1.d AS date, t1.t AS task
        FROM t1
        JOIN t2
        ON t1.d = t2.d AND t1.cnt = t2.max;
END;
$$ LANGUAGE PLPGSQL;

BEGIN;
CALL prc_frequent_tasks('task_6');
FETCH ALL FROM task_6;
END;

