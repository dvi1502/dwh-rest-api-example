CREATE FUNCTION [IIS].[fnGetSipmentListByDocDate]
(
	@StartDate datetime, 
	@EndDate datetime = null
)
RETURNS xml
AS
BEGIN





	DECLARE @xml xml;
	SET @EndDate = ISNULL(@EndDate,GETDATE());

	IF (DATEDIFF(day, @StartDate, @EndDate) > 5) BEGIN

		SET @xml =  
			(
			SELECT 'Error. Interval too long (more than 5 days).' AS [MESSAGE] 
			FOR XML RAW 
			,ROOT('Summary')
			,BINARY BASE64
			);

		RETURN @xml;

	END;

DECLARE @t TABLE (

		[Tag] int, 
		[Parent] int,

		[Shipment!3!ID] bigint, 
		[Shipment!3!DLM] datetime,
		[Shipment!3!DateDoc] datetime,
		[Shipment!3!Marked]	bit,
		[Shipment!3!Posted]	bit,
		[Shipment!3!CHECKSUMM] int,

		[Shipment!3!GUID] varchar(38),

		[Aggregation!4!Contragents] int, 
		[Aggregation!4!Nomenclatures]int,
		[Aggregation!4!Shipments] int

)

INSERT INTO @t (
		[Tag], 
		[Parent],
		[Shipment!3!ID], 
		[Shipment!3!DLM],
		[Shipment!3!DateDoc],
		[Shipment!3!Marked]	,
		[Shipment!3!Posted]	,
		[Shipment!3!CHECKSUMM],
		[Shipment!3!GUID]
	)

	SELECT DISTINCT
		3 as [Tag], 
		null as [Parent],

		doc.ID as [Shipment!3!ID], 
		doc.[DLM] as [Shipment!3!DLM],
		doc.[DocDate] as [Shipment!3!DateDoc],

		doc.Marked as [Shipment!3!Marked],
		doc.Posted  as [Shipment!3!Posted],
		CHECKSUM_AGG(cast(Shipments.[CHECKSUMM] as int)) as [Shipment!3!CHECKSUMM],

		[DW].[fnGetGuid1C](Shipments.[CodeInIS]) as [Shipment!3!GUID]

		FROM [DW].[FactSalesOfGoods] Shipments
		INNER JOIN [DW].[DocJournal] as doc
			ON Shipments.[CodeInIS] = doc.[CodeInIS] 
			AND Shipments.InformationSystemID = doc.InformationSystemID
		WHERE 
			[doc].[DocDate] between @StartDate and @EndDate 
	    GROUP BY doc.ID, doc.[DLM],doc.Marked,doc.Posted, doc.[DocDate],Shipments.[CodeInIS];

	;




	INSERT INTO @t ([Tag], [Parent],[Aggregation!4!Shipments])
	SELECT 	4,null, COUNT([Shipment!3!ID]) FROM  @t

	SET @xml = (SELECT DISTINCT * from  @t ORDER BY [Aggregation!4!Shipments] DESC FOR XML EXPLICIT, ROOT('Summary'), BINARY BASE64);

	RETURN @xml;

END
GO