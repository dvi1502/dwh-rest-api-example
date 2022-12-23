CREATE FUNCTION [IIS].[fnGetContragentDiscounts]
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
				  cnt.ID as  [ContragentID]
				  ,dp.ID as [DeliveryPlaceID]
				  ,[DocNumber]
				  ,[DocumentDate]
				  ,[DateStart]
				  ,[DateEnd]
				  ,[DiscountPercent]
				  ,t.[Comment]
			  FROM [DW].[FactInstallationDiscountsNomenclatures] as t
			  INNER JOIN [DW].[DimContragents] as cnt ON t.[ContragentID] = cnt.CodeInIS
			  LEFT JOIN [DW].[DimDeliveryPlaces] as dp ON t.[DeliveryPlaceID] = dp.CodeInIS
			  WHERE  t.[Marked] = 0 
				AND ((t.[DLM] >= @StartDate)  OR (@StartDate is null))
				AND ((t.[DLM] <  @EndDate) OR (@EndDate is null))

			  ORDER BY t.[ID]
				OFFSET @Offset ROWS
				FETCH NEXT @RowCount ROWS ONLY
		) as D

		FOR XML PATH ('ContragentDiscount')
		,ROOT('Discounts')
		--,ELEMENTS XSINIL
		,BINARY BASE64 
		--AUTO
		--,XMLSCHEMA 
		)
END
