-- Q1
with people as 
(select FullName, PhoneNumber, FaxNumber, SUBSTRING(EmailAddress, CHARINDEX( '@', [EmailAddress] ) + 1, len([EmailAddress])) as domain_name
from Application.People),
c_company as 
(select phoneNumber, FaxNumber, SUBSTRING(domain_name, 0, CHARINDEX('/',domain_name)) as domain_name
from (select PhoneNumber, FaxNumber, SUBSTRING(WebsiteURL, CHARINDEX( '.', [WebsiteURL] ) + 1, len([WebsiteURL])) as domain_name
from sales.Customers) as c),
s_company as(
select PhoneNumber, FaxNumber, SUBSTRING(WebsiteURL, CHARINDEX( '.', [WebsiteURL] ) + 1, len([WebsiteURL])) as domain_name
from Purchasing.Suppliers)

select distinct FullName, p.PhoneNumber, p.FaxNumber, c.PhoneNumber as company_phone, c.FaxNumber as company_fax
from people as p,
c_company as c,
s_company as s
where p.PhoneNumber = c.PhoneNumber
or p.FaxNumber = c.FaxNumber
or p.domain_name = s.domain_name

-- Q2
select c.CustomerName
from sales.Customers c
join Application.people as p
on c.PrimaryContactPersonID = p.PersonID
where c.PhoneNumber = p.PhoneNumber

-- Q3

select customerID
from sales.Orders
group by CustomerID, orderdate
having max(OrderDate) < '2016-01-01'


-- Q4
select StockItemID, sum(OrderedOuters)  as total_quantity
from Purchasing.PurchaseOrders as p1
join Purchasing.PurchaseOrderLines as p2
on p1.PurchaseOrderID = p2.PurchaseOrderID
where year(OrderDate) = 2013
group by stockItemID
order by StockItemID

-- Q5
select distinct StockItemID
from Purchasing.PurchaseOrderLines
where len(Description) >= 10

-- Q6
select distinct StockItemID
from Sales.Customers as c
join Application.Cities as ci
on c.DeliveryCityID = ci.CityID
join Application.StateProvinces as s
on ci.StateProvinceID = s.StateProvinceID
join Sales.Invoices as i
on c.CustomerID = i.CustomerID
join Sales.InvoiceLines as il
on i.InvoiceID = il.InvoiceID
where year(InvoiceDate) = 2014
and StateProvinceName != 'Alabama'
and StateProvinceName != 'Georgia'

-- Q7
select StateProvinceName, AVG(DATEDIFF(day, OrderDate, ConfirmedDeliveryTime)) as avg_day
from Sales.Invoices as i
join Sales.Orders as o
on i.OrderID = o.OrderID
join Sales.Customers as c
on o.CustomerID = c.CustomerID
join Application.Cities as ci
on c.DeliveryCityID = ci.CityID
join Application.StateProvinces as sp
on sp.StateProvinceID = ci.StateProvinceID
group by StateProvinceName

-- Q8
select StateProvinceName, MONTH(orderdate) as month, AVG(DATEDIFF(DAY, OrderDate, ConfirmedDeliveryTime)) as avg_day
from Sales.Invoices as i
join Sales.Orders as o
on i.OrderID = o.OrderID
join Sales.Customers as c
on o.CustomerID = c.CustomerID
join Application.Cities as ci
on c.DeliveryCityID = ci.CityID
join Application.StateProvinces as sp
on sp.StateProvinceID = ci.StateProvinceID
group by StateProvinceName, MONTH(orderdate)
order by StateProvinceName, MONTH(orderdate)

-- Q9
select StockItemID, sum(Quantity) as quantity
from Warehouse.StockItemTransactions
where year(TransactionOccurredWhen) = 2015
group by StockItemID
having sum(quantity) > 0

-- Q10
select c.CustomerName, c.PhoneNumber, p.FullName as Primary_Contact_Person
from Sales.Customers as c
join Application.People as p
on c.PrimaryContactPersonID = p.PersonID
where c.CustomerID not in
(select o.CustomerID
from sales.Orders as o
join sales.OrderLines as ol
on o.OrderID = ol.OrderID
where ol.Description like '%mug%'
and year(o.OrderDate) = 2016
and ol.Quantity > 10)

-- Q11
select c.CityName
from Application.Cities as c
join Application.StateProvinces as s
on c.StateProvinceID = s.StateProvinceID
where year(s.ValidFrom) = 2015

-- Q12
select StockItemID, Description, i.DeliveryInstructions, CityName, StateProvinceName, CountryName, o.ContactPersonID, PhoneNumber, Quantity
from Sales.Orders as o
join Sales.OrderLines as ol
on o.OrderID = ol.OrderID
join Sales.Invoices as i
on o.CustomerID = i.CustomerID
join Sales.customers as c
on c.CustomerID = o.CustomerID
join Application.Cities as ci
on ci.CityID = c.DeliveryCityID
join Application.StateProvinces as sp
on ci.StateProvinceID = sp.StateProvinceID
join Application.Countries as cty
on sp.CountryID = cty.CountryID
where orderdate = '2014-07-01'

-- Q13
select sg.StockGroupID, sum(total_quantity_purchased) as total_quantity_purchased, sum(total_quantity_sold) as total_quantity_sold, sum(total_quantity_purchased-total_quantity_sold) as total_remaining_stock_quantity
from (select StockItemID, sum(quantity) as total_quantity_sold
from Warehouse.StockItemTransactions
where Quantity < 0
group by StockItemID) as t1
join
(select st.StockItemID, sum(quantity + QuantityOnHand) as total_quantity_purchased
from Warehouse.StockItemTransactions as st
join Warehouse.StockItemHoldings as sh
on st.StockItemID = sh.StockItemID
where Quantity > 0
group by st.StockItemID) as t2
on t1.StockItemID = t2.StockItemID
join Warehouse.StockItemStockGroups as sisg
on t1.StockItemID = sisg.StockItemID
join Warehouse.StockGroups as sg
on sisg.StockGroupID = sg.StockGroupID
group by sg.StockGroupID
order by sg.StockGroupID

-- Q14
WITH cte0 AS (SELECT ol.StockItemID, c.DeliveryCityID, COUNT(*) AS Delivery 
FROM Sales.OrderLines as ol
JOIN Sales.Orders as o 
ON o.OrderID = ol.OrderID
JOIN sales.Customers as c 
ON o.CustomerID = c.CustomerID
WHERE YEAR(o.OrderDate) = 2016
GROUP BY ol.StockItemID, c.DeliveryCityID),
cte1 AS(SELECT StockItemID, DeliveryCityID 
FROM ( 
SELECT StockItemID, DeliveryCityID, 
DENSE_RANK() OVER(PARTITION BY DeliveryCityId ORDER BY Delivery DESC) AS rnk
FROM cte0) as a 
WHERE rnk = 1)
SELECT c.CityName, ISNULL(s.StockItemName, 'No Sale') AS MostDelivery
FROM cte1 as c1 
JOIN Warehouse.StockItems as s 
ON c1.StockItemID = s.StockItemID
RIGHT JOIN Application.Cities as c 
ON c1.DeliveryCityID = c.CityID

-- Q15
select OrderID
from Sales.Invoices
where ReturnedDeliveryData like '%Receiver not present%'


-- Q16
select StockItemID, StockItemName, CustomFields
from Warehouse.StockItems
where CustomFields like '%China%'

-- Q17
select country, sum(Quantity) as total_quantity
from(
select SUBSTRING(SUBSTRING(CustomFields, CHARINDEX( ':', CustomFields ) + 1, len(CustomFields)), 0, CHARINDEX( ',', SUBSTRING(CustomFields, CHARINDEX( ':', CustomFields ) + 1, len(CustomFields)) )) as country,
Quantity
from Sales.OrderLines as o
join Warehouse.StockItems as s
on s.StockItemID = o.StockItemID
where year(PickingCompletedWhen) = 2015) as sub
group by country

-- Q18
CREATE VIEW Sales.StockItemByYear AS WITH cte0 AS (
SELECT StockGroupName, 2013 AS [Year]
FROM Warehouse.StockGroups
UNION ALL
SELECT StockGroupName, [Year] + 1
FROM cte0
WHERE [Year] < 2017
),
cte1 AS (SELECT YEAR(o.OrderDate) AS [Year], sg.StockGroupName, SUM(ol.Quantity) AS Quantity
FROM Sales.Orders o
JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
JOIN Warehouse.StockItems s ON ol.StockItemID =s.StockItemID
JOIN Warehouse.StockItemStockGroups g ON g.StockItemID = s.StockItemID
JOIN Warehouse.StockGroups sg ON g.StockGroupID = sg.StockGroupID WHERE YEAR(o.OrderDate) BETWEEN 2013 AND 2017
GROUP BY YEAR(o.OrderDate), sg.StockGroupName),
cte2 AS (SELECT c0.StockGroupName, c0.[Year], ISNULL(c1.Quantity, 0) AS Quantity FROM cte0 c0
LEFT JOIN cte1 c1 ON c0.[Year] = c1.[Year] AND c0.StockGroupName = c1.StockGroupName
	)SELECT StockGroupName, [2013], [2014], [2015], [2016], [2017]
FROM cte2 PIVOT
(MIN(Quantity) FOR Year IN ([2013], [2014], [2015], [2016], [2017])) TBL

-- Q19
CREATE OR ALTER VIEW TotalQuantities2 AS
WITH temp AS(SELECT SOL.StockItemID, SUM(SOL.Quantity) AS TotalQuanPerStockItem,YEAR(SO.OrderDate) 
AS OrderYear FROM Sales.Orders SO 
JOIN Sales.OrderLines SOL ON SO.OrderID=SOL.OrderID WHERE YEAR(SO.OrderDate) BETWEEN '2013' AND '2017'
GROUP BY StockItemID,YEAR(SO.OrderDate)),
temp2 AS(SELECT SISG.StockGroupID, temp.OrderYear, SUM(temp.TotalQuanPerStockItem) AS TotalQuanPerGroupYear 
FROM Warehouse.StockItemStockGroups SISG JOIN temp ON SISG.StockItemID = temp.StockItemID 
GROUP BY SISG.StockGroupID, temp.OrderYear)
SELECT OrderYear, [1] AS Group1, [2] AS Group2, [3] AS Group3, [4] AS Group4,
[5] AS Group5, [6] AS Group6, [7] AS Group7, [8] AS Group8, [9] AS Group9, [10] AS Group10 FROM
(SELECT * FROM temp2) AS SourceTable 
PIVOT(
MIN(TotalQuanPerGroupYear) FOR StockGroupID IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])
) AS PivotTable;
SELECT * FROM TotalQuantities2 ORDER BY OrderYear;

-- Q20
CREATE OR ALTER FUNCTION dbo.udf20(@OrderId INT) 
RETURNS DEC(18,2) AS
BEGIN
DECLARE @OrderTotal DEC(18,2);
SELECT @OrderTotal = SUM((Quantity*UnitPrice)) FROM Sales.OrderLines SOL 
WHERE SOL.OrderID = @OrderId;
RETURN @OrderTotal;
END;
SELECT * FROM Sales.Invoices SI CROSS APPLY (SELECT dbo.udf20(SI.OrderID)) AS TAB(OrderTotal);

-- Q21
CREATE SCHEMA ods
GO
CREATE TABLE ods.Orders
(OrderID INT PRIMARY KEY,
OrderDate DATE,
OrderTotal DECIMAL(18, 2),
CustomerID INT)
GO
CREATE PROCEDURE ods.OrderTotalOfDate @OrderDate DATE
AS 
IF EXISTS (SELECT 1 FROM ods.Orders WHERE OrderDate = @OrderDate)
	BEGIN
		RAISERROR('Date Exists ', 16, 1)
	END
ELSE
BEGIN
BEGIN TRANSACTION
INSERT INTO ods.Orders
SELECT o.OrderID, o.OrderDate, f.Total, o.CustomerID
FROM Sales.Orders o
CROSS APPLY Sales.OrderTotal(OrderID) f
WHERE o.OrderDate = @OrderDate
COMMIT
END
GO
EXEC ods.OrderTotalOfDate '2013-01-01'
EXEC ods.OrderTotalOfDate '2013-01-02'
EXEC ods.OrderTotalOfDate '2013-01-03'
EXEC ods.OrderTotalOfDate '2013-01-04'
EXEC ods.OrderTotalOfDate '2013-01-05'

-- Q25
SELECT Year AS Year,
	[Novelty Items] AS 'StockGroup.Novelty Items',
	[Clothing] AS 'StockGroup.Clothing', 
	[Mugs] AS 'StockGroup.Mugs',
	[T-Shirts] AS 'StockGroup.T-Shirts',
	[Airline Novelties] AS 'StockGroup.Airline Novelties', 
	[Computing Novelties] AS 'StockGroup.Computing Novelties', 
	[USB Novelties] AS 'StockGroup.USB Novelties', 
	[Furry Footwear] AS 'StockGroup.Furry Footwear', 
	[Toys] AS 'StockGroup.Toys', 
	[Packaging Materials] AS 'StockGroup.Packaging Materials'
FROM Sales.StockItemByName 
FOR JSON PATH

-- Q26
SELECT Year AS '@Year',
	[Novelty Items] AS NoveltyItems,
	[Clothing], 
	[Mugs],
	[T-Shirts],
	[Airline Novelties] AS AirlineNovelties, 
	[Computing Novelties] AS ComputingNovelties, 
	[USB Novelties] AS USBNovelties, 
	[Furry Footwear] AS FurryFootwear, 
	[Toys], 
	[Packaging Materials] AS PackagingMaterials
FROM Sales.StockItemByName 
FOR XML PATH('StockItems')



