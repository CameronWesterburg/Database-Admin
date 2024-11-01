-- create a generic table
-- Database: db55
-- schema rps   (It doesn't matter, we just have to know where it is.)

/*
    Disclaimer:
    
    You will *not* turn in code that creates *tbl_generic*.  
    I'm creating that table and its associated procedure: *proc_insert_generic*
    ONLY as a demonstration.  Please do not copy this code and turn it in
    as your assignment.  For the PHP "front end" assignment, please use 
    the SQL code I provided in the file: *midterm_solution.sql* which may
    be found linked in the page titled: "Mid-term Project Complete Code (Copy)"
    
    You will drop your "rps" schema and re-create it.  Then set your search-path
    and run the sql code in that file.  This will create:
    
        proc_insert_player(CHAR(16), INOUT SMALLINT)
        proc_insert_game(CHAR(16), CHAR(16), INOUT SMALLINT)
        proc_insert_round(CHAR(16), CHAR(1), CHAR(16), CHAR(1), INOUT SMALLINT)
        
    You will develop three php scripts that will call these three procedures.  You
    do not need to turn in the file *midterm_solution.sql*, but you may.
    
    Do not turn in *demo_of_php.sql* (this file).  Do not copy it... it exists for
    demonstration ONLY!  Do not turn in *myForm.php*; however, that one is your 
    example of how a .php file.
*/

DO $outer_block$
BEGIN
    DO $drop_objects$
    BEGIN
    
        DROP TABLE IF EXISTS tbl_generic;
        DROP PROCEDURE IF EXISTS proc_insert_generic;
        
    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0005'; 
    END $drop_objects$;
    
    DO $create_table$
    BEGIN

        CREATE TABLE tbl_generic
        (
            fld_fee_pk  CHAR(16),
            fld_fie     CHAR(16)
            ,CONSTRAINT generic_pk PRIMARY KEY(fld_fee_pk)
            ,CONSTRAINT zero_len_pk CHECK(LENGTH(fld_fee_pk)>0)
            ,CONSTRAINT null_fie CHECK(fld_fie IS NOT NULL AND LENGTH(fld_fie)>0)
        ); 
    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0006'; 
    END $create_table$;

    DO $create_procedure$
    BEGIN
    -- --------------------------------------------
        CREATE OR REPLACE PROCEDURE proc_insert_generic
            (IN parm_fee CHAR(16), IN parm_fie CHAR(16), INOUT parm_errlvl SMALLINT)
        LANGUAGE plpgsql
        SECURITY DEFINER
        AS $GO$
        BEGIN
            parm_errlvl := 0;
    
            IF parm_fee IS NULL OR LENGTH(parm_fee)=0 
                    OR parm_fie IS NULL OR LENGTH(parm_fie)=0
            THEN parm_errlvl := 1;
            ELSIF EXISTS(SELECT * FROM db55.rps.tbl_generic WHERE fld_fee_pk=parm_fee)
                THEN parm_errlvl := 2;
                ELSE
                    INSERT INTO db55.rps.tbl_generic(fld_fee_pk,fld_fie)
                    VALUES(parm_fee, parm_fie);
            END IF;
        END $GO$;
    -- --------------------------------------------
    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0007'; 
    END $create_procedure$;
    

    DO $admin_block$
    BEGIN
        GRANT EXECUTE ON PROCEDURE rps.proc_insert_generic TO public_users;
        GRANT CONNECT ON DATABASE db55 TO public_users;
        GRANT USAGE ON SCHEMA rps TO public_users;
    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0008'; 
    END $admin_block$;
    
    RAISE INFO 'Successful Creation.';
    
EXCEPTION -- outer_block
    WHEN SQLSTATE 'P0005' THEN
        RAISE INFO E'\n\n\n  Drop objects failed.\n\n\n';
    WHEN SQLSTATE 'P0006' THEN
        RAISE INFO E'\n\n\n  Create table failed.\n\n\n';
    WHEN SQLSTATE 'P0007' THEN
        RAISE INFO E'\n\n\n  Create procedure failed.\n\n\n';
    WHEN SQLSTATE 'P0008' THEN
        RAISE INFO E'\n\n\n  Create admin block failed.\n\n\n';
    WHEN OTHERS THEN
        -- We should *NEVER* see this warning!!!  If we do, it means our
        -- creation script is wrong on a low level!
        RAISE WARNING E'\n\n\nError: sqlstate %, sqlerrm %.\n\n\n', SQLSTATE, SQLERRM;
END $outer_block$;
