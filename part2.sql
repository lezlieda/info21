/*Parameters: nickname of the person being checked, checker's nickname, task name, P2P check status, time.
  If the status is "start", add a record in the Checks table (use today's date).
  Add a record in the P2P table.
  If the status is "start", specify the record just added as a check, otherwise specify the check with the
  unfinished P2P step.
*/
CREATE OR REPLACE PROCEDURE
add_p2p_check(p_peer VARCHAR, p_checking_peer VARCHAR, p_task VARCHAR, p_status check_status, p_time TIME)
LANGUAGE PLPGSQL AS $$
BEGIN
    IF (p_status = 'Start') THEN
        INSERT INTO checks VALUES((SELECT MAX(id) + 1 FROM checks),
                                  p_peer,
                                  p_task,
                                  now()::DATE);
        INSERT INTO p2p VALUES((SELECT MAX(id) + 1 FROM p2p),
                               (SELECT MAX(id) FROM checks),
                                p_checking_peer,
                                p_status,
                                p_time);
    ELSE
        INSERT INTO p2p VALUES((SELECT MAX(id) + 1 FROM p2p),
                               (SELECT MAX(check_id) FROM p2p 
                                WHERE state = 'Start' AND checking_peer = p_checking_peer),
                               p_checking_peer,
                               p_status,
                               p_time);
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE add_verter_check(p_peer VARCHAR, p_task VARCHAR, p_status check_status, p_time TIME)
LANGUAGE PLPGSQL AS $$
BEGIN
    IF (p_status = 'Start') THEN
        INSERT INTO verter VALUES((SELECT MAX(id) + 1 FROM verter),
                                  )
$$;

SELECT * FROM checks;
SELECT * FROM p2p;
CALL add_p2p_check('Pormissina', 'Troducity', 'C2_SimpleBashUtils', 'Start', '15:17:11');
CALL add_p2p_check('Pormissina', 'Troducity', 'C2_SimpleBashUtils', 'Failure', '15:30:08');


SELECT * FROM verter;