/*
    This is the creation script we will now use
    as our working database.
    
    -- Execute in psql as admin logged into your default database.
    -- I.e.: *not* db55
    
    DROP DATABASE db55;
    CREATE DATABASE db55;
    \c db55
    CREATE SCHEMA rps;
    SET SEARCH_PATH TO rps;
    
    -- Now, run this script as admin
*/

DO $outer_block$
BEGIN
    DO $drop_tables$
    BEGIN
        -- DROP TABLES if they exist
        DROP TABLE IF EXISTS tbl_rounds;
        DROP TABLE IF EXISTS tbl_games;
        DROP TABLE IF EXISTS tbl_players;

        DROP FUNCTION IF EXISTS func_get_game_id;

        DROP PROCEDURE IF EXISTS proc_insert_player;
        DROP PROCEDURE IF EXISTS proc_insert_game;
        DROP PROCEDURE IF EXISTS proc_insert_round;

        DROP SEQUENCE IF EXISTS seq_pk;     -- This might go elsewhere.
        CREATE SEQUENCE seq_pk AS INTEGER;

        DROP TABLE IF EXISTS tbl_errata;    -- Create it anywhere.
        CREATE TABLE tbl_errata
        (
            fld_e_doc   TIMESTAMP DEFAULT NOW(),
            fld_e_sqlstate   TEXT,
            fld_e_sqlerrm   TEXT
        );
    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0005'; -- code may vary
    END $drop_tables$;


    -- ----------------------------------------------------------

    DO $create_tbl_players$
    BEGIN

        CREATE TABLE tbl_players
        (
            fld_p_id_pk     VARCHAR(16),
            fld_p_doc       TIMESTAMP DEFAULT NOW(),
            --
            CONSTRAINT players_pk PRIMARY KEY(fld_p_id_pk),
            CONSTRAINT zero_len_p_pk CHECK(LENGTH(fld_p_id_pk) > 0)
        );

    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0006'; -- code may vary
    END $create_tbl_players$;

    -- ----------------------------------------------------------

    DO $create_tbl_games$
    BEGIN

        CREATE TABLE tbl_games
        (
            fld_g_id_pk     INTEGER DEFAULT NEXTVAL('seq_pk'),
            fld_g_p1_fk     CHAR(16),
            fld_g_p2_fk     CHAR(16),
            fld_g_doc       TIMESTAMP DEFAULT NOW(),
            --
            CONSTRAINT games_pk PRIMARY KEY(fld_g_id_pk),
            CONSTRAINT null_player
                CHECK(NULLIF(fld_g_p1_fk,'')||NULLIF(fld_g_p2_fk,'')IS NOT NULL),
                -- See comment below
            CONSTRAINT p1_fk FOREIGN KEY(fld_g_p1_fk) 
                                        REFERENCES tbl_players(fld_p_id_pk),
            CONSTRAINT p2_fk FOREIGN KEY(fld_g_p2_fk) 
                                        REFERENCES tbl_players(fld_p_id_pk),
            CONSTRAINT unique_pair UNIQUE(fld_g_p1_fk, fld_g_p2_fk),
            CONSTRAINT player_order CHECK(fld_g_p1_fk < fld_g_p2_fk)
        );
        /*
            The built-in function of standard SQL: NULLIF(val1, val2)
            is designed to detect NULL and zero length.  Its logic is:
            
                IF val1=val2
                THEN RETURN NULL;
                ELSE RETURN val1;
                
            It may be concatenated and then checked for NULL:
            
            IF(NULLIF(a,'')||NULLIF(b,''))IS NULL
                then at least one of (a,b) is either [NULL OR '']
        */

    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0007'; -- code may vary
    END $create_tbl_games$;

    -- ----------------------------------------------------------

    DO $create_tbl_rounds$
    BEGIN

        CREATE TABLE tbl_rounds
        (
            fld_r_id_pk     INTEGER DEFAULT NEXTVAL('seq_pk'),
            fld_g_id_fk     INTEGER,
            fld_r_token1    CHAR(1),
            fld_r_token2    CHAR(1),
            fld_r_doc       TIMESTAMP DEFAULT NOW(),
            --
            CONSTRAINT rounds_pk PRIMARY KEY(fld_r_id_pk),
            CONSTRAINT null_gid CHECK(fld_g_id_fk IS NOT NULL),
            CONSTRAINT g_id_fk FOREIGN KEY(fld_g_id_fk) REFERENCES tbl_games(fld_g_id_pk),
            CONSTRAINT null_tokens
                CHECK(NULLIF(fld_r_token1,'')||NULLIF(fld_r_token2,'')IS NOT NULL),
            CONSTRAINT valid_tokens CHECK(fld_r_token1 IN ('R', 'P', 'S')
                                                        AND
                                           fld_r_token2 IN ('R', 'P', 'S'))
        );

    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0008'; -- code may vary
    END $create_tbl_rounds$;

    -- ---------------------------------------------------------

    DO $create_proc_insert_player$
    BEGIN
        -- ----
        CREATE OR REPLACE PROCEDURE proc_insert_player
                        (IN parm_pid CHAR(16), INOUT parm_errlvl SMALLINT)
        LANGUAGE plpgsql
        SECURITY DEFINER
        /*
            Error codes
                0 - success
                1 - static violation of parameter
                2 - duplicate PK
        */
        AS $GO$
        BEGIN
            parm_errlvl:=0;
            
            IF NULLIF(parm_pid,'') IS NULL
            THEN parm_errlvl:=1;
            ELSIF EXISTS
                (
                    SELECT *
                    FROM tbl_players
                    WHERE fld_p_id_pk=parm_pid
                )
                THEN parm_errlvl:=2;
                ELSE INSERT INTO tbl_players(fld_p_id_pk)
                     VALUES(parm_pid);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                INSERT INTO tbl_errata(fld_e_sqlstate, fld_e_sqlerrm)
                VALUES(SQLSTATE, SQLERRM);
        END $GO$;
        -- ----
    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0009'; -- code may vary
    END $create_proc_insert_player$;

    -- ---------------------------------------------------------

    DO $create_func_get_game_id$
    BEGIN
        -- ----
        CREATE OR REPLACE FUNCTION func_get_game_id
                    ( arg_p1 CHAR(16), arg_p2 CHAR(16) )
            RETURNS INTEGER
            LANGUAGE plpgsql
            SECURITY DEFINER
        AS $GO$
        DECLARE
            lv_p1 CHAR(16);
            lv_p2 CHAR(16);
            lv_swapped SMALLINT:=1;
            lv_gid INTEGER;
        BEGIN
            IF arg_p1>arg_p2
            THEN
                lv_p1:=arg_p2;
                lv_p2:=arg_p1;
                lv_swapped:=-1;
            ELSE
                lv_p1:=arg_p1;
                lv_p2:=arg_p2;
            END IF;

            SELECT fld_g_id_pk INTO lv_gid
            FROM tbl_games
            WHERE fld_g_p1_fk=lv_p1 AND fld_g_p2_fk=lv_p2;

            RETURN lv_swapped*lv_gid;
        END $GO$;
        -- ----
    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0010'; -- code may vary
    END $create_func_get_game_id$;

    -- ---------------------------------------------------------

    DO $create_proc_insert_game$
    BEGIN
        -- ----
        CREATE OR REPLACE PROCEDURE proc_insert_game
            (IN parm_p1 CHAR(16), IN parm_p2 CHAR(16), INOUT parm_errlvl SMALLINT)
        LANGUAGE plpgsql
        SECURITY DEFINER
        /*
            Error codes
                0 - success
                1 - static parameter issue
                2 - foreign key violation
                3 - unique game violation
        */
        AS $GO$
        DECLARE
            lv_p1 CHAR(16);
            lv_p2 CHAR(16);
        BEGIN
            IF parm_p1>parm_p2
            THEN
                lv_p1:=parm_p2;
                lv_p2:=parm_p1;
            ELSE
                lv_p1:=parm_p1;
                lv_p2:=parm_p2;
            END IF;

            parm_errlvl:=0; -- set default

            IF NULLIF(lv_p1,'')||NULLIF(lv_p2,'') IS NULL
            THEN parm_errlvl:=1;
            ELSIF NOT EXISTS        -- check that players are valid
                (
                    SELECT *
                    FROM tbl_players
                    WHERE fld_p_id_pk=lv_p1
                )
                OR NOT EXISTS
                (
                    SELECT *
                    FROM tbl_players
                    WHERE fld_p_id_pk=lv_p2
                )
                THEN parm_errlvl:=2;
                            -- Here, we may leverage func_get_game_id
                    ELSIF func_get_game_id(lv_p1, lv_p2) IS NOT NULL
                    THEN parm_errlvl:=3;
                    ELSE
                        INSERT INTO tbl_games(fld_g_p1_fk, fld_g_p2_fk)
                        VALUES(lv_p1, lv_p2);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                INSERT INTO tbl_errata(fld_e_sqlstate, fld_e_sqlerrm)
                VALUES(SQLSTATE, SQLERRM);
        END $GO$;
        -- ----
    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0011'; -- code may vary
    END $create_proc_insert_game$;

    -- ---------------------------------------------------------

    DO $create_proc_insert_round$
    BEGIN
        -- ----
        CREATE OR REPLACE PROCEDURE proc_insert_round
                        (   IN parm_p1 CHAR(16), IN parm_t1 CHAR(1),
                            IN parm_p2 CHAR(16), IN parm_t2 CHAR(1),
                            INOUT parm_errlvl SMALLINT )
            LANGUAGE plpgsql
            SECURITY DEFINER
        /*
            Error codes
                0 - success
                1 - No game exists
                2 - Invalid Token
        */
        AS $GO$
        DECLARE
            lv_t1 CHAR(1);
            lv_t2 CHAR(2);
            lv_gid INT := func_get_game_id(parm_p1, parm_p2);
        BEGIN
            parm_errlvl:=0;
            
            IF lv_gid IS NULL
            THEN parm_errlvl:=1;
                 -- and done
            ELSE
                IF lv_gid<0
                THEN
                    lv_t1:=parm_t2;
                    lv_t2:=parm_t1;
                    lv_gid:=ABS(lv_gid);
                ELSE
                    lv_t1:=parm_t1;
                    lv_t2:=parm_t2;
                END IF;
                                
                IF NOT(lv_t1 IN ('R','P','S') AND lv_t2 IN ('R','P','S'))
                THEN parm_errlvl:=2;
                ELSE INSERT INTO tbl_rounds(fld_g_id_fk, fld_r_token1, fld_r_token2)
                     VALUES(lv_gid, lv_t1, lv_t2);
                END IF;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                INSERT INTO tbl_errata(fld_e_sqlstate, fld_e_sqlerrm)
                VALUES(SQLSTATE, SQLERRM);
        END $GO$;        
        -- ----
    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0012'; -- code may vary
    END $create_proc_insert_round$;

    -- ---------------------------------------------------------

    DO $admin_block$
    BEGIN
        GRANT CONNECT ON DATABASE db55 TO public_users;
        GRANT USAGE ON SCHEMA rps TO public_users;
        GRANT EXECUTE ON PROCEDURE proc_insert_player TO public_users;
        GRANT EXECUTE ON PROCEDURE proc_insert_game TO public_users;
        GRANT EXECUTE ON PROCEDURE proc_insert_round TO public_users;

    EXCEPTION
        WHEN OTHERS THEN RAISE EXCEPTION USING ERRCODE = 'P0013'; -- code may vary
    END $admin_block$;

    -- ---------------------------------------------------------


    -- If we get here, SUCCESS!!!
    RAISE INFO E'\n\n\n  Creation Script Completes Successfully.\n\n\n';
    -- Creation script ends here.
    
    

EXCEPTION
    WHEN SQLSTATE 'P0005' THEN
        RAISE INFO E'\n\n\n  Drop tables failed.\n\n\n';
    WHEN SQLSTATE 'P0006' THEN
        RAISE INFO E'\n\n\n  Create tbl_players failed.\n\n\n';
    WHEN SQLSTATE 'P0007' THEN
        RAISE INFO E'\n\n\n  Create tbl_games failed.\n\n\n';
    WHEN SQLSTATE 'P0008' THEN
        RAISE INFO E'\n\n\n  Create tbl_rounds failed.\n\n\n';
    WHEN SQLSTATE 'P0009' THEN
        RAISE INFO E'\n\n\n  Create insert_player failed.\n\n\n';
    WHEN SQLSTATE 'P0010' THEN
        RAISE INFO E'\n\n\n  Create get_game_id failed.\n\n\n';
    WHEN SQLSTATE 'P0011' THEN
        RAISE INFO E'\n\n\n  Create insert_game failed.\n\n\n';
    WHEN SQLSTATE 'P0012' THEN
        RAISE INFO E'\n\n\n  Create insert_round failed.\n\n\n';
    WHEN SQLSTATE 'P0013' THEN
        RAISE INFO E'\n\n\n  Admin block failed.\n\n\n';
    WHEN OTHERS THEN
        -- We should *NEVER* see this warning!!!  If we do, it means our
        -- creation script is wrong on a low level!
        RAISE WARNING E'\n\n\nFatal Error: sqlstate %, sqlerrm %.\n\n\n', SQLSTATE, SQLERRM;
END $outer_block$;
