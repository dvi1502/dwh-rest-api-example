CREATE FUNCTION [IIS].[fnGetNomenclatureChangesList]
(
	@StartDate datetime = null, @EndDate datetime = null, @Offset int = 0, @RowCount int = 10
)
RETURNS xml
AS
BEGIN

	-- Метод устарел
	 --RETURN 
		--	(
		--	SELECT 'Deprecated method! Do not use again. Use FN [IIS].[fnGetNomenclatureByID] jointly FN [IIS].[fnGetSummaryList]' AS [MESSAGE] 
		--	FOR XML RAW 
		--	,ROOT('Summary')
		--	,BINARY BASE64
		--	);

	DECLARE @t TABLE (id int)
	INSERT INTO @t (id)
	SELECT Nomenclature.[ID]
	FROM [DW].[DimNomenclatures] as Nomenclature
	LEFT JOIN [DW].[DimTypesOfNomenclature] t
		ON Nomenclature.NomenclatureType = t.[CodeInIS] --AND Nomenclature.[InformationSystemID] = t.[InformationSystemID]
	WHERE t.[GoodsForSale] = 1
		AND COALESCE(Nomenclature.[Marked],0) = 0 
		AND ((Nomenclature.[DLM] >= @StartDate)  OR (@StartDate is null))
		AND ((Nomenclature.[DLM] <  @EndDate)    OR (@EndDate is null))
	ORDER BY Nomenclature.[ID]	OFFSET (@Offset*@RowCount) ROWS	FETCH NEXT @RowCount ROWS ONLY;

	RETURN 	(

		SELECT * FROM (

		SELECT 
			Nomenclature.[ID]						"@ID"
			,Nomenclature.[Name]					"@Name"
			,Nomenclature.[Code]					"@Code"	
			,Nomenclature.[MasterId]				"@MasterId"
			,[DW].[fnGetGuid1C](Nomenclature.[CodeInIS]) "@CodeInIS"
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
			AND Nomenclature.[ID] IN (select id from @t)

		) as D

		FOR XML PATH('Nomenclature')
			,ROOT('Goods')
			,BINARY BASE64 
		)
END