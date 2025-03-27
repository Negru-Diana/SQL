use GestiuneServiciiDeStreaming --Utilizez baza de date
go


---
--- PROCEDURILE SI INVERSELE PROCEDURILOR
---


-- Creez procedura 1 (modifica tipul unei coloane)
CREATE PROCEDURE do_proc_1
AS
BEGIN
	-- Verific daca tabela si coloana exista
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ContinutMedia' AND COLUMN_NAME = 'Titlu')
	BEGIN
		-- Modific tipul coloanei Titlu din tabela ContinutMedia din varchar(250) NOT NULL in TEXT NOT NULL
		ALTER TABLE ContinutMedia
		ALTER COLUMN Titlu TEXT NOT NULL;

		-- Afiseaza un mesaj daca modificarea a avut succes
		PRINT 'S-a modificat tipul coloanei Titlu din tabela ContinutMedia';
	END
	ELSE
	BEGIN
		-- Afisez un mesaj de eroare daca tabela sau coloana nu exista
		PRINT 'Tabela sau coloana specificata nu exista';
	END
END;
GO -- Marchez sfarsitul blocului de comenzi do_proc_1


-- Creez inversa procedurii 1 (modifica tipul coloanei la cel original)
CREATE PROCEDURE undo_proc_1
AS
BEGIN
	-- Verific daca tabela si coloana exista
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ContinutMedia' AND COLUMN_NAME = 'Titlu')
	BEGIN
		-- Modifica tipul coloanei Titlu din tabela ContinutMedia inapoi la varchar(250) NOT NULL
		ALTER TABLE ContinutMedia
		ALTER COLUMN Titlu varchar(250) NOT NULL;

		-- Afiseaza un mesaj daca modificarea a avut succes
		PRINT 'S-a modificat tipul coloanei la cel original -> varchar(250) NOT NULL';
	END
	ELSE
	BEGIN
		-- Afisez un mesaj de eroare daca tabela sau coloana nu exista
		PRINT 'Tabela sau coloana specificata nu exista';
	END
END;
GO -- Marchez sfarsitul blocului de comenzi undo_proc_1




-- Creez procedura 2 (adaug o constrangere implicita)
CREATE PROCEDURE do_proc_2
AS
BEGIN
	-- Verific daca tabela si coloana exista
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ContinutMedia' AND COLUMN_NAME = 'Status_disponibilitate')
	BEGIN
		-- Adaug o constrangere "implicita" pentru campul Status_disponibilitate
		ALTER TABLE ContinutMedia
		ADD CONSTRAINT df_disponibil DEFAULT 'disponibil'
		FOR Status_disponibilitate;

		-- Afiseaza un mesaj daca adaugarea constrangerii a avut succes
		PRINT 'S-a adaugat constrangerea implicita pentru coloana Status_disponibilitate din tabela ContinutMedia';
	END
	ELSE
	BEGIN
		-- Afisez un mesaj de eroare daca tabela sau coloana nu exista
		PRINT 'Tabela sau coloana specificata nu exista';
	END
END;
GO -- Marchez sfarsitul blocului de comenzi do_proc_2


-- Creez inversa procedurii 2 (sterg constrangerea implicita)
CREATE PROCEDURE undo_proc_2
AS
BEGIN
	-- Verific daca tabela si coloana exista
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ContinutMedia' AND COLUMN_NAME = 'Status_disponibilitate')
	BEGIN
		ALTER TABLE ContinutMedia
		DROP CONSTRAINT df_disponibil;

		-- Afiseaza un mesaj daca stergerea constrangerii a avut succes
		PRINT 'S-a sters constrangerea implicita pentru coloana Status_disponibilitate din tabela ContinutMedia';
	END
	ELSE
	BEGIN
		-- Afisez un mesaj de eroare daca tabela sau coloana nu exista
		PRINT 'Tabela sau coloana specificata nu exista';
	END
END;
GO -- Marchez sfarsitul blocului de comenzi undo_proc_2




-- Creez procedura 3 (creez o tabela noua)
CREATE PROCEDURE do_proc_3
AS
BEGIN
	-- Verific daca tabela Preferinte exista deja
	-- Daca exista deja tabela Preferinte, o sterg pentru a o recrea
	IF OBJECT_ID('Preferinte', 'U') IS NOT NULL -->  'U' reprezinta tipul obiectului (User-defined table)
	BEGIN
		DROP TABLE Preferinte; -- Sterg tabela daca exista
		PRINT 'Tabela Preferinte a fost stearsa';
	END

	-- Creez tabela Preferinte
	CREATE TABLE Preferinte(
		ID_preferinta INT PRIMARY KEY IDENTITY,
		ID_utilizator INT FOREIGN KEY REFERENCES Utilizatori(ID_utilizator),
		Preferinta VARCHAR(50) NOT NULL
		);

	-- Afisez un mesaj de confirmare a crearii tabelei
	PRINT 'Tabela Preferinte a fost creata cu succes';
END;
GO -- Marchez sfarsitul blocului de comenzi do_proc_3


-- Creez inversa procedurii 3 (sterg tabela noua)
CREATE PROCEDURE undo_proc_3
AS
BEGIN
	-- Verifica daca tabela Preferinte exista
	IF OBJECT_ID('Preferinte', 'U') IS NOT NULL
	BEGIN
		-- Sterg tabela Preferinte
		DROP TABLE Preferinte;

		-- Afisez un mesaj de confirmare a stergerii tabelei
		PRINT 'Tabela Preferinte a fost stearsa cu succes.';
	END
	ELSE
	BEGIN
		-- Afisez un mesaj de eroare daca tabela nu exista
		PRINT 'Tabela Preferinte nu exista.';
	END
END;
GO -- Marchez sfarsitul blocului de comenzi undo_proc_3




-- Creez procedura 4 (adaug un camp nou)
CREATE PROCEDURE do_proc_4
AS
BEGIN
	-- Verific daca tabela Preferinte exista
	IF OBJECT_ID('Preferinte', 'U') IS NOT NULL
	BEGIN
		-- Adaug coloana ID_serviciu de tip int
		ALTER TABLE Preferinte
		ADD ID_serviciu INT NOT NULL;

		-- Afisez un mesaj de confirmare a adaugarii unui camp nou
		PRINT 'Coloana ID_serviciu a fost adaugata cu succes.';
	END
	ELSE
	BEGIN
		-- Afisez un mesaj de eroare daca tabela nu exista
		PRINT 'Tabela Preferinte nu exista.';
	END
END;
GO -- Marchez sfarsitul blocului de comenzi do_proc_4


-- Creez inversa procedurii 4 (sterg campul nou)
CREATE PROCEDURE undo_proc_4
AS
BEGIN
	-- Verific daca tabela Preferinte si coloana ID_serviciu exista
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Preferinte' AND COLUMN_NAME = 'ID_serviciu')
	BEGIN
		-- Sterg coloana Tip_continut
		ALTER TABLE Preferinte
		DROP COLUMN ID_serviciu;

		-- Afisez mesaj pentru stergerea coloanei Tip_continut
		PRINT 'Coloana ID_serviciu a fost stearsa cu succes.';
	END
	ELSE
	BEGIN
		-- Afisez mesaj de eroare daca tabela/coloana nu exista
		PRINT 'Tabela sau coloana specificata nu exista';
	END
END;
GO -- Marchez sfarsitul blocului de comenzi undo_proc_4




-- Creez procedura 5 (creez o constrangere de tip cheie straina)
CREATE PROCEDURE do_proc_5
AS
BEGIN
    -- Verific daca tabela Preferinte, tabela ServiciiDeStreaming si coloana ID_serviciu exista in cele doua tabele
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Preferinte')
       AND EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Preferinte' AND COLUMN_NAME = 'ID_serviciu')
       AND EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ServiciiDeStreaming')
       AND EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ServiciiDeStreaming' AND COLUMN_NAME = 'ID_serviciu')
    BEGIN
        -- Verific daca tabela Preferinte nu are deja constrangerea de cheie straina catre ServiciiDeStreaming
        IF NOT EXISTS (SELECT * 
					   FROM sys.foreign_keys     -- Contine informatii despre toate cheile straine din baza de date 
					   WHERE parent_object_id = OBJECT_ID('Preferinte')    -- Tabela parinte
					   AND referenced_object_id = OBJECT_ID('ServiciiDeStreaming')    -- Tabela de referinta
					   AND name = 'fk_ID_serviciu')  -- Numele specific al constrangerii
        BEGIN
            -- Adaug constrangerea de tip cheie straina pentru coloana ID_serviciu
            ALTER TABLE Preferinte
            ADD CONSTRAINT fk_ID_serviciu
            FOREIGN KEY (ID_serviciu) REFERENCES ServiciiDeStreaming(ID_serviciu);

			-- Afisez un mesaj de succes daca constrangerea a fost adaugata cu succes
            PRINT 'Constrangerea de tip cheie straina fk_ID_serviciu a fost adaugata cu succes.';
        END
        ELSE
        BEGIN
			-- Afisez un mesaj de eroare daca constrangerea de tip cheie straina fk_ID_serviciu exista deja
            PRINT 'Constrangerea de tip cheie straina fk_ID_serviciu exista deja in tabela Preferinte.';
        END
    END
    ELSE
    BEGIN
		-- Afisez mesaj de eroare daca tabela/coloana nu exista
        PRINT 'Una dintre tabele (Preferinte sau ServiciiDeStreaming) sau coloana ID_serviciu nu exista.';
    END
END;
GO -- Marchez sfarsitul blocului de comenzi do_proc_5


-- Creez inversa procedurii 5 (sterg constrangerea de tip cheie straina)
CREATE PROCEDURE undo_proc_5
AS
BEGIN
    -- Verific daca tabela Preferinte si constrangerea de tip cheie straina fk_ID_serviciu exista
    IF EXISTS (SELECT * 
               FROM sys.foreign_keys 
               WHERE parent_object_id = OBJECT_ID('Preferinte') 
               AND name = 'fk_ID_serviciu')
    BEGIN
        -- Sterg constrangerea de tip cheie straina fk_ID_serviciu
        ALTER TABLE Preferinte
        DROP CONSTRAINT fk_ID_serviciu;

        -- Afisez mesaj de confirmare pentru stergerea constrangerii
        PRINT 'Constrangerea de tip cheie straina fk_ID_serviciu a fost stearsa cu succes.';
    END
    ELSE
    BEGIN
        -- Afisez un mesaj de eroare daca constrangerea nu exista
        PRINT 'Constrangerea de tip cheie straina fk_ID_serviciu nu exista in tabela Preferinte.';
    END
END;
GO -- Marchez sfarsitul blocului de comenzi undo_proc_5




---
--- TABELA CARE MEMOREAZA  
---


CREATE TABLE VersiuniBD
( ID_versiune INT PRIMARY KEY,
Versiune INT, 
Data_modificare DATETIME2(0) DEFAULT CAST(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss') AS DATETIME) NOT NULL);


INSERT INTO VersiuniBD(ID_versiune, Versiune) VALUES (1, 0); -- Adaug versiunea actuala la care este BD (versiunea 0) si definesc id-ul versiunii ca fiind 1

--SELECT * FROM VersiuniBD;




---
--- PROCEDURA PENTRU MODIFICAREA VERSIUNII BAZEI DE DATE
---

-- Creez procedura care se ocupa de modificarea versiunii bazei de date
-- Procedura primeste ca parametru un numar (INT) pe care il stochez in variabila @versiune
CREATE PROCEDURE modifica_versiune (@versiune INT)
AS
BEGIN
	-- Validez valoarea variabilei @versiune
	IF @versiune < 0 OR @versiune > 5
	BEGIN
		PRINT 'Versiunea ceruta nu exista! Versiuni disponibile: 0, 1, 2, 3, 4, 5.';
		RETURN; -- Iesire din procedura
	END

	DECLARE @versiune_curenta INT; -- Variabila pentru versiunea curenta a bazei de date

	-- Determin versiunea curenta a bazei de date din tabela VersiuniBD (are o singura inregistrare - ID_versiune = 1)
	SELECT @versiune_curenta = Versiune
	FROM VersiuniBD
	WHERE ID_versiune = 1;

	IF @versiune_curenta = @versiune
	BEGIN
		PRINT 'Deja baza de date este la versiunea ' + CAST(@versiune AS VARCHAR(10)) + '.';
		RETURN;
	END


	-- Daca @versiune_curenta (versiunea curenta a bazei de date) < @versiune (versiunea dorita) vom creste versiunea bazei de date
	IF @versiune_curenta < @versiune
	BEGIN
		-- Aplic procedurile pana ajung la versiunea dorita
		WHILE @versiune_curenta < @versiune
		BEGIN
			SET @versiune_curenta = @versiune_curenta + 1; -- Cresc versiunea curenta cu 1

			-- Execut procedurile pentru cresterea versiunii bazei de date
			IF @versiune_curenta = 1 EXEC do_proc_1;
			IF @versiune_curenta = 2 EXEC do_proc_2;
			IF @versiune_curenta = 3 EXEC do_proc_3;
			IF @versiune_curenta = 4 EXEC do_proc_4;
			IF @versiune_curenta = 5 EXEC do_proc_5;
		END
	END


	-- Daca @versiune_curenta (versiunea curenta a bazei de date) > @versiune (versiunea dorita) vom scadea versiunea bazei de date
	ELSE IF @versiune_curenta > @versiune
	BEGIN
		-- Aplic procedurile inverse pana ajung la versiunea dorita
		WHILE @versiune_curenta > @versiune  -- MODIFICARE AICI: Adauga WHILE pentru a scadea versiunea
		BEGIN
			IF @versiune_curenta = 5 EXEC undo_proc_5;
			IF @versiune_curenta = 4 EXEC undo_proc_4;
			IF @versiune_curenta = 3 EXEC undo_proc_3;
			IF @versiune_curenta = 2 EXEC undo_proc_2;
			IF @versiune_curenta = 1 EXEC undo_proc_1;

			SET @versiune_curenta = @versiune_curenta - 1; -- Scad versiunea curenta cu 1
		END
	END
		
	-- Dupa ce am ajuns la versiunea dorita, actualizez versiunea in tabela VersiuniBD
	UPDATE VersiuniBD
	SET Versiune = @versiune, Data_modificare = CAST(FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss') AS DATETIME2(0)) -- Actualizez versiunea si data modificarii
	WHERE ID_versiune = 1;

	PRINT 'Versiunea bazei de date a fost modificata la versiunea: ' + CAST(@versiune AS VARCHAR(10)) + '.';
END;
GO -- Marchez sfarsitul blocului de comenzi modifica_versiune



--
-- EXECUTARE MODIFICARE VERSIUNE
--

EXEC modifica_versiune @versiune = 2;
EXEC modifica_versiune @versiune = 5;
EXEC modifica_versiune @versiune = 3;
EXEC modifica_versiune @versiune = 0;
EXEC modifica_versiune @versiune = -1;
EXEC modifica_versiune @versiune = 8;


SELECT * FROM VersiuniBD;



---
--- VERIFICARE MODIFICARI CONCRETE
---


-- VERSIUNEA 0
EXEC modifica_versiune @versiune = 0;
EXEC sp_help 'ContinutMedia';  -- Verificare daca suntem la versiunea 0


EXEC modifica_versiune @versiune = 1;
EXEC sp_help 'ContinutMedia';  -- Verificare daca s-a executat do_proc_1


EXEC modifica_versiune @versiune = 2;
EXEC sp_help 'ContinutMedia'; -- Verificare daca s-a executat do_proc_2
IF OBJECT_ID('Preferinte', 'U') IS NOT NULL     -- Verific daca tabela a fost creata
    PRINT 'Tabela Preferinte exista';
ELSE
    PRINT 'Tabela Preferinte nu exista';


EXEC modifica_versiune @versiune = 3;
IF OBJECT_ID('Preferinte', 'U') IS NOT NULL     -- Verific daca tabela a fost creata
    PRINT 'Tabela Preferinte exista';
ELSE
    PRINT 'Tabela Preferinte nu exista';
SELECT * FROM Preferinte;


EXEC modifica_versiune @versiune = 4;
SELECT * FROM Preferinte;                 -- Verific daca coloana noua a fost creata
EXEC sp_help 'Preferinte';


EXEC modifica_versiune @versiune = 5;
EXEC sp_help 'Preferinte';