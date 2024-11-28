-- 1) Write a function that returns the TransferredPoints table in a more human-readable form
--    Peer's nickname 1, Peer's nickname 2, number of transferred peer points.
--    The number is negative if peer 2 received more points from peer 1.

CREATE OR REPLACE FUNCTION fnc_readable_transfer_points()
RETURNS table(peer1 VARCHAR, peer2 VARCHAR, point_amount BIGINT) AS $$
BEGIN
    RETURN QUERY
    WITH t1 AS (SELECT CASE WHEN checking_peer > checked_peer THEN checking_peer ELSE checked_peer END,
                       CASE WHEN checking_peer > checked_peer THEN checked_peer ELSE checking_peer END,
                       CASE WHEN checking_peer > checked_peer THEN -tp.points_amount ELSE tp.points_amount END AS p_a
                FROM transferred_points tp)
    SELECT checking_peer, checked_peer, SUM(p_a)
    FROM t1
    GROUP BY checking_peer, checked_peer
    ORDER BY 1, 2;
END;
$$ LANGUAGE PLPGSQL;
SELECT * FROM fnc_readable_transfer_points();
SELECT * FROM transferred_points WHERE checked_peer = 'aaeuppmlip';

-- 2) Write a function that returns a table of the following form: user name,
--    name of the checked task, number of XP received

CREATE OR REPLACE FUNCTION fnc_xp_received()
RETURNS table(peer VARCHAR, task VARCHAR, xp INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT c.peer, c.task, xp.xp_amount
    FROM xp
    JOIN checks c
    ON c.id = xp.check
    ORDER BY 1, 2;
END;
$$ LANGUAGE PLPGSQL;

SELECT * FROM fnc_xp_received();

-- 3) Write a function that finds the peers who have not left campus for the whole day

CREATE OR REPLACE FUNCTION fnc_peers_not_left(p_date DATE)
RETURNS table(peer VARCHAR) AS $$
BEGIN
    RETURN QUERY
    WITH t1 AS (SELECT tp.peer, COUNT(tp.peer) AS enters FROM time_tracking tp
                WHERE date = p_date AND state = 1
                GROUP BY 1)
    SELECT t1.peer FROM t1 WHERE enters = 1;
END;
$$ LANGUAGE PLPGSQL;


SELECT date, COUNT(date) FROM time_tracking GROUP BY 1 ORDER BY 2 DESC;
SELECT * FROM time_tracking WHERE date = '2022-01-01' ;

SELECT * FROM fnc_peers_not_left('2022-01-01');

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

SELECT checking_peer, SUM(points_amount) FROM transferred_points WHERE checking_peer = 'byklmdzrsa' GROUP BY 1;
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
    WITH RECURSIVE  t1 AS (SELECT title, ROW_NUMBER() OVER(ORDER BY title) AS num -- all tasks from the block
                            FROM tasks
                            WHERE title SIMILAR TO p_block || '[0-9]%'
                            ORDER BY 1),
                    t2 AS (SELECT c.peer, c.task, c.date FROM checks c -- all finished tasks
                            JOIN xp
                            ON c.id = xp.check),
                    t3 AS (SELECT *                                    -- all peers with finished tasks in selected block
                            FROM t2
                            WHERE task IN (SELECT title FROM t1)
                            GROUP BY 1, 2, 3),
                    t4(peer, date, task) AS (
                            SELECT t3.peer, MIN(t3.date) AS day, 1 AS task
                            FROM t3
                            JOIN t1
                            ON t3.task = t1.title
                            WHERE t1.num = 1
                            GROUP BY 1
                            UNION
                            SELECT t3.peer, t3.date AS day, t4.task + 1 AS task
                            FROM t3
                            JOIN t1
                            ON t3.task = t1.title
                            JOIN t4
                            ON t3.peer = t4.peer
                            WHERE t1.num = t4.task + 1
                            GROUP BY 1, 2, 3)
                SELECT peer, MIN(date) AS day
                FROM t4
                WHERE task = (SELECT COUNT(title) FROM t1)
                GROUP BY 1;
END;
$$ LANGUAGE PLPGSQL;

BEGIN;
CALL prc_peers_completed_block('SQL');
FETCH ALL FROM ex_7;
END;

SELECT * FROM checks WHERE peer = 'qgljzebhhh' AND task SIMILAR TO 'SQL%';


-- 8) Determine which peer each student should go to for a check.
-- insert some data for representantion
CREATE OR REPLACE PROCEDURE prc_check_assignment(INOUT curs REFCURSOR = 'ex_8') AS $$
BEGIN
    OPEN curs FOR
        WITH t1 AS (SELECT f1.peer1, f1.peer2 -- all friends
                    FROM friends f1
                    UNION
                    SELECT f2.peer2, f2.peer1
                    FROM friends f2
                    ORDER BY 1, 2),
            t2 AS (SELECT peers.nickname, peer2 AS friends -- all peers and their friends
                    FROM t1
                    RIGHT JOIN peers
                    ON t1.peer1 = peers.nickname
                    ORDER BY 1, 2),
            t3 AS (SELECT r.peer, r.recommended_peer, COUNT(r.recommended_peer) AS cn -- all recommendations
                    FROM recommendations r
                    GROUP BY 1, 2),
            t4 AS (SELECT DISTINCT t2.nickname, t3.recommended_peer, t3.count -- all peers and their friends and recommendations
                    FROM t2
                    RIGHT JOIN t3
                    ON t2.friends = t3.peer
                    WHERE nickname IS NOT NULL
                    GROUP BY 1, 2
                    ORDER BY 3 DESC),
            t5 AS (SELECT t4.nickname, max(t4.count) AS max_count -- max count of recommendations for each peer
                    FROM t4
                    GROUP BY 1)
        SELECT p.nickname, COALESCE(t4.recommended_peer, 'No recommendations') AS recommended_peer
        FROM peers p
        LEFT JOIN t4
        ON p.nickname = t4.nickname
        LEFT JOIN t5
        ON p.nickname = t5.nickname AND t4.count = t5.max_count;
END;
$$ LANGUAGE PLPGSQL;

BEGIN;
CALL prc_check_assignment();
FETCH ALL FROM ex_8;
END;

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

CALL prc_peers_percentage('SQL', 'AP');

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
CREATE OR REPLACE PROCEDURE prc_peers_did_2_not_3(IN p_task1 VARCHAR, IN p_task2 VARCHAR, IN p_task3 VARCHAR, 
                                              INOUT curs REFCURSOR = 'ex_11') AS $$
BEGIN
    OPEN curs FOR
        WITH t1 AS (SELECT c.peer, c.task          -- peers and done tasks
                    FROM xp
                    JOIN checks c
                    ON c.id = xp.check
                    ORDER BY 1, 2),
            t2 AS (SELECT DISTINCT peer            -- peers who did the given tasks 1 and 2
                    FROM t1
                    WHERE task = p_task1
                    INTERSECT
                    SELECT DISTINCT peer
                    FROM t1
                    WHERE task = p_task2)
        SELECT * 
        FROM t2
        INTERSECT
        SELECT p.nickname AS peer
        FROM peers p
        WHERE p.nickname NOT IN (SELECT peer FROM t1 WHERE task = p_task3);
END;
$$ LANGUAGE PLPGSQL;

BEGIN;
CALL prc_peers_did_2_not_3('SQL1', 'SQL2', 'SQL3');
FETCH ALL FROM ex_11;
END;

-- 12) Using recursive common table expression, output the number of preceding tasks for each task

CREATE OR REPLACE PROCEDURE prc_num_preceding_tasks(INOUT curs REFCURSOR = 'ex_12') AS $$
BEGIN
    OPEN curs FOR
        WITH RECURSIVE cte(task, prev_count) AS (
                SELECT title, 0
                FROM tasks
                WHERE parent_task IS NULL
                UNION
                SELECT t.title, cte.prev_count + 1
                FROM tasks t
                JOIN cte
                ON t.parent_task = cte.task
                )
        SELECT * FROM cte;
END;
$$ LANGUAGE PLPGSQL;

BEGIN;
CALL prc_num_preceding_tasks();
FETCH ALL FROM ex_12;
END;

-- 13) Find "lucky" days for checks. A day is considered "lucky" if it has at least N consecutive successful checks
--     Parameters of the procedure: the N number of consecutive successful checks .
--     The time of the check is the start time of the P2P step.
--     Successful consecutive checks are the checks with no unsuccessful checks in between.
--     The amount of XP for each of these checks must be at least 80% of the maximum.
--     Output format: list of days

CREATE OR REPLACE PROCEDURE prc_lucky_days(IN p_num INTEGER, INOUT curs REFCURSOR = 'ex_13') AS $$
BEGIN
    OPEN curs FOR
    WITH t1 AS (SELECT c.id, c.task, c.peer, c.date, xp_amount::NUMERIC / t.max_xp::NUMERIC >= 0.8 AS stat
            FROM checks c
            JOIN xp
            ON c.id = xp.check
            JOIN tasks t
            ON c.task = t.title
            ORDER BY 1 ASC),
     t2 AS (SELECT t1.date, row_number() OVER (PARTITION BY t1.date, t1.stat) AS cc
            FROM t1),
     t3 AS (SELECT t2.date, MAX(t2.cc) AS max_series
            FROM t2
            GROUP BY 1)
    SELECT t3.date
    FROM t3
    WHERE t3.max_series >= p_num;
END;
$$ LANGUAGE PLPGSQL;

BEGIN;
CALL prc_lucky_days(5);
FETCH ALL FROM ex_13;
END;

-- 14) Find the peer with the highest amount of XP

CREATE OR REPLACE PROCEDURE prc_most_expirienced(INOUT peer VARCHAR = '', INOUT xp INTEGER = 0) AS $$
BEGIN
    WITH t1 AS (SELECT c.peer AS p, c.task, MAX(xp.xp_amount) AS max_xp
            FROM xp
            JOIN checks c
            ON c.id = xp.check
            GROUP BY 1, 2)
    SELECT p, SUM(max_xp)
    FROM t1
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 1
    INTO peer, xp;
END;
$$ LANGUAGE PLPGSQL;

CALL prc_most_expirienced();

-- 15) Determine the peers that came before the given time at least N times during the whole time
--     Procedure parameters: time, N number of times .
--     Output format: list of peers

CREATE OR REPLACE PROCEDURE prc_early_birds(IN p_time TIME, IN p_num INTEGER, INOUT curs REFCURSOR = 'ex_15') AS $$
BEGIN
    OPEN curs FOR
    WITH t1 AS (SELECT peer, date, time
            FROM time_tracking
            WHERE state = 1 AND time <= p_time),
         t2 AS (SELECT peer, COUNT(peer) AS cnt
                FROM t1
                GROUP BY 1)
    SELECT peer
    FROM t2
    WHERE cnt >= p_num;
END;
$$ LANGUAGE PLPGSQL;

BEGIN;
CALL prc_early_birds('09:00:00', 4);
FETCH ALL FROM ex_15;
END;

-- 16) Determine the peers who left the campus more than M times during the last N days
--     Procedure parameters: N number of days , M number of times .
--     Output format: list of peers

CREATE OR REPLACE PROCEDURE prc_peers_smokers(IN p_days INTEGER, IN p_times INTEGER, INOUT curs REFCURSOR = 'ex_16') AS $$
BEGIN
    OPEN curs FOR
    WITH t1 AS (SELECT *, row_number() OVER (PARTITION BY date, peer) AS exits_count
            FROM time_tracking WHERE state = 2),
         t2 AS (SELECT peer, date, MAX(exits_count) - 1 AS lefts
                FROM t1
                GROUP BY 1, 2),
         t3 AS (SELECT * FROM t2 WHERE lefts > p_times)
    SELECT peer FROM t3 WHERE date > current_date - p_days * INTERVAL '1' DAY
    GROUP BY 1;
END;
$$ LANGUAGE PLPGSQL;

BEGIN;
CALL prc_peers_smokers(1500, 5);
FETCH ALL FROM ex_16;
END;

-- 17) Determine for each month the percentage of early entries
CREATE OR REPLACE PROCEDURE prc_determine_early_entries(INOUT curs REFCURSOR = 'ex_17') AS $$
BEGIN
    OPEN curs FOR
        WITH t1 AS (SELECT to_char(date, 'Month') AS m, peer, date, time, row_number() OVER (PARTITION BY peer, date) AS enters
                    FROM time_tracking
                    WHERE state = 1),
            t2 AS (SELECT nickname, to_char(birthday, 'Month') AS mm FROM peers),
            t3 AS (SELECT * FROM t1
                    JOIN t2
                    ON t1.peer = t2.nickname AND t1.m = t2.mm
                    WHERE t1.enters = 1),
            t4 AS (SELECT t3.m AS Month, COUNT(t3.m) AS total_entries
                    FROM t3
                    GROUP BY 1),
            t5 AS (SELECT t3.m, COUNT(t3.m) AS early_entries
                    FROM t3
                    WHERE time < '12:00:00'
                    GROUP BY 1)
        SELECT t4.Month, ROUND(t5.early_entries::NUMERIC / t4.total_entries::NUMERIC * 100, 2) AS early_entries
        FROM t4
        JOIN t5
        ON t4.Month = t5.m
        ORDER BY to_date(t4.Month, 'Month')::DATE;
END;
$$ LANGUAGE PLPGSQL;

BEGIN;
CALL prc_determine_early_entries();
FETCH ALL FROM ex_17;
END;
