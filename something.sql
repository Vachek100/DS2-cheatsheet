-- Napiste ulozenou funkci CreateArticleYear s parametrem p_year int, -- ktera vytvori tabulku z_article_year se stejnou strukturou, jako ma -- tabulka z_article, az na novy atribut last_update datoveho typu date -- (hodnota nemuze byt null). Primarni a cizi klice musi byt stejne jako -- v puvodni tabulce. -- -- Do nove tabulky zkopirujete, jednim prikazem SQL, zaznamy clanku z -- roku p_year z tabulky z_article (v dynamickem SQL pouzijete vazane -- promenne pokud je to mozne). Hodnota atributu last_update bude nastavena -- na aktualni datum. -- -- Jednim prikazem SQL zjistite pocet zaznamu nove tabulky, tento pocet -- pak bude funkce vracet. -- -- Pred ukoncenim funkce zrusite tabulku. -- -- V miste volani funkce vypisete navratovou hodnotu funkce. Budete testovat -- pro dva roky tak, aby v jednom roce byl pocet zaznamu 0 a ve druhem roce -- byl pocet zaznamu nenulovy.

SET SERVEROUTPUT ON;

CREATE OR REPLACE FUNCTION CreateArticleYear(
    p_year INT
)RETURN INT
IS
    v_count NUMBER;
    v_sql VARCHAR2(1024);
BEGIN
    dbms_output.put_line('Start');
    
    -- smazani tabulky pokud existuje
    BEGIN 
        EXECUTE IMMEDIATE 'DROP TABLE z_article_year CASCADE CONSTRAINTS';
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    --vytvoreni tabulky se stejnou strukturou
    EXECUTE IMMEDIATE '
        CREATE TABLE z_article_year AS
        SELECT aid,jid,year,ut_wos,name,type,author_count,institution_count
        FROM z_article
        WHERE 1 = 0
    ';
    
    /*
    
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
    
    -- primarnni klic
    EXECUTE IMMEDIATE '
        ALTER TABLE z_article_year
        ADD CONSTRAINT pk_z_article_year PRIMARY KEY (aid)
    ';
    
    -- cizi klic na Journal 
    EXECUTE IMMEDIATE '
        ALTER TABLE z_article_year
        ADD CONSTRAINT fk_z_article_year_journal FOREIGN KEY (jid)
        REFERENCES z_journal(jid)
    ';
    
    -- zkopirovani zaznamu z clanku do nove tabluky
    /*
    EXECUTE IMMEDIATE '
        INSERT INTO z_article_year
        SELECT aid,jid,year,ut_wos,name,type,author_count,institution_count, SYSDATE
        FROM z_article a
        WHERE a.year = :1
    ' USING p_year;
    */
    
    v_sql := 'INSERT INTO z_article_year '||
             'SELECT aid,jid,year,ut_wos,name,type,author_count,institution_count,SYSDATE '||
             'FROM z_article a '||
             'WHERE a.year = ' || p_year;
    
    EXECUTE IMMEDIATE v_sql;
    
    -- zjisteni poctu
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM z_article_year' INTO v_count;

    -- smazani tabulky
    EXECUTE IMMEDIATE '
        DROP TABLE z_article_year CASCADE CONSTRAINTS
    ';
    
    RETURN v_count;
END;
/
