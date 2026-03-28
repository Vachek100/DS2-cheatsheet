SET SERVEROUTPUT ON;

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE work_z_institution';
EXCEPTION 
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE work_z_article_institution';
EXCEPTION 
    WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE work_z_institution AS 
SELECT *
FROM z_institution


CREATE TABLE work_z_article_institution AS 
SELECT *
FROM z_article_institution

CREATE OR REPLACE PROCEDURE P_DeleteInstitutionByName(
    p_inst_name VARCHAR2
)
AS
    v_iid NUMBER;
    v_deleted_links NUMBER;
    v_remaining NUMBER;
    v_links_remaining NUMBER;
BEGIN

    IF p_inst_name IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('Jmeno nesmi byt NULL');
        RETURN;
    END IF;
    
    SELECT iid INTO v_iid
    FROM work_z_institution
    WHERE name = p_inst_name;

    -- mazani vazeb
    DELETE FROM work_z_article_institution
    WHERE iid = v_iid;
    
    v_deleted_links := SQL%ROWCOUNT;

    -- mazani instituce
    DELETE FROM work_z_institution
    WHERE iid = v_iid;
    
    COMMIT;

    -- kontrolni SELECTy
    SELECT COUNT(*) INTO v_remaining FROM work_z_institution;
    SELECT COUNT(*) INTO v_links_remaining FROM work_z_article_institution;

    DBMS_OUTPUT.PUT_LINE('Instituce ' || p_inst_name || ' byla uspesne smazana.');
    DBMS_OUTPUT.PUT_LINE('Odstraneno zaznamu z vazebni tabulky: ' || v_deleted_links);
    DBMS_OUTPUT.PUT_LINE('institution_remaining: ' || v_remaining);
    DBMS_OUTPUT.PUT_LINE('institution_links_remaining: ' || v_links_remaining);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Instituce ' || p_inst_name || ' neexistuje.');
        ROLLBACK;

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Chyba pri mazani');
        ROLLBACK;
END;
/
