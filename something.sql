-- Zapne výpis zpráv z PL/SQL (např. pomocí DBMS_OUTPUT)
SET SERVEROUTPUT ON;

-- Vytvoření nebo nahrazení funkce v databázi
CREATE OR REPLACE FUNCTION F_SetArticleAuthor(
    p_aid NUMBER,   -- ID článku (Article ID)
    p_rid NUMBER,   -- ID autora (Researcher ID)
    p_set BOOLEAN   -- TRUE = přidat autora, FALSE = odebrat autora
)
RETURN VARCHAR2     -- Funkce vrací textový řetězec (např. 'I', 'D', 'N')
IS
    v_exists NUMBER; -- Proměnná pro uložení počtu existujících záznamů
BEGIN

    -- Zjistí, jestli už existuje vazba mezi článkem a autorem
    -- COUNT(*) vrátí počet řádků splňujících podmínku
    SELECT COUNT(*)
    INTO v_exists
    FROM article_author
    WHERE aid = p_aid AND rid = p_rid;
    
    -- Pokud chceme autora PŘIDAT
    IF p_set THEN
        
        -- Pokud vazba ještě neexistuje
        IF v_exists = 0 THEN
        
            -- Vloží nový záznam do spojovací tabulky
            INSERT INTO article_author(aid, rid)
            VALUES (p_aid, p_rid);
            
            -- Zvýší počet autorů u daného článku o 1
            UPDATE article
            SET author_count = author_count + 1
            WHERE aid = p_aid;
            
            -- Vrací 'I' jako Insert (vložen)
            RETURN 'I';
            
        ELSE
            -- Pokud už existuje → nic nedělej
            RETURN 'N'; -- N = No change
        END IF;
        
    ELSE  -- Pokud chceme autora ODEBRAT
        
        -- Pokud vazba existuje
        IF v_exists = 1 THEN
        
            -- Smaže záznam ze spojovací tabulky
            DELETE FROM article_author
            WHERE aid = p_aid AND rid = p_rid;
            
            -- Sníží počet autorů o 1
            UPDATE article
            SET author_count = author_count - 1
            WHERE aid = p_aid;
            
            -- Vrací 'D' jako Delete (smazán)
            RETURN 'D';
        ELSE
            -- Pokud neexistuje → nic nedělej
            RETURN 'N'; -- N = No change
        END IF;
    
    END IF;
END;
/

DECLARE
    v_result VARCHAR2(1);
BEGIN
    v_result := F_SetArticleAuthor(1, 10, TRUE);
    DBMS_OUTPUT.PUT_LINE('Výsledek: ' || v_result);
END;
/
