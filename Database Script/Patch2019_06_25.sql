USE [DB_SMART_BSM]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('dbo.spInsDocMandatoryWithCheck'))
   EXEC('CREATE PROCEDURE [dbo].[spInsDocMandatoryWithCheck] AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE [dbo].[spInsDocMandatoryWithCheck] @TipeRekananList VARCHAR(50), @NameType VARCHAR(250)
AS
--EXEC [dbo].[spInsDocMandatoryWithCheck] '4,5,1,11,12', 'Ijin OJK'
BEGIN
	SET NOCOUNT ON;
	DECLARE @Jumlah INT, @TipeRekanan INT, @IdTypeOfDocument INT, @i INT, @intDocMandatory INT
	SET @i = 1
	--SELECT * FROM mstTypeOfDocument WHERE NameType LIKE '%' + @NameType + '%'
	--CEK DI MASTER ADA TIPE DOKUMEN NYA ?
	SELECT @IdTypeOfDocument = ISNULL(MAX(IdTypeOfDoc),0) FROM mstTypeOfDocument WHERE NameType LIKE '%' + @NameType + '%'

	--JIKA TIDAK, INSERT DAN AMBIL IDDOC NYA
	IF (@IdTypeOfDocument = 0) 
	BEGIN
		INSERT INTO [dbo].[mstTypeOfDocument]
		([NameType],[IsDataOrganisasi],[CreatedUser],[CreatedDate],[IsActive])
		VALUES	(@NameType,0,'admin',getdate(),1)
	END
	--AMBIL IDDOC NYA, 
	SELECT @IdTypeOfDocument = ISNULL(MAX(IdTypeOfDoc),0) FROM mstTypeOfDocument WHERE NameType LIKE '%' + @NameType + '%'
	--INSERT KE BEBERAPA DOCMANDATORY KE BEBERAPA JENIS REKANAN (LIST REKANAN)
	SELECT @Jumlah = COUNT(1) FROM [dbo].[splitstring](@TipeRekananList)
	WHILE @i < @Jumlah + 1
	BEGIN
		SELECT @TipeRekanan = CAST(Name AS INT) FROM [dbo].[splitstring](@TipeRekananList)
		WHERE Urutan = @i 
		SET @i = @i + 1
		--CEK UDAH ADA BLOM ?
		SELECT @intDocMandatory = COUNT(1) FROM trxDocumentMandatory WHERE IdTypeOfRekanan = @TipeRekanan AND IdTypeOfDocument = @IdTypeOfDocument
		IF(@intDocMandatory = 0)
		BEGIN
			INSERT INTO [dbo].[trxDocumentMandatory]
			([IdTypeOfRekanan],[IdTypeOfDocument],[docSeq],[CreatedUser],[CreatedDate],[IsMandatory])
			VALUES (@TipeRekanan,@IdTypeOfDocument ,1, 'admin',GETDATE(),1)
		END
	END
END

ALTER TABLE [dbo].[mstTypeOfDocument] ALTER COLUMN [NameType] [varchar](250) NOT NULL
DELETE mstTypeOfDocument where NameType = 'Laporan Keuangan (2 tahun terakhir)'

EXEC [dbo].[spInsDocMandatoryWithCheck] '4,5,1,11,12', 'Ijin OJK'

IF NOT EXISTS ( SELECT 1 FROM syscolumns WHERE id = OBJECT_ID('mstTypeOfDocument') AND name = 'IsAdminDoc' ) 
BEGIN
	ALTER TABLE [dbo].[mstTypeOfDocument] ADD [IsAdminDoc] [bit] NULL
	ALTER TABLE [dbo].[mstTypeOfDocument] ADD  CONSTRAINT [DF_mstTypeOfDocument_IsAdminDoc]  DEFAULT ((0)) FOR [IsAdminDoc]
END
UPDATE [dbo].[mstTypeOfDocument] SET IsAdminDoc = 0
ALTER TABLE [dbo].[mstTypeOfDocument] ALTER COLUMN [IsAdminDoc] [bit] NOT NULL

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'IF' AND OBJECT_ID = OBJECT_ID('dbo.fGetKelengkapanDokumenByRek'))
BEGIN
	EXEC('CREATE FUNCTION [dbo].[fGetKelengkapanDokumenByRek]() RETURNS TABLE AS RETURN (SELECT 1 Nama)')
END
GO
ALTER FUNCTION [dbo].[fGetKelengkapanDokumenByRek](@IdTypeOfRekanan INT, @DocIncluded INT, @IsAdminDoc BIT)
RETURNS TABLE AS RETURN
(
	--SELECT * FROM [dbo].[fGetKelengkapanDokumenByRek] (1, 0, 0)
	SELECT b.IdTypeOfDoc, b.NameType, CASE WHEN (a.docSeq IS NULL) THEN ROW_NUMBER() OVER (ORDER BY b.IdTypeOfDoc) ELSE a.docSeq END docSeq
	FROM trxDocumentMandatory a 
	RIGHT JOIN mstTypeOfDocument b ON a.IdTypeOfDocument = b.IdTypeOfDoc AND a.IdTypeOfRekanan = @IdTypeOfRekanan AND b.IsAdminDoc = @IsAdminDoc
	WHERE CASE WHEN(a.docSeq IS NULL) THEN 0 ELSE 1 END = @DocIncluded AND b.IsAdminDoc = @IsAdminDoc
)

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('dbo.spUpdDocMandatoryByTipeRek'))
   EXEC('CREATE PROCEDURE [dbo].[spUpdDocMandatoryByTipeRek] AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE [dbo].[spUpdDocMandatoryByTipeRek] 
@DaftarDokumen VARCHAR(MAX), @IdTypeOdRekanan INT, @IsAdminDoc BIT
--EXEC [dbo].[spUpdDocMandatoryByTipeRek] '1|15|16|21|22|23|31|33|44|46|50|3061|51|52|58|60',7
AS
BEGIN
	SET NOCOUNT ON;
	--UPDATE DATA
	UPDATE b SET docSeq = a.docSeq 
	FROM (SELECT Id docSeq, Data idTypeOfDocument 
	FROM SplitMe(@DaftarDokumen, '|')) a
	JOIN trxDocumentMandatory b ON 
	a.idTypeOfDocument = b.IdTypeOfDocument AND b.IdTypeOfRekanan = @IdTypeOdRekanan

	--INSERT DATA
	INSERT INTO [dbo].[trxDocumentMandatory]
	([IdTypeOfRekanan],[IdTypeOfDocument],[docSeq],[CreatedUser],[CreatedDate]
	,[IsMandatory])
	SELECT @IdTypeOdRekanan, a.idTypeOfDocument, a.docSeq, 'adminListBox', GETDATE(), 1 
	FROM (SELECT Id docSeq, Data idTypeOfDocument 
	FROM SplitMe(@DaftarDokumen, '|')) a
	LEFT JOIN trxDocumentMandatory b ON 
	a.idTypeOfDocument = b.IdTypeOfDocument AND b.IdTypeOfRekanan = @IdTypeOdRekanan
	WHERE b.IdTypeOfDocument IS NULL

	--DELETE DATA
	DELETE trxDocumentMandatory WHERE IdMandatoryDocument IN (
	SELECT b.IdMandatoryDocument
	FROM (SELECT Id docSeq, Data idTypeOfDocument 
	FROM SplitMe(@DaftarDokumen, '|')) a
	JOIN mstTypeOfDocument c ON a.idTypeOfDocument = c.IdTypeOfDoc
	RIGHT JOIN trxDocumentMandatory b ON 
	a.idTypeOfDocument = b.IdTypeOfDocument 
	WHERE a.IdTypeOfDocument IS NULL AND b.IdTypeOfRekanan = @IdTypeOdRekanan AND c.IsAdminDoc = @IsAdminDoc)
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'IF' AND OBJECT_ID = OBJECT_ID('dbo.SplitMe'))
BEGIN
	EXEC('CREATE FUNCTION [dbo].[SplitMe]() RETURNS TABLE AS RETURN (SELECT 1 Nama)')
END
GO

ALTER FUNCTION [dbo].[SplitMe]
(
    @String VARCHAR(5000),
    @Delimiter VARCHAR(1)
)
RETURNS TABLE
AS
RETURN
(
    WITH SplitMe(stpos,endpos)
    AS(
        SELECT 0 AS stpos, CHARINDEX(@Delimiter,@String) AS endpos
        UNION ALL
        SELECT endpos+1, CHARINDEX(@Delimiter,@String,endpos+1)
            FROM SplitMe
            WHERE endpos > 0
    )
    SELECT 'Id' = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
        'Data' = SUBSTRING(@String,stpos,COALESCE(NULLIF(endpos,0),LEN(@String)+1)-stpos)
    FROM SplitMe
)

ALTER FUNCTION [dbo].[fKelengkapanDokByIdSupervisor](@IdSupervisor INT)
RETURNS TABLE AS RETURN
(
	--SELECT * FROM [dbo].[fKelengkapanDokByIdSupervisor](3)
	select a.IdRekanan, b.IdTypeOfDocument
	, CASE WHEN(e.IdTypeOfDocument IS NULL) THEN 0 ELSE 1 END IsDocExist, ISNULL(e.flgFinal, 0) isComplete 
	from mstrekanan a 
	join trxDocumentMandatory b on a.IdTypeOfRekanan = b.IdTypeOfRekanan
	join mstTypeOfDocument c on b.IdTypeOfDocument = c.IdTypeOfDoc
	join mstTypeOfRegion d on a.IdRegion = d.IdRegion
	left outer join 
	(select IdRekanan, IdTypeOfDocument
	--, flgSumAll/11, flgSumAll%11
	, case when(flgSumAll/11 > 0 and flgSumAll%11 = 0) then 1 else 0 end flgFinal from (
	select IdRekanan, IdTypeOfDocument, SUM(flgNomorDok) * 10 + SUM(flgLampiran) flgSumAll from (
	select IdRekanan, IdTypeOfDocument
	, CASE WHEN(LEN(case when(IdTypeOfDocument = 10) then badanPembuatDokumen else nomorDokumen end) > 1) THEN 1 ELSE 0 END flgNomorDok
	, CASE WHEN(LEN(fileExt) > 3) THEN 1 ELSE 0 END flgLampiran
	from trxDocMandatoryDetail --where IdRekanan = 'C94C8FE5-6802-4EB1-92BB-51024D9541B1'
	) a 
	group by IdRekanan, IdTypeOfDocument) aa) e on a.IdRekanan = e.IdRekanan and b.IdTypeOfDocument = e.IdTypeOfDocument
	where d.IdSupervisor = @IdSupervisor
)
