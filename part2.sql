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
        INSERT INTO checks VALUES((SELECT COALESCE(MAX(id), 0) + 1 FROM checks),
                                  p_peer,
                                  p_task,
                                  now()::DATE);
        INSERT INTO p2p VALUES((SELECT COALESCE(MAX(id), 0) + 1 FROM p2p),
                               (SELECT COALESCE(MAX(id), 1) FROM checks),
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
        INSERT INTO verter VALUES((SELECT COALESCE(MAX(id), 0) + 1 FROM verter),
                                  (SELECT MAX(c.id) FROM checks c
                                   INNER JOIN p2p p ON c.id = p.check_id
                                   WHERE c.peer = p_peer AND c.task = p_task AND p.state = 'Success'),
                                   p_status,
                                   p_time);
    ELSE
        INSERT INTO verter VALUES((SELECT MAX(id) + 1 FROM verter),
                                  (SELECT MAX(c.id) FROM checks c
                                   INNER JOIN verter v ON c.id = v.check_id
                                   WHERE c.peer = p_peer AND c.task = p_task AND v.state = 'Start'),
                                   p_status,
                                   p_time);
    END IF;
END;
$$ LANGUAGE PLPGSQL;

-- 3) Write a trigger: after adding a record with the "start" status to the P2P table,
--    change the corresponding record in the TransferredPoints table
CREATE OR REPLACE FUNCTION fnc_transfer_exists(p_checking VARCHAR, p_checked VARCHAR) RETURNS BOOLEAN AS $$
BEGIN
    IF EXISTS (SELECT points_amount FROM transferred_points
    WHERE checking_peer = $1 AND checked_peer = $2)
    THEN
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION fnc_transfer_point() RETURNS trigger AS $trg_transfer_point$
BEGIN
    IF NEW.State = 'Start' THEN
        IF fnc_transfer_exists(NEW.checking_peer, (SELECT peer FROM checks WHERE id = NEW.check_id)) = TRUE THEN
            UPDATE transferred_points
            SET points_amount = points_amount + 1
            WHERE checking_peer = NEW.checking_peer
            AND checked_peer = (SELECT peer FROM checks WHERE id = NEW.check_id);
        ELSE
            INSERT INTO transferred_points
            VALUES((SELECT COALESCE(MAX(id), 0) + 1 FROM transferred_points),
                   NEW.checking_peer,
                   (SELECT peer FROM checks WHERE id = NEW.check_id),
                   1);
        END IF;
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
    IF NEW.xp_amount BETWEEN 0 AND (SELECT max_xp FROM checks c JOIN tasks t ON t.title = c.task WHERE c.id = NEW.check_id)
    AND fnc_is_check_successful(NEW.check_id) = TRUE THEN
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$trg_check_xp_insert$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trg_check_xp_insert
BEFORE INSERT ON xp
FOR EACH ROW EXECUTE FUNCTION fnc_check_xp_insert();

---------- tests -------------------------------------------------------
-- 1 check
CALL add_p2p_check('Pormissina', 'Troducity', 'C2_SimpleBashUtils', 'Start', '12:17:11');
CALL add_p2p_check('Pormissina', 'Troducity', 'C2_SimpleBashUtils', 'Success', '12:41:12');
CALL add_verter_check('Pormissina', 'C2_SimpleBashUtils', 'Start', '12:41:15');
CALL add_verter_check('Pormissina', 'C2_SimpleBashUtils', 'Success', '12:42:15');
INSERT INTO xp VALUES((SELECT MAX(id) + 1 FROM xp), (SELECT MAX(id) FROM checks), 350);
-- 2 check
CALL add_p2p_check('Bredual', 'Anchil', 'C2_SimpleBashUtils', 'Start', '12:19:11');
CALL add_p2p_check('Bredual', 'Anchil', 'C2_SimpleBashUtils', 'Success', '12:41:08');
CALL add_verter_check('Bredual', 'C2_SimpleBashUtils', 'Start', '12:41:11');
CALL add_verter_check('Bredual', 'C2_SimpleBashUtils', 'Failure', '12:42:11');
-- 3 check
CALL add_p2p_check('Bredual', 'Pormissina', 'C2_SimpleBashUtils', 'Start', '15:34:51');
CALL add_p2p_check('Bredual', 'Pormissina', 'C2_SimpleBashUtils', 'Success', '16:19:02');
CALL add_verter_check('Bredual', 'C2_SimpleBashUtils', 'Start', '16:19:03');
CALL add_verter_check('Bredual', 'C2_SimpleBashUtils', 'Failure', '16:20:00');
-- 4 check
CALL add_p2p_check('Bredual', 'Prowels', 'C2_SimpleBashUtils', 'Start', '22:20:01');
CALL add_p2p_check('Bredual', 'Prowels', 'C2_SimpleBashUtils', 'Success', '22:29:36');
CALL add_verter_check('Bredual', 'C2_SimpleBashUtils', 'Start', '22:29:37');
CALL add_verter_check('Bredual', 'C2_SimpleBashUtils', 'Success', '22:30:37');
INSERT INTO xp VALUES((SELECT MAX(id) + 1 FROM xp), (SELECT MAX(id) FROM checks), 1350); -- 1350 > 350
INSERT INTO xp VALUES((SELECT MAX(id) + 1 FROM xp), (SELECT MAX(id) FROM checks), -350); -- -350 < 0
INSERT INTO xp VALUES((SELECT MAX(id) + 1 FROM xp), (SELECT MAX(id) FROM checks), 265);

-- 5 check
CALL add_p2p_check('Bredual', 'Anchil', 'C3_s21_string+', 'Start', '22:45:00');
CALL add_p2p_check('Bredual', 'Anchil', 'C3_s21_string+', 'Success', '23:24:31');
CALL add_verter_check('Bredual', 'C3_s21_string+', 'Start', '23:24:32');
CALL add_verter_check('Bredual', 'C3_s21_string+', 'Success', '23:25:32');

INSERT INTO xp VALUES((SELECT MAX(id) + 1 FROM xp), (SELECT MAX(id) FROM checks), 555);




SELECT * FROM checks;
SELECT * FROM p2p;
SELECT * FROM verter;
SELECT * FROM xp;
SELECT * FROM transferred_points;

