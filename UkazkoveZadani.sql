-- Napiste ulozenou funkci CreateArticleYear s parametrem p_year int, -- ktera vytvori tabulku z_article_year se stejnou strukturou, jako ma -- tabulka z_article, az na novy atribut last_update datoveho typu date -- (hodnota nemuze byt null). Primarni a cizi klice musi byt stejne jako -- v puvodni tabulce. -- -- Do nove tabulky zkopirujete, jednim prikazem SQL, zaznamy clanku z -- roku p_year z tabulky z_article (v dynamickem SQL pouzijete vazane -- promenne pokud je to mozne). Hodnota atributu last_update bude nastavena -- na aktualni datum. -- -- Jednim prikazem SQL zjistite pocet zaznamu nove tabulky, tento pocet -- pak bude funkce vracet. -- -- Pred ukoncenim funkce zrusite tabulku. -- -- V miste volani funkce vypisete navratovou hodnotu funkce. Budete testovat -- pro dva roky tak, aby v jednom roce byl pocet zaznamu 0 a ve druhem roce -- byl pocet zaznamu nenulovy.

SET SERVEROUTPUT ON;
-- zapne výpis pomocí DBMS_OUTPUT.PUT_LINE (jinak by se text nezobrazil)

CREATE OR REPLACE FUNCTION CreateArticleYear(
    p_year INT
)RETURN INT
-- CREATE OR REPLACE = vytvoří funkci nebo přepíše existující
-- FUNCTION = definice funkce
-- p_year = vstupní parametr (rok)
-- RETURN INT = funkce vrací číslo

IS
    v_count NUMBER;
    -- proměnná pro uložení počtu řádků (výsledek COUNT)

    v_sql VARCHAR2(1024);
    -- proměnná pro dynamický SQL dotaz (textový řetězec)

BEGIN
    dbms_output.put_line('Start');
    -- vypíše text do konzole (pro ladění)

    -- smazani tabulky pokud existuje
    BEGIN 
        EXECUTE IMMEDIATE 'DROP TABLE z_article_year CASCADE CONSTRAINTS';
        -- EXECUTE IMMEDIATE = spustí SQL uložené jako text (dynamické SQL)
        -- DROP TABLE = smaže tabulku
        -- CASCADE CONSTRAINTS = smaže i všechny vazby (PK, FK)

    EXCEPTION
        WHEN OTHERS THEN
            NULL;
        -- pokud tabulka neexistuje → vznikne chyba → ignorujeme ji (NULL = nic nedělej)
    END;

    --vytvoreni tabulky se stejnou strukturou
    EXECUTE IMMEDIATE '
        CREATE TABLE z_article_year AS
        SELECT aid,jid,year,ut_wos,name,type,author_count,institution_count
        FROM z_article
        WHERE 1 = 0
    ';
    -- CREATE TABLE AS SELECT = vytvoří tabulku podle SELECTu
    -- WHERE 1 = 0 = podmínka je vždy nepravdivá → nevloží se žádná data
    -- => vytvoří se jen struktura tabulky (sloupce)

    
    /*
    -- alternativní ruční vytvoření tabulky (nepoužívá se)
    v_sql := 'create table z_article_year' || '(' 
    || 'aid int primary key,' 
    || 'jid int null references z_journal, ' 
    || 'UT_WoS varchar(25) null, ' 
    || 'name varchar(2000) not null, ' 
    || 'type varchar(100) null, ' 
    || 'year int not null, ' 
    || 'author_count int null, ' 
    || 'last_update date not null ' || ')';
    */

    
    --pridani noveho sloupce
    EXECUTE IMMEDIATE '
        ALTER TABLE z_article_year
        ADD (last_update DATE NOT NULL)
    ';
    -- ALTER TABLE = změna tabulky
    -- ADD = přidání sloupce
    -- last_update = nový sloupec
    -- DATE = datový typ (datum)
    -- NOT NULL = nesmí být prázdný

    
    -- primarnni klic
    EXECUTE IMMEDIATE '
        ALTER TABLE z_article_year
        ADD CONSTRAINT pk_z_article_year PRIMARY KEY (aid)
    ';
    -- CONSTRAINT = omezení (pravidlo)
    -- PRIMARY KEY = unikátní identifikátor řádku
    -- aid = sloupec, který musí být unikátní a NOT NULL

    
    -- cizi klic na Journal 
    EXECUTE IMMEDIATE '
        ALTER TABLE z_article_year
        ADD CONSTRAINT fk_z_article_year_journal FOREIGN KEY (jid)
        REFERENCES z_journal(jid)
    ';
    -- FOREIGN KEY = cizí klíč (vazba na jinou tabulku)
    -- jid = sloupec v této tabulce
    -- REFERENCES z_journal(jid) = odkaz na tabulku z_journal
    -- zajišťuje referenční integritu (hodnota musí existovat v z_journal)

    
    -- zkopirovani zaznamu z clanku do nove tabluky
    
    EXECUTE IMMEDIATE '
        INSERT INTO z_article_year
        SELECT aid,jid,year,ut_wos,name,type,author_count,institution_count, SYSDATE
        FROM z_article a
        WHERE a.year = :1
    ' USING p_year;
    -- INSERT INTO = vložení dat do tabulky
    -- SELECT = výběr dat z jiné tabulky
    -- SYSDATE = aktuální datum → uloží se do last_update
    -- WHERE a.year = :1 = parametr (bezpečné dosazení hodnoty)
    -- USING p_year = dosadí hodnotu parametru do :1

    
    /*
    -- alternativní (méně bezpečná) verze přes string
    v_sql := 'INSERT INTO z_article_year '||
             'SELECT aid,jid,year,ut_wos,name,type,author_count,institution_count,SYSDATE '||
             'FROM z_article a '||
             'WHERE a.year = ' || p_year;
    
    EXECUTE IMMEDIATE v_sql;
    */

    
    -- zjisteni poctu
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM z_article_year' INTO v_count;
    -- COUNT(*) = počet řádků v tabulce
    -- INTO v_count = uloží výsledek do proměnné

    
    -- smazani tabulky
    EXECUTE IMMEDIATE '
        DROP TABLE z_article_year CASCADE CONSTRAINTS
    ';
    -- tabulka se po použití smaže (funguje jako dočasná)

    
    RETURN v_count;
    -- vrátí počet záznamů jako výsledek funkce

END;
