create database GestiuneServiciiDeStreaming --Creare baza de date
go
use GestiuneServiciiDeStreaming --Utilizez baza de date
go

CREATE TABLE Utilizatori --Creare tabela Utilizatori: continte informatii despre utilizatori
( ID_utilizator INT PRIMARY KEY IDENTITY, --Seteaza ID_utilizator ca si cheie primara
Nume varchar(50) NOT NULL,
Email varchar(50) NOT NULL,
Parola varchar(50) NOT NULL,
Data_inregistrarii DATE DEFAULT CAST(GETDATE() AS DATE) NOT NULL, --Seteaza data curenta ca valoare implicita
Tara varchar(50) NOT NULL
)

CREATE TABLE ServiciiDeStreaming --Creare tabela ServiciiDeStreaming: contine informatii despre serviciile de streaming
( ID_serviciu INT PRIMARY KEY IDENTITY, --Seteaza ID_serviciu ca si cheie primara
Nume_serviciu varchar(100) NOT NULL,
Tip_serviciu VARCHAR(30) CHECK (LOWER(Tip_serviciu) IN ('video', 'audio', 'audio/video')) NOT NULL --Seteaza Tip_serviciu de tip CHECK pentru a ma asigura ca este una dintre variantele date
)

CREATE TABLE TipuriDeAbonamente --Creare tabela TipuriDeAbonamente: contine informatii despre tipurile de abonamente ale fiecarui serviciu de streaming
(  ID_tip_abonament INT PRIMARY KEY IDENTITY, --Seteaza ID_tip_abonament ca si cheie primara
ID_serviciu INT FOREIGN KEY REFERENCES ServiciiDeStreaming(ID_serviciu), --Seteaza ID_serviciu din tabela ServiciiDeStreaming ca si cheie straina
Nume_abonament varchar(100) NOT NULL,
Pret decimal(5,2) NOT NULL, --Seteaza pretul abonamentului (maxim 5 cifre inainte de virgula, maxim 2 cifre dupa virgula)
Durata varchar(10) CHECK (Durata IN ('luna', 'an')), --Seteaza Durata de tip CHECK pentru a ma asigura ca este una dintre variantele date
Descriere varchar(100) NULL --Seteaza Descriere sa permita si valori de tip NULL
)

CREATE TABLE AbonamenteUtilizatori  --Creare tabela AbonamenteUtilizatori: contine informatii despre abonamentele utilizatorilor
( ID_utilizator INT FOREIGN KEY REFERENCES Utilizatori(ID_utilizator),  --Seteaza ID_utilizator din tabela Utilizatori ca si cheie straina
ID_tip_abonament INT FOREIGN KEY REFERENCES TipuriDeAbonamente(ID_tip_abonament),  --Seteaza ID_tip_abonament din tabela TipuriDeAbonamente ca si cheie straina
Data_inceput_abonament DATE DEFAULT CAST(GETDATE() AS DATE) NOT NULL,  --Seteaza data curenta ca valoare implicita
Data_sfarsit_abonament DATE,  --Seteaza Data_sfarsit_abonament de tip DATE
Status_abonament varchar(30) CHECK (LOWER(Status_abonament) IN ('activ', 'suspendat', 'expirat'))  --Seteaza Status_abonament de tip CHECK pentru a ma asigura ca este una dintre variantele date
CONSTRAINT pk_AbonamenteUtilizatori PRIMARY KEY (ID_utilizator, ID_tip_abonament)  --Seteaza ca si cheie primara perechea: ID_utilizator,  ID_tip_abonament
)

CREATE TABLE ContinutMedia  --Creare tabela ContinutMedia: contine informatii despre contentul disponibil
( ID_continut INT PRIMARY KEY IDENTITY,  --Seteaza ID_continut ca si cheie primara
ID_serviciu INT FOREIGN KEY REFERENCES ServiciiDeStreaming(ID_serviciu),  --Seteaza ID_serviciu din tabela ServiciiDeStreaming ca si cheie straina
Titlu varchar(250) NOT NULL,
Tip_continut varchar(30) CHECK (LOWER(Tip_continut) IN ('film', 'serial', 'muzica', 'video', 'audiobook')),  --Seteaza Tip_continut de tip CHECK pentru a ma asigura ca este una dintre variantele date
Gen varchar(100) NOT NULL,
Numar_sezoane INT DEFAULT 0,
Data_lansarii DATE NOT NULL,  --Seteaza Data_lansarii de tip DATE
Durata TIME(0) NOT NULL DEFAULT '00:00:00',  --Seteaza Durata de tip TIME (in minute)
Evaluare decimal(3, 1) NULL,  --Seteaza Evaluare sa aiba o valoare intre 0 si 10
Status_disponibilitate varchar(30) CHECK (LOWER(Status_disponibilitate) IN ('disponibil', 'indisponibil'))  --Seteaza Status_disponibilitate de tip CHECK pentru a ma asigura ca este una dintre variantele date
)

CREATE TABLE Episoade  --Creare tabela Episoade: contine informatii despre episoadele serialelor din ContinutMedia
(  ID_continut INT FOREIGN KEY REFERENCES ContinutMedia(ID_continut),  --Seteaza ID_continut din tabela ContinutMedia ca si cheie straina
Numar_sezon INT NOT NULL,
Numar_episod INT NOT NULL,
Titlu_episod varchar(250) NOT NULL,
Durata TIME(0) NOT NULL  --Seteaza Durata de tip TIME (in minute)
CONSTRAINT pk_Episoade PRIMARY KEY (ID_continut, Numar_sezon, Numar_episod)  --Seteaza ca si cheie primara perechea: ID_continut, Numar_sezon, Numar_episod
)

CREATE TABLE Vizualizari  --Creare tabela Vizualizari: contine informatii despre fiecare vizualizare a utilizatorilor
(  ID_vizualizare INT PRIMARY KEY IDENTITY,  --Seteaza ID_vizualizare ca si cheie primara
ID_utilizator INT FOREIGN KEY REFERENCES Utilizatori(ID_utilizator),  --Seteaza ID_utilizator din tabela Utilizatori ca si cheie straina
ID_continut INT FOREIGN KEY REFERENCES ContinutMedia(ID_continut),  --Seteaza ID_continut din tabela ContinutMedia ca si cheie straina
Numar_sezon INT NULL, --Sezonul din care face parte episodul la care se uita utilizatorul (NULL pentru filme)
Numar_episod INT NULL, --Episodul pe care il vizioneaza utilizatorul din serial (NULL pentru filme)
Durata_vizionata TIME(0) NOT NULL DEFAULT '00:00:00', --Seteaza Durata_vizionata de tip TIME (in minute)
Status_vizualizare varchar(30) CHECK (LOWER(Status_vizualizare) IN ('finalizat', 'in derulare'))  --Seteaza Status_vizualizare de tip CHECK pentru a ma asigura ca este una dintre variantele date
FOREIGN KEY (ID_continut) REFERENCES ContinutMedia(ID_continut),  -- Cheie straina pentru referinta la ContinutMedia
    CONSTRAINT chk_vizualizari CHECK ( --Determin daca este serial sau film
        (Numar_sezon IS NOT NULL AND Numar_episod IS NOT NULL) OR (Numar_sezon IS NULL AND Numar_episod IS NULL)
    )
)

CREATE TABLE Recenzii  --Creare tabela Recenzii: contine informatii despre fiecare recenzie lasata de utilizatori
(  ID_recenzie INT PRIMARY KEY IDENTITY,  --Seteaza ID_recenzie ca si cheie primara
ID_utilizator INT FOREIGN KEY REFERENCES Utilizatori(ID_utilizator),  --Seteaza ID_utilizator din tabela Utilizatori ca si cheie straina
ID_continut INT FOREIGN KEY REFERENCES ContinutMedia(ID_continut),  --Seteaza ID_continut din tabela ContinutMedia ca si cheie straina
Evaluare decimal(3, 1) NULL,  --Seteaza Evaluare sa aiba o valoare intre 0 si 10
Comentariu TEXT NULL --Seteaza Comentariu pentru a putea stoca un numar mare de caractere
)

CREATE TABLE Dispozitive  --Creare tabela Dispozitive: contine informatii despre fiecare dispozitiv folosit de utilizatori
(  ID_dispozitiv INT PRIMARY KEY IDENTITY,  --Seteaza ID_dispozitiv ca si cheie primara
ID_utilizator INT FOREIGN KEY REFERENCES Utilizatori(ID_utilizator),  --Seteaza ID_utilizator din tabela Utilizatori ca si cheie straina
ID_serviciu INT FOREIGN KEY REFERENCES ServiciiDeStreaming(ID_serviciu),  --Seteaza ID_serviciu din tabela ServiciiDeStreaming ca si cheie straina
Tip_dispozitiv varchar(100) NOT NULL
)

CREATE TABLE DateCard  --Creare tabela DateCard: contine informatii despre datele cardului fiecarui utilizator
(  ID_utilizator INT FOREIGN KEY REFERENCES Utilizatori(ID_utilizator),  --Seteaza ID_utilizator din tabela Utilizatori ca si cheie straina
Numar_card varchar(20) NOT NULL,
Data_expirarii DATE NOT NULL,  --Seteaza Data_expirarii de tip DATE
Nume_detinator varchar(50) NOT NULL,
CONSTRAINT pk_DateCard PRIMARY KEY (ID_utilizator)  --Seteaza ca si cheie primara ID_utilizator
)

CREATE TABLE Facturi  --Creare tabela Facturi: contine informatii despre facturile fiecarui utilizator
(  ID_factura INT PRIMARY KEY IDENTITY,  --Seteaza ID_factura ca si cheie primara
ID_utilizator INT FOREIGN KEY REFERENCES Utilizatori(ID_utilizator),  --Seteaza ID_utilizator din tabela Utilizatori ca si cheie straina
ID_serviciu INT FOREIGN KEY REFERENCES ServiciiDeStreaming(ID_serviciu),  --Seteaza ID_tip_abonament din tabela TipuriDeAbonamente ca si cheie straina
Data_emiterii DATE DEFAULT GETDATE() NOT NULL,  --Seteaza Data_emiterii de tip DATE
Suma decimal(10,2) NOT NULL,  --Seteaza suma facturii (maxim 10 cifre inainte de virgula, maxim 2 cifre dupa virgula)
Data_platii DATE NULL,  --Seteaza Data_platii de tip DATE
Status_factura varchar(15) CHECK (LOWER(Status_factura) IN ('platita', 'neplatita'))  --Seteaza Status_factura de tip CHECK pentru a ma asigura ca este una dintre variantele date
)

