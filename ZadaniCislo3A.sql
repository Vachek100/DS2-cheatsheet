SET SERVEROUTPUT ON;
-- Zapne výpis výstupu (např. DBMS_OUTPUT.PUT_LINE), užitečné pro ladění

CREATE OR REPLACE PROCEDURE P_BuildArticleRatingStats(
    p_year_from INT,        -- vstupní parametr: od jakého roku počítat statistiky
    p_mode VARCHAR2         -- režim: 'CREATE' nebo 'REPLACE'
)
AS
    v_exists NUMBER;        -- proměnná: bude obsahovat počet existujících tabulek
    v_sql VARCHAR2(2000);   -- proměnná pro dynamický SQL příkaz
BEGIN

    -- =====================
    -- VALIDACE VSTUPŮ
    -- =====================

    IF p_year_from IS NULL THEN
        -- kontrola, že rok není NULL
        RAISE_APPLICATION_ERROR(-20001, 'year_from je NULL');
        -- vyhodí chybu s vlastním kódem
    END IF;

    IF p_mode IS NULL OR (p_mode != 'CREATE' AND p_mode != 'REPLACE') THEN
        -- kontrola, že mód je správný
        RAISE_APPLICATION_ERROR(-20002, 'spatny mode');
    END IF;

    -- =====================
    -- ZJIŠTĚNÍ, ZDA TABULKA EXISTUJE
    -- =====================

    SELECT COUNT(*) INTO v_exists
    FROM user_tables
    WHERE table_name = 'ARTICLE_RATING_STATS';
    -- user_tables = systémový pohled obsahující tabulky aktuálního uživatele
    -- COUNT(*) = kolik takových tabulek existuje (0 nebo 1)
    -- INTO v_exists = uloží výsledek do proměnné

    -- =====================
    -- LOGIKA PODLE EXISTENCE
    -- =====================

    IF v_exists > 0 THEN
        -- pokud tabulka existuje

        IF p_mode = 'CREATE' THEN
            -- režim CREATE = nechceme přepisovat
            RAISE_APPLICATION_ERROR(-20003, 'tabulka existuje');
        ELSE
            -- režim REPLACE = smažeme starou tabulku
            EXECUTE IMMEDIATE 'DROP TABLE ARTICLE_RATING_STATS';
            -- EXECUTE IMMEDIATE = spustí dynamický SQL příkaz
        END IF;

    END IF;

    -- =====================
    -- VYTVOŘENÍ TABULKY
    -- =====================

    v_sql := '
    CREATE TABLE ARTICLE_RATING_STATS AS
    SELECT a.year, yfj.ranking, COUNT(*) AS article_count
    FROM z_article a
    JOIN z_year_field_journal yfj
        ON a.jid = yfj.jid AND a.year = yfj.year
    WHERE a.year >= :1
    GROUP BY a.year, yfj.ranking
    ';
    -- CREATE TABLE ... AS SELECT = vytvoří tabulku rovnou s daty
    -- a.year = rok článku
    -- yfj.ranking = ranking časopisu
    -- COUNT(*) = počet článků
    -- JOIN = spojení dvou tabulek podle jid a roku
    -- WHERE = filtr (jen od určitého roku)
    -- :1 = bind proměnná (bezpečné předání parametru)
    -- GROUP BY = seskupení (počítáme počet pro každou kombinaci)

    EXECUTE IMMEDIATE v_sql USING p_year_from;
    -- spustí SQL a dosadí p_year_from místo :1

END;
/
BEGIN
    P_BuildArticleRatingStats(2018, 'REPLACE');
END;
/

SELECT *
FROM ARTICLE_RATING_STATS
ORDER BY year DESC, ranking
FETCH FIRST 10 ROWS ONLY;
