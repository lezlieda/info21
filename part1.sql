CREATE DATABASE info21;
----- drop tables ----------------------------------
DROP TABLE peers CASCADE;
DROP TABLE tasks CASCADE;
DROP TYPE check_status  CASCADE;
DROP TABLE p2p CASCADE;
DROP TABLE verter CASCADE;
DROP TABLE checks CASCADE;
DROP TABLE transferred_points CASCADE;
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
    xp_amount INTEGER NOT NULL
);

CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure');

CREATE TABLE checks (
    id BIGINT PRIMARY KEY,
    peer VARCHAR REFERENCES peers,
    task VARCHAR REFERENCES tasks,
    date DATE
);

CREATE TABLE p2p (
    id BIGINT PRIMARY KEY,
    check_id BIGINT REFERENCES checks,
    checking_peer VARCHAR REFERENCES peers,
    state check_status,
    time TIME NOT NULL
);

CREATE TABLE verter (
    id BIGINT PRIMARY KEY,
    check_id BIGINT REFERENCES checks,
    state check_status,
    time TIME NOT NULL
);

CREATE TABLE transferred_points (
    id BIGINT PRIMARY KEY,
    checking_peer VARCHAR REFERENCES peers,
    checked_peer VARCHAR REFERENCES peers,
    points_amount INTEGER
); -- checking_peer > 0 > checked_peer

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

--------------------------------------------------------------------------------
CREATE TABLE xp (
    id BIGINT PRIMARY KEY,
    check_id BIGINT REFERENCES checks,
    xp_amount INTEGER
);

CREATE TABLE time_tracking (
    id BIGINT PRIMARY KEY,
    peer VARCHAR REFERENCES peers,
    date DATE,
    time TIME,
    state INTEGER CHECK (state IN (1, 2))
);

----------------- data import / export ------------------------------------

CREATE OR REPLACE PROCEDURE import_data(t_name VARCHAR, f_path VARCHAR, dlmtr VARCHAR)
LANGUAGE PLPGSQL AS $$
BEGIN
EXECUTE (SELECT FORMAT('COPY %s FROM ''%s'' %s%s ''%s'' NULL ''null'' CSV;', t_name, f_path, 'DELI', 'MITER' , dlmtr));
END;
$$;

------------ importing all the tables --------------------------------------------------------
CALL import_data('peers', 'C:\Users\user\s21\core\SQL\s21_info21\data\peers.csv', ',');
CALL import_data('tasks', 'C:\Users\user\s21\core\SQL\s21_info21\data\tasks.csv', ',');
CALL import_data('checks', 'C:\Users\user\s21\core\SQL\s21_info21\data\checks.csv', ',');
CALL import_data('p2p', 'C:\Users\user\s21\core\SQL\s21_info21\data\p2p.csv', ',');
CALL import_data('verter', 'C:\Users\user\s21\core\SQL\s21_info21\data\verter.csv', ',');
CALL import_data('transferred_points', 'C:\Users\user\s21\core\SQL\s21_info21\data\transferred_points.csv', ',');
CALL import_data('friends', 'C:\Users\user\s21\core\SQL\s21_info21\data\friends.csv', ',');
CALL import_data('recommendations', 'C:\Users\user\s21\core\SQL\s21_info21\data\recommendations.csv', ',');

------------ tables output -------------------------------------------------
SELECT * FROM peers;
SELECT * FROM tasks;
SELECT * FROM checks;
SELECT * FROM p2p;
SELECT * FROM verter;
SELECT * FROM transferred_points;
SELECT * FROM friends;
SELECT * FROM recommendations;



-- tests-----------------------------------------------------------------------------

SET DateStyle to 'DMY';
SELECT '19:23:02'::TIME;

show datestyle;

SELECT now()::INTERVAL; 

SELECT now()::TIME WITH TIME ZONE;

SELECT FORMAT('COPY %s FROM ''%s'' %s%s ''%s'' CSV WITH NULL AS ''null'';', 't_name', 'f_path', 'DELI', 'MITER' , 'dlmtr');

DROP PROCEDURE import_data;

SELECT * FROM peers;
SELECT * FROM tasks;
SELECT * FROM checks;

TRUNCATE TABLE checks CASCADE;


SELECT to_char(now(), 'DD.MM.YY');
