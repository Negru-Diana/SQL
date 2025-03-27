USE GestiuneServiciiDeStreaming -- Specififc BD pe care o folosesc
GO


----- 1. Functii pentru cautarea/verificarea anumitor campuri -----

---- 1.1. Functie pentru cautarea ID-ului unui utilizator dupa Nume si Email ----

CREATE FUNCTION dbo.FindID_utilizator
(
	@Nume varchar(50),
	@Email varchar(50)
)
RETURNS INT
AS
BEGIN
	-- Declar o variabila pentru a stoca ID-ul utilizatorului
	DECLARE @ID_utilizator INT;

	-- Caut ID-ul utilizatorului in tabela Utilizatori
	SELECT @ID_utilizator = ID_utilizator
	FROM Utilizatori
	WHERE Nume = @Nume AND Email = @Email;

	-- Daca utilizatorul nu a fost gasit returnez valoarea -1
	IF @ID_utilizator IS NULL
	BEGIN
		RETURN -1;
	END

	-- Returnez @ID_utilizator daca utilizatorul a fost gasit
	RETURN @ID_utilizator;
END;


---- 1.2. Functie pentru a valida un camp care trebuie sa nu fie NULL ----

CREATE FUNCTION dbo.IsNotNull
(
	@Continut varchar(100)
)
RETURNS BIT
AS
BEGIN
	-- Verific daca @Continut este NULL
	IF LEN(@Continut) > 0
	BEGIN
		RETURN 1;  -- Returnez TRUE (1) daca nu este NULL
	END

	RETURN 0;  -- Returnez FALSE (0) daca este NULL
END;



---- 1.3. Functie pentru validarea adresei de email ----

CREATE FUNCTION dbo.IsEmailValid
(
	@Email varchar(100)
)
RETURNS BIT
AS
BEGIN
	-- Verific daca @Email este valid
	IF @Email NOT LIKE '%_@__%.__%'
	BEGIN
		RETURN 0
	END

	RETURN 1
END;


---- 1.4. Functie pentru validarea parolei ----

CREATE FUNCTION dbo.IsParolaValid
(
	@Parola varchar(100)
)
RETURNS BIT
AS
BEGIN
	-- Verific daca @Parola este valida
	IF LEN(@Parola) < 8
	BEGIN
		RETURN 0
	END

	RETURN 1
END;


---- 1.5. Functie pentru validarea numarului de card ----

CREATE FUNCTION dbo.IsNumarCardValid
(
	@Numar_card varchar(50)
)
RETURNS BIT
AS
BEGIN
	--Verific daca numarul de card este valid
	IF @Numar_card NOT LIKE '____-____-____-____'
	BEGIN
		RETURN 0
	END

	RETURN 1
END;


---- 1.6. Functie pentru validarea datei de expirare a cardului ----

CREATE FUNCTION dbo.IsDataExpirariiValid
(
	@Data_expirarii DATE  -- Format: an-luna-zi 
)
RETURNS BIT
AS
BEGIN
	--Verific daca @Data_expirarii este valida
	IF @Data_expirarii <= GETDATE()
	BEGIN
		RETURN 0
	END

	RETURN 1
END;


---- 1.7. Functie pentru verificarea a verifica daca este valid si unic numele unui serviciu de streaming ----

CREATE FUNCTION dbo.IsNumeServiciuDeStreamingValid
(
	@Nume_serviciu varchar(100)
)
RETURNS BIT
AS
BEGIN
	-- Verific validitatea si unicitatea @Nume_serviciu
	IF EXISTS (SELECT 1 FROM ServiciiDeStreaming WHERE Nume_serviciu = @Nume_serviciu) OR dbo.IsNotNull(@Nume_serviciu) = 0
	BEGIN
		RETURN 0
	END

	RETURN 1
END;


---- 1.8. Functie pentru validarea pretului ----

CREATE FUNCTION dbo.IsPretValid
(
	@Pret decimal(5,2)
)
RETURNS BIT
AS
BEGIN
	-- Verific daca @Pret este valid
	IF @Pret < 0
	BEGIN
		RETURN 0
	END

	RETURN 1
END;


---- 1.9. Functie pentru validarea duratei abonamentului ----

CREATE FUNCTION dbo.IsDurataAbonamentValida
(
	@Durata varchar(30)
)
RETURNS BIT
AS
BEGIN
	-- Verific daca @Durata este valida
	IF @Durata != 'luna' AND @Durata != 'an'
	BEGIN
		RETURN 0
	END

	RETURN 1
END;


---- 1.10. Functie pentru verificarea existentei id-ului unui tip de abonament ----

CREATE FUNCTION dbo.ExistaIdTipAbonament
(
	@ID_tip_abonament int
)
RETURNS BIT
AS 
BEGIN
	-- Verific daca @ID_tip_abonament este valid (exista in tabela TipuriDeAbonament)
	IF NOT EXISTS (SELECT 1 FROM TipuriDeAbonamente WHERE ID_tip_abonament = @ID_tip_abonament)
	BEGIN
		RETURN 0
	END

	RETURN 1
END;


---- 1.11. Verific daca tipul serviciului este valid ----

CREATE FUNCTION dbo.IsTipServiciuValid
(
	@Tip_serviciu varchar(30)
)
RETURNS BIT
AS
BEGIN
	-- Verific daca @Tip_serviciu este valid
	IF LOWER(@Tip_serviciu) != 'audio' AND LOWER(@Tip_serviciu) != 'video' AND LOWER(@Tip_serviciu) != 'audio/video'
	BEGIN
		RETURN 0
	END

	RETURN 1
END;



---- 1.12. Verific daca numele unei tabele apare in tabela TabeleCRUD ----

CREATE FUNCTION dbo.IsTabelaValida
(
	@TableName nvarchar(100)
)
RETURNS BIT
AS
BEGIN
	-- Verific daca @TableName este valid
	IF NOT EXISTS (SELECT 1 FROM TabeleCRUD WHERE Nume_tabela = @TableName)
	BEGIN
		RETURN 0
	END

	RETURN 1
END;



---- 1.13. Verific daca campurile apartin tabelei date ----

CREATE FUNCTION dbo.IsColumnsTableValid
(
	@TableName nvarchar(100),
	@Columns nvarchar(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
	-- Variabile
    DECLARE @Mesaj NVARCHAR(MAX) = '';       -- Mesaj final de întoarcere
    DECLARE @ColumnList TABLE (ColumnName NVARCHAR(128));  -- Tabel temporar pentru coloanele furnizate
    DECLARE @InvalidColumns NVARCHAR(MAX) = ''; -- Lista coloanelor invalide
    DECLARE @IdentityColumns NVARCHAR(MAX) = ''; -- Lista coloanelor de tip IDENTITY
	DECLARE @MissingNotNullColumns NVARCHAR(MAX) = ''; -- Lista coloanelor NOT NULL lipsa
    DECLARE @Separator NVARCHAR(2) = ', ';

    -- Populez tabela temporara cu coloanele furnizate de utilizator
    INSERT INTO @ColumnList (ColumnName)
    SELECT TRIM(value)
    FROM STRING_SPLIT(@Columns, ',');

    -- Identific coloanele care nu fac parte din tabel
    SELECT @InvalidColumns = STRING_AGG(ColumnName, @Separator)
    FROM @ColumnList
    WHERE NOT EXISTS (
        SELECT 1
        FROM INFORMATION_SCHEMA.COLUMNS AS TableColumns
        WHERE TableColumns.TABLE_NAME = @TableName
          AND TableColumns.COLUMN_NAME = ColumnName
    );

    -- Identific coloanele de tip IDENTITY incluse in lista
    SELECT @IdentityColumns = STRING_AGG(ColumnName, @Separator)
    FROM @ColumnList
    WHERE EXISTS (
        SELECT 1
        FROM INFORMATION_SCHEMA.COLUMNS AS TableColumns
        WHERE TableColumns.TABLE_NAME = @TableName
          AND TableColumns.COLUMN_NAME = ColumnName
          AND COLUMNPROPERTY(OBJECT_ID(TableColumns.TABLE_SCHEMA + '.' + TableColumns.TABLE_NAME), TableColumns.COLUMN_NAME, 'IsIdentity') = 1
    );

	-- Identific coloanele NOT NULL care nu au fost specificate (fara cele de tip IDENTITY) si care nu au un DEFAULT
	SELECT @MissingNotNullColumns = STRING_AGG(COLUMN_NAME, @Separator)
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = @TableName
		AND IS_NULLABLE = 'NO'  -- Coloanele NOT NULL
		AND COLUMNPROPERTY(OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME), COLUMN_NAME, 'IsIdentity') <> 1 -- Exclud coloanele de tip IDENTITY
		-- Excludem coloanele care au un DEFAULT definit
		AND COLUMN_DEFAULT IS NULL
		AND COLUMN_NAME NOT IN (
			SELECT ColumnName
			FROM @ColumnList
		);


    -- Construiesc mesajul
    IF @InvalidColumns IS NOT NULL
        SET @Mesaj = @Mesaj + 'Urmatoarele coloane nu fac parte din tabela specificata: ' + @InvalidColumns + '. ' + CHAR(13) + CHAR(10);  -- CHAR(13) + CHAR(10) ==> new line

    IF @IdentityColumns IS NOT NULL
        SET @Mesaj = @Mesaj + 'Urmatoarele coloane nu sunt disponibile pentru inserare: ' + @IdentityColumns + '.'+ CHAR(13) + CHAR(10);  -- CHAR(13) + CHAR(10) ==> new line

	IF @MissingNotNullColumns IS NOT NULL
        SET @Mesaj = @Mesaj + 'Urmatoarele coloane sunt obligatorii si nu au fost specificate: ' + @MissingNotNullColumns + '.' + CHAR(13) + CHAR(10);


	RETURN @Mesaj; -- este '' daca toate coloanele sunt valide
END;



---- 1.14. Verific daca se permite operatia de UPDATE pe coloana data ----

CREATE FUNCTION dbo.IsAcceptedUpdate
(
	@TableName varchar(100),
	@Column varchar(100)
)
RETURNS BIT
AS
BEGIN
	RETURN (SELECT 
			CASE
				WHEN EXISTS (SELECT 1 FROM TabeleCRUD T INNER JOIN AcceptedUpdateCol AUC ON T.ID_tabelaCRUD = AUC.ID_tabelaCRUD
								WHERE T.Nume_tabela = @TableName AND AUC.Nume_coloana = @Column)
				THEN 1
				ELSE 0
			END);
END;





----- 2. Functii pentru validare (date tabele) -----


---- 2.1. Functie pentru validarea datelor de intrare pentru tabela "Utilizatori" ----

CREATE FUNCTION dbo.IsUtilizatoriDataValid 
(
    @Columns nvarchar(MAX),   -- Lista de coloane
    @Values nvarchar(MAX)     -- Lista de valori
)
RETURNS VARCHAR(1000) -- Returneaza un mesaj cu lungimea = 0 (daca datele sunt valide) sau un mesaj cu lungimea > 0 (daca datele sunt invalide)
AS
BEGIN
    -- Declar o variabila pentru a stoca mesajul returnat
    DECLARE @Mesaj VARCHAR(1000) = '';
    DECLARE @ColumnList TABLE (ColumnName NVARCHAR(128), RowNum INT);  -- Tabel temporar pentru coloanele furnizate
    DECLARE @ValueList TABLE (ColumnValue NVARCHAR(MAX), RowNum INT); -- Tabel temporar pentru valorile furnizate

    -- Populez tabela temporara @ColumnList cu valorile din @Columns
    INSERT INTO @ColumnList (ColumnName, RowNum)
    SELECT TRIM(value), ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
    FROM STRING_SPLIT(@Columns, ',');

    -- Populez tabela temporara @ValueList cu valorile din @Values
    INSERT INTO @ValueList (ColumnValue, RowNum)
    SELECT TRIM(value), ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
    FROM STRING_SPLIT(@Values, ',');

    -- Verific daca au fost furnizate valori pentru fiecare camp
    IF (SELECT COUNT(*) FROM @ColumnList) != (SELECT COUNT(*) FROM @ValueList)
    BEGIN
        SET @Mesaj = @Mesaj + 'Trebuie furnizate valori pentru toate coloanele!' + CHAR(13) + CHAR(10);
        RETURN @Mesaj
    END

    -- Variabile pentru fiecare coloana si valoarea acesteia
    DECLARE @ColumnPosition INT;
    DECLARE @ColumnValue NVARCHAR(MAX);

    -- Verific daca valoarea coloanei 'Nume' este valida
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'Nume');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF dbo.IsNotNull(@ColumnValue) = 0
    BEGIN
        SET @Mesaj = @Mesaj + 'Numele nu este valid!' + CHAR(13) + CHAR(10);  
    END

    -- Verific daca valoarea coloanei 'Email' este valida
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'Email');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF dbo.IsEmailValid(@ColumnValue) = 0
    BEGIN
        SET @Mesaj = @Mesaj + 'Email-ul nu este valid!' + CHAR(13) + CHAR(10);
    END

    -- Verific daca valoarea coloanei 'Parola' este valida
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'Parola');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF dbo.IsParolaValid(@ColumnValue) = 0
    BEGIN
        SET @Mesaj = @Mesaj + 'Parola trebuie sa contina minim 8 caractere!' + CHAR(13) + CHAR(10);
    END

    -- Verific daca valoarea coloanei 'Tara' este valida
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'Tara');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF dbo.IsNotNull(@ColumnValue) = 0
    BEGIN
        SET @Mesaj = @Mesaj + 'Tara nu este valida!' + CHAR(13) + CHAR(10);
    END

    RETURN @Mesaj;
END;





---- 2.2. Functie pentru validarea datelor de intrare pentru tabela "DateCard" ----

CREATE FUNCTION dbo.IsDateCardDataValid
(
    @Columns nvarchar(MAX),   -- Lista de coloane
    @Values nvarchar(MAX)     -- Lista de valori
)
RETURNS VARCHAR(1000) -- Returneaza un mesaj cu lungimea = 0 (daca datele sunt valide) sau un mesaj cu lungimea > 0 (daca datele sunt invalide)
AS
BEGIN
    -- Declar o variabila pentru a stoca mesajul returnat
    DECLARE @Mesaj VARCHAR(1000) = '';
    DECLARE @ColumnList TABLE (ColumnName NVARCHAR(128), RowNum INT);  -- Tabel temporar pentru coloanele furnizate
    DECLARE @ValueList TABLE (ColumnValue NVARCHAR(MAX), RowNum INT); -- Tabel temporar pentru valorile furnizate

    -- Populez tabela temporara @ColumnList cu valorile din @Columns
    INSERT INTO @ColumnList (ColumnName, RowNum)
    SELECT TRIM(value), ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
    FROM STRING_SPLIT(@Columns, ',');

    -- Populez tabela temporara @ValueList cu valorile din @Values
    INSERT INTO @ValueList (ColumnValue, RowNum)
    SELECT TRIM(value), ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
    FROM STRING_SPLIT(@Values, ',');

    -- Verific daca au fost furnizate valori pentru fiecare camp
    IF (SELECT COUNT(*) FROM @ColumnList) != (SELECT COUNT(*) FROM @ValueList)
    BEGIN
        SET @Mesaj = @Mesaj + 'Trebuie furnizate valori pentru toate coloanele!' + CHAR(13) + CHAR(10);
        RETURN @Mesaj
    END

    -- Variabile pentru fiecare coloana si valoarea acesteia
    DECLARE @ColumnPosition INT;
    DECLARE @ColumnValue NVARCHAR(MAX);
    DECLARE @Nume NVARCHAR(128);
    DECLARE @Email NVARCHAR(128);
    DECLARE @ID_utilizator INT;

    -- Verific daca valoarea coloanei 'ID_utilizator' este valida
	SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'ID_utilizator');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

	IF NOT EXISTS (SELECT ID_utilizator FROM Utilizatori WHERE ID_utilizator = @ColumnValue)
	BEGIN
		SET @Mesaj = @Mesaj + 'ID-ul utilizatorului este invalid! (Nu exista un utilizator cu acest ID)' + CHAR(13) + CHAR(10);
	END

	IF EXISTS (SELECT ID_utilizator FROM DateCard WHERE ID_utilizator = @ColumnValue)
	BEGIN
		SET @Mesaj = @Mesaj + 'ID-ul utilizatorului este invalid! (Exista datele cardului utilizatorului cu acest ID)' + CHAR(13) + CHAR(10);
	END
    

    -- Verific daca valoarea coloanei 'Numar_card' este valida
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'Numar_card');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF dbo.IsNumarCardValid(@ColumnValue) = 0
    BEGIN
        SET @Mesaj = @Mesaj + 'Numarul cardului este invalid!' + CHAR(13) + CHAR(10);
    END

    -- Verific daca valoarea coloanei 'Data_expirarii' este valida
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'Data_expirarii');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF dbo.IsDataExpirariiValid(@ColumnValue) = 0
    BEGIN
        SET @Mesaj = @Mesaj + 'Cardul este expirat!' + CHAR(13) + CHAR(10);
    END

    -- Verific daca valoarea coloanei 'Nume_detinator' este valida
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'Nume_detinator');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF dbo.IsNotNull(@ColumnValue) = 0
    BEGIN
        SET @Mesaj = @Mesaj + 'Numele detinatorului cardului este invalid!' + CHAR(13) + CHAR(10);
    END

    -- Returnez @Mesaj
    RETURN @Mesaj;
END;





---- 2.3. Functie pentru validarea datelor de intrare pentru tabela "ServiciiDeStreaming" ----

CREATE FUNCTION dbo.IsServiciiDeStreamingDataValid
(
    @Columns nvarchar(MAX),   -- Lista de coloane
    @Values nvarchar(MAX)     -- Lista de valori
)
RETURNS VARCHAR(1000) -- Returneaza un mesaj cu lungimea = 0 (daca datele sunt valide) sau un mesaj cu lungimea > 0 (daca datele sunt invalide)
AS
BEGIN
    -- Declar o variabila pentru a stoca mesajul returnat
    DECLARE @Mesaj VARCHAR(1000) = '';
    DECLARE @ColumnList TABLE (ColumnName NVARCHAR(128), RowNum INT);  -- Tabel temporar pentru coloanele furnizate
    DECLARE @ValueList TABLE (ColumnValue NVARCHAR(MAX), RowNum INT); -- Tabel temporar pentru valorile furnizate

    -- Populez tabela temporara @ColumnList cu valorile din @Columns
    INSERT INTO @ColumnList (ColumnName, RowNum)
    SELECT TRIM(value), ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
    FROM STRING_SPLIT(@Columns, ',');

    -- Populez tabela temporara @ValueList cu valorile din @Values
    INSERT INTO @ValueList (ColumnValue, RowNum)
    SELECT TRIM(value), ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
    FROM STRING_SPLIT(@Values, ',');

    -- Verific daca au fost furnizate valori pentru fiecare camp
    IF (SELECT COUNT(*) FROM @ColumnList) != (SELECT COUNT(*) FROM @ValueList)
    BEGIN
        SET @Mesaj = @Mesaj + 'Trebuie furnizate valori pentru toate coloanele!' + CHAR(13) + CHAR(10);
        RETURN @Mesaj
    END

    -- Variabile pentru fiecare coloana si valoarea acesteia
    DECLARE @ColumnPosition INT;
    DECLARE @ColumnValue NVARCHAR(MAX);

    -- Verific daca valoarea coloanei 'Nume_serviciu' este valida
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'Nume_serviciu');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF dbo.IsNotNull(@ColumnValue) = 0
    BEGIN
        SET @Mesaj = @Mesaj + 'Numele serviciului de streaming este invalid!' + CHAR(13) + CHAR(10);
    END

    -- Verific daca valoarea coloanei 'Tip_serviciu' este valida
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'Tip_serviciu');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF dbo.IsNotNull(@ColumnValue) = 0
    BEGIN
        SET @Mesaj = @Mesaj + 'Tipul serviciului de streaming este invalid! (Nu poate fi gol sau NULL)' + CHAR(13) + CHAR(10);
    END
    ELSE IF dbo.IsTipServiciuValid(@ColumnValue) = 0
    BEGIN
        SET @Mesaj = @Mesaj + 'Tipul serviciului de streaming este invalid! Tipuri admise: video, audio, audio/video.' + CHAR(13) + CHAR(10);
    END

    -- Verific daca nu exista deja un serviciu de streaming cu acelasi nume
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'Nume_serviciu');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF dbo.IsNumeServiciuDeStreamingValid(@ColumnValue) = 0
    BEGIN
        SET @Mesaj = @Mesaj + 'Exista deja un serviciu de streaming cu acest nume!' + CHAR(13) + CHAR(10);
    END

    -- Returnez @Mesaj
    RETURN @Mesaj;
END;




---- 2.4. Functie pentru validarea datelor de intrare pentru tabela "Dispozitive" ----

CREATE FUNCTION dbo.IsDispozitiveDataValid
(
    @Columns nvarchar(MAX),   -- Lista de coloane
    @Values nvarchar(MAX)     -- Lista de valori
)
RETURNS VARCHAR(1000) -- Returneaza un mesaj cu lungimea = 0 (daca datele sunt valide) sau un mesaj cu lungimea > 0 (daca datele sunt invalide)
AS
BEGIN
    -- Declar o variabila pentru a stoca mesajul returnat
    DECLARE @Mesaj VARCHAR(1000) = '';
    DECLARE @ColumnList TABLE (ColumnName NVARCHAR(128), RowNum INT);  -- Tabel temporar pentru coloanele furnizate
    DECLARE @ValueList TABLE (ColumnValue NVARCHAR(MAX), RowNum INT); -- Tabel temporar pentru valorile furnizate

    -- Populez tabela temporara @ColumnList cu valorile din @Columns
    INSERT INTO @ColumnList (ColumnName, RowNum)
    SELECT TRIM(value), ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
    FROM STRING_SPLIT(@Columns, ',');

    -- Populez tabela temporara @ValueList cu valorile din @Values
    INSERT INTO @ValueList (ColumnValue, RowNum)
    SELECT TRIM(value), ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
    FROM STRING_SPLIT(@Values, ',');

    -- Verific daca au fost furnizate valori pentru fiecare camp
    IF (SELECT COUNT(*) FROM @ColumnList) != (SELECT COUNT(*) FROM @ValueList)
    BEGIN
        SET @Mesaj = @Mesaj + 'Trebuie furnizate valori pentru toate coloanele!' + CHAR(13) + CHAR(10);
        RETURN @Mesaj
    END

    -- Variabile pentru fiecare coloana si valoarea acesteia
    DECLARE @ColumnPosition INT;
    DECLARE @ColumnValue NVARCHAR(MAX);

    -- Verific daca valoarea coloanei 'ID_utilizator' este valida
	SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'ID_utilizator');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

	IF NOT EXISTS (SELECT ID_utilizator FROM Utilizatori WHERE ID_utilizator = @ColumnValue)
	BEGIN
		SET @Mesaj = @Mesaj + 'ID-ul utilizatorului este invalid! (Nu exista un utilizator cu acest ID)' + CHAR(13) + CHAR(10);
	END

    -- Verific daca valoarea coloanei 'ID_serviciu' este valida
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'ID_serviciu');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF NOT EXISTS (SELECT ID_serviciu FROM ServiciiDeStreaming WHERE ID_serviciu = @ColumnValue)
	BEGIN
		SET @Mesaj = @Mesaj + 'ID-ul serviciului de streaming este invalid! (Nu exista un serviciu de streaming cu acest ID)' + CHAR(13) + CHAR(10);
	END

    -- Verific daca valoarea coloanei 'Tip_dispozitiv' este valida
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'Tip_dispozitiv');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF dbo.IsNotNull(@ColumnValue) = 0
    BEGIN
        SET @Mesaj = @Mesaj + 'Tipul dispozitivului este invalid!' + CHAR(13) + CHAR(10);
    END

    -- Returnez @Mesaj
    RETURN @Mesaj;
END;



---- 2.5. Functie pentru validarea datelor de intrare pentru tabela "TipuriDeAbonamente" ----

CREATE FUNCTION dbo.IsTipuriDeAbonamenteDataValid
(
    @Columns nvarchar(MAX),   -- Lista de coloane
    @Values nvarchar(MAX)     -- Lista de valori
)
RETURNS VARCHAR(1000) -- Returneaza un mesaj cu lungimea = 0 (daca datele sunt valide) sau un mesaj cu lungimea > 0 (daca datele sunt invalide)
AS
BEGIN
    -- Declar o variabila pentru a stoca mesajul returnat
    DECLARE @Mesaj VARCHAR(1000) = '';
    DECLARE @ColumnList TABLE (ColumnName NVARCHAR(128), RowNum INT);  -- Tabel temporar pentru coloanele furnizate
    DECLARE @ValueList TABLE (ColumnValue NVARCHAR(MAX), RowNum INT); -- Tabel temporar pentru valorile furnizate

    -- Populez tabela temporara @ColumnList cu valorile din @Columns
    INSERT INTO @ColumnList (ColumnName, RowNum)
    SELECT TRIM(value), ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
    FROM STRING_SPLIT(@Columns, ',');

    -- Populez tabela temporara @ValueList cu valorile din @Values
    INSERT INTO @ValueList (ColumnValue, RowNum)
    SELECT TRIM(value), ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
    FROM STRING_SPLIT(@Values, ',');

    -- Verific daca au fost furnizate valori pentru fiecare camp
    IF (SELECT COUNT(*) FROM @ColumnList) != (SELECT COUNT(*) FROM @ValueList)
    BEGIN
        SET @Mesaj = @Mesaj + 'Trebuie furnizate valori pentru toate coloanele!' + CHAR(13) + CHAR(10);
        RETURN @Mesaj
    END

    -- Variabile pentru fiecare coloana si valoarea acesteia
    DECLARE @ColumnPosition INT;
    DECLARE @ColumnValue NVARCHAR(MAX);

   -- Verific daca valoarea coloanei 'ID_serviciu' este valida
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'ID_serviciu');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF NOT EXISTS (SELECT ID_serviciu FROM ServiciiDeStreaming WHERE ID_serviciu = @ColumnValue)
	BEGIN
		SET @Mesaj = @Mesaj + 'ID-ul serviciului de streaming este invalid! (Nu exista un serviciu de streaming cu acest ID)' + CHAR(13) + CHAR(10);
	END

    -- Verific daca valoarea coloanei 'Nume_abonament' este valida
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'Nume_abonament');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF dbo.IsNotNull(@ColumnValue) = 0
    BEGIN
        SET @Mesaj = @Mesaj + 'Numele abonamentului nu este valid!' + CHAR(13) + CHAR(10);
    END

    -- Verific daca valoarea coloanei 'Pret' este valida
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'Pret');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF dbo.IsPretValid(CAST(@ColumnValue AS DECIMAL(5,2))) = 0
    BEGIN
        SET @Mesaj = @Mesaj + 'Pretul abonamentului trebuie sa fie un numar pozitiv!' + CHAR(13) + CHAR(10);
    END

    -- Verific daca valoarea coloanei 'Durata' este valida
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'Durata');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF dbo.IsDurataAbonamentValida(@ColumnValue) = 0
    BEGIN
        SET @Mesaj = @Mesaj + 'Durata este invalida! (Tipuri admise: luna, an)' + CHAR(13) + CHAR(10);
    END

    -- Returnez @Mesaj
    RETURN @Mesaj;
END;




---- 2.6. Functie pentru validarea datelor de intrare pentru tabela "AbonamenteUtilizatori" ----
DROP FUNCTION dbo.IsAbonamenteUtilizatoriDataValid

CREATE FUNCTION dbo.IsAbonamenteUtilizatoriDataValid
(
    @Columns nvarchar(MAX),   -- Lista de coloane
    @Values nvarchar(MAX)     -- Lista de valori
)
RETURNS VARCHAR(1000) -- Returneaza un mesaj cu lungimea = 0 (daca datele sunt valide) sau un mesaj cu lungimea > 0 (daca datele sunt invalide)
AS
BEGIN
    -- Declar o variabila pentru a stoca mesajul returnat
    DECLARE @Mesaj VARCHAR(1000) = '';
    DECLARE @ColumnList TABLE (ColumnName NVARCHAR(128), RowNum INT);  -- Tabel temporar pentru coloanele furnizate
    DECLARE @ValueList TABLE (ColumnValue NVARCHAR(MAX), RowNum INT); -- Tabel temporar pentru valorile furnizate

    -- Populez tabela temporara @ColumnList cu valorile din @Columns
    INSERT INTO @ColumnList (ColumnName, RowNum)
    SELECT TRIM(value), ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
    FROM STRING_SPLIT(@Columns, ',');

    -- Populez tabela temporara @ValueList cu valorile din @Values
    INSERT INTO @ValueList (ColumnValue, RowNum)
    SELECT TRIM(value), ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
    FROM STRING_SPLIT(@Values, ',');

    -- Verific daca au fost furnizate valori pentru fiecare camp
    IF (SELECT COUNT(*) FROM @ColumnList) != (SELECT COUNT(*) FROM @ValueList)
    BEGIN
        SET @Mesaj = @Mesaj + 'Trebuie furnizate valori pentru toate coloanele!' + CHAR(13) + CHAR(10);
        RETURN @Mesaj
    END

    -- Variabile pentru fiecare coloana si valoarea acesteia
    DECLARE @ColumnPosition INT;
    DECLARE @ColumnValue NVARCHAR(MAX);

   -- Verific daca valoarea coloanei 'ID_utilizator' este valida
	SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'ID_utilizator');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

	IF NOT EXISTS (SELECT ID_utilizator FROM Utilizatori WHERE ID_utilizator = @ColumnValue)
	BEGIN
		SET @Mesaj = @Mesaj + 'ID-ul utilizatorului este invalid! (Nu exista un utilizator cu acest ID)' + CHAR(13) + CHAR(10);
	END

    -- Verific daca valoarea coloanei 'ID_tip_abonament' este valida
    SET @ColumnPosition = (SELECT RowNum FROM @ColumnList WHERE ColumnName = 'ID_tip_abonament');
    SET @ColumnValue = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @ColumnPosition);

    IF dbo.ExistaIdTipAbonament(CAST(@ColumnValue AS INT)) = 0
    BEGIN
        SET @Mesaj = @Mesaj + 'Tipul de abonament ales nu exista!' + CHAR(13) + CHAR(10);
    END

    -- Returnez @Mesaj
    RETURN @Mesaj;
END;



---- 2.7. Functie pentru validarea unei coloane din tabela 'Utilizatori' ----

CREATE FUNCTION dbo.IsCamputilizatoriValid
(
	@Camp nvarchar(100),
	@Valoare nvarchar(100)
)
RETURNS varchar(MAX)
AS
BEGIN
	DECLARE @Mesaj varchar(MAX) = '';
	
	IF @Camp = 'Nume'
	BEGIN
		IF dbo.IsNotNull(@Valoare) = 0
		BEGIN
			SET @Mesaj = @Mesaj + 'Numele pentru UPDATE este invalid!';
		END
	END

	IF @Camp = 'Email'
	BEGIN
		IF dbo.IsEmailValid(@Valoare) = 0
		BEGIN
			SET @Mesaj = @Mesaj + 'Email-ul pentru UPDATE este invalid!';
		END
	END

	IF @Camp = 'Parola'
	BEGIN
		IF dbo.IsParolaValid(@Valoare) = 0
		BEGIN
			SET @Mesaj = @Mesaj + 'Parola pentru UPDATE este invalida!';
		END
	END

	IF @Camp = 'Tara'
	BEGIN
		IF dbo.IsNotNull(@Valoare) = 0
		BEGIN
			SET @Mesaj = @Mesaj + 'Tara pentru UPDATE este invalida!';
		END
	END

	RETURN @Mesaj;
END;



---- 2.8. Functie pentru validarea unei coloane din tabela 'DateCard' ----

CREATE FUNCTION dbo.IsCampDateCardValid
(
	@Camp nvarchar(100),
	@Valoare nvarchar(100)
)
RETURNS varchar(MAX)
AS
BEGIN
	DECLARE @Mesaj varchar(MAX) = '';

	IF @Camp = 'Numar_card'
	BEGIN
		IF dbo.IsNumarCardValid(@Valoare) = 0
		BEGIN
			SET @Mesaj = @Mesaj + 'Numarul cardului pentru UPDATE este invalid!';
		END
	END

	IF @Camp = 'Data_expirarii'
	BEGIN
		IF dbo.IsDataExpirariiValid(@Valoare) = 0
		BEGIN
			SET @Mesaj = @Mesaj + 'data expirarii cardului pentru UPDATE este invalida!';
		END
	END

	IF @Camp = 'Nume_detinator'
	BEGIN
		IF dbo.IsNotNull(@Valoare) = 0
		BEGIN
			SET @Mesaj = @Mesaj + 'Numele detinatorului pentru UPDATE este invalid!';
		END
	END

	RETURN @Mesaj;
END;



---- 2.9. Functie pentru validarea unei coloane din tabela 'ServiciiDeStreaming' ----

CREATE FUNCTION dbo.IsCampServiciiDeStreamingValid
(
	@Camp nvarchar(100),
	@Valoare nvarchar(100)
)
RETURNS varchar(MAX)
AS
BEGIN
	DECLARE @Mesaj varchar(MAX) = '';

	IF @Camp = 'Nume_serviciu'
	BEGIN
		IF dbo.IsNumeServiciuDeStreamingValid(@Valoare) = 0
		BEGIN
			SET @Mesaj = @Mesaj + 'Numele serviciului de streaming pentru UPDATE este invalid!';
		END
	END

	IF @Camp = 'Tip_serviciu'
	BEGIN
		IF dbo.IsTipServiciuValid(@Valoare) = 0
		BEGIN
			SET @Mesaj = @Mesaj + 'Tipul serviciului pentru UPDATE este invalid! (Valori permise: audio, video, audio/video)';
		END
	END

	RETURN @Mesaj;
END;



---- 2.10. Functie pentru validarea unei coloane din tabela 'Dispozitive' ----

CREATE FUNCTION dbo.IsCampDispozitiveValid
(
	@Camp nvarchar(100),
	@Valoare nvarchar(100)
)
RETURNS varchar(MAX)
AS
BEGIN
	DECLARE @Mesaj varchar(MAX) = '';

	IF @Camp = 'Tip_dispozitiv'
	BEGIN
		IF dbo.IsNotNull(@Valoare) = 0
		BEGIN
			SET @Mesaj = @Mesaj + 'Tipul dispozitivului pentru UPDATE este invalid!';
		END
	END

	RETURN @Mesaj;
END;



---- 2.11. Functie pentru validarea unei coloane din tabela 'TipuriDeAbonamente' ----

CREATE FUNCTION dbo.IsCampTipuriDeAbonamenteValid
(
	@Camp nvarchar(100),
	@Valoare nvarchar(100)
)
RETURNS varchar(MAX)
AS
BEGIN
	DECLARE @Mesaj varchar(MAX) = '';

	IF @Camp = 'ID_serviciu'
	BEGIN
		IF NOT EXISTS (SELECT ID_serviciu FROM ServiciiDeStreaming WHERE ID_serviciu = @Valoare)
		BEGIN
			SET @Mesaj = @Mesaj + 'ID-ul serviciului pentru UPDATE este invalid!';
		END
	END

	IF @Camp = 'Nume_abonament'
	BEGIN
		IF dbo.IsNotNull(@Valoare) = 0
		BEGIN
			SET @Mesaj = @Mesaj + 'numele abonamentului pentru UPDATE este invalid!';
		END
	END

	IF @Camp = 'Pret'
	BEGIN
		IF dbo.IsPretValid(@Valoare) = 0
		BEGIN
			SET @Mesaj = @Mesaj + 'Pretul pentru UPDATE este invalid!';
		END
	END

	IF @Camp = 'Durata'
	BEGIN
		IF dbo.IsDurataAbonamentValida(@Valoare) = 0
		BEGIN
			SET @Mesaj = @Mesaj + 'Durata abonamentului pentru UPDATE este invalida! (Valori admise: luna, an)';
		END
	END

	IF @Camp = 'Descriere'
	BEGIN
		IF dbo.IsNotNull(@Valoare) = 0
		BEGIN
			SET @Mesaj = @Mesaj + 'Descrierea pentru UPDATE este invalida!';
		END
	END

	RETURN @Mesaj;
END;



---- 2.12. Functie pentru validarea unei coloane din tabela 'AbonamenteUtilizatori' ----

CREATE FUNCTION dbo.IsCampAbonamenteUtilizatoriValid
(
	@Camp nvarchar(100),
	@Valoare nvarchar(100)
)
RETURNS varchar(MAX)
AS
BEGIN
	DECLARE @Mesaj varchar(MAX) = '';

	IF @Camp = 'Data_sfarsit_abonament'
	BEGIN
		IF dbo.IsDataExpirariiValid(@Valoare) = 0
		BEGIN
			SET @Mesaj = @Mesaj + 'Data de sfarsit a abonamentului pentru UPDATE este invalida!';
		END
	END

	IF @Camp = 'Status_abonament'
	BEGIN
		IF @Valoare != 'activ' AND @Valoare != 'suspendat' AND @Valoare != 'expirat'
		BEGIN
			SET @Mesaj = @Mesaj + 'Statusul abonamentului pentru UPDATE este invalid! (Valori admise: activ, suspendat, expirat)';
		END
	END


	RETURN @Mesaj;
END;




----- 3. Tabele ajutatoare pentru operatiile CRUD -----

---- 3.1. Creare tabela TabeleCRUD ----

-- Tabela "TabeleCRUD" contine numele tabelelor pe care se pot executa operatii CRUD
CREATE TABLE TabeleCRUD
( ID_tabelaCRUD INT PRIMARY KEY IDENTITY,
Nume_tabela varchar(50) NOT NULL
)


---- 3.2. Populare tabela TabeleCRUD ----

INSERT INTO TabeleCRUD (Nume_tabela)
VALUES ('Utilizatori'), ('DateCard'), ('ServiciiDeStreaming'), ('Dispozitive'), ('TipuriDeAbonamente'), ('AbonamenteUtilizatori');


SELECT * FROM TabeleCRUD


---- 3.3. Creare tabela AcceptedUpdateCol ----

-- Tabela "AcceptedUpdateCol" contine pentru fiecare tabela coloanele pentru care se poate face UPDATE

CREATE TABLE AcceptedUpdateCol
( ID INT PRIMARY KEY IDENTITY, 
ID_tabelaCRUD INT FOREIGN KEY REFERENCES TabeleCRUD(ID_tabelaCRUD),
Nume_coloana varchar(50) NOT NULL
)


---- 3.4. Populare tabela AcceptedUpdateCol ----

INSERT INTO AcceptedUpdateCol (ID_tabelaCRUD, Nume_coloana)
VALUES (1, 'Nume'), (1,'Email'), (1, 'Parola'), (1,'Tara'),
(2, 'Numar_card'), (2, 'Data_expirarii'), (2, 'Nume_detinator'),
(3, 'Nume_serviciu'), (3, 'Tip_serviciu'),
(4, 'Tip_dispozitiv'),
(5, 'ID_serviciu'), (5, 'Nume_abonament'), (5, 'Pret'), (5, 'Durata'), (5, 'Descriere'),
(6, 'Data_sfarsit_abonament'), (6, 'Status_abonament');


SELECT * FROM AcceptedUpdateCol





----- 4. Operatii CRUD -----


---- 4.1. Operatia CREATE = INSERT ----

DROP PROCEDURE InsertIntoTable

CREATE PROCEDURE InsertIntoTable
    @TableName nvarchar(50), -- Numele tabelei in care vreau sa inserez
    @Columns nvarchar(MAX), -- Lista coloanelor separate prin virgula
    @Values nvarchar(MAX) -- Lista valorilor de inserat separate prin virgula
AS
BEGIN
    SET NOCOUNT ON; -- Suprima afisarea numarului de randuri afectate

    -- Declaram variabile pentru a manipula valorile
    DECLARE @SQL nvarchar(MAX);
    DECLARE @ColumnList TABLE (ColumnName NVARCHAR(128), RowNum INT);
    DECLARE @ValueList TABLE (ColumnValue NVARCHAR(MAX), RowNum INT);

    -- Populam tabelele temporare cu coloanele si valorile
    INSERT INTO @ColumnList (ColumnName, RowNum)
    SELECT TRIM(value), ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
    FROM STRING_SPLIT(@Columns, ',');

    INSERT INTO @ValueList (ColumnValue, RowNum)
    SELECT TRIM(value), ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum
    FROM STRING_SPLIT(@Values, ',');

    -- Verificam daca numarul de coloane corespunde cu numarul de valori
    IF (SELECT COUNT(*) FROM @ColumnList) != (SELECT COUNT(*) FROM @ValueList)
    BEGIN
        PRINT 'Numarul de coloane nu corespunde cu numarul de valori!';
        RETURN;
    END

    -- Construim query-ul INSERT dinamic
    SET @SQL = 'INSERT INTO ' + QUOTENAME(@TableName) + ' (';

    -- Adaugam coloanele in query
    SELECT @SQL = @SQL + QUOTENAME(ColumnName) + ',' 
    FROM @ColumnList;

    -- Stergem ultima virgula adaugata
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 1);

    SET @SQL = @SQL + ') VALUES (';

    -- Adaugam valorile in query, cu ghilimele pentru valorile text
    DECLARE @Value NVARCHAR(MAX);
    DECLARE @RowNum INT = 1;

    WHILE @RowNum <= (SELECT COUNT(*) FROM @ValueList)
    BEGIN
        -- Preluam valoarea curenta
        SET @Value = (SELECT ColumnValue FROM @ValueList WHERE RowNum = @RowNum);

        -- Verificam daca valoarea este text sau numeric
        IF ISNUMERIC(@Value) = 0 -- Valoare de tip text
        BEGIN
            SET @Value = '''' + @Value + ''''; -- Adaugam ghilimele pentru text
        END

        -- Adaugam valoarea in query
        SET @SQL = @SQL + @Value + ',';

        SET @RowNum = @RowNum + 1;
    END

    -- Stergem ultima virgula adaugata
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 1);

    -- Incheiem query-ul
    SET @SQL = @SQL + ')';

    -- Executam query-ul INSERT dinamic
    EXEC sp_executesql @SQL;
END;



-- EXEC InsertIntoTable @TableName = 'Utilizatori', @Columns = 'Nume, Email, Parola, Tara', @Values = ' ''Anca Portocala'', ''anca.portocala@gmail.com'', ''ancaPortocala#4'', ''Austria'' '
-- SELECT * FROM Utilizatori
-- DELETE FROM Utilizatori WHERE Nume = 'Anca Portocala'



---- 4.2. Operatia READ = SELECT ----

CREATE PROCEDURE SelectTableData
	@TableName nvarchar(50)
AS
BEGIN
	DECLARE @SQL nvarchar(MAX)

	-- Creez comanda sql pentru SELECT
	SET @SQL = 'SELECT * FROM ' + QUOTENAME(@TableName)

	-- Execut comanda SQL
	EXEC sp_executesql @SQL
END


-- EXEC SelectTableData @TableName = 'DateCard'



---- 4.3. Operatia UPDATE ----

CREATE PROCEDURE UpdateTableData
	@TableName nvarchar(50),  -- Numele tabelei pe care se face UPDATE

	-- Pentru UPDATE pe un interval
	@Start int = NULL,    -- Inceputul intervalului pentru UPDATE
	@Stop int = NULL,     -- Finalul intervalului pentru UPDATE

	-- Pentru UPDATE pentru o singura inregistrare
	@ID_update int = NULL,    -- ID-ul elementului pentru care vreau sa fac UPDATE

	-- Coloana si valoarea pentru UPDATE
	@Camp_update nvarchar(50),   -- Coloana pe care vreau sa fac update
	@Valoarea_update nvarchar(50),  -- Valoarea cu care vreau sa modific

	-- Pentru tabela AbonamenteUtilizatori
    @ID_tip_abonament int = NULL
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SQL nvarchar(MAX)
	DECLARE @Camp_ID nvarchar(MAX)



	-- Daca trebuie sa fac UPDATE pe tabela 'Utilizatori'
	IF @TableName = 'Utilizatori'
	BEGIN
		SET @Camp_ID = 'ID_utilizator';
	END

	-- Daca trebuie sa fac UPDATE pe tabela 'DateCard'
	IF @TableName = 'DateCard'
	BEGIN
		SET @Camp_ID = 'ID_utilizator';
	END

	-- Daca trebuie sa fac UPDATE pe tabela 'ServiciiDeStreaming'
	IF @TableName = 'ServiciiDeStreaming'
	BEGIN
		SET @Camp_ID = 'ID_serviciu';
	END


	-- Daca trebuie sa fac UPDATE pe tabela 'Dispozitive'
	IF @TableName = 'Dispozitive'
	BEGIN
		SET @Camp_ID = 'ID_dispozitiv';
	END


	-- Daca trebuie sa fac UPDATE pe tabela 'TipuriDeAbonamente'
	IF @TableName = 'TipuriDeAbonamente'
	BEGIN
		SET @Camp_ID = 'ID_tip_abonament';
	END





	-- Daca trebuie sa fac UPDATE pe tabele cu PK simple (necompuse din FK-uri)
	IF @TableName != 'AbonamenteUtilizatori'
	BEGIN
    
		-- UPDATE pentru o singura inregistrare
		IF @ID_update IS NOT NULL
		BEGIN
			SET @SQL = 'UPDATE ' + QUOTENAME(@TableName) + 
				       ' SET ' + QUOTENAME(@Camp_update) + ' = @Valoarea_update' + 
					   ' WHERE ' + QUOTENAME(@Camp_ID) + ' = @ID_update;';

			EXEC sp_executesql @SQL, N'@Valoarea_update NVARCHAR(50), @ID_update INT', @Valoarea_update, @ID_update;
		END
    
		-- UPDATE pentru un interval de inregistrari
		ELSE IF @Start IS NOT NULL AND @Stop IS NOT NULL
		BEGIN
			SET @SQL = 'WITH NumberedRows AS (
				            SELECT ROW_NUMBER() OVER (ORDER BY ' + QUOTENAME(@Camp_ID) + ') AS RowNum, ' + QUOTENAME(@Camp_ID) + '
					        FROM ' + QUOTENAME(@TableName) + '
						)
						UPDATE ' + QUOTENAME(@TableName) + '
						SET ' + QUOTENAME(@Camp_update) + ' = @Valoarea_update
						WHERE ' + QUOTENAME(@Camp_ID) + ' IN (
							SELECT ' + QUOTENAME(@Camp_ID) + '
							FROM NumberedRows
							WHERE RowNum BETWEEN @Start AND @Stop
						);';

			EXEC sp_executesql @SQL, N'@Valoarea_update NVARCHAR(50), @Start INT, @Stop INT', @Valoarea_update, @Start, @Stop;
		END
	END



	-- Daca trebuie sa fac UPDATE pe tabela 'AbonamenteUtilizatori'
	IF @TableName = 'AbonamenteUtilizatori'
	BEGIN

		-- UPDATE pentru o singura inregistrare
		IF @ID_update IS NOT NULL
		BEGIN
			SET @SQL = 'UPDATE AbonamenteUtilizatori SET ' + QUOTENAME(@Camp_update) + ' = @Valoarea_update WHERE ID_utilizator = @ID_update AND ID_tip_abonament = @ID_tip_abonament;'

			EXEC sp_executesql @SQL, N'@Valoarea_update NVARCHAR(50), @ID_update INT, @ID_tip_abonament INT', @Valoarea_update, @ID_update, @ID_tip_abonament;
		END

		-- UPDATE pentru un interval de inregistrari
		ELSE IF @Start IS NOT NULL AND @Stop IS NOT NULL
		BEGIN
			SET @SQL = 'WITH NumberedRows AS (
							SELECT ROW_NUMBER() OVER (ORDER BY ID_utilizator, ID_tip_abonament) AS RowNum, ID_utilizator, ID_tip_abonament
							FROM AbonamenteUtilizatori
						)
						UPDATE AbonamenteUtilizatori
						SET ' + QUOTENAME(@Camp_update) + ' = @Valoarea_update
						WHERE EXISTS (
							SELECT 1
							FROM NumberedRows
							WHERE NumberedRows.RowNum BETWEEN @Start AND @Stop
									AND NumberedRows.ID_utilizator = AbonamenteUtilizatori.ID_utilizator
									AND NumberedRows.ID_tip_abonament = AbonamenteUtilizatori.ID_tip_abonament
                );';

			EXEC sp_executesql @SQL, N'@Valoarea_update NVARCHAR(50), @Start INT, @Stop INT', @Valoarea_update, @Start, @Stop;
		END
	END

END;


-- EXEC UpdateTableData @TableName = 'Utilizatori', @ID_update = 1, @Camp_update = 'Tara', @Valoarea_update = 'Italy'
-- EXEC UpdateTableData @TableName = 'Utilizatori', @Camp_update = 'Tara', @Valoarea_update = 'Italy', @Start = 5, @Stop = 10
-- SELECT * FROM Utilizatori

-- EXEC UpdateTableData @TableName = 'DateCard', @ID_update = 1, @Camp_update = 'Nume_detinator', @Valoarea_update = 'Negru Adina'
-- EXEC UpdateTableData @TableName = 'DateCard', @Camp_update = 'Data_expirarii', @Valoarea_update = '2040-02-13', @Start = 3, @Stop = 5
-- SELECT * FROM DateCard

-- EXEC UpdateTableData @TableName = 'ServiciiDeStreaming', @ID_update = 1, @Camp_update = 'Nume_serviciu', @Valoarea_update = 'Netflix_CRUD'
-- EXEC UpdateTableData @TableName = 'ServiciiDeStreaming', @Camp_update = 'Tip_serviciu', @Valoarea_update = 'audio', @Start = 3, @Stop = 20
-- SELECT * FROM ServiciiDeStreaming

-- EXEC UpdateTableData @TableName = 'Dispozitive', @ID_update = 1, @Camp_update = 'Tip_dispozitiv', @Valoarea_update = 'tableta_CRUD'
-- EXEC UpdateTableData @TableName = 'Dispozitive', @Camp_update = 'Tip_dispozitiv', @Valoarea_update = 'telefon_CRUD', @Start = 3, @Stop = 20
-- SELECT * FROM Dispozitive

-- EXEC UpdateTableData @TableName = 'TipuriDeAbonamente', @ID_update = 1, @Camp_update = 'Descriere', @Valoarea_update = 'CRUD'
-- EXEC UpdateTableData @TableName = 'TipuriDeAbonamente', @Camp_update = 'Pret', @Valoarea_update = '1.00', @Start = 10, @Stop = 20
-- SELECT * FROM TipuriDeAbonamente

-- EXEC UpdateTableData @TableName = 'AbonamenteUtilizatori', @ID_update = 1, @ID_tip_abonament = 23 , @Camp_update = 'Status_abonament', @Valoarea_update = 'suspendat'
-- EXEC UpdateTableData @TableName = 'AbonamenteUtilizatori', @Camp_update = 'Data_sfarsit_abonament', @Valoarea_update = '2050-12-14', @Start = 10, @Stop = 20
-- SELECT * FROM AbonamenteUtilizatori




---- 4.4. Operatia DELETE ----

DROP PROCEDURE DeleteFromTable


CREATE PROCEDURE DeleteFromTable
(
    @TableName NVARCHAR(100),   -- Numele tabelei din care vreau sa execut stergerea
    
	-- Daca vreau sa sterg dupa un ID dat
	@ID_delete INT = NULL,  
	
	-- Daca vreau sa sterg inergistrarile dintr-un interval
    @Start INT = NULL,          
    @Stop INT = NULL,

	-- Daca vreau sa sterg in functie de o conditie
    @Camp_conditie NVARCHAR(100) = NULL, 
    @Valoarea_conditie NVARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @PrimaryKeyColumn NVARCHAR(128);

    -- Determin PK a tabelei
    SELECT TOP 1 @PrimaryKeyColumn = COLUMN_NAME
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
    WHERE TABLE_NAME = @TableName AND OBJECTPROPERTY(OBJECT_ID(CONSTRAINT_NAME), 'IsPrimaryKey') = 1;

    IF @PrimaryKeyColumn IS NULL
    BEGIN
        RAISERROR('Tabela specificata nu are definita o cheie primara.', 16, 1);
        RETURN;
    END

    -- Dezactivez constrangerile FK
    EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

    -- Construiesc stergerea din tabela principala
    SET @SQL = 'DELETE FROM ' + @TableName;

    IF @ID_delete IS NOT NULL
        SET @SQL = @SQL + ' WHERE ' + @PrimaryKeyColumn + ' = ' + CAST(@ID_delete AS NVARCHAR);
    ELSE IF @Start IS NOT NULL AND @Stop IS NOT NULL
        SET @SQL = @SQL + ' WHERE ' + @PrimaryKeyColumn + ' BETWEEN ' + CAST(@Start AS NVARCHAR) + ' AND ' + CAST(@Stop AS NVARCHAR);
    ELSE IF @Camp_conditie IS NOT NULL AND @Valoarea_conditie IS NOT NULL
        SET @SQL = @SQL + ' WHERE ' + @Camp_conditie + ' = ''' + @Valoarea_conditie + '''';

    EXEC sp_executesql @SQL;
END;





--- Exemple pentru stergere din tabele simple (care nu transmit FK la alte tabele)
-- EXEC DeleteFromTable @TableName = 'DateCard', @ID_delete = 1
-- EXEC DeleteFromTable @TableName = 'DateCard', @Start = 4, @Stop = 6
-- EXEC DeleteFromTable @TableName = 'DateCard', @Camp_conditie = 'Data_expirarii', @Valoarea_conditie = '2025-09-30'
-- SELECT * FROM DateCard

--- Exemple pentru stergere din tabele care transmit FK la alte tabele
-- EXEC DeleteFromTable @TableName = 'Utilizatori', @ID_delete = 1
-- EXEC DeleteFromTable @TableName = 'Utilizatori', @Start = 4, @Stop = 6
-- EXEC DeleteFromTable @TableName = 'Utilizatori', @Camp_conditie = 'Tara', @Valoarea_conditie = 'Italy'
-- SELECT * FROM Utilizatori




---- 4.5. Procedura finala ----

-- TREBUIE VALIDATI PARAMETRII DE INTRARE, EXISTA PARAMETRII DE INTRARE PENTRU FIECARE OPERATIE CRUD
-- TREBUIE FACUT SELECT PE FIECARE TABELA PENTRU A OBSERVA CA S-A EXECUTAT OPERATIA CRUD

DROP PROCEDURE ExecuteCRUD

CREATE PROCEDURE ExecuteCRUD
(
	-- Numele tabelei pe care se executa operatiile CRUD
	@TableName nvarchar(100),   -- Daca e singurul parametru introdus se face READ = SELECT


	-- Parametrii pentru operatia CREATE = INSERT
	@Columns nvarchar(MAX) = NULL, -- Lista coloanelor separate prin virgula
	@Values nvarchar(MAX) = NULL, -- Lista valorilor de inserat separate prin virgula



	-- Parametrii pentru operatia UPDATE

	-- Pentru UPDATE pe un interval
	@Start_update int = NULL,    -- Inceputul intervalului pentru UPDATE
	@Stop_update int = NULL,     -- Finalul intervalului pentru UPDATE

	-- Pentru UPDATE pentru o singura inregistrare
	@ID_update int = NULL,    -- ID-ul elementului pentru care vreau sa fac UPDATE
    @ID_tip_abonament_update int = NULL,    -- Pentru tabela AbonamenteUtilizatori (UPDATE)

	-- Coloana si valoarea pentru UPDATE
	@Camp_update nvarchar(50) = NULL,   -- Coloana pe care vreau sa fac update
	@Valoarea_update nvarchar(50) = NULL,  -- Valoarea cu care vreau sa modific



	-- Parametrii pentru DELETE

	-- Daca vreau sa sterg dupa un ID dat
	@ID_delete INT = NULL, 

	-- Daca vreau sa sterg inregistrarile dintr-un interval
	@Start_delete INT = NULL,
	@Stop_delete INT = NULL,

	-- Daca vreau sa sterg in functie de o conditie
	@Camp_conditie_delete NVARCHAR(100) = NULL,
	@Valoarea_conditie_delete NVARCHAR(100) = NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Rez varchar(MAX);

	-- Verific daca @TableName este valid
	IF dbo.IsTabelaValida(@TableName) = 0
	BEGIN
		PRINT 'Tabela aleasa nu face parte din tabelele pe care se pot executa operatii CRUD!';

		SELECT Nume_tabela AS 'Tabele acceptate pentru operatiile CRUD'
		FROM TabeleCRUD

		RETURN;
	END

	-- Afisez continutul tabelului inainte de modificari (READ = SELECT)
	EXEC SelectTableData @TableName = @TableName


	-- Daca se doreste executarea operatiei CREATE = INSERT
	-- Parametrii INSERT: @Columns, @Values
	IF dbo.IsNotNull(@Columns) = 1 AND dbo.IsNotNull(@Values) = 1 -- Verific daca s-au furnizat parametrii pentru INSERT
	BEGIN
		SET @Rez = dbo.IsColumnsTableValid(@TableName, @Columns);  -- Verific daca coloanele alese pentru inserare sunt valide
		
		IF LEN(@Rez) > 0
		BEGIN
			PRINT 'NU SE POATE EXECUTA INSERAREA IN TABEL DOARECE: ' + CHAR(13) + CHAR(10);
			PRINT @Rez

			RETURN;
		END

		-- Daca tabele pentru inserare este tabela 'Utilizatori'
		IF @TableName = 'Utilizatori'
		BEGIN
			SET @Rez = dbo.IsUtilizatoriDataValid(@Columns, @Values)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA INSERAREA IN TABELA ''Utilizatori'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END
		END


		-- Daca tabela pentru inserare este tabela 'DateCard'
		IF @TableName = 'DateCard'
		BEGIN
			SET @Rez = dbo.IsDateCardDataValid(@Columns, @Values)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA INSERAREA IN TABELA ''DateCard'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END
		END

		-- Daca tabela pentru inserare este tabela 'ServiciiDeStreaming'
		IF @TableName = 'ServiciiDeStreaming'
		BEGIN
			SET @Rez = dbo.IsServiciiDeStreamingDataValid(@Columns, @Values)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA INSERAREA IN TABELA ''ServiciiDeStreaming'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END
		END

		-- Daca tabela pentru inserare este tabela 'Dispozitive'
		IF @TableName = 'Dispozitive'
		BEGIN
			SET @Rez = dbo.IsDispozitiveDataValid(@Columns, @Values)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA INSERAREA IN TABELA ''Dispozitive'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END
		END


		-- Daca tabela pentru inserare este tabela 'TipuriDeAbonamente'
		IF @TableName = 'TipuriDeAbonamente'
		BEGIN
			SET @Rez = dbo.IsTipuriDeAbonamenteDataValid(@Columns, @Values)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA INSERAREA IN TABELA ''TipuriDeAbonamente'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END
		END


		-- Daca tabela pentru inserare este tabela 'AbonamenteUtilizatori'
		IF @TableName = 'AbonamenteUtilizatori'
		BEGIN
			SET @Rez = dbo.IsAbonamenteUtilizatoriDataValid(@Columns, @Values)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA INSERAREA IN TABELA ''AbonamenteUtilizatori'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END
		END


		-- Executarea inserarii
		EXEC InsertIntoTable @TableName = @TableName, @Columns = @Columns, @Values = @Values


		-- Afisez continutul tabelului dupa INSERARE
		EXEC SelectTableData @TableName = @TableName
	END

	

	-- Daca se doreste executarea operatiei UPDATE
	-- Parametrii UPDATE pe un interval: @Start_update, @Stop_update
	-- Parametrii UPDATE pentru o singura inregistrare: @ID_update, @ID_tip_abonament_update (daca PK e format din 2 FK)
	-- Parametrii UPDATE pentru coloana si valoare (obligatorii atat pentru interval cat si pentru o sinura inregistrare): @Camp_update, @Valoarea_update

	-- Verific daca se doreste update pentru un interval
	IF @Start_update IS NOT NULL AND @Stop_update IS NOT NULL
	BEGIN
		IF @Camp_update IS NULL OR @Valoarea_update IS NULL
		BEGIN
			PRINT 'Nu se poate face UPDATE daca nu dati valorile @Camp_update si @Valoarea_update!';

			RETURN;
		END


		IF dbo.IsAcceptedUpdate(@TableName, @Camp_update) = 0  -- Verific daca coloana pe care vreau sa fac UPDATE este permisa
		BEGIN
			PRINT 'Nu se poate face UPDATE pe coloana aleasa!';

			RETURN;
		END


		-- Daca tabele pentru update este tabela 'Utilizatori'
		IF @TableName = 'Utilizatori'
		BEGIN
			SET @Rez = dbo.IsCamputilizatoriValid(@Camp_update, @Valoarea_update)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA UPDATE IN TABELA ''Utilizatori'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END
		END


		-- Daca tabela pentru update este tabela 'DateCard'
		IF @TableName = 'DateCard'
		BEGIN
			SET @Rez = dbo.IsCampDateCardValid(@Camp_update, @Valoarea_update)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA UPDATE IN TABELA ''DateCard'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END
		END


		-- Daca tabela pentru update este tabela 'ServiciiDeStreaming'
		IF @TableName = 'ServiciiDeStreaming'
		BEGIN
			SET @Rez = dbo.IsCampServiciiDeStreamingValid(@Camp_update, @Valoarea_update)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA UPDATE IN TABELA ''ServiciiDeStreaming'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END
		END

		-- Daca tabela pentru update este tabela 'Dispozitive'
		IF @TableName = 'Dispozitive'
		BEGIN
			SET @Rez = dbo.IsCampDispozitiveValid(@Camp_update, @Valoarea_update)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA UPDATE IN TABELA ''Dispozitive'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END
		END


		-- Daca tabela pentru update este tabela 'TipuriDeAbonamente'
		IF @TableName = 'TipuriDeAbonamente'
		BEGIN
			SET @Rez = dbo.IsCampTipuriDeAbonamenteValid(@Camp_update, @Valoarea_update)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA UPDATE IN TABELA ''TipuriDeAbonamente'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END
		END


		-- Daca tabela pentru update este tabela 'AbonamenteUtilizatori'
		IF @TableName = 'AbonamenteUtilizatori'
		BEGIN
			SET @Rez = dbo.IsCampAbonamenteUtilizatoriValid(@Camp_update, @Valoarea_update)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA UPDATE IN TABELA ''AbonamenteUtilizatori'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END
		END

		-- Executarea inserarii
		EXEC UpdateTableData @TableName = @TableName, @Start = @Start_update, @Stop = @Stop_update, @Camp_update = @Camp_update, @Valoarea_update = @Valoarea_update


		-- Afisez continutul tabelului dupa UPDATE
		EXEC SelectTableData @TableName = @TableName
	END


	-- Verific daca se doreste update pentru o singura inregistrare
	--> Pentru tabela 'AbonamenteUtilizatori'
	IF @ID_update IS NOT NULL AND @ID_tip_abonament_update IS NOT NULL
	BEGIN
		IF @Camp_update IS NULL OR @Valoarea_update IS NULL
		BEGIN
			PRINT 'Nu se poate face UPDATE daca nu dati valorile @Camp_update si @Valoarea_update!';

			RETURN;
		END


		IF dbo.IsAcceptedUpdate(@TableName, @Camp_update) = 0  -- Verific daca coloana pe care vreau sa fac UPDATE este permisa
		BEGIN
			PRINT 'Nu se poate face UPDATE pe coloana aleasa!';

			RETURN;
		END

		-- Verific daca ID-urile sunt valide
		IF NOT EXISTS(SELECT * FROM AbonamenteUtilizatori WHERE ID_utilizator = @ID_update AND ID_tip_abonament = @ID_tip_abonament_update)
		BEGIN
			PRINT 'Nu exista o inregistrare cu ID-urile date in tabela AbonamenteUtilizatori pentru a putea face UPDATE!' + CHAR(13) + CHAR(10);
			RETURN;
		END

		-- Daca tabela pentru update este tabela 'AbonamenteUtilizatori'
		IF @TableName = 'AbonamenteUtilizatori'
		BEGIN
			SET @Rez = dbo.IsCampAbonamenteUtilizatoriValid(@Camp_update, @Valoarea_update)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA UPDATE IN TABELA ''AbonamenteUtilizatori'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END
		END

		-- Executarea inserarii
		EXEC UpdateTableData @TableName = @TableName, @ID_update = @ID_update, @ID_tip_abonament = @ID_tip_abonament_update, @Camp_update = @Camp_update, @Valoarea_update = @Valoarea_update


		-- Afisez continutul tabelului dupa UPDATE
		EXEC SelectTableData @TableName = @TableName
	END

	-- Mesaj de eroare daca se doreste UPDATE pe tabela AbonamenteUtilizatori si nu s-a furnizat @ID_tip_abonament_update
	IF @TableName = 'AbonamenteUtilizatori' AND @ID_update IS NOT NULL AND @ID_tip_abonament_update IS NULL
	BEGIN
		PRINT 'Pentru a face UPDATE  pe tabela AbonamenteUtilizatori trebuie furnizat si @ID_tip_abonament_update!' + CHAR(13) + CHAR(10);
		RETURN;
	END

	--> Pentru restul tabelelor
	IF @ID_update IS NOT NULL AND @TableName != 'AbonamenteUtilizatori'
	BEGIN
		IF @Camp_update IS NULL OR @Valoarea_update IS NULL
		BEGIN
			PRINT 'Nu se poate face UPDATE daca nu dati valorile @Camp_update si @Valoarea_update!';

			RETURN;
		END


		IF dbo.IsAcceptedUpdate(@TableName, @Camp_update) = 0  -- Verific daca coloana pe care vreau sa fac UPDATE este permisa
		BEGIN
			PRINT 'Nu se poate face UPDATE pe coloana aleasa!';

			RETURN;
		END

		-- Daca tabela pentru update este tabela 'Utilizatori'
		IF @TableName = 'Utilizatori'
		BEGIN
			SET @Rez = dbo.IsCamputilizatoriValid(@Camp_update, @Valoarea_update)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA UPDATE IN TABELA ''Utilizatori'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END

			-- Verific daca ID-ul este valid
			IF NOT EXISTS (SELECT * FROM Utilizatori WHERE ID_utilizator = @ID_update)
			BEGIN
				PRINT 'Nu exista o inregistrare cu ID-urile date in tabela Utilizatori pentru a putea face UPDATE!' + CHAR(13) + CHAR(10);
				RETURN;
			END
		END


		-- Daca tabela pentru update este tabela 'DateCard'
		IF @TableName = 'DateCard'
		BEGIN
			SET @Rez = dbo.IsCampDateCardValid(@Camp_update, @Valoarea_update)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA UPDATE IN TABELA ''DateCard'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END

			-- Verific daca ID-ul este valid
			IF NOT EXISTS (SELECT * FROM DateCard WHERE ID_utilizator = @ID_update)
			BEGIN
				PRINT 'Nu exista o inregistrare cu ID-urile date in tabela DateCard pentru a putea face UPDATE!' + CHAR(13) + CHAR(10);
				RETURN;
			END
		END


		-- Daca tabela pentru update este tabela 'ServiciiDeStreaming'
		IF @TableName = 'ServiciiDeStreaming'
		BEGIN
			SET @Rez = dbo.IsCampServiciiDeStreamingValid(@Camp_update, @Valoarea_update)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA UPDATE IN TABELA ''ServiciiDeStreaming'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END

			-- Verific daca ID-ul este valid
			IF NOT EXISTS (SELECT * FROM ServiciiDeStreaming WHERE ID_serviciu = @ID_update)
			BEGIN
				PRINT 'Nu exista o inregistrare cu ID-urile date in tabela ServiciiDeStreaming pentru a putea face UPDATE!' + CHAR(13) + CHAR(10);
				RETURN;
			END
		END

		-- Daca tabela pentru update este tabela 'Dispozitive'
		IF @TableName = 'Dispozitive'
		BEGIN
			SET @Rez = dbo.IsCampDispozitiveValid(@Camp_update, @Valoarea_update)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA UPDATE IN TABELA ''Dispozitive'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END

			-- Verific daca ID-ul este valid
			IF NOT EXISTS (SELECT * FROM Dispozitive WHERE ID_dispozitiv = @ID_update)
			BEGIN
				PRINT 'Nu exista o inregistrare cu ID-urile date in tabela Dispozitive pentru a putea face UPDATE!' + CHAR(13) + CHAR(10);
				RETURN;
			END
		END


		-- Daca tabela pentru update este tabela 'TipuriDeAbonamente'
		IF @TableName = 'TipuriDeAbonamente'
		BEGIN
			SET @Rez = dbo.IsCampTipuriDeAbonamenteValid(@Camp_update, @Valoarea_update)

			IF LEN(@Rez) > 0
			BEGIN
				PRINT 'NU SE POATE EXECUTA UPDATE IN TABELA ''TipuriDeAbonamente'' DOARECE: ' + CHAR(13) + CHAR(10);
				PRINT @Rez

				RETURN;
			END

			-- Verific daca ID-ul este valid
			IF NOT EXISTS (SELECT * FROM TipuriDeAbonamente WHERE ID_serviciu = @ID_update)
			BEGIN
				PRINT 'Nu exista o inregistrare cu ID-urile date in tabela TipuriDeAbonamente pentru a putea face UPDATE!' + CHAR(13) + CHAR(10);
				RETURN;
			END
		END

		-- Executarea inserarii
		EXEC UpdateTableData @TableName = @TableName, @ID_update = @ID_update, @Camp_update = @Camp_update, @Valoarea_update = @Valoarea_update


		-- Afisez continutul tabelului dupa UPDATE
		EXEC SelectTableData @TableName = @TableName
	END


	-- Daca se doreste executarea operatiei DELETE
	-- Parametrii pentru stergerea dup un ID dat: @ID_delete
	-- Parametrii pentru stergerea inregistrarilor dintr-un interval: @Start_delete, @Stop_delete
	-- parametrii pentru stergerea dupa o valoare data a unui camp: @Camp_conditie_delete, @Valoarea_conditie_delete

	--> Pentru stergerea dupa un ID dat
	IF @ID_delete IS NOT NULL
	BEGIN
		EXEC DeleteFromTable @TableName = @TableName, @ID_delete = @ID_delete

		-- Afisez continutul tabelului dupa DELETE
		EXEC SelectTableData @TableName = @TableName
	END

	--> Pentru stergerea inregistrarilor dintr-un interval
	IF @Start_delete IS NOT NULL AND @Stop_delete IS NOT NULL
	BEGIN
		EXEC DeleteFromTable @TableName = @TableName, @Start = @Start_delete, @Stop = @Stop_delete

		-- Afisez continutul tabelului dupa DELETE
		EXEC SelectTableData @TableName = @TableName
	END 

	--> Pentru stergerea dupa o valoare data a unui camp
	IF @Camp_conditie_delete IS NOT NULL AND @Valoarea_conditie_delete IS NOT NULL
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @TableName AND COLUMN_NAME = @Camp_conditie_delete)
		BEGIN
			PRINT 'Campul dupa care doriti sa stergeti nu este valid!' + CHAR(13) + CHAR(10);
			RETURN;
		END

		EXEC DeleteFromTable @TableName = @TableName, @Camp_conditie = @Camp_conditie_delete, @Valoarea_conditie = @Valoarea_conditie_delete

		-- Afisez continutul tabelului dupa DELETE
		EXEC SelectTableData @TableName = @TableName
	END

END;





--- Exemple pentru READ = SELECT
EXEC ExecuteCRUD @TableName = 'Facturi'   -- NU face parte din tabelele valide
EXEC ExecuteCRUD @TableName = 'DateCard'
EXEC ExecuteCRUD @TableName = 'Utilizatori'
EXEC ExecuteCRUD @TableName = 'ServiciiDeStreaming'
EXEC ExecuteCRUD @TableName = 'Dispozitive'
EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente'
EXEC ExecuteCRUD @TableName = 'AbonamenteUtilizatori'


--- Exemple pentru CREATE = INSERT
EXEC ExecuteCRUD @TableName = 'Utilizatori', @Columns = 'Nume, Prenume, Tara, ID_utilizator', @Values = 'a, b, c, 1'   -- NU sunt corecte coloanele
EXEC ExecuteCRUD @TableName = 'Utilizatori', @Columns = 'Nume, Email, Tara, Parola', @Values = 'Anca Blancos,anca.blancos@yahoo.com, Grecia, 12345678'
EXEC ExecuteCRUD @TableName = 'Utilizatori', @Columns = 'Nume, Email, Tara, Parola', @Values = 'Negru Diana,@yahoo.com, Romania, 12345678'  -- NU sunt corecte valorile
EXEC ExecuteCRUD @TableName = 'Utilizatori', @Columns = 'Nume, Email, Tara, Parola', @Values = 'diana_negru@yahoo.com, Romania, 12345678'  -- NU sunt complete valorile

EXEC ExecuteCRUD @TableName = 'DateCard', @Columns = 'Nume, Prenume, Tara, ID_utilizator', @Values = 'a, b, c, 1'   -- NU sunt corecte coloanele
EXEC ExecuteCRUD @TableName = 'DateCard', @Columns = 'ID_utilizator, Numar_card, Data_expirarii, Nume_detinator', @Values = '-1, 124973, 2020-03-01, diana'   -- NU sunt corecte valorile
EXEC ExecuteCRUD @TableName = 'DateCard', @Columns = 'ID_utilizator, Numar_card, Data_expirarii, Nume_detinator', @Values = '11, 1234-5678-1234-5678, 2050-03-01, Anca Blank'  -- ID invalid
EXEC ExecuteCRUD @TableName = 'DateCard', @Columns = 'ID_utilizator, Numar_card, Data_expirarii, Nume_detinator', @Values = '44, 1234-1234-1234-1234, 2050-08-12, Anca Blancos'


EXEC ExecuteCRUD @TableName = 'ServiciiDeStreaming', @Columns = 'ID_utilizator, Numar_card, Data_expirarii, Nume_detinator', @Values = '11, 1234-5678-1234-5678, 2050-03-01, a'  -- NU sunt corecte coloanele
EXEC ExecuteCRUD @TableName = 'ServiciiDeStreaming', @Columns = 'Nume_serviciu', @Values = '11, 1234-5678-1234-5678, 2050-03-01, a' -- NU sunt corecte coloanele
EXEC ExecuteCRUD @TableName = 'ServiciiDeStreaming', @Columns = 'Nume_serviciu, Tip_serviciu', @Values = 'Netflix, audio/'  -- NU sunt corecte valorile
EXEC ExecuteCRUD @TableName = 'ServiciiDeStreaming', @Columns = 'Nume_serviciu, Tip_serviciu', @Values = 'Boom, audio'

EXEC ExecuteCRUD @TableName = 'Dispozitive', @Columns = 'ID_utilizator, Tip_serviciu, ID_serviciu', @Values = 'Netflix, audio/'  -- NU sunt corecte coloanele
EXEC ExecuteCRUD @TableName = 'Dispozitive', @Columns = 'ID_utilizator, Tip_dispozitiv, ID_serviciu', @Values = 'Netflix, audio/'   -- NU sunt complete valorile
EXEC ExecuteCRUD @TableName = 'Dispozitive', @Columns = 'ID_utilizator, Tip_dispozitiv, ID_serviciu', @Values = '11, telefon2, 8' 

EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente', @Columns = 'ID_serviciu, Durata, Descriere', @Values = '11, laptop, 8' -- NU sunt corecte coloanele
EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente', @Columns = 'ID_serviciu, Durata, Descriere, Nume_abonament, Pret', @Values = '11, laptop, 8' -- NU sunt complete valorile
EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente', @Columns = 'ID_serviciu, Durata, Descriere, Nume_abonament, Pret', @Values = '1, 1, -, hello, -1'  -- NU sunt corecte valorile
EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente', @Columns = 'ID_serviciu, Durata, Descriere, Nume_abonament, Pret', @Values = '1, an, abonament, hello, 15.00'

EXEC ExecuteCRUD @TableName = 'AbonamenteUtilizatori', @Columns = 'ID_serviciu, Nume_abonament', @Values = '1, m'  -- NU sunt corecte coloanele
EXEC ExecuteCRUD @TableName = 'AbonamenteUtilizatori', @Columns = 'ID_utilizator, ID_tip_abonament', @Values = '-1, 0'  -- NU sunt corecte valorile
EXEC ExecuteCRUD @TableName = 'AbonamenteUtilizatori', @Columns = 'ID_utilizator, ID_tip_abonament', @Values = '44, 5'  


--- Exemple pentru UPDATE  (SELECT * FROM AcceptedUpdateCol)

--> UPDATE pe un interval
EXEC ExecuteCRUD @TableName = 'Utilizatori', @Start_update = 1, @Stop_update = 5, @Camp_update = 'ID_utilizator', @Valoarea_update = 13   -- Coloana invalida pentru UPDATE
EXEC ExecuteCRUD @TableName = 'Utilizatori', @Start_update = 1, @Stop_update = 5, @Camp_update = 'Tara', @Valoarea_update = 'Germany'

EXEC ExecuteCRUD @TableName = 'DateCard', @Start_update = 1, @Stop_update = 5, @Camp_update = 'ID_utilizator', @Valoarea_update = 13   -- Coloana invalida pentru UPDATE
EXEC ExecuteCRUD @TableName = 'DateCard', @Start_update = 1, @Stop_update = 5, @Camp_update = 'Data_expirarii', @Valoarea_update = '2020-12-12'  -- Valoare invalida
EXEC ExecuteCRUD @TableName = 'DateCard', @Start_update = 1, @Stop_update = 5, @Camp_update = 'Data_expirarii', @Valoarea_update = '2050-12-12'

EXEC ExecuteCRUD @TableName = 'ServiciiDeStreaming', @Start_update = 1, @Stop_update = 5, @Camp_update = 'ID_serviciu', @Valoarea_update = 12  -- Coloana invalida pentru UPDATE
EXEC ExecuteCRUD @TableName = 'ServiciiDeStreaming', @Start_update = 1, @Stop_update = 5, @Camp_update = 'Tip_serviciu', @Valoarea_update = 'video/audio '   -- Valoare invalida
EXEC ExecuteCRUD @TableName = 'ServiciiDeStreaming', @Start_update = 1, @Stop_update = 5, @Camp_update = 'Tip_serviciu', @Valoarea_update = 'Video'

EXEC ExecuteCRUD @TableName = 'Dispozitive', @Start_update = 1, @Stop_update = 5, @Camp_update = 'ID_serviciu', @Valoarea_update = 11    -- Coloana invalida pentru UPDATE
EXEC ExecuteCRUD @TableName = 'Dispozitive', @Start_update = 1, @Stop_update = 5, @Camp_update = 'Tip_dispozitiv', @Valoarea_update = ''     -- Valoare invalida
EXEC ExecuteCRUD @TableName = 'Dispozitive', @Start_update = 1, @Stop_update = 5, @Camp_update = 'Tip_dispozitiv', @Valoarea_update = 'calculator'

EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente', @Start_update = 1, @Stop_update = 5, @Camp_update = 'ID_tip_abonament', @Valoarea_update = 11   -- Coloana invalida pentru UPDATE
EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente', @Start_update = 1, @Stop_update = 5, @Camp_update = 'Nume_abonament', @Valoarea_update = ''   -- Valoare invalida
EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente', @Start_update = 1, @Stop_update = 5, @Camp_update = 'ID_serviciu', @Valoarea_update = 50   -- Valoare invalida
EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente', @Start_update = 1, @Stop_update = 5, @Camp_update = 'ID_serviciu', @Valoarea_update = 8  

EXEC ExecuteCRUD @TableName = 'AbonamenteUtilizatori', @Start_update = 1, @Stop_update = 5, @Camp_update = 'ID_utilizator', @Valoarea_update = 8   -- Coloana invalida pentru UPDATE
EXEC ExecuteCRUD @TableName = 'AbonamenteUtilizatori', @Start_update = 1, @Stop_update = 5, @Camp_update = 'Status_abonament', @Valoarea_update = 'inactiv'   -- Valoare invalida
EXEC ExecuteCRUD @TableName = 'AbonamenteUtilizatori', @Start_update = 1, @Stop_update = 5, @Camp_update = 'Status_abonament', @Valoarea_update = 'suspendat'


--> UPDATE pentru o singura inregistrare
EXEC ExecuteCRUD @TableName = 'Utilizatori', @ID_update = 1, @Camp_update = 'ID_utilizator', @Valoarea_update = 13   -- Coloana invalida pentru UPDATE
EXEC ExecuteCRUD @TableName = 'Utilizatori', @ID_update = 1000, @Camp_update = 'Tara', @Valoarea_update = 'Italy'   -- ID invalid
EXEC ExecuteCRUD @TableName = 'Utilizatori', @ID_update = 11, @Camp_update = 'Tara', @Valoarea_update = 'Italy'

EXEC ExecuteCRUD @TableName = 'DateCard', @ID_update = 1, @Camp_update = 'ID_utilizator', @Valoarea_update = 13   -- Coloana invalida pentru UPDATE
EXEC ExecuteCRUD @TableName = 'DateCard', @ID_update = 1, @Camp_update = 'Data_expirarii', @Valoarea_update = '2020-12-12'  -- Valoare invalida
EXEC ExecuteCRUD @TableName = 'DateCard', @ID_update = 1000, @Camp_update = 'Data_expirarii', @Valoarea_update = '2075-12-12'   -- ID invalid
EXEC ExecuteCRUD @TableName = 'DateCard', @ID_update = 17, @Camp_update = 'Data_expirarii', @Valoarea_update = '2075-12-12' 

EXEC ExecuteCRUD @TableName = 'ServiciiDeStreaming', @ID_update = 1, @Camp_update = 'ID_serviciu', @Valoarea_update = 12  -- Coloana invalida pentru UPDATE
EXEC ExecuteCRUD @TableName = 'ServiciiDeStreaming', @ID_update = 1, @Camp_update = 'Tip_serviciu', @Valoarea_update = 'video/audio '   -- Valoare invalida
EXEC ExecuteCRUD @TableName = 'ServiciiDeStreaming', @ID_update = 1000, @Camp_update = 'Tip_serviciu', @Valoarea_update = 'Video'   -- ID invalid
EXEC ExecuteCRUD @TableName = 'ServiciiDeStreaming', @ID_update = 1, @Camp_update = 'Tip_serviciu', @Valoarea_update = 'audio/video'

EXEC ExecuteCRUD @TableName = 'Dispozitive', @ID_update = 1, @Camp_update = 'ID_serviciu', @Valoarea_update = 11    -- Coloana invalida pentru UPDATE
EXEC ExecuteCRUD @TableName = 'Dispozitive', @ID_update = 1, @Camp_update = 'Tip_dispozitiv', @Valoarea_update = ''     -- Valoare invalida
EXEC ExecuteCRUD @TableName = 'Dispozitive', @ID_update = 10000, @Camp_update = 'Tip_dispozitiv', @Valoarea_update = 'calculator'   -- ID invalid
EXEC ExecuteCRUD @TableName = 'Dispozitive', @ID_update = 11, @Camp_update = 'Tip_dispozitiv', @Valoarea_update = 'laptop'

EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente', @ID_update = 1, @Camp_update = 'ID_tip_abonament', @Valoarea_update = 11   -- Coloana invalida pentru UPDATE
EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente', @ID_update = 1, @Camp_update = 'Nume_abonament', @Valoarea_update = ''   -- Valoare invalida
EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente', @ID_update = 1, @Camp_update = 'ID_serviciu', @Valoarea_update = 50   -- Valoare invalida
EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente', @ID_update = 1000, @Camp_update = 'ID_serviciu', @Valoarea_update = 8    -- ID invalid
EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente', @ID_update = 1, @Camp_update = 'ID_serviciu', @Valoarea_update = 1

EXEC ExecuteCRUD @TableName = 'AbonamenteUtilizatori', @ID_update = 1, @ID_tip_abonament_update = 1, @Camp_update = 'ID_utilizator', @Valoarea_update = 8   -- Coloana invalida pentru UPDATE
EXEC ExecuteCRUD @TableName = 'AbonamenteUtilizatori', @ID_update = 14,@ID_tip_abonament_update = 20, @Camp_update = 'Status_abonament', @Valoarea_update = 'inactiv'   -- Valoare invalida
EXEC ExecuteCRUD @TableName = 'AbonamenteUtilizatori', @ID_update = 1, @Camp_update = 'Status_abonament', @Valoarea_update = 'activ'   -- Nu s-au furnizat toate ID-urile necesare
EXEC ExecuteCRUD @TableName = 'AbonamenteUtilizatori', @ID_update = 1000,@ID_tip_abonament_update = 2000, @Camp_update = 'Status_abonament', @Valoarea_update = 'activ'   -- ID-uri invalide
EXEC ExecuteCRUD @TableName = 'AbonamenteUtilizatori', @ID_update = 14,@ID_tip_abonament_update = 20, @Camp_update = 'Status_abonament', @Valoarea_update = 'expirat'



--- Exemple pentru DELETE

--> DELETE pentru stergerea dupa un ID dat
EXEC ExecuteCRUD @TableName = 'Utilizatori', @ID_delete = 15
EXEC ExecuteCRUD @TableName = 'DateCard', @ID_delete = 14
EXEC ExecuteCRUD @TableName = 'ServiciiDeStreaming', @ID_delete = 6
EXEC ExecuteCRUD @TableName = 'Dispozitive', @ID_delete = 56
EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente', @ID_delete = 7


--> DELETE pentru stergerea inregistrarilor dintr-un interval
EXEC ExecuteCRUD @TableName = 'Utilizatori', @Start_delete = 15, @Stop_delete = 20
EXEC ExecuteCRUD @TableName = 'DateCard', @Start_delete = 15, @Stop_delete = 20
EXEC ExecuteCRUD @TableName = 'ServiciiDeStreaming', @Start_delete = 1, @Stop_delete = 5
EXEC ExecuteCRUD @TableName = 'Dispozitive', @Start_delete = 15, @Stop_delete = 20
EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente', @Start_delete = 1, @Stop_delete = 5
EXEC ExecuteCRUD @TableName = 'AbonamenteUtilizatori', @Start_delete = 1, @Stop_delete = 5


--> DELETE pentru stergerea dupa o valoare data a unui camp
EXEC ExecuteCRUD @TableName = 'Utilizatori', @Camp_conditie_delete = 'Varsta', @Valoarea_conditie_delete = 20   -- Camp invalid
EXEC ExecuteCRUD @TableName = 'Utilizatori', @Camp_conditie_delete = 'Tara', @Valoarea_conditie_delete = 'Romania'
EXEC ExecuteCRUD @TableName = 'DateCard', @Camp_conditie_delete = 'Data_expirarii', @Valoarea_conditie_delete = '2050-12-12'
EXEC ExecuteCRUD @TableName = 'ServiciiDeStreaming', @Camp_conditie_delete = 'Tip_serviciu', @Valoarea_conditie_delete = 'audio'
EXEC ExecuteCRUD @TableName = 'Dispozitive', @Camp_conditie_delete = 'Tip_dispozitiv', @Valoarea_conditie_delete = 'Laptop'
EXEC ExecuteCRUD @TableName = 'TipuriDeAbonamente', @Camp_conditie_delete = 'Durata', @Valoarea_conditie_delete = 'an'
EXEC ExecuteCRUD @TableName = 'AbonamenteUtilizatori', @Camp_conditie_delete = 'Status_abonament', @Valoarea_conditie_delete = 'suspendat'



-- Exemplu de rulare complet (contine toate operatiile CRUD)
EXEC ExecuteCRUD @TableName = 'Utilizatori', @Columns = 'Nume, Email, Parola, Tara', @Values = 'Popescu Alina, popescu.alina@gmail.com, 12345678, Italy',   -- inserare
	@ID_update = 1, @Camp_update = 'Nume', @Valoarea_update = 'UPDATE CRUD',    -- update
	@Camp_conditie_delete = 'Tara', @Valoarea_conditie_delete = 'Italy';      -- delete





----- 5. View-uri -----

---- 5.1. UtilizatoriAbonamenteView ----

-- Vizualizarea utilizatorilor care au abonamente expirate, oferind informatii detaliate despre acestia si tipul abonamentului pe care l-au avut.
CREATE OR ALTER VIEW UtilizatoriAbonamenteView AS
SELECT 
    u.ID_utilizator, 
    u.Nume, 
    u.Email, 
    u.Tara,
    ta.Nume_abonament, 
    ta.Pret, 
    ta.Durata, 
    a.Data_inceput_abonament, 
    a.Data_sfarsit_abonament, 
    a.Status_abonament,
    COUNT(*) AS Numar_abonamente_active
FROM 
    Utilizatori u
INNER JOIN 
    AbonamenteUtilizatori a ON u.ID_utilizator = a.ID_utilizator
INNER JOIN 
    TipuriDeAbonamente ta ON a.ID_tip_abonament = ta.ID_tip_abonament
WHERE 
    a.Status_abonament = 'expirat'
GROUP BY
    u.ID_utilizator, u.Nume, u.Email, u.Tara,
    ta.Nume_abonament, ta.Pret, ta.Durata, 
    a.Data_inceput_abonament, a.Data_sfarsit_abonament, a.Status_abonament
HAVING 
    COUNT(*) > 1





---- 5.2. ServiciiAbonamenteView ----

-- Vizualizarea tipurilor de abonamente disponibile pentru serviciul de streaming Netflix, cu informatii despre costul si durata acestora.
CREATE OR ALTER VIEW ServiciiAbonamenteView AS
SELECT 
    s.ID_serviciu,
    s.Nume_serviciu, 
    s.Tip_serviciu, 
    ta.Nume_abonament, 
    ta.Pret, 
    ta.Durata, 
    ta.Descriere
FROM 
    ServiciiDeStreaming s
INNER JOIN 
    TipuriDeAbonamente ta ON s.ID_serviciu = ta.ID_serviciu
WHERE
    s.Nume_serviciu LIKE '%Netflix%'
    AND ta.Pret > 10





---- 5.3. UtilizatoriServiciiDispozitiveView ----

-- Obtin dispozitivele (mai mult de 2) folosite de utilizatori pentru a accesa serviciile de streaming, asociind utilizatorii cu serviciile si tipurile de dispozitive utilizate.
CREATE OR ALTER VIEW UtilizatoriServiciiDispozitiveView AS
SELECT 
    u.ID_utilizator,
    u.Nume AS Nume_utilizator, 
    s.Nume_serviciu, 
    s.Tip_serviciu, 
    d.Tip_dispozitiv,
    COUNT(d.ID_dispozitiv) AS Numar_dispozitive
FROM 
    Utilizatori u
INNER JOIN 
    Dispozitive d ON u.ID_utilizator = d.ID_utilizator
INNER JOIN 
    ServiciiDeStreaming s ON d.ID_serviciu = s.ID_serviciu
WHERE 
    LOWER(d.Tip_dispozitiv) IN ('telefon', 'televizor') 
GROUP BY 
    u.ID_utilizator, u.Nume, s.Nume_serviciu, s.Tip_serviciu, d.Tip_dispozitiv
HAVING 
    COUNT(d.ID_dispozitiv) > 2  




---- 5.4. DateCardAbonamenteView ----

-- Obtin detaliile despre datele cardului de credit ale utilizatorilor care au abonamente active, inclusiv tipul de abonament asociat si data de expirare a cardului.
CREATE OR ALTER VIEW DateCardAbonamenteView AS
SELECT 
    u.ID_utilizator,
    u.Nume AS Nume_utilizator, 
    dc.Numar_card, 
    dc.Data_expirarii AS Data_expirarii_card, 
    dc.Nume_detinator, 
    ta.Nume_abonament, 
    a.Status_abonament,
    ta.Durata
FROM 
    DateCard dc
INNER JOIN 
    Utilizatori u ON dc.ID_utilizator = u.ID_utilizator
INNER JOIN 
    AbonamenteUtilizatori a ON u.ID_utilizator = a.ID_utilizator
INNER JOIN 
    TipuriDeAbonamente ta ON a.ID_tip_abonament = ta.ID_tip_abonament
INNER JOIN 
    ServiciiDeStreaming s ON ta.ID_serviciu = s.ID_serviciu  
WHERE 
    a.Status_abonament = 'activ'
    AND ta.Durata = 'luna'  






----- 6. Indecsi Non-Clustered -----


CREATE NONCLUSTERED INDEX IDX_Utilizatori_ID_utilizator ON Utilizatori(ID_utilizator);
CREATE NONCLUSTERED INDEX IDX_AbonamenteUtilizatori_ID_utilizator_Status_abonament ON AbonamenteUtilizatori(ID_utilizator, Status_abonament);
CREATE NONCLUSTERED INDEX IDX_TipuriDeAbonamente_ID_tip_abonament ON TipuriDeAbonamente(ID_tip_abonament);
CREATE NONCLUSTERED INDEX IDX_ServiciiDeStreaming_ID_serviciu ON ServiciiDeStreaming(ID_serviciu);
CREATE NONCLUSTERED INDEX IDX_TipuriDeAbonamente_ID_serviciu ON TipuriDeAbonamente(ID_serviciu);
CREATE NONCLUSTERED INDEX IDX_Dispozitive_ID_utilizator_ID_serviciu ON Dispozitive(ID_utilizator, ID_serviciu);
CREATE NONCLUSTERED INDEX IDX_DateCard_ID_utilizator ON DateCard(ID_utilizator);
CREATE NONCLUSTERED INDEX IDX_TipuriDeAbonamente_ID_serviciu_Durata ON TipuriDeAbonamente(ID_serviciu, Durata);
CREATE NONCLUSTERED INDEX IDX_Utilizatori_Nume ON Utilizatori(Nume);
CREATE NONCLUSTERED INDEX IDX_AbonamenteUtilizatori_Status_ID ON AbonamenteUtilizatori(Status_abonament, ID_utilizator);





----- 7. Testare indecsi Non-Clustered ----


SELECT * 
FROM UtilizatoriAbonamenteView
ORDER BY Nume


SELECT *
FROM ServiciiAbonamenteView
ORDER BY ID_serviciu


SELECT * 
FROM UtilizatoriServiciiDispozitiveView
ORDER BY ID_utilizator


SELECT *
FROM DateCardAbonamenteView
ORDER BY ID_utilizator
