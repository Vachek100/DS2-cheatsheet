-- Zapne výpis z DBMS_OUTPUT (aby bylo možné vypisovat zprávy pomocí DBMS_OUTPUT.PUT_LINE)
SET SERVEROUTPUT ON;

-- Vytvoření nebo přepsání procedury s názvem P_CreateWork
CREATE OR REPLACE PROCEDURE P_CreateWork
IS
-- IS = začátek deklarativní části procedury (proměnné by byly tady)
BEGIN
    -- Vnořený blok (má vlastní výjimky)
    BEGIN 
        -- Dynamické spuštění SQL příkazu (DDL musí být přes EXECUTE IMMEDIATE)
        EXECUTE IMMEDIATE 'DROP TABLE z_work';
        
    EXCEPTION
        -- Zachytí jakoukoli chybu
        WHEN OTHERS THEN 
            -- Pokud tabulka neexistuje, chyba se ignoruje (nic se nestane)
            NULL;
    END;
    
    -- Vytvoření nové tabulky z_work jako kopie dat
    EXECUTE IMMEDIATE '
        CREATE TABLE z_work AS
        SELECT aid, rid
        FROM z_article_autgor
    ';
    -- CREATE TABLE AS SELECT = vytvoří tabulku a rovnou do ní vloží data

END;
/
-- "/" = spustí předchozí PL/SQL blok

-- Vytvoření nebo přepsání triggeru
CREATE OR REPLACE TRIGGER trg_article_author_count

-- Trigger se spustí PO (AFTER) operaci INSERT nebo DELETE
AFTER INSERT OR DELETE ON z_work

-- FOR EACH ROW = trigger se spustí pro každý řádek zvlášť
FOR EACH ROW
BEGIN
    -- Pokud došlo k INSERTu
    IF INSERTING THEN
    
        -- Aktualizace tabulky z_article
        UPDATE z_article
        SET author_count = author_count + 1
        -- Zvýší počet autorů o 1
        
        WHERE aid = :NEW.aid;
        -- :NEW = nové hodnoty vloženého řádku

    -- Pokud došlo ke smazání
    ELSIF DELETING THEN
    
        UPDATE z_article
        SET author_count = author_count - 1
        -- Sníží počet autorů
        
        WHERE aid = :OLD.aid;
        -- :OLD = původní hodnoty smazaného řádku
        
    END IF;
END;
/
-- "/" = spuštění vytvoření triggeru

-- Spuštění procedury
BEGIN
    P_CreateWork;
    -- Zavolání procedury, která vytvoří tabulku z_work
END;
/

-- Vložení dat do tabulky
INSERT INTO z_work VALUES (1, 100);
-- Tento INSERT spustí trigger:
-- → zvýší author_count u článku s aid = 1
