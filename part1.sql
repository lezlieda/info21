CREATE DATABASE info21;


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