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
CREATE OR REPLACE PROCEDURE prc_peerpoints(INOUT curs refcursor = 'ex_4') AS $$
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
CALL prc_peerpoints();
FETCH ALL FROM ex_4;
END;

-- 5) Calculate the change in the number of peer points of each peer using the table returned
--    by the first function from Part 3

CREATE OR REPLACE PROCEDURE prc_peerpoints_alt(INOUT curs refcursor = 'ex_5') AS $$
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
CALL prc_peerpoints_alt();
FETCH ALL FROM ex_5;
END;

-- 6) Find the most frequently checked task for each day
CREATE OR REPLACE PROCEDURE prc_frequent_tasks(INOUT curs refcursor = 'ex_6') AS $$
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

UPDATE checks SET date = '2024-02-01' WHERE id BETWEEN 7 AND 9;
SELECT * FROM checks;
BEGIN;
CALL prc_frequent_tasks();
FETCH ALL FROM ex_6;
END;

-- 7) Find all peers who have completed the whole given block of tasks and the completion date of the last task
--    Procedure parameters: name of the block, for example “CPP”.
--    The result is sorted by the date of completion.
--    Output format: peer's name, date of completion of the block (i.e. the last completed task from that block)
CREATE OR REPLACE PROCEDURE prc_peers_completed_block(IN p_block VARCHAR, INOUT curs REFCURSOR = 'ex_7') AS $$
BEGIN
    OPEN curs FOR
    WITH t1 AS (SELECT title
            FROM tasks
            WHERE title SIMILAR TO p_block || '[0-9]%'
            ORDER BY 1 DESC
            LIMIT 1),
     t2 AS (SELECT c.peer, c.task, c.date FROM checks c
            JOIN xp
            ON c.id = xp.check_id)
    SELECT t2.peer, MIN(t2.date) AS day
    FROM t2
    JOIN t1
    ON t2.task = t1.title
    GROUP BY t2.peer
    ORDER BY 2 DESC;
END;
$$ LANGUAGE PLPGSQL;

BEGIN;
CALL prc_peers_completed_block('C');
FETCH ALL FROM ex_7;
END;


-- 8) Determine which peer each student should go to for a check.

-- ????????????????????????????????????????????????????????????????????????????????????


-- 9) Determine the percentage of peers who:
--    - Started only block 1
--    - Started only block 2
--    - Started both
--    - Have not started any of them
-- A peer is considered to have started a block if he has at least one check of any task
-- from this block (according to the Checks table)

-- Procedure parameters: name of block 1, for example SQL, name of block 2, for example A.
-- Output format: percentage of those who started only the first block, percentage of those
-- who started only the second block, percentage of those who started both blocks, percentage
-- of those who did not started any of them

CREATE OR REPLACE PROCEDURE prc_peers_percentage(IN p_block1 VARCHAR,
                                                 IN p_block2 VARCHAR,
                                                 INOUT Started_Block1 NUMERIC = 0,
                                                 INOUT Started_Block2 NUMERIC = 0,
                                                 INOUT Started_Both NUMERIC = 0,
                                                 INOUT Didnt_start_any NUMERIC = 0) AS $$
BEGIN
    WITH t1 AS (SELECT peer FROM checks
                    WHERE task SIMILAR TO p_block1 || '[0-9]%'
                    GROUP BY 1),
         t2 AS (SELECT peer FROM checks
                WHERE task SIMILAR TO p_block2 || '[0-9]%'
                GROUP BY 1),
         t3 AS (SELECT * FROM t1 INTERSECT SELECT * FROM t2),
         t4 AS (SELECT ROUND(COUNT(t1.peer)::NUMERIC / (SELECT COUNT(nickname) FROM peers)::NUMERIC * 100, 2) AS s1 FROM t1),
         t5 AS (SELECT ROUND(COUNT(t2.peer)::NUMERIC / (SELECT COUNT(nickname) FROM peers)::NUMERIC * 100, 2) AS s2 FROM t2),
         t6 AS (SELECT ROUND(COUNT(t3.peer)::NUMERIC / (SELECT COUNT(nickname) FROM peers)::NUMERIC * 100, 2) AS sb FROM t3)
    SELECT s1, s2, sb, 100 - s1 - s2 - sb
    FROM t4
    CROSS JOIN t5
    CROSS JOIN t6
    INTO Started_Block1, Started_Block2, Started_Both, Didnt_start_any;

END;
$$ LANGUAGE PLPGSQL;

CALL prc_peers_percentage('CPP', 'DO');

-- 10) Determine the percentage of peers who have ever successfully passed a check on their birthday

CREATE OR REPLACE PROCEDURE prc_birthday_percentage(INOUT Successful_Checks NUMERIC = 0, 
                                                    INOUT Unsuccessful_Checks NUMERIC = 0) AS $$
BEGIN
    WITH t1 AS (SELECT nickname, EXTRACT(MONTH FROM birthday) AS m, EXTRACT(DAY FROM birthday) AS d FROM peers),
     t2 AS (SELECT id, peer, EXTRACT(MONTH FROM date) AS m, EXTRACT(DAY FROM date) AS d FROM checks),
     t3 AS (SELECT fnc_is_check_successful(t2.id) AS s
            FROM t1 JOIN t2
            ON t1.m = t2.m AND t1.d = t2.d AND t1.nickname = t2.peer),
     s AS  (SELECT ROUND((SELECT COUNT(t3.s) FROM t3 WHERE t3.s = true)::NUMERIC
                           / (SELECT COUNT(t3.s) FROM t3)::NUMERIC * 100, 2) AS c)
    SELECT s.c, 100 - s.c AS u from s
    INTO Successful_Checks, Unsuccessful_Checks;
END;
$$ LANGUAGE PLPGSQL;

CALL prc_birthday_percentage();

-- 11) Determine all peers who did the given tasks 1 and 2, but did not do task 3

-- ????????????????????????????????????????????

-- 12) Using recursive common table expression, output the number of preceding tasks for each task

CREATE OR REPLACE PROCEDURE prc_num_preceding_tasks(INOUT curs REFCURSOR = 'ex_12') AS $$
BEGIN

END;
$$ LANGUAGE PLPGSQL;

SELECT * FROM tasks;

WITH RECURSIVE cte(task, prev_count) AS (
                SELECT title, 0
                FROM tasks
                WHERE parent_task IS NULL
                UNION
                SELECT task, prev_count + 1
                FROM cte
                JOIN tasks
                ON tasks.title
                )
SELECT * FROM cte;

SELECT title, 0 AS cnt FROM tasks WHERE parent_task IS NULL;