CREATE FUNCTION [IIS].[fnGetPrices]
(
	@StartDate datetime = null, @EndDate datetime = null, @Offset int = 0, @RowCount int = 10
)
RETURNS xml
AS
BEGIN

	-- Метод устарел
	 RETURN 
			(
			SELECT 'Deprecated method! Do not use again. Don''t call here again.' AS [MESSAGE] 
			FOR XML RAW 
			,ROOT('Summary')
			,BINARY BASE64
			);


	RETURN 	(
		SELECT * FROM (
			SELECT 
				n.ID as NomenclatureID
				,[Price]
				,IsAction
				,[StartDate] as StartDate
				--,case when lead ([StartDate]) over(partition by [NomenclatureId] order by DateID,[NomenclatureId]) is NULL 
				--then cast(getdate() as date)
				--else lead ([StartDate]) over(partition by [NomenclatureId] order by [StartDate], [NomenclatureId]) END as EndDate

			  FROM [DW].[FactPrices] as t 
			  INNER JOIN [DW].[DimNomenclatures] as n 
			  ON t.NomenclatureID = n.CodeInIS
			  WHERE 
				[PriceTypeID] = 0xBA6D90E6BA17BDD711E297052E5C534D 
				and [DocType] = 'DocumentRef.УстановкаЦенНоменклатуры'
				and IsAction = 0
				AND ((t.[DLM] >= @StartDate)  OR (@StartDate is null))
				AND ((t.[DLM] <  @EndDate) OR (@EndDate is null))

			  ORDER BY t.[ID]
				OFFSET @Offset ROWS
				FETCH NEXT @RowCount ROWS ONLY

		) as D

		FOR XML PATH ('Price')
		,ROOT('Prices')
		--,ELEMENTS XSINIL
		,BINARY BASE64 
		--AUTO
		--,XMLSCHEMA 
		)
END
