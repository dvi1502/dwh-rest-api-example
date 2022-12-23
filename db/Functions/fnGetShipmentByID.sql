CREATE FUNCTION [IIS].[fnGetShipmentByID]
(
	@ID bigint	
)
RETURNS xml
AS
BEGIN
	
	-- Метод устарел
	 --RETURN 
		--	(
		--	SELECT 'Deprecated method! Do not use again. Use SP [IIS].[GetShipments] and FN [IIS].[GetRefShipmentsById]' AS [MESSAGE] 
		--	FOR XML RAW 
		--	,ROOT('Summary')
		--	,BINARY BASE64
		--	);

	DECLARE @IDTbl TABLE (ID varbinary(16))

	INSERT INTO @IDTbl 
		SELECT gg.[CodeInIS] 
		FROM [DW].[DocJournal] gg
		WHERE gg.CodeInIS IN
		(
			SELECT DISTINCT [CodeInIS] 
			FROM [DW].[FactSalesOfGoods] ss
			WHERE gg.ID = @ID
		)
		GROUP BY gg.[CodeInIS]

	DECLARE @sales TABLE  
	(
		[Tag]				int
		,[Parent]			int
		,[Shipment!1!ID]	bigint

		,[Shipment!1!Marked]	bit
		,[Shipment!1!Posted]	bit

		,[Shipment!1!DocNum]			nvarchar(15)
		,[Shipment!1!DocDate]			datetime

		,[Shipment!1!OrgID]				bigint
		,[Shipment!1!OrgName]			nvarchar(150)
	
		,[Shipment!1!ContragentID]		bigint
		,[Shipment!1!ContragentName]	nvarchar(150)

		,[Shipment!1!DeliveryPlaceID]	bigint
		,[Shipment!1!DeliveryPlace]		nvarchar(150)

		,[Shipment!1!ShippingDate]		datetime

		,[Shipment!2!NomenclatureID]		int
		,[Shipment!2!NomenclatureMasterID]	int
		,[Shipment!2!NomenclatureName]		nvarchar(150)
		,[Shipment!2!Qty]					numeric(15,3)
		,[Shipment!2!Price]					numeric(15,2)
		,[Shipment!2!Cost]					numeric(15,2)
		,[Shipment!2!CostWithDiscounts]		numeric(15,2)
		,[Shipment!2!PercentageDiscounts]	numeric(15,2)
		,[Shipment!2!Price2]				numeric(15,2)
		,[Shipment!2!OrderDocDate]			datetime
	)


--declare @StartDate	datetime = N'20200409'; 
--declare @EndDate	datetime = null;
--declare @Offset int		= 0; 
--declare @RowCount int	= 10000;


	INSERT INTO @sales (
		[Tag],[Parent]		
		,[Shipment!1!ID]

		,[Shipment!1!Marked]	
		,[Shipment!1!Posted]	

		,[Shipment!1!DocNum]
		,[Shipment!1!DocDate]

		,[Shipment!1!OrgID]
		,[Shipment!1!OrgName]	

		,[Shipment!1!ContragentID]
		,[Shipment!1!ContragentName]

		,[Shipment!1!DeliveryPlaceID]
		,[Shipment!1!DeliveryPlace]
		,[Shipment!1!ShippingDate]

		,[Shipment!2!OrderDocDate]
		,[Shipment!2!NomenclatureID]
		,[Shipment!2!NomenclatureMasterID]
		,[Shipment!2!NomenclatureName]
		,[Shipment!2!Qty]
		,[Shipment!2!Price]
		,[Shipment!2!Cost]
		,[Shipment!2!CostWithDiscounts]
		,[Shipment!2!PercentageDiscounts]
		,[Shipment!2!Price2]

	)
		SELECT
			1					[Tag]
			,NULL				[Parent]
			,doc.[ID]			[Shipment!1!CID]
			,doc.Marked         [Shipment!1!Posted]
			,doc.Posted			[Shipment!1!Marked]

			,doc.[DocNum]		[Shipment!1!DocNum]	
			,doc.[DocDate]		[Shipment!1!DocDate]
			,org.[ID]			[Shipment!1!OrgID]
			,org.[Description]	[Shipment!1!OrgName]
			,cn.[ID]			[Shipment!1!ContragentID]
			,cn.[Name]			[Shipment!1!ContragentName]
			,dp.[ID]			[Shipment!1!DeliveryPlaceID]
			,dp.[Name]			[Shipment!1!DeliveryPlace]

			,doc.[DocDate]		[Shipment!1!ShippingDate]
			,NULL			as	[Shipment!2!OrderDocDate]
			,NULL				[Shipment!2!NomenclatureID]
			,NULL				[Shipment!2!NomenclatureMasterID]
			,NULL				[Shipment!2!NomenclatureName]
			,NULL				[Shipment!2!Qty]
			,NULL				[Shipment!2!Price]
			,SUM(ss.[Cost])		[Shipment!2!Cost]
			,NULL				[Shipment!2!CostWithDiscounts]
			,NULL				[Shipment!2!PercentageDiscounts]
			,NULL				[Shipment!2!BasePrice]

		FROM [DW].[FactSalesOfGoods] ss
		INNER JOIN [DW].[DocJournal] as doc
		ON ss.[CodeInIS] = doc.[CodeInIS]
   --     LEFT JOIN 
		 -- (SELECT MAX(jj.DocDate) DocDate, MAX(oo.OrderDate) OrderDate, MAX(oo.ShippingDate) ShippingDate, oo.CodeInIS, oo.InformationSystemID FROM [DW].[FactOrdersOfGoods] oo
			--INNER JOIN  [DW].[DocJournal] jj ON oo.CodeInIS = jj.CodeInIS
			--AND jj.InformationSystemID = oo.InformationSystemID
			--GROUP BY oo.CodeInIS,oo.InformationSystemID
		 -- ) o
		 -- ON ss.OrderID = o.CodeInIS
		 -- AND ss.InformationSystemID = o.InformationSystemID


		LEFT JOIN [DW].[DimOrganizations] as org
		ON doc.[OrgID] = org.[CodeInIS]
		  AND doc.InformationSystemID = org.InformationSystemID

		LEFT JOIN [DW].[DimContragents] as cn
		ON ss.[ContragentID] = cn.[CodeInIS]
		  AND ss.InformationSystemID = cn.InformationSystemID

		LEFT JOIN [DW].[DimDeliveryPlaces] as dp
		ON ss.[DeliveryPlaceID] = dp.[CodeInIS]
		  AND ss.InformationSystemID = dp.InformationSystemID

		WHERE ss.[CodeInIS] IN (SELECT ID FROM @IDTbl)

		GROUP BY 
			doc.[ID]	
			,doc.Marked
			,doc.Posted
			
			,doc.[DocNum]		
			,doc.[DocDate]		
			,org.[ID]			
			,org.[Description]	
			,cn.[ID]			
			,cn.[Name]			
			,dp.[ID]			
			,dp.[Name]	
			--,o.[DocDate] 
			--,o.[OrderDate]
			--,o.[ShippingDate]
		
		UNION ALL

		SELECT 
		2				[Tag]
		,1				[Parent]
		,doc.[ID]		[Shipment!1!CID]
		,null			[Shipment!1!Marked]	
		,null			[Shipment!1!Posted]	

		,null			[Shipment!1!DocNum]
		,null			[Shipment!1!DocDate]

		,null			[Shipment!1!OrgID]
		,null			[Shipment!1!OrgName]
	
		,null			[Shipment!1!ContragentID]
		,null			[Shipment!1!ContragentName]
	
		,null			[Shipment!1!DeliveryPlaceID]
		,null			[Shipment!1!DeliveryPlace]
		,null			[Shipment!1!ShippingDate]			
		,ord.DocDate							[Shipment!2!OrderDocDate]	
		,n.[ID]									[Shipment!2!NomenclatureID]
		,n.[MasterID]							[Shipment!2!NomenclatureMasterID]
		,n.[Name]								[Shipment!2!NomenclatureName]
		,SUM(ss.[Qty] * COALESCE(n.[Weight],1))	[Shipment!2!Qty]
		,ss.[Price]								[Shipment!2!Price]
		,SUM(ss.[Cost])							[Shipment!2!Cost]
		,SUM( ss.[Cost] - (ss.[Cost]*ss.[PercentageDiscounts])/100 )	[Shipment!2!CostWithDiscounts]
		,ss.[PercentageDiscounts]				[Shipment!2!PercentageDiscounts]
		,ss.[BasePrice]							[Shipment!2!BasePrice]

	FROM  [DW].[FactSalesOfGoods] ss

	INNER JOIN [DW].[DocJournal] as doc 
		ON ss.[CodeInIS] = doc.[CodeInIS]
		AND ss.InformationSystemID = doc.InformationSystemID

	INNER JOIN [DW].[DimNomenclatures] as n 
		ON ss.[NomenclatureID] = n.[CodeInIS]
		AND ss.InformationSystemID = n.InformationSystemID

	LEFT JOIN (
		SELECT DISTINCT jj.[DocDate],oo.[CodeInIS],oo.[NomenclatureID],oo.[InformationSystemID]
		FROM [DW].[FactOrdersOfGoods] oo
		INNER JOIN  [DW].[DocJournal] jj 
			ON oo.CodeInIS = jj.CodeInIS 
			AND jj.InformationSystemID = oo.InformationSystemID
		) as ord 
		ON ss.InformationSystemID = ord.InformationSystemID 
		AND ss.[OrderID] = ord.[CodeInIS] 
		AND ss.[NomenclatureID] = ord.[NomenclatureID]

	WHERE ss.[CodeInIS] IN (SELECT ID FROM @IDTbl)

	GROUP BY 
		doc.[ID]
		,ord.DocDate						
		,n.[ID]								
		,n.[MasterID]								
		,n.[Name]							
		,ss.[PercentageDiscounts]			
		,ss.[Price]							
		,ss.[BasePrice]							

	
	DECLARE @xml xml = (
	SELECT * FROM @sales ORDER BY [Shipment!1!ID],Tag 
	FOR XML EXPLICIT 
			,ROOT('Shipments')
			,BINARY BASE64
	)

	RETURN @xml;

END
