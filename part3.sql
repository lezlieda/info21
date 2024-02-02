-- 1) Write a function that returns the TransferredPoints table in a more human-readable form
--    Peer's nickname 1, Peer's nickname 2, number of transferred peer points.
--    The number is negative if peer 2 received more points from peer 1.

CREATE OR REPLACE FUNCTION fnc_readable_transfer_points()
RETURNS table(peer1 VARCHAR, peer2 VARCHAR, points_amount BIGINT) AS $$
BEGIN;


END;
$$ LANGUAGE PLPGSQL;