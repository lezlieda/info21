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

CREATE OR REPLACE PROCEDURE
add_verter_check(p_peer VARCHAR, p_task VARCHAR, p_status check_status, p_time TIME)
LANGUAGE PLPGSQL AS $$
BEGIN
    IF (p_status = 'Start') THEN
        INSERT INTO verter VALUES((SELECT MAX(id) + 1 FROM verter),
                                  (SELECT MAX(c.id) FROM checks c
                                   INNER JOIN p2p p ON c.id = p.check_id
                                   WHERE c.peer = p_peer AND c.task = p_task AND p.state = 'Success'),
                                   p_status,
                                   p_time);
    ELSE
        INSERT INTO verter VALUES((SELECT MAX(id) + 1 FROM verter),
                                  (SELECT MAX(c.id) FROM checks c
                                   INNER JOIN verter v ON c.id = v.check_id
                                   WHERE c.peer = p_peer AND c.task = p_task HAVING COUNT(v.state) = 1),
                                   p_status,
                                   p_time);
    END IF;
END;
$$;

SELECT * FROM checks;
SELECT * FROM p2p;
SELECT * FROM verter;
CALL add_p2p_check('Pormissina', 'Troducity', 'C2_SimpleBashUtils', 'Start', '15:17:11');
CALL add_p2p_check('Bredual', 'Anchil', 'C2_SimpleBashUtils', 'Start', '15:19:11');
CALL add_p2p_check('Bredual', 'Anchil', 'C2_SimpleBashUtils', 'Success', '15:41:08');
CALL add_verter_check('Bredual', 'C2_SimpleBashUtils', 'Start', '15:41:11');
CALL add_p2p_check('Pormissina', 'Troducity', 'C2_SimpleBashUtils', 'Success', '15:41:12');
CALL add_verter_check('Pormissina', 'C2_SimpleBashUtils', 'Start', '15:41:15');
CALL add_verter_check('Bredual', 'C2_SimpleBashUtils', 'Success', '15:42:11');
CALL add_verter_check('Pormissina', 'C2_SimpleBashUtils', 'Success', '15:42:15');



DELETE FROM checks WHERE id = 7;



SELECT MAX(c.id)
FROM checks c
INNER JOIN verter v
ON c.id = v.check_id
WHERE c.peer = 'Pormissina' AND c.task = 'C2_SimpleBashUtils' AND v.state = 'Start';
