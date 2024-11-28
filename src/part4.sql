-- 1) Create a stored procedure that, without destroying the database, destroys all those tables
--    in the current database whose names begin with the phrase 'TableName'.

CREATE OR REPLACE PROCEDURE prc_drop_tables_by_prefix(p_prefix VARCHAR) AS $$
DECLARE
    v_table_name VARCHAR;
BEGIN
    FOR v_table_name IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name LIKE p_prefix || '%'
    LOOP
        EXECUTE FORMAT('DROP TABLE %I CASCADE', v_table_name);
    END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE TABLE test1 (id BIGINT PRIMARY KEY, name VARCHAR);
CREATE TABLE test2 (id BIGINT PRIMARY KEY, name VARCHAR);
CREATE TABLE test3 (id BIGINT PRIMARY KEY, name VARCHAR);
CREATE TABLE test_test_test (id BIGINT PRIMARY KEY, name VARCHAR);

CALL prc_drop_tables_by_prefix('test');


-- 2) Create a stored procedure with an output parameter that outputs a list of names and parameters
--    of all scalar user's SQL functions in the current database. Do not output function names
--    without parameters. The names and the list of parameters must be in one string. The output
--    parameter returns the number of functions found.


-- 3) Create a stored procedure with output parameter, which destroys all SQL DML triggers
--    in the current database.The output parameter returns the number of destroyed triggers.
DROP PROCEDURE prc_drop_triggers(INOUT p_count INTEGER);
CREATE OR REPLACE PROCEDURE prc_drop_triggers(OUT p_count INTEGER) AS $$
DECLARE
    v_trg_name NAME;
BEGIN
    p_count := 0;
    FOR v_trg_name IN
        SELECT trigger_name
        FROM information_schema.triggers
        WHERE event_manipulation IN ('INSERT', 'UPDATE', 'DELETE')
    LOOP
        EXECUTE FORMAT('DROP TRIGGER %I ON %I', v_trg_name, (SELECT event_object_table FROM information_schema.triggers WHERE trigger_name = v_trg_name));
        p_count := p_count + 1;
    END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CALL prc_drop_triggers(p_count := 243234);

-- 4) Create a stored procedure with an input parameter that outputs names and descriptions of 
--    object types (only stored procedures and scalar functions) that have a string specified 
--    by the procedure parameter.

CREATE OR REPLACE PROCEDURE prc_find_objects_by_description(IN p_search_string VARCHAR, INOUT curs REFCURSOR = 'part4_ex4') AS $$
BEGIN
    OPEN curs FOR
        SELECT routine_name, routine_definition
        FROM information_schema.routines
        WHERE routine_schema = 'public' AND routine_type IN ('PROCEDURE', 'FUNCTION') AND routine_definition LIKE '%' || p_search_string || '%';
END;
$$ LANGUAGE PLPGSQL;

BEGIN;
CALL prc_find_objects_by_description('RETURN');
FETCH ALL FROM part4_ex4;
END;