----- 1. Crearea structurii relationale -----
---- Am rulat Lab4Structure.sql ----




----- 2. Crearea View-urilor -----

---- 2.1. Un view ce contine o comanda SELECT pe o tabela ----

-- Creez un view cu SELECT pe tabela "Utilizatori" 
-- Obtin toate datele pentru fiecare utilizator din tabela "Utilizatori"
CREATE VIEW view_utilizatori AS 
SELECT *
FROM Utilizatori;


--- Verificare daca s-a creat view-ul: view_utilizatori
SELECT * 
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_NAME = 'view_utilizatori';



---- 2.2. Un view ce contine o comanda SELECT aplicata pe cel putin doua tabele ----

-- Creez un view care foloseste tabelele: "Utilizatori", "AbonamenteUtilizatori" si "TipuriDeAbonamente"
-- Obtin informatii despre utilizatori si abonamentele lor
CREATE VIEW view_abonamente_utilizatori AS
SELECT U.ID_utilizator, U.Nume, T.Nume_abonament, T.Pret, A.Status_abonament
FROM Utilizatori U
JOIN AbonamenteUtilizatori A ON U.ID_utilizator = A.ID_utilizator
JOIN TipuriDeAbonamente T ON A.ID_tip_abonament = T.ID_tip_abonament;


--- Verificare daca s-a creat view-ul: view_abonamente_utilizatori
SELECT * 
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_NAME = 'view_abonamente_utilizatori';



---- 2.3. Un view ce contine o comanda SELECT aplicata pe cel putin doua tabele si avand o clauza GROUP BY ----

-- Creez un view care foloseste tabelele: "Utilizatori" si "Facturi"
-- Obtin pentru fiecare utilizator suma totala a facturilor asociate
CREATE VIEW view_facturi_utilizatori AS
SELECT U.ID_utilizator, U.Nume, SUM(F.Suma) AS TotalFacturi
FROM Utilizatori U
JOIN Facturi F ON U.ID_utilizator = F.ID_utilizator
GROUP BY U.ID_utilizator, U.Nume;


--- Verificare daca s-a creat view-ul: view_facturi_utilizatori
SELECT * 
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_NAME = 'view_facturi_utilizatori';




----- 3. Adaugare tabele si view-uri -----


---- 3.1. Adaug tabelele necesare pentru testare in tabela "Tables" ----
INSERT INTO Tables (Name)
VALUES
	('DateCard'),				-- Adaug tabela "DateCard"
	('Facturi'),				-- Adaug tabela "Facturi" (tabela care contine cel putin o cheie straina)
	('Dispozitive'),			-- Adaug tabela "Dispozitive"
	('Recenzii'),				-- Adaug tabela "Recenzii"
	('Vizualizari'),		    -- Adaug tabela "Vizualizari"
	('Episoade'),			    -- Adaug tabela "Episoade"
	('ContinutMedia'),			-- Adaug tabela "ContinutMedia"
	('AbonamenteUtilizatori'),  -- Adaug tabela "AbonamenteUtilizatori" (tabela care are cheia primara formata din 2 chei straine)
	('TipuriDeAbonamente'),     -- Adaug tabela "TipuriDeAbonamente"
	('ServiciiDeStreaming'),	-- Adaug tabela "ServiciiDeStreaming"
	('Utilizatori');		    -- Adaug tabela "Utilizatori" (tabela fara chei straine)




-- SELECT * FROM Utilizatori
-- SELECT * FROM AbonamenteUtilizatori
-- SELECT * FROM TipuriDeAbonamente
-- SELECT * FROM Facturi
-- SELECT * FROM ServiciiDeStreaming


-- Verific daca s-au introdus datele corect in tabela "Tables"
SELECT * FROM Tables



---- 3.2. Adaug view-urile pentru testare in tabela "Views" ----
INSERT INTO Views (Name)
VALUES
	('view_utilizatori'),			    -- Adaug view-ul "view_utilizatori"
	('view_abonamente_utilizatori'),    -- Adaug view-ul "view_abonamente_utilizatori"
	('view_facturi_utilizatori');		-- ADaug view-ul "view_facturi_utilizatori"


-- Verific daca s-au introdus datele corect in tabela "Views"
SELECT * FROM Views



---- 3.3. Procedura pentru asocierea tabelelor si view-urilor ----

-- Stergere procedura daca exista
DROP PROCEDURE IF EXISTS proc_asociere_tabele_si_view

-- Creare procedura
-- Procedura de asociere a tabelelor si view-urilor
CREATE PROCEDURE proc_asociere_tabele_si_view
    @TestID INT
AS
BEGIN
    -- Verifică dacă TestID există în tabela Tests
    IF NOT EXISTS (SELECT 1 FROM Tests WHERE TestID = @TestID)
    BEGIN
        PRINT 'TestID nu există. Creez un TestID valid înainte de a insera tabelele și view-urile.';
        
        -- Adaugă un TestID valid în tabela Tests
        SET IDENTITY_INSERT Tests ON;
        INSERT INTO Tests (TestID, Name) 
        VALUES (@TestID, 'Testare pentru testul cu ID-ul ' + CAST(@TestID AS VARCHAR));
        SET IDENTITY_INSERT Tests OFF;
        
        PRINT 'TestID a fost adăugat în tabela Tests.';
    END

    -- Variabile pentru cursori
    DECLARE @TableID INT;
    DECLARE @Position INT;
    DECLARE @MaxPosition INT;

    -- Calculăm numărul total de tabele
    SELECT @MaxPosition = COUNT(*) FROM Tables;

    -- 1. Determinăm tabelele cu FK și dependențele lor
    -- Așezăm tabelele care sunt dependente (au FK) mai devreme
    DECLARE @TableCursor CURSOR;
    SET @TableCursor = CURSOR FOR
    SELECT TableID
    FROM Tables
    WHERE EXISTS (SELECT 1 
                  FROM sys.foreign_keys fk
                  WHERE fk.parent_object_id = OBJECT_ID(Tables.Name)) -- Tabelele cu FK

    OPEN @TableCursor;
    FETCH NEXT FROM @TableCursor INTO @TableID;

    SET @Position = 1;  -- Poziția pentru tabelele cu FK

    -- Setăm pozițiile pentru tabelele cu FK
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM TestTables WHERE TestID = @TestID AND TableID = @TableID)
        BEGIN
            -- Alocă poziția
            INSERT INTO TestTables (TestID, TableID, NoOfRows, Position)
            VALUES (@TestID, @TableID, 100, @Position);
        END

        FETCH NEXT FROM @TableCursor INTO @TableID;
        SET @Position = @Position + 1;  -- Creștem poziția pentru următoarea tabelă cu FK
    END

    CLOSE @TableCursor;
    DEALLOCATE @TableCursor;

    -- 2. Procesăm tabelele fără FK (care sunt furnizori de FK)
    SET @TableCursor = CURSOR FOR
    SELECT TableID
    FROM Tables
    WHERE NOT EXISTS (SELECT 1 
                      FROM sys.foreign_keys fk
                      WHERE fk.parent_object_id = OBJECT_ID(Tables.Name)) -- Tabelele fără FK

    OPEN @TableCursor;
    FETCH NEXT FROM @TableCursor INTO @TableID;

    SET @Position = @MaxPosition + 1;  -- Poziția pentru tabelele fără FK

    -- Setăm pozițiile pentru tabelele fără FK
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM TestTables WHERE TestID = @TestID AND TableID = @TableID)
        BEGIN
            -- Alocă poziția
            INSERT INTO TestTables (TestID, TableID, NoOfRows, Position)
            VALUES (@TestID, @TableID, 1000, @Position);
        END

        FETCH NEXT FROM @TableCursor INTO @TableID;
        SET @Position = @Position + 1;  -- Creștem poziția pentru următoarea tabelă fără FK
    END

    CLOSE @TableCursor;
    DEALLOCATE @TableCursor;

    -- 3. Asocierea TestID cu Views
    DECLARE @ViewID INT;
    DECLARE @ViewCursor CURSOR;
    SET @ViewCursor = CURSOR FOR
    SELECT ViewID
    FROM Views;

    OPEN @ViewCursor;
    FETCH NEXT FROM @ViewCursor INTO @ViewID;

    -- Inserăm view-urile
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM TestViews WHERE TestID = @TestID AND ViewID = @ViewID)
        BEGIN
            INSERT INTO TestViews (TestID, ViewID)
            VALUES (@TestID, @ViewID);
        END

        FETCH NEXT FROM @ViewCursor INTO @ViewID;
    END

    CLOSE @ViewCursor;
    DEALLOCATE @ViewCursor;

    -- Verificare finală
    PRINT 'Procedura de asociere a tabelelor și view-urilor a fost executată cu succes!';
END;




-- Executarea procedurii "proc_asociere_tabele_si_view" pentru a asocia automat tabelele si view-urile
EXEC proc_asociere_tabele_si_view @TestID = 1;

-- Verificare daca asocierea s-a facut corect
SELECT * FROM Tests;	   -- Verificare daca s-a adaugat @TestID in tabela (in cazul in care nu exista)
SELECT * FROM TestTables;  -- Verific daca s-au asociat testele din tabela "Tests"
SELECT * FROM TestViews;   -- Verific daca s-au asociat view-urile din tabela "Views"
SELECT * FROM Tables       -- Pentru a verifica daca campul "Position" s-a setat corect



----- 4. Proceduri pentru transefrul/stergerea/inserarea datelor in tabelele din "Tables" -----

---- 4.1. Procedura pentru transferul datelor care urmeaza sa fie sterse din tabele ----

-- Sterg procedura "proc_copiaza_date_test", daca exista
DROP PROCEDURE IF EXISTS proc_copiaza_date_test;

-- Creare procedură corectată
CREATE PROCEDURE proc_copiaza_date_test
    @TestID INT
AS
BEGIN
    -- Verifică dacă TestID există
    IF NOT EXISTS (SELECT 1 FROM Tests WHERE TestID = @TestID)
    BEGIN
        PRINT 'TestID nu există. Procedura nu poate continua.';
        RETURN;
    END

    -- Declarare variabile
    DECLARE @TableName NVARCHAR(128);
    DECLARE @BackupTableName NVARCHAR(128);
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @NoOfRows INT;
    DECLARE @ColumnList NVARCHAR(MAX);
    DECLARE @HasIdentity BIT;

    -- Cursor pentru a parcurge tabelele asociate testului
    DECLARE TableCursor CURSOR FOR
    SELECT T.Name, TT.NoOfRows
    FROM TestTables TT
    JOIN Tables T ON TT.TableID = T.TableID
    WHERE TT.TestID = @TestID
    ORDER BY TT.Position ASC; -- Ordinea poziției

    OPEN TableCursor;
    FETCH NEXT FROM TableCursor INTO @TableName, @NoOfRows;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Creează numele tabelului de backup
        SET @BackupTableName = @TableName + '_Backup';

        -- Creează tabelul de backup dacă nu există
        SET @SQL = '
            IF OBJECT_ID(''[dbo].[' + @BackupTableName + ']'', ''U'') IS NULL
            BEGIN
                SELECT TOP 0 * INTO [dbo].[' + @BackupTableName + '] 
                FROM [dbo].[' + @TableName + '];
            END';
        EXEC sp_executesql @SQL;

        -- Obține lista de coloane ale tabelului, excluzând coloana IDENTITY
        SELECT @ColumnList = STRING_AGG(QUOTENAME(c.name), ', ')
        FROM sys.columns c
        JOIN sys.objects o ON c.object_id = o.object_id
        WHERE o.name = @TableName
        AND c.is_identity = 0; -- Exclude coloana IDENTITY

        -- Verifică dacă tabelul original are o coloană IDENTITY
        SELECT @HasIdentity = CASE WHEN EXISTS (
            SELECT 1
            FROM sys.columns c
            JOIN sys.objects o ON c.object_id = o.object_id
            WHERE o.name = @TableName
            AND c.is_identity = 1
        ) THEN 1 ELSE 0 END;

        -- Activează IDENTITY_INSERT dacă este necesar
        IF @HasIdentity = 1
        BEGIN
            SET @SQL = 'SET IDENTITY_INSERT [dbo].[' + @BackupTableName + '] ON;';
            EXEC sp_executesql @SQL;
        END

        -- Copiază datele din tabelul original în tabelul de backup, cu o listă explicită de coloane
        SET @SQL = '
            INSERT INTO [dbo].[' + @BackupTableName + '] (' + @ColumnList + ')
            SELECT TOP (' + CAST(@NoOfRows AS NVARCHAR) + ') ' + @ColumnList + '
            FROM [dbo].[' + @TableName + '];';
        EXEC sp_executesql @SQL;

        -- Dezactivează IDENTITY_INSERT dacă a fost activat
        IF @HasIdentity = 1
        BEGIN
            SET @SQL = 'SET IDENTITY_INSERT [dbo].[' + @BackupTableName + '] OFF;';
            EXEC sp_executesql @SQL;
        END

        PRINT 'Datele din tabelul ' + @TableName + ' au fost copiate în ' + @BackupTableName + ' (' + CAST(@NoOfRows AS NVARCHAR) + ' rânduri).';

        -- Continuă cu următorul tabel
        FETCH NEXT FROM TableCursor INTO @TableName, @NoOfRows;
    END

    CLOSE TableCursor;
    DEALLOCATE TableCursor;

    PRINT 'Toate datele asociate testului au fost copiate cu succes.';
END;


-- Executare procedura "proc_copiaza_date_test"

EXEC proc_copiaza_date_test @TestID = 1



-- Verificare tabele de backup
SELECT * FROM [dbo].[AbonamenteUtilizatori_Backup]
SELECT * FROM [dbo].[Facturi_Backup]
SELECT * FROM [dbo].[ServiciiDeStreaming_Backup]
SELECT * FROM [dbo].[TipuriDeAbonamente_Backup]
SELECT * FROM [dbo].[Utilizatori_Backup]




---- 4.2. Procedura pentru stergerea datelor din tabele ----

-- Stergere procedură existentă
DROP PROCEDURE IF EXISTS proc_sterge_date_test;

-- Creează procedura
CREATE PROCEDURE proc_sterge_date_test
    @TestID INT,
	@TestRunID INT
AS
BEGIN
    -- Verifică dacă TestID există
    IF NOT EXISTS (SELECT 1 FROM Tests WHERE TestID = @TestID)
    BEGIN
        PRINT 'TestID nu există. Procedura nu poate continua.';
        RETURN;
    END

    -- Declarare variabile
    DECLARE @TableName NVARCHAR(128);
    DECLARE @NoOfRows INT;
    DECLARE @SQL NVARCHAR(MAX);
	DECLARE @TableID INT;
	DECLARE @Start DATETIME;
	DECLARE @End DATETIME;

    -- Cursor pentru a parcurge tabelele asociate testului, în ordinea corectă a poziției (ascendentă)
    DECLARE TableCursor CURSOR FOR
    SELECT T.Name, TT.NoOfRows, TT.TableID
    FROM TestTables TT
    JOIN Tables T ON TT.TableID = T.TableID
    WHERE TT.TestID = @TestID
    ORDER BY TT.Position ASC; -- Ordinea este ascendentă, conform specificației

    OPEN TableCursor;
    FETCH NEXT FROM TableCursor INTO @TableName, @NoOfRows, @TableID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
		SET @Start = GETDATE()
        BEGIN TRY
            -- Construiește și execută comanda de ștergere
            SET @SQL = 'DELETE TOP (' + CAST(@NoOfRows AS NVARCHAR) + ') FROM [dbo].[' + @TableName + ']';
            EXEC sp_executesql @SQL;

            PRINT 'Au fost șterse ' + CAST(@NoOfRows AS NVARCHAR) + ' rânduri din tabela: ' + @TableName;
        END TRY
        BEGIN CATCH
            -- Prinde erorile și le afișează, dar continuă procesul pentru celelalte tabele
            PRINT 'Eroare la ștergerea din tabela: ' + @TableName + '. Mesaj: ' + ERROR_MESSAGE();
        END CATCH;
		SET @End = GETDATE()

		-- Adaug datele in tabela TestRunTables
		INSERT INTO TestRunTables (TestRunID, TableID, StartAt, EndAt)
		VALUES (@TestRunID, @TestID, @Start, GETDATE());

        -- Avansează cursorul
        FETCH NEXT FROM TableCursor INTO @TableName, @NoOfRows, @TableID;
    END

    -- Închide și deallocatează cursorul
    CLOSE TableCursor;
    DEALLOCATE TableCursor;

    PRINT 'Datele au fost șterse din toate tabelele asociate TestID, în funcție de ordinea Position.';
END;




-- Executarea procedurii "proc_sterge_date_test"

EXEC proc_sterge_date_test @TestID = 1, @TestRunID = 1;




---- 4.3. Procedura pentru inserarea datelor in tabele ----

-- Sterg procedura, daca exista
DROP PROCEDURE IF EXISTS proc_restaureaza_date_test;

-- Creez procedura
CREATE PROCEDURE proc_restaureaza_date_test
    @TestID INT,
	@TestRunID INT
AS
BEGIN
    -- Verifică dacă TestID există
    IF NOT EXISTS (SELECT 1 FROM Tests WHERE TestID = @TestID)
    BEGIN
        PRINT 'TestID nu există. Procedura nu poate continua.';
        RETURN;
    END

    -- Declarare variabile
    DECLARE @TableName NVARCHAR(128);
    DECLARE @BackupTableName NVARCHAR(128);
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ColumnList NVARCHAR(MAX);
    DECLARE @HasIdentity BIT;
	DECLARE @End DATETIME;
	DECLARE @TableID INT;

    -- Cursor pentru a parcurge tabelele asociate testului, în ordinea inversă a poziției (descendentă)
    DECLARE TableCursor CURSOR FOR
    SELECT T.Name, TT.TableID
    FROM TestTables TT
    JOIN Tables T ON TT.TableID = T.TableID
    WHERE TT.TestID = @TestID
    ORDER BY TT.Position DESC; -- Ordinea este descendentă

    OPEN TableCursor;
    FETCH NEXT FROM TableCursor INTO @TableName, @TableID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            -- Creează numele tabelului de backup
            SET @BackupTableName = @TableName + '_Backup';

            -- Obține lista de coloane ale tabelului, excluzând coloana IDENTITY
            SELECT @ColumnList = STRING_AGG(QUOTENAME(c.name), ', ')
            FROM sys.columns c
            JOIN sys.objects o ON c.object_id = o.object_id
            WHERE o.name = @TableName
            AND c.is_identity = 0; -- Exclude coloana IDENTITY

            -- Verifică dacă tabelul original are o coloană IDENTITY
            SELECT @HasIdentity = CASE WHEN EXISTS (
                SELECT 1
                FROM sys.columns c
                JOIN sys.objects o ON c.object_id = o.object_id
                WHERE o.name = @TableName
                AND c.is_identity = 1
            ) THEN 1 ELSE 0 END;

            -- Dezactivează toate constrângerile de chei externe și primare
            SET @SQL = 'ALTER TABLE [dbo].[' + @TableName + '] NOCHECK CONSTRAINT ALL;';
            EXEC sp_executesql @SQL;

            -- Activează IDENTITY_INSERT dacă este necesar
            IF @HasIdentity = 1
            BEGIN
                SET @SQL = 'SET IDENTITY_INSERT [dbo].[' + @TableName + '] ON;';
                EXEC sp_executesql @SQL;
            END

            -- Timpul de început al inserării
            DECLARE @StartTime DATETIME = GETDATE();

            -- Copiază datele din tabelul de backup în tabelul original
            SET @SQL = '
                INSERT INTO [dbo].[' + @TableName + '] (' + @ColumnList + ')
                SELECT ' + @ColumnList + '
                FROM [dbo].[' + @BackupTableName + '];';
            EXEC sp_executesql @SQL;

            -- Timpul de final al inserării
            DECLARE @EndTime DATETIME = GETDATE();

            -- Salvează timpii în TestRunTables
            SET @SQL = '
                INSERT INTO [dbo].[TestRunTables] (TestRunID, TableID, StartAt, EndAt)
                VALUES (@TestID, (SELECT TableID FROM [dbo].[Tables] WHERE Name = @TableName), @StartTime, @EndTime);';
            EXEC sp_executesql @SQL, N'@TestID INT, @TableName NVARCHAR(128), @StartTime DATETIME, @EndTime DATETIME', @TestID, @TableName, @StartTime, @EndTime;

            -- Dezactivează IDENTITY_INSERT dacă a fost activat
            IF @HasIdentity = 1
            BEGIN
                SET @SQL = 'SET IDENTITY_INSERT [dbo].[' + @TableName + '] OFF;';
                EXEC sp_executesql @SQL;
            END

            -- Reactivează constrângerile de chei externe și primare
            SET @SQL = 'ALTER TABLE [dbo].[' + @TableName + '] CHECK CONSTRAINT ALL;';
            EXEC sp_executesql @SQL;

            PRINT 'Datele au fost restaurate în tabelul: ' + @TableName;
        END TRY
        BEGIN CATCH
            -- Prinde erorile și le afișează, dar continuă procesul pentru celelalte tabele
            PRINT 'Eroare la restaurarea datelor în tabelul: ' + @TableName + '. Mesaj: ' + ERROR_MESSAGE();
        END CATCH;

		-- Adaug timpul de final
		UPDATE TestRunTables
		SET EndAt = GETDATE()
		WHERE TestRunID = @TestRunID AND TableID = @TableID;

        -- Avansează cursorul
        FETCH NEXT FROM TableCursor INTO @TableName, @TableID;
    END

    -- Închide și deallocatează cursorul
    CLOSE TableCursor;
    DEALLOCATE TableCursor;

    PRINT 'Toate datele au fost restaurate în tabelele asociate TestID, în funcție de ordinea inversă a Position.';
END;





-- Executare procedura
EXEC proc_restaureaza_date_test @TestID = 1, @TestRunID = 1;





SELECT * FROM Tests
SELECT * FROM Tables
SELECT * FROM TestTables
SELECT * FROM Views
SELECT * FROM TestViews
SELECT * FROM TestRuns
SELECT * FROM TestRunTables
SELECT * FROM TestRunViews




------- RULARE ------

-- Stergere procedura existenta
DROP PROCEDURE IF EXISTS proc_test_main;


-- Creare procedura principala
CREATE PROCEDURE proc_test_main
AS
BEGIN
	DECLARE @ds DATETIME; -- start time test
	DECLARE @di DATETIME; -- intermediate time test
	DECLARE @de DATETIME; -- end time test
	DECLARE @testRunID INT -- id-ul TestRuns

	-- Fac o copie a datelor care urmeaza sa fie sterse
	EXEC proc_copiaza_date_test @TestID = 1

	SET @ds = GETDATE() -- salvez data/ora de inceput a testului

	-- Creez o noua intrare in tabela TestRuns
	INSERT INTO TestRuns (Description, StartAt)
	VALUES ('Testare BD', @ds);

	-- Obtin id-ul TestRunID
	SET @testRunID = SCOPE_IDENTITY();

	-- Sterg datele din tabele
	EXEC proc_sterge_date_test @TestID = 1, @TestRunID = @testRunID;
	--Inserez datele inapoi in tabele
	EXEC proc_restaureaza_date_test @TestID = 1, @testRunID = @testRunID;
	SET @di = GETDATE() -- salvez data/ora de sfarsit a inserarii si a stergerii datelor

	-- Evaluez (select from) view
	DECLARE @ViewName NVARCHAR(128);
	DECLARE @SQL NVARCHAR(MAX);
	DECLARE @ViewID INT;

	DECLARE ViewCursor CURSOR FOR
	SELECT v.Name, v.ViewID
	FROM Views  v
	JOIN TestViews tv ON v.ViewID = tv.ViewID;

	OPEN ViewCursor;
	FETCH NEXT FROM ViewCursor INTO @ViewName, @ViewID;

	-- Iterez prin fiecare view si execut un SELECT pentru fiecare
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SQL = 'SELECT * FROM ' + QUOTENAME(@ViewName);
		EXEC sp_executesql @SQL;

		-- Adaug datele despre view in tabela TestRunViews
		INSERT INTO TestRunViews (TestRunID, ViewID, StartAt, EndAt)
		VALUES (@testRunID, @ViewID, @di, GETDATE());

		FETCH NEXT FROM ViewCursor INTO @ViewName, @ViewID;
	END

	CLOSE ViewCursor;
	DEALLOCATE ViewCursor;

	SET @de = GETDATE() -- salvez data/ora de final a testului

	-- Adaug data/ora la care s-a finalizat testul
	UPDATE TestRuns
	SET EndAt = @de
	WHERE TestRunID = @testRunID
END;


EXEC proc_test_main;


-- EXEC proc_copiaza_date_test @TestID = 1
-- EXEC proc_sterge_date_test @TestID = 1;
-- EXEC proc_restaureaza_date_test @TestID = 1;

SELECT * FROM TestRuns
SELECT * FROM TestRunTables
SELECT * FROM TestRunViews