-- Zapne výstup z DBMS_OUTPUT, aby bylo možné zobrazovat zprávy (např. PUT_LINE)
SET SERVEROUTPUT ON;

-- Vytvoření nebo přepsání funkce (pokud už existuje, nahradí se)
CREATE OR REPLACE FUNCTION F_FindNullableColumns(
    p_table_name VARCHAR2  -- vstupní parametr: název tabulky (textový řetězec)
)
RETURN VARCHAR2            -- funkce vrací text (seznam sloupců)
IS
    -- Deklarace proměnných:

    v_result VARCHAR2(4000) := '';  
    -- proměnná pro výsledek (max 4000 znaků), inicializovaná na prázdný řetězec

    v_sql VARCHAR2(1000);  
    -- proměnná pro dynamický SQL dotaz (budeme ho skládat jako text)

    v_count NUMBER;        
    -- proměnná pro počet NULL hodnot ve sloupci

    v_exists NUMBER;       
    -- proměnná pro kontrolu existence tabulky (0 = neexistuje, >0 existuje)

BEGIN

    -- =========================
    -- KONTROLA EXISTENCE TABULKY
    -- =========================

    -- Spočítá, kolik tabulek s tímto názvem existuje v USER_TABLES
    -- USER_TABLES = systémový pohled obsahující tabulky aktuálního uživatele
    SELECT COUNT(*) INTO v_exists
    FROM user_tables
    WHERE table_name = UPPER(p_table_name);
    -- UPPER = převede název na velká písmena (Oracle ukládá názvy tabulek velkými písmeny)

    -- Pokud tabulka neexistuje
    IF v_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Tabulka neexistuje');
        -- vypíše zprávu do konzole

        RETURN NULL;
        -- funkce skončí a vrátí NULL
    END IF;

    -- =========================
    -- PROCHÁZENÍ SLOUPCŮ TABULKY
    -- =========================

    -- FOR cyklus přes všechny sloupce dané tabulky
    FOR rec IN (
        SELECT column_name
        FROM user_tab_columns
        WHERE table_name = UPPER(p_table_name)
        -- USER_TAB_COLUMNS = seznam sloupců tabulek
    )
    LOOP

        -- Sestavení dynamického SQL dotazu:
        v_sql := 'SELECT COUNT(*) FROM ' || p_table_name ||
                 ' WHERE ' || rec.column_name || ' IS NULL';
        -- || = spojení řetězců
        -- rec.column_name = aktuální sloupec z cyklu
        -- výsledkem je např:
        -- SELECT COUNT(*) FROM moje_tabulka WHERE sloupec IS NULL

        -- Spuštění dynamického SQL dotazu
        EXECUTE IMMEDIATE v_sql INTO v_count;
        -- EXECUTE IMMEDIATE = spustí SQL, které je uložené jako text
        -- výsledek (COUNT) se uloží do v_count

        -- Pokud existují NULL hodnoty v tomto sloupci
        IF v_count > 0 THEN
            -- přidá název sloupce a počet NULL do výsledku
            v_result := v_result || rec.column_name || ' (' || v_count || '), ';
            -- např: "NAME (3), AGE (1), "
        END IF;

    END LOOP;

    -- =========================
    -- NÁVRAT VÝSLEDKU
    -- =========================

    RETURN v_result;
    -- vrátí text se seznamem sloupců obsahujících NULL hodnoty

END;
/
