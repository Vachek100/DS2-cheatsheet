-- zapne vypis z DBMS_OUTPUT (aby se zobrazovaly zpravy z procedury)
SET SERVEROUTPUT ON;

-- anonymni blok (BEGIN...END), pouziva se pro spusteni PL/SQL kodu
BEGIN
    -- dynamicky SQL prikaz (retezec), ktery se vykona az za behu
    EXECUTE IMMEDIATE 'DROP TABLE work_z_author';

-- zachyceni vsech chyb (napr. kdyz tabulka neexistuje)
EXCEPTION 
    WHEN OTHERS THEN NULL; -- nic nedelat (ignoruj chybu)
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE work_z_article_author';
EXCEPTION 
    WHEN OTHERS THEN NULL;
END;
/

-- vytvori kopii tabulky z_author do work_z_author
CREATE TABLE work_z_author AS
SELECT *
FROM z_author;

-- vytvori kopii tabulky z_article_author
CREATE TABLE work_z_article_author AS
SELECT *
FROM z_article_author;

-- vytvoreni procedury (ulozeny program v DB)
CREATE OR REPLACE PROCEDURE P_DeleteAuthorByName(
    p_author_name VARCHAR2  -- vstupni parametr (jmeno autora)
)
AS
    v_rid NUMBER;  -- promenna pro ulozeni ID autora (rid)
BEGIN

    -- kontrola, jestli parametr neni NULL
    IF p_author_name IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('Jmeno nesmi byt NULL');
        RETURN; -- ukonci proceduru
    END IF;
    
    -- najdi autora podle jmena
    -- SELECT INTO = ulozi vysledek dotazu do promenne
    SELECT rid INTO v_rid
    FROM work_z_author
    WHERE name = p_author_name;
    
    -- smaz zaznamy v propojovaci tabulce (clanky autora)
    DELETE FROM work_z_article_author
    WHERE rid = v_rid;
    
    -- smaz autora samotneho
    DELETE FROM work_z_author
    WHERE rid = v_rid;
    
    -- ulozeni zmen do databaze
    COMMIT;
    
    -- vypis informacni zpravy
    DBMS_OUTPUT.PUT_LINE('Autor ' || p_author_name || ' byl smazan');
    
    EXCEPTION
        -- chyba: SELECT nic nenasel
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Autor '|| p_author_name ||' nenalezen');
            ROLLBACK; -- vrati zmeny zpet

        -- jakakoliv jina chyba
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Chyba pri mazani');
            ROLLBACK;
END;
/
