-- 1) Write a procedure for adding P2P check
--    Parameters: nickname of the person being checked, checker's nickname, task name, P2P check status, time.
--    If the status is "start", add a record in the Checks table (use today's date).
--    Add a record in the P2P table.
--    If the status is "start", specify the record just added as a check, otherwise specify the check with the
--    unfinished P2P step.
CREATE OR REPLACE PROCEDURE
add_p2p_check(p_peer VARCHAR, p_checking_peer VARCHAR, p_task VARCHAR, p_status check_status, p_time TIME) AS $$
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
$$ LANGUAGE PLPGSQL;

-- 2) Write a procedure for adding checking by Verter
--    Parameters: nickname of the person being checked, task name, Verter check status, time.
--    Add a record to the Verter table (as a check specify the check of the corresponding task
--    with the latest (by time) successful P2P step)
CREATE OR REPLACE PROCEDURE
add_verter_check(p_peer VARCHAR, p_task VARCHAR, p_status check_status, p_time TIME) AS $$
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
$$ LANGUAGE PLPGSQL;

-- 3) Write a trigger: after adding a record with the "start" status to the P2P table,
--    change the corresponding record in the TransferredPoints table

CREATE OR REPLACE FUNCTION fnc_transfer_point() RETURNS trigger AS $trg_transfer_point$
BEGIN
    IF NEW.State = 'Start' THEN
        UPDATE transferred_points
        SET points_amount = points_amount + 1
        WHERE checking_peer = NEW.checking_peer
        AND checked_peer = (SELECT peer FROM checks WHERE id = NEW.check_id);
    END IF;
    RETURN NULL;
END;
$trg_transfer_point$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trg_transfer_point
AFTER INSERT ON p2p
FOR EACH ROW EXECUTE FUNCTION fnc_transfer_point();

-- 4) Write a trigger: before adding a record to the XP table, check if it is correct
--    The number of XP does not exceed the maximum available for the task being checked
--    The Check field refers to a successful check If the record does not pass the check, do not add it to the table.
CREATE OR REPLACE FUNCTION fnc_is_check_successful(p_check_id BIGINT) RETURNS BOOLEAN AS $$
BEGIN
    IF (SELECT state FROM p2p WHERE check_id = p_check_id ORDER BY id DESC LIMIT 1) = 'Success' AND
    (NOT EXISTS (SELECT state FROM verter WHERE check_id = p_check_id ORDER BY id DESC LIMIT 1) OR
    (SELECT state FROM verter WHERE check_id = p_check_id ORDER BY id DESC LIMIT 1)  = 'Success') THEN
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION fnc_check_xp_insert() RETURNS trigger AS $trg_check_xp_insert$
BEGIN
    IF NEW.xp_amount IN (0, (SELECT max_xp FROM checks c JOIN tasks t ON t.title = c.task WHERE c.id = NEW.id)) AND
    fnc_is_check_successful(NEW.check_id) = TRUE THEN
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$trg_check_xp_insert$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trg_check_xp_insert
BEFORE INSERT ON xp
FOR EACH ROW EXECUTE FUNCTION fnc_check_xp_insert();

---------- tests -------------------------------------------------------

INSERT INTO xp VALUES((SELECT MAX(id) + 1 FROM xp), 7, 350);
INSERT INTO xp VALUES((SELECT MAX(id) + 1 FROM xp), 8, 1350);

SELECT fnc_is_check_successful(1) ;

SELECT state FROM p2p WHERE check_id = 3 ORDER BY id DESC LIMIT 1;

SELECT c.id, t.max_xp AS max_xp
FROM checks c
JOIN tasks t
ON t.title = c.task;



SELECT * FROM checks;
SELECT * FROM p2p;
SELECT * FROM verter;

SELECT * FROM transferred_points;

SELECT c.peer FROM p2p p JOIN checks c ON p.check_id = c.id;



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
