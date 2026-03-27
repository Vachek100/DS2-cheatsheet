-- Zapnutí výpisu zpráv z DBMS_OUTPUT (aby fungoval PRINT z triggeru)
SET SERVEROUTPUT ON;

-- Blok pro smazání tabulky, pokud existuje
BEGIN
    -- Dynamické SQL = umožňuje spouštět SQL příkazy jako text
    EXECUTE IMMEDIATE 'DROP TABLE work_z_article';
EXCEPTION
    -- Když nastane jakákoliv chyba (např. tabulka neexistuje)
    WHEN OTHERS THEN NULL; -- ignoruj chybu (nic nedělej)
END;
/

-- Totéž pro druhou tabulku
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE work_z_article_deleted';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Totéž pro třetí tabulku
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE work_z_article_author';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Vytvoření pracovní kopie tabulky z_article
CREATE TABLE work_z_article AS
SELECT *
FROM z_article; -- vezme všechna data i strukturu

-- Vytvoření prázdné tabulky se stejnou strukturou
CREATE TABLE work_z_article_deleted AS
SELECT *
FROM z_article
WHERE 1 = 0; 
-- WHERE 1=0 = vždy nepravda → vytvoří jen strukturu bez dat

-- Kopie tabulky autorů
CREATE TABLE work_z_article_author AS
SELECT *
FROM z_article_author;

-- Vytvoření triggeru (automatická akce při události)
CREATE OR REPLACE TRIGGER TR_DeleteAudit 
-- CREATE OR REPLACE = vytvoří nový nebo přepíše existující trigger

AFTER DELETE ON work_z_article
-- AFTER DELETE = spustí se po smazání řádku
-- ON work_z_article = sleduje tuto tabulku

FOR EACH ROW
-- trigger se spustí pro KAŽDÝ smazaný řádek zvlášť

DECLARE 
    v_count NUMBER;
    -- proměnná pro počet autorů (NUMBER = číselný typ)

BEGIN
    -- spočítání autorů daného článku
    SELECT COUNT(*) INTO v_count
    FROM work_z_article_author
    WHERE aid = :OLD.aid;
    -- COUNT(*) = spočítá počet řádků
    -- INTO = uloží výsledek do proměnné
    -- :OLD = stará hodnota řádku (ten který se maže)
    -- aid = ID článku

    -- podmínka: jen pokud má článek 3 nebo méně autorů
    IF v_count <= 3 THEN

        -- vložení smazaného článku do auditní tabulky
        INSERT INTO work_z_article_deleted
        (aid, jid, ut_wos, name, type, year, author_count, institution_count)
        VALUES
        (:OLD.aid, :OLD.jid, :OLD.ut_wos, :OLD.name, :OLD.type, :OLD.year, :OLD.author_count, :OLD.institution_count);

        -- :OLD.xxx = hodnoty z mazáného řádku
    END IF;

    -- výpis do konzole (pro debugging)
    DBMS_OUTPUT.PUT_LINE('deleted_audit_count: ' || v_count);
    -- || = spojení textu

EXCEPTION
    -- zachycení všech chyb v triggeru
    WHEN OTHERS THEN
        -- vyvolá vlastní chybu
        RAISE_APPLICATION_ERROR(-20001, 'Chyba v triggeru');
END;
/
