CREATE FUNCTION [IIS].[fnGetNomenclatureByID]
(
	@ID bigint 
)
RETURNS xml
AS
BEGIN
	RETURN 	(

		SELECT * FROM (

		SELECT 
			Nomenclature.[ID]						"@ID"
			,Nomenclature.[Name]					"@Name"
			,Nomenclature.[Code]					"@Code"	
			,Nomenclature.[MasterId]				"@MasterId"
			,Nomenclature.[NameFull]				"FullName"
			,ng.[Name]								"NomenclatureGroup"
			,JSON_VALUE(Nomenclature.[Parents], '$.parents[0]') "Category"
			,b.[Name]								"Brand"
			,Nomenclature.[boxTypeName]				"boxTypeName"
			,Nomenclature.[packTypeName]			"packTypeName"
			,Nomenclature.[Unit]					"Unit"
			,cost.[Price]					        "PlannedCost"

			,CAST((SELECT [Price] as "@Price"
				,IsAction as "@IsAction"
				,[StartDate] as "@StartDate"
			  FROM [DW].[FactPrices] as t 
			  WHERE 
				[PriceTypeID] = 0xBA6D90E6BA17BDD711E297052E5C534D 
				and [DocType] = 'DocumentRef.УстановкаЦенНоменклатуры'
				and IsAction = 0
				and t.NomenclatureID = Nomenclature.CodeInIS
			  FOR XML PATH ('Price'),BINARY BASE64 
			) as xml) as Prices


		FROM [DW].[DimNomenclatures] as Nomenclature

		LEFT JOIN [DW].[DimTypesOfNomenclature] t
		  ON Nomenclature.NomenclatureType = t.[CodeInIS] --AND Nomenclature.[InformationSystemID] = t.[InformationSystemID]

		LEFT JOIN [DW].[vwCurrentPlannedCost] cost
		  ON Nomenclature.[ID] = cost.[NomenclatureID]

		LEFT JOIN [DW].[DimNomenclatureGroups] as ng
		  ON Nomenclature.[NomenclatureGroup] = ng.[CodeInIS]

		LEFT JOIN [DW].[DimBrands] as b
		  ON Nomenclature.[Brand] = b.[CodeInIS]

		WHERE 
			--JSON_VALUE(Nomenclature.[Parents], '$.parents[0]') IN ('Колбасные изделия','Мясные продукты','Рыбная продукция')
			t.[GoodsForSale] = 1
			AND COALESCE(Nomenclature.[Marked],0) = 0 
			AND Nomenclature.[ID] = @ID

		) as D

		FOR XML PATH('Nomenclature')
			,ROOT('Goods')
		--	,ELEMENTS XSINIL
			,BINARY BASE64 
		--AUTO
		--,XMLSCHEMA 
		)
END