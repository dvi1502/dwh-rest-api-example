CREATE FUNCTION [IIS].[fnGetContragentByID]
(
	@ID bigint 
)
RETURNS xml
AS
BEGIN
	RETURN 	(

		SELECT * FROM (

			SELECT Contragent.[ID]						"@ID"
				,Contragent.[Name]						"@Name"
				,Contragent.[Code]						"@Code"	
				,Contragent.[FullName]					"@FullName"
				,Contragent.[ContragentType]			"@ContragentType"
				,Contragent.[INN]						"@INN"
				,Contragent.[KPP]						"@KPP"
				,Contragent.[OKPO]						"@OKPO"
				,Contragent.[GUID_Mercury]				"@GUID_Mercury"
				,Contragent.[ConsolidatedClientID]		"@ConsolidatedClientID"
				,Contragent.[Comment]					"@Comment"

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

				,CAST(Contragent.[ContactInfo] as XML)	"ContactInformations"
				,(SELECT 
					DeliveryPlaces.[ID]						[@ID]
					,DeliveryPlaces.[Name]					[@Name]
					,DeliveryPlaces.[Address]				[@Address]
					,DeliveryPlaces.[FormatStoreName]		[@FormatName]
					,DeliveryPlaces.[RegionStoreName]		[@RegionName]
					,[Region].[Code]						[@RegionCode]
					,CASE 
						WHEN DeliveryPlaces.[RegionStoreId] = 0x00000000000000000000000000000000 
						THEN NULL 
						ELSE  [DW].[fnGetGuid1C](DeliveryPlaces.[RegionStoreId]) 
						END [@RegionId]
				FROM [DW].[DimDeliveryPlaces] DeliveryPlaces
				LEFT JOIN [DW].[DimRegions] Region 
				ON [DeliveryPlaces].[RegionStoreId] = [Region].[CodeInIS] 
				AND [DeliveryPlaces].InformationSystemID = [Region].InformationSystemID 

				WHERE 	DeliveryPlaces.[ContragentID] = Contragent.[CodeInIS] AND DeliveryPlaces.[Marked] = 0
				FOR XML PATH('DeliveryPlaces'), TYPE
				) as  DeliveryPlaces

			FROM DW.DimContragents as Contragent

			WHERE 
				Contragent.[IsBuyer]	= 1 
				AND Contragent.[Marked] = 0 
				AND Contragent.ID = @ID
				
		) as D

		FOR XML PATH ('Contragent')
		,ROOT('Contragents')
		--,ELEMENTS XSINIL
		,BINARY BASE64 
		--AUTO
		--,XMLSCHEMA 
		)
END

