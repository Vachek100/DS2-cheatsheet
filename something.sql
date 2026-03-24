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
