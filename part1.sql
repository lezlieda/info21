CREATE DATABASE info21;

---------------------------------------
DROP TABLE peers CASCADE;
DROP TABLE tasks CASCADE;
DROP TYPE check_status  CASCADE;
DROP TABLE p2p CASCADE;
DROP TABLE verter CASCADE;
DROP TABLE checks CASCADE;
DROP TABLE transfered_points CASCADE;
DROP TABLE friends CASCADE;
DROP TABLE xp CASCADE;
DROP TABLE time_tracking CASCADE;
----------------------------------------

CREATE TABLE peers (
    nickname VARCHAR PRIMARY KEY,
    birthday DATE
);

CREATE TABLE tasks (
    title VARCHAR PRIMARY KEY,
    parent_task VARCHAR REFERENCES tasks,
    xp_amount INTEGER NOT NULL
);

CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure');

CREATE TABLE p2p (
    id BIGINT PRIMARY KEY,
    check_id BIGINT,
    checking_peer VARCHAR REFERENCES peers(nickname),
    state check_status,
    time TIME
);

CREATE TABLE verter (
    id BIGINT PRIMARY KEY,
    check_id BIGINT,
    state check_status,
    time TIME
);

CREATE TABLE checks (
    id BIGINT PRIMARY KEY,
    peer VARCHAR REFERENCES peers(nickname),
    task VARCHAR REFERENCES tasks(title),
    date DATE
);

ALTER TABLE p2p
ADD CONSTRAINT fk_p2p_check_id FOREIGN KEY (check_id) REFERENCES checks(id);

ALTER TABLE verter
ADD CONSTRAINT fk_verter_check_id FOREIGN KEY (check_id) REFERENCES checks(id);

CREATE TABLE transfered_points (
    id BIGINT PRIMARY KEY,
    checking_peer VARCHAR REFERENCES peers(nickname),
    checked_peer VARCHAR REFERENCES peers(nickname),
    points_amount INTEGER
);

CREATE TABLE friends (
    id BIGINT PRIMARY KEY,
    peer VARCHAR REFERENCES peers(nickname),
    recommended_peer VARCHAR REFERENCES peers(nickname)
);

CREATE TABLE xp (
    id BIGINT PRIMARY KEY,
    check_id BIGINT REFERENCES checks(id),
    xp_amount INTEGER
);

CREATE TABLE time_tracking (
    id BIGINT PRIMARY KEY,
    peer VARCHAR REFERENCES peers(nickname),
    date DATE,
    time TIME,
    state INTEGER CHECK (state IN (1, 2))
);

CREATE OR REPLACE PROCEDURE import_data(t_name VARCHAR, f_path VARCHAR, dlmtr VARCHAR)
LANGUAGE PLPGSQL AS $$
BEGIN
EXECUTE (SELECT FORMAT('COPY %s FROM ''%s'' %s%s ''%s'' NULL ''null'' CSV;', t_name, f_path, 'DELI', 'MITER' , dlmtr));
END;
$$;

-- importing all the tables
CALL import_data('peers', 'C:\Users\user\s21\core\SQL\s21_info21\data\peers.csv', ',');
CALL import_data('tasks', 'C:\Users\user\s21\core\SQL\s21_info21\data\tasks.csv', ',');





SELECT FORMAT('COPY %s FROM ''%s'' %s%s ''%s'' CSV WITH NULL AS ''null'';', 't_name', 'f_path', 'DELI', 'MITER' , 'dlmtr');

DROP PROCEDURE import_data;

SELECT * FROM transfered_points;

TRUNCATE TABLE transfered_points CASCADE;


SELECT to_char(now(), 'DD.MM.YY');
