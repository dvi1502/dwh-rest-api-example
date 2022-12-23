CREATE FUNCTION [IIS].[fnGetContragentChangesList]
(
	@StartDate datetime = null, @EndDate datetime = null, @Offset int = 0, @RowCount int = 10
)
RETURNS xml
AS
BEGIN

	-- Метод устарел
	 --RETURN 
		--	(
		--	SELECT 'Deprecated method! Do not use again. Use FN [IIS].[fnGetContragentByID] jointly FN [IIS].[fnGetSummaryList]' AS [MESSAGE] 
		--	FOR XML RAW 
		--	,ROOT('Summary')
		--	,BINARY BASE64
		--	);

		DECLARE @t TABLE (id int)
		INSERT INTO @t (id)
		SELECT Contragent.[ID]
		FROM DW.DimContragents as Contragent
			WHERE 
				Contragent.[IsBuyer] = 1 
				AND Contragent.[Marked] = 0 
				AND ((Contragent.[DLM] >= @StartDate)  OR (@StartDate is null))
				AND ((Contragent.[DLM] <  @EndDate) OR (@EndDate is null))
			ORDER BY Contragent.[ID]
				OFFSET @Offset ROWS FETCH NEXT @RowCount ROWS ONLY;



	RETURN 	(
		SELECT * FROM (
		SELECT Contragent.[ID]				"@ID"
			,Contragent.[Name]				"@Name"
			,Contragent.[Code]				"@Code"	
			,Contragent.[FullName]			"@FullName"
			,Contragent.[ContragentType]	"@ContragentType"
			,Contragent.[INN]				"@INN"
			,Contragent.[KPP]				"@KPP"
			,Contragent.[OKPO]				"@OKPO"
			,Contragent.[GUID_Mercury]		"@GUID_Mercury"
			,Contragent.[ConsolidatedClientID]		"@ConsolidatedClientID"
			,Contragent.[Comment]			"@Comment"
			,[DW].[fnGetGuid1C](Contragent.[CodeInIS]) "@CodeInIS"

			,CAST((SELECT dp.ID as "@DeliveryPlaceID"
						  ,[DocNumber] as  "@DocNumber"
						  ,[DocumentDate] as "@DocumentDate"
						  ,[DateStart]  as "@DateStart"
						  ,[DateEnd] as "@DateEnd"
						  ,[DiscountPercent] as "@DiscountPercent"
						  ,t.[Comment] as "@Comment"

					  FROM [DW].[FactInstallationDiscountsNomenclatures] as t
					  LEFT JOIN [DW].[DimDeliveryPlaces] dp
					  ON t.[DeliveryPlaceID] = dp.[CodeInIS]
					  WHERE t.[ContragentID] = Contragent.CodeInIS

  					FOR XML PATH ('Discount'),BINARY BASE64 
			) as XML) as Discounts

			,CAST(Contragent.[ContactInfo] as XML) "ContactInformations"
			,(SELECT 
					DeliveryPlaces.[ID]						[@ID]
					,DeliveryPlaces.[Name]					[@Name]
					,DeliveryPlaces.[Address]				[@Address]
					,DeliveryPlaces.[FormatStoreName]		[@FormatName]
					,DeliveryPlaces.[RegionStoreName]		[@RegionName]
					,[Region].[Code]						[@RegionCode]
					,[DW].[fnGetGuid1C](DeliveryPlaces.[CodeInIS]) "@CodeInIS"

					,CASE 
						WHEN DeliveryPlaces.[RegionStoreId] = 0x00000000000000000000000000000000 
						THEN NULL 
						ELSE  [DW].[fnGetGuid1C](DeliveryPlaces.[RegionStoreId]) 
						END [@RegionId]
				FROM [DW].[DimDeliveryPlaces] DeliveryPlaces
				LEFT JOIN [DW].[DimRegions] Region 
				ON [DeliveryPlaces].[RegionStoreId] = [Region].[CodeInIS] 
				WHERE 	DeliveryPlaces.[ContragentID] = Contragent.[CodeInIS] AND DeliveryPlaces.[Marked] = 0
				FOR XML PATH('DeliveryPlaces'), TYPE
				) as  DeliveryPlaces

		FROM DW.DimContragents as Contragent
		WHERE Contragent.[ID] IN (select id from @t)

		) as D

		FOR XML PATH ('Contragent')
		,ROOT('Contragents')
		--,ELEMENTS XSINIL
		,BINARY BASE64 
		--AUTO
		--,XMLSCHEMA 
		)
END
