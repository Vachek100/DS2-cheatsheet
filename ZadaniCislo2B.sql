SET SERVEROUTPUT ON;

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE work_z_author';
EXCEPTION 
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE work_z_author_name_changes';
EXCEPTION 
    WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE work_z_author AS 
SELECT *
FROM z_author;

CREATE TABLE work_z_author_name_changes (
    rid INT,
    old_name VARCHAR2(200),
    new_name VARCHAR2(200),
    change_time DATE
);

CREATE OR REPLACE TRIGGER TR_AuthorNameAudit
AFTER UPDATE 
OF name 
ON work_z_author 
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    
    IF :OLD.name != :NEW.name THEN
    
        -- spocitej pocet clanku autora
        SELECT COUNT(*) INTO v_count
        FROM z_article_author
        WHERE rid = :OLD.rid;
        
        IF v_count > 5 THEN
            INSERT INTO work_z_author_name_changes
            (rid, old_name, new_name, change_time)
            VALUES
            (:OLD.rid, :OLD.name, :NEW.name, SYSDATE);
            
            DBMS_OUTPUT.PUT_LINE('name_changes_recorded: 1');
    
        END IF;
    END IF;
    
    EXCEPTION
    -- zachycení všech chyb v triggeru
    WHEN OTHERS THEN
        -- vyvolá vlastní chybu
        RAISE_APPLICATION_ERROR(-20001, 'Chyba v triggeru');
END;
/
