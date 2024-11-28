CREATE DATABASE info21;
\c info21
----- drop tables ----------------------------------

DROP TABLE peers CASCADE;
DROP TABLE tasks CASCADE;
DROP TYPE check_status  CASCADE;
DROP TABLE p2p CASCADE;
DROP TABLE verter CASCADE;
DROP TABLE checks CASCADE;
DROP TABLE transferred_points CASCADE;
DROP TABLE friends CASCADE;
DROP TABLE recommendations CASCADE;
DROP TABLE xp CASCADE;
DROP TABLE time_tracking CASCADE;

----- tables creation ---------------------------------
CREATE TABLE peers (
    nickname VARCHAR PRIMARY KEY,
    birthday DATE NOT NULL
);

CREATE TABLE tasks (
    title VARCHAR PRIMARY KEY,
    parent_task VARCHAR REFERENCES tasks,
    max_xp INTEGER NOT NULL
);

CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure', '0', '1', '2');


CREATE TABLE checks (
    id BIGINT PRIMARY KEY,
    peer VARCHAR REFERENCES peers,
    task VARCHAR REFERENCES tasks,
    date DATE
);

CREATE TABLE p2p (
    id BIGINT PRIMARY KEY,
    "check" BIGINT REFERENCES checks,
    checking_peer VARCHAR REFERENCES peers,
    state check_status,
    time TIME NOT NULL
);

CREATE TABLE verter (
    id BIGINT PRIMARY KEY,
    "check" BIGINT REFERENCES checks,
    state check_status,
    time TIME NOT NULL
);

CREATE OR REPLACE FUNCTION fnc_status_insert() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.state IN ('0', 'Start') THEN
        NEW.state = 'Start';
    ELSIF NEW.state IN ('1', 'Success') THEN
        NEW.state = 'Success';
    ELSE
        NEW.state = 'Failure';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER trg_p2p_insert_status
BEFORE INSERT ON p2p
FOR EACH ROW
EXECUTE FUNCTION fnc_status_insert();

CREATE OR REPLACE TRIGGER trg_verter_insert_status
BEFORE INSERT ON verter
FOR EACH ROW
EXECUTE FUNCTION fnc_status_insert();

CREATE TABLE transferred_points (
    id BIGINT PRIMARY KEY,
    checking_peer VARCHAR REFERENCES peers,
    checked_peer VARCHAR REFERENCES peers,
    points_amount INTEGER
);

CREATE TABLE friends (
    id BIGINT PRIMARY KEY,
    peer1 VARCHAR REFERENCES peers,
    peer2 VARCHAR REFERENCES peers
);

CREATE TABLE recommendations (
    id BIGINT PRIMARY KEY,
    peer VARCHAR REFERENCES peers,
    recommended_peer VARCHAR REFERENCES peers
);

CREATE TABLE xp (
    id BIGINT PRIMARY KEY,
    "check" BIGINT REFERENCES checks,
    xp_amount INTEGER NOT NULL
);

CREATE TABLE time_tracking (
    id BIGINT PRIMARY KEY,
    peer VARCHAR REFERENCES peers,
    date DATE NOT NULL,
    time TIME NOT NULL,
    state INTEGER NOT NULL CHECK (state IN (1, 2))
);

----------------- data import / export ------------------------------------
CREATE OR REPLACE PROCEDURE prc_import_data(t_name VARCHAR, f_path VARCHAR, dlmtr VARCHAR)
LANGUAGE PLPGSQL AS $$
BEGIN
EXECUTE (SELECT FORMAT('COPY %s FROM ''%s'' %s%s ''%s'' NULL ''None'' CSV HEADER;', t_name, f_path, 'DELI', 'MITER' , dlmtr));
END;
$$;

CREATE OR REPLACE PROCEDURE prc_export_data(t_name VARCHAR, f_path VARCHAR, dlmtr VARCHAR)
LANGUAGE PLPGSQL AS $$
BEGIN
EXECUTE (SELECT FORMAT('COPY %s TO ''%s'' %s%s ''%s'' NULL ''None'' CSV HEADER;', t_name, f_path, 'DELI', 'MITER' , dlmtr));
END;
$$;

------------ importing from CSV files the tables --------------------------------------------------------
SET DATESTYLE TO DMY;

CALL prc_import_data('peers', 'C:\Users\user\s21\core\SQL2_Info21_v1.0-1\src\dataset_sql\peers.csv', ';');
CALL prc_import_data('tasks', 'C:\Users\user\s21\core\SQL2_Info21_v1.0-1\src\dataset_sql\tasks.csv', ';');
CALL prc_import_data('checks', 'C:\Users\user\s21\core\SQL2_Info21_v1.0-1\src\dataset_sql\checks.csv', ';');
CALL prc_import_data('friends', 'C:\Users\user\s21\core\SQL2_Info21_v1.0-1\src\dataset_sql\friends.csv', ';');
CALL prc_import_data('recommendations', 'C:\Users\user\s21\core\SQL2_Info21_v1.0-1\src\dataset_sql\recommendations.csv', ';');
CALL prc_import_data('time_tracking', 'C:\Users\user\s21\core\SQL2_Info21_v1.0-1\src\dataset_sql\time_tracking.csv', ';');
CALL prc_import_data('xp', 'C:\Users\user\s21\core\SQL2_Info21_v1.0-1\src\dataset_sql\xp.csv', ';');
CALL prc_import_data('p2p', 'C:\Users\user\s21\core\SQL2_Info21_v1.0-1\src\dataset_sql\p2p.csv', ';');
CALL prc_import_data('verter', 'C:\Users\user\s21\core\SQL2_Info21_v1.0-1\src\dataset_sql\verter.csv', ';');
CALL prc_import_data('transferred_points', 'C:\Users\user\s21\core\SQL2_Info21_v1.0-1\src\dataset_sql\transferred_points.csv', ';');

------------ tables output -------------------------------------------------
SELECT * FROM peers;
SELECT * FROM tasks;
SELECT * FROM checks;
SELECT * FROM p2p;
SELECT * FROM verter;
SELECT * FROM transferred_points;
SELECT * FROM friends;
SELECT * FROM recommendations;
SELECT * FROM xp;
SELECT * FROM time_tracking;

------------ exporting to CSV files the tables --------------------------------------------------------
CALL prc_export_data('peers', 'C:\Users\user\s21\core\SQL2_Info21_v1.0-1\src\dataset_sql\peers1.csv', ';');
CALL prc_export_data('tasks', 'C:\Users\user\s21\core\SQL2_Info21_v1.0-1\src\dataset_sql\tasks1.csv', ';');
CALL prc_export_data('checks', 'C:\Users\user\s21\core\SQL2_Info21_v1.0-1\src\dataset_sql\checks1.csv', ';');

----------- insert data for part3 ----------------------------------------------------------------------
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'azovbzwucs', 'oikupfmulj');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'nwlekkiqkd', 'lqrnoqonel');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'opdevribry', 'qqrvtitrgx');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'yhzlwxbhwo', 'rbowhduudf');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'sktlbnkubd', 'edwizmdsac');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'vnsckbjooq', 'uatkgtmnug');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'joankrslxd', 'czrtbqtbfe');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'nzbkgdytmi', 'ciqxegnxtb');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'wsglyubmeq', 'ypmjxuzbbu');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'amswxgncxe', 'ysobsqaevg');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'nyjptxdqrd', 'ziacynxkne');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'pobssonjog', 'ohhhjftknf');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'eeapeibrdy', 'jscewpegsf');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'xebdeqnkjw', 'kccouxefom');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'skhwzerkmd', 'mkdtcjrqcz');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'uydhpkwvxp', 'aczlyhjvvs');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'aczbqvkxvu', 'ysobsqaevg');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'eeapeibrdy', 'nwwwjafhsp');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'pfvoxeuwet', 'qgpytyvzbi');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'nwlekkiqkd', 'uydhpkwvxp');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'eeapeibrdy', 'pfvoxeuwet');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'nwwwjafhsp', 'yhzlwxbhwo');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'nyjptxdqrd', 'qgpytyvzbi');
INSERT INTO friends VALUES ( (SELECT max(id) + 1 FROM friends) , 'joankrslxd', 'amswxgncxe');
INSERT INTO recommendations VALUES ( (SELECT max(id) + 1 FROM recommendations) , 'lculbswapx', 'fmqqdxpszk');
INSERT INTO recommendations VALUES ( (SELECT max(id) + 1 FROM recommendations) , 'hueztkcnpq', 'ggcxzeollh'); 