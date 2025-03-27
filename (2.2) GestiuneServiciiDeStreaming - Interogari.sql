USE GestiuneServiciiDeStreaming
GO

--INTEROGAREA 1: 
-- Sa se afiseze utilizatorii care au conturile suspendate pentru anumite servicii de streaming, impreuna cu denumirea serviciului.
SELECT DISTINCT u.Nume, s.Nume_serviciu
FROM Utilizatori u
JOIN AbonamenteUtilizatori a ON u.ID_utilizator=a.ID_utilizator
JOIN TipuriDeAbonamente t ON a.ID_tip_abonament=t.ID_tip_abonament
JOIN ServiciiDeStreaming s ON t.ID_serviciu=s.ID_serviciu
WHERE LOWER(a.Status_abonament)='suspendat';

--INTEROGAREA 2:
-- Sa se afiseze comentariile care au fost lasate pe platforma YouTube (ID_serviciu = 8).
SELECT r.Comentariu, u.Nume, c.Titlu
FROM Recenzii r
JOIN Utilizatori u ON r.ID_utilizator=u.ID_utilizator
JOIN ContinutMedia c ON r.ID_continut=c.ID_continut
WHERE c.ID_serviciu=8;

--INTEROGAREA 3:
-- Sa se afiseze filmele vizionate de utilizatorului cu id-ul 1 de pe toate platformele de streaming.
SELECT u.Nume, s.Nume_serviciu, c.Titlu, v.Status_vizualizare
FROM Utilizatori u
JOIN Vizualizari v ON u.ID_utilizator=v.ID_utilizator
JOIN ContinutMedia c ON v.ID_continut=c.ID_continut
JOIN ServiciiDeStreaming s ON c.ID_serviciu=s.ID_serviciu
WHERE u.ID_utilizator=1 AND c.Tip_continut='film';

--INTEROGAREA 4:
-- Sa se afiseze serialele, impreuna cu sezonul si episodul, vizionate, dar neterminate, de utilizatorului cu id-ul 1 de pe toate platformele de streaming.
SELECT  u.Nume, s.Nume_serviciu, c.Titlu, e.Numar_sezon, e.Numar_episod, v.Durata_vizionata, v.Status_vizualizare
FROM  Vizualizari v
JOIN  Utilizatori u ON u.ID_utilizator = v.ID_utilizator
JOIN  ContinutMedia c ON v.ID_continut = c.ID_continut
JOIN  Episoade e ON c.ID_continut = e.ID_continut AND v.Numar_sezon = e.Numar_sezon AND v.Numar_episod = e.Numar_episod
JOIN  ServiciiDeStreaming s ON c.ID_serviciu = s.ID_serviciu
WHERE  u.ID_utilizator = 1  AND v.Status_vizualizare = 'in derulare'  AND c.Tip_continut = 'serial';

--INTEROGAREA 5:
-- Sa se afiseze cati utilizatori are fiecare platforma de streaming.
SELECT s.Nume_serviciu, COUNT(DISTINCT u.ID_utilizator) AS Numar_utilizatori
FROM Utilizatori u
JOIN Dispozitive d ON u.ID_utilizator=d.ID_utilizator
JOIN ServiciiDeStreaming s ON d.ID_serviciu=s.ID_serviciu
GROUP BY s.Nume_serviciu;

--INTEROGAREA 6:
-- Sa se afiseze platformele de streaming care au mai mult de 5 utilizatori.
SELECT s.Nume_serviciu, COUNT(DISTINCT u.ID_utilizator) AS Numar_utilizatori
FROM Utilizatori u
JOIN Dispozitive d ON u.ID_utilizator=d.ID_utilizator
JOIN ServiciiDeStreaming s ON d.ID_serviciu=s.ID_serviciu
GROUP BY s.Nume_serviciu
HAVING COUNT(DISTINCT u.ID_utilizator)>5;

--INTEROGAREA 7:
-- Sa se afiseze continutul cu cele mai multe vizualizari.
SELECT TOP 1 c.Titlu, s.Nume_serviciu, COUNT(v.Id_vizualizare) AS Numar_vizualizari
FROM ContinutMedia c
JOIN Vizualizari v ON c.ID_continut=v.ID_continut
JOIN ServiciiDeStreaming s ON c.ID_serviciu=s.ID_serviciu
GROUP BY c.ID_continut, c.Titlu, s.Nume_serviciu
ORDER BY Numar_vizualizari DESC;

--INTEROGAREA 8:
-- Sa se afiseze serviciile de streaming care au abonamente suspendate/expirate.
SELECT s.Nume_serviciu, COUNT(a.Id_tip_abonament) AS Numar_abonamente_inactive
FROM ServiciiDeStreaming s
LEFT JOIN TipuriDeAbonamente t ON s.ID_serviciu=t.ID_serviciu
LEFT JOIN AbonamenteUtilizatori a ON t.ID_tip_abonament=a.ID_tip_abonament
WHERE a.Status_abonament IN ('suspendat', 'expirat')
GROUP BY s.ID_serviciu, s.Nume_serviciu
HAVING COUNT(a.Id_tip_abonament)>0;

--INTEROGAREA 9:   (m-n)
-- Sa se afiseze factura pentru fiecare serviciu de streaming a fiecarui utilizator pentru luna 10, anul 2024
SELECT u.Nume, s.Nume_serviciu, f.Id_factura, f.Data_emiterii, f.Suma, f.Status_factura
FROM Facturi f
JOIN Utilizatori u ON f.ID_utilizator=u.ID_utilizator
JOIN ServiciiDeStreaming s ON f.ID_serviciu=s.ID_serviciu
WHERE f.Data_emiterii>='2024-10-01' AND f.Data_emiterii<'2024-11-01'
ORDER BY u.Nume, s.Nume_serviciu;

--INTEROGAREA 10:   (m-n)
-- Sa se afiseze utilizatorii care au mai mult de 2 dispozitive pentru un serviciu de streaming, impreuna cu numele serviciului.
SELECT u.Nume, s.Nume_serviciu, COUNT(d.ID_dispozitiv) AS Numar_dispozitive
FROM Utilizatori u
JOIN Dispozitive d ON u.ID_utilizator=d.ID_utilizator
JOIN ServiciiDeStreaming s ON d.ID_serviciu=s.ID_serviciu
GROUP BY u.ID_utilizator, u.Nume, s.ID_serviciu, s.Nume_serviciu
HAVING COUNT(D.ID_dispozitiv)>2
ORDER BY u.Nume, s.Nume_serviciu;


