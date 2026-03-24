SET SERVEROUTPUT ON;
-- Zapne výpis výstupu v Oracle (např. DBMS_OUTPUT.PUT_LINE)

CREATE OR REPLACE FUNCTION F_ExportJournalXML(
    p_jid NUMBER,   -- vstupní parametr: ID journalu (číslo)
    p_year NUMBER   -- vstupní parametr: rok
) RETURN CLOB      -- funkce vrací CLOB (velký text, např. XML)
IS
    v_xml CLOB;                -- proměnná pro výsledný XML text
    v_name VARCHAR2(100);      -- proměnná pro název journalu
    v_issn VARCHAR2(100);      -- proměnná pro ISSN journalu

BEGIN

-- 1. načti journal
    SELECT name, issn
    INTO v_name, v_issn
    FROM z_journal
    WHERE jid = p_jid;
    -- SELECT = načti data z tabulky
    -- INTO = ulož výsledek do proměnných
    -- WHERE = filtr (ber jen konkrétní journal podle ID)

-- 2. začni XML
    v_xml := '<journal jid="' || p_jid || '">';
    -- := znamená přiřazení
    -- || znamená spojení textu (konkatenace)
    
    v_xml := v_xml || '<name>' || v_name || '</name>';
    -- přidání XML elementu <name>
    
    v_xml := v_xml || '<issn>' || v_issn || '</issn>';
    -- přidání XML elementu <issn>
    
-- 3. fields loop
    v_xml := v_xml || '<fields>';
    -- začátek seznamu fieldů
    
    FOR rec IN (
        SELECT f.fid, f.name
        FROM z_year_field_journal yf
        JOIN z_field_ford f ON f.fid = yf.fid
        -- JOIN = spojení tabulek podle podmínky
        WHERE yf.jid = p_jid
          AND yf.year = p_year
    ) LOOP
        -- FOR loop = projde všechny řádky z SELECTu
        -- rec = aktuální řádek (record)
        
        v_xml := v_xml || '<field fid="' || rec.fid || '">';
        -- atribut fid
        
        v_xml := v_xml || '<name>' || rec.name || '</name>';
        -- název field
        
        v_xml := v_xml || '</field>';
        -- uzavření elementu
    END LOOP;
    
    v_xml := v_xml || '</fields>';
    -- konec seznamu fieldů
    
-- 4. articles loop
    v_xml := v_xml || '<articles>';
    -- začátek seznamu článků
    
    FOR rec IN (
        SELECT aid, name
        FROM z_article
        WHERE jid = p_jid
          AND year = p_year
    ) LOOP
        -- opět cyklus přes články
        
        v_xml := v_xml || '<article aid="' || rec.aid || '">';
        -- atribut aid
        
        v_xml := v_xml || '<name>' || rec.name || '</name>';
        -- název článku
        
        v_xml := v_xml || '</article>';
        -- uzavření elementu
    END LOOP;
    
    v_xml := v_xml || '</articles>';
    -- konec článků
    
-- 5. zavření XML

    v_xml := v_xml || '</journal>';
    -- uzavření hlavního elementu

    RETURN v_xml;
    -- vrácení výsledného XML

END;
/
