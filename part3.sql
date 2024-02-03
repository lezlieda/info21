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

SELECT * FROM time_tracking;

SELECT * FROM fnc_peers_not_left('2024-01-17');

-- 4) Calculate the change in the number of peer points of each peer using the TransferredPoints table

WITH t1 AS (SELECT checking_peer, SUM(points_amount) AS received
            FROM transferred_points
            GROUP BY 1),
      t2 AS (SELECT checked_peer, SUM(points_amount) AS spent
            FROM transferred_points
            GROUP BY 1),
      t3 AS (SELECT *
            FROM t1
            LEFT JOIN t2 ON t1.checking_peer = t2.checked_peer)
SELECT checking_peer AS peer, received - COALESCE(spent, 0) AS points_change
FROM t3;

WITH t1 AS (SELECT checking_peer, SUM(points_amount) AS received
            FROM transferred_points
            GROUP BY 1),
      t2 AS (SELECT checked_peer, SUM(points_amount) AS spent
            FROM transferred_points
            GROUP BY 1),
      t3 AS (SELECT * FROM t1
            LEFT JOIN t2 ON t1.checking_peer = t2.checked_peer
            WHERE t1.received != COALESCE(t2.spent,0))
SELECT checking_peer AS peer, received - COALESCE(spent, 0) AS points_change
FROM t3;

CREATE OR REPLACE PROCEDURE prc_peerpoints(INOUT peer VARCHAR DEFAULT '', 
                                           INOUT points_change INTEGER DEFAULT 0) AS $$
BEGIN
    SELECT checking_peer, points_amount FROM transferred_points
    INTO peer, points_change;
END;
$$ LANGUAGE PLPGSQL;

CALL prc_peerpoints();

SELECT * FROM transferred_points;



SELECT checking_peer, SUM(points_amount)
            FROM transferred_points
            GROUP BY 1;

SELECT checked_peer, SUM(-points_amount)
            FROM transferred_points
            GROUP BY 1;

