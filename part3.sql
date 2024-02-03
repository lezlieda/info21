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
    SELECT DISTINCT peer
    FROM checks
    WHERE EXTRACT(DAY FROM check_time) = EXTRACT(DAY FROM p_date);
END;
$$ LANGUAGE PLPGSQL;

SELECT * FROM time_tracking;

SELECT nickname FROM peers
EXCEPT
SELECT peer
FROM time_tracking
WHERE date = '2024-01-17' AND state = 2;
SELECT nickname FROM peers;
