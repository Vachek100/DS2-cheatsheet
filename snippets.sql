SET SERVEROUTPUT ON; --nezapomínat (pro jistotu)


CREATE OR REPLACE FUNCTION funkce(par1 COURSE.CODE%TYPE, par2 STUDENT.LOGIN%TYPE) RETURN NUMBER AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('Funkce zavolána');
    RETURN 1234; 
END;

CREATE OR REPLACE PROCEDURE procedura(par1 COURSE.CODE%TYPE, par2 STUDENT.LOGIN%TYPE) AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('Procedura zavolána');
END;

CREATE OR REPLACE PROCEDURE bezparametrova AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('žádné parametry');
END;


EXEC bezparametrova; --takto se volají mimo procedury
EXECUTE procedura('asd', 'dsa'); -- EXEC a EXECUTE jsou to samé v tomhle případě (ale ne v dynamickém SQL)

DECLARE --buď si vytvoříte function/procedure, a nebo tuhle anonymní proceduru, která se ale hned spustí
    v_var1    COURSE.CODE%TYPE;
    v_bool BOOLEAN;
    v_counter INT := 0; --defaultní hodnota, vhodná hlavně na countery 
    v_sql VARCHAR(2000); --pro vlastní varchary musíte mít danou i délku!!! (např v sql dotazech) 
    v_grade COURSE.GRADE%TYPE;

    e_vlastniError EXCEPTION;
BEGIN
    null; -- placeholder pro kód, aby se to dalo spustit.
          -- taky placeholder pro empty value, např. ve výrazu IS NOT NULL

    -- operátory: <, >, =, <>, NOT, IN
    -- na stringy: LIKE, ||
    -- set value:  :=    

    --errory
    BEGIN --hodí se vkládat do nested procedur jako forma error-handlingu. po zpracování pak vnější kód pokračuje dál.
        RAISE e_vlastniError;
        raise_application_error(-20001, 'vlastní error hodnota, musí být menší než -20000');
 
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('Výsledek query prázdný');
        rollback;

        WHEN e_vlastniError THEN
            dbms_output.put_line('vlastní error zpracován:' || sqlerrm);
            rollback;

        WHEN OTHERS THEN
            dbms_output.put_line('Error message proměnná: '|| sqlerrm);
            rollback;
    END;


    --systémové proměnné a funkce:
    dbms_output.put_line(ROWNUM ||'Index daného řádku ve výsledku dotazu, začíná od 1'); --využití v nested dotazech, např.: WHERE ROWNUM = 1 (pro jen první řádek)
    dbms_output.put_line(SQL%ROWCOUNT || 'Počet řádků affektovaných dotazem');
    dbms_output.put_line(SQL%NOTFOUND || SQL%FOUND || 'booleany na to, jestli byly nějaké řádky affektovány');
    dbms_output.put_line(CURRENTTIMESTAMP || 'Nynější čas (teď nevím jestli DB time nebo client time- asi client?)');
    dbms_output.put_line(SYSDATE || 'vrátí datum z serveru na kterém je databáze');
    dbms_output.put_line(EXTRACT(YEAR FROM CURRENTTIMESTAMP) || 'Extrahuje hodnoty z timestamp. Pozor, datumy v SQL jsou udělané kokotsky a nemusí vždy fungovat');
    dbms_output.put_line(ROUND(9.8765, 2)); ---> 9.87 
    dbms_output.put_line((SELECT COALESCE(AVG(GRADE), 0) FROM COURSE)); --COALESCE vrátí první nenulovou hodnotu kterou přečte (buď AVG() nebo 0 jako fallback) 
    dbms_output.put_line(SUBSTR('abcdefgh', 2, 3)); ---> 'bcd', SUBSTR(string, start_index, substring_length), 1. parametr může indexovat od konce negativními čísly
    dbms_output.put_line(LPAD('ahoj', 10, '*')); ---> '******ahoj', zleva padduje string aby se dostal do délky 2. parametru vypisováním stringu 3. parametru.
    dbms_output.put_line(REPLACE('Tutorial', 'T', 'C')); --vrací změněný string. (Tutorial -> CuCorial)
                                                                  --POZOR! není case sensitive, a přemění všechny instance 2. parametru na 3. parametr

    --zajímavé formy sql dotazů:
    SELECT * FROM STUDENT s FETCH FIRST 3 ROWS ONLY; --dává se na konec, až za order by. vrátí první 3 řádky
    
    --tabulky:
    SELECT * FROM USER_TABLES WHERE table_name = UPPER('Student'); --USER_TABLES obsahuje všechny tabulky. UPPER přeměňuje na caps (potřeba pro funkční dotaz)
    SELECT * FROM USER_TAB_COLUMNS; --obsahuje všechny sloupce vlastněné nynějším uživatelem
    SELECT * FROM USER_TAB_COLS; --obsahuje všechny sloupce vlastněné nynějším uživatelem, obsahuje i skryté systémové sloupce/tabulky
    SELECT SYSDATE FROM DUAL; --takový 'example' table, obsahuje jen 1 sloupec s řádkem o hodnotě 'X'
                              -- využívá se pokud chceš systémové proměnné jako SYSDATE, nebo prostě jen vlastní výrazy jako SELECT 1+1 FROM DUAL

    --dynamické SQL:
    EXECUTE IMMEDIATE 
            ('  SELECT GRADE_' || replace(p_course_code, '-', '') || '
                FROM gradematrix
                where student_login = :1')
     INTO v_grade USING 'asd123'; --ukázka ze cvičení, vybere hodnotu z dynamicky vybraného sloupce. 
                                  -- :1 je parametr placeholder. (POZOR. parametry používat pouze jako params, ne table/row names)

    --spouštění procedur/funkcí:
    bezparametrova;
    procedura('exampleCourse', 'asd123');
    funkce('exampleCourse', 'asd123');
    --mimo proceduru se volají pomocí EXEC


    --loops/conditionals
    IF TRUE = FALSE THEN
        dbms_output.put_line('True');
    ELSIF 1 > 2 THEN
        dbms_output.put_line('Maybe');
    ELSE 
        dbms_output.put_line('False');
    END IF;

    ----
    FOR item IN (SELECT s.login FROM STUDENT s)
    LOOP
        dbms_output.put_line('Loop item číslo '|| v_counter || ' je ' || item);
        v_counter := v_counter + 1;
    END LOOP;

    --v_counter := 0;
    --WHILE v_counter < 5  --while loop okopírovaný z internetu, ale interpretter mi hází errory. stejně to asi nevyužijete, stačí FOR loop
    --BEGIN  
    --    v_counter := v_counter + 1;
    --END;


    --delete, insert, update, drop, atd. dokážete udělat přetáhnutím tabulky z leva do kódu.
    --pokud to ale nevýjde, zde jsou ukázky:
    INSERT INTO COURSE (CODE, NAME, CAPACITY, TEACHER_LOGIN) 
    VALUES ( :v0, :v1, :v2, :v3);
    ----
    DELETE FROM COURSE
    WHERE
        CODE = :v0 AND
        NAME = :v1 AND
        CAPACITY = :v2 AND
        TEACHER_LOGIN = :v3;
    ----
    UPDATE COURSE 
    SET 
        CODE = "example_1234", 
        NAME = "příkladové jméno"
    WHERE
        CODE = :v0 AND
        NAME = :v1 AND
        CAPACITY = :v2 AND
        TEACHER_LOGIN = :v3;
    ----
    --DROP TABLE COURSE; --trošku nebezpečné. zakomentováno pro vaši bezpečnost.
    ----
    
    --commit;
    rollback;
END;
