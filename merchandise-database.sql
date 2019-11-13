--create database
CREATE DATABASE MerchandiseDB;
GO

USE MerchandiseDB
GO

--the first table created is merchandise to list the options that the customer has to buy
--the data is created manually, since the customers will need a set of options to buy the merchandise
--a stored procedure of inserting new merchandise will also be created
DROP TABLE IF EXISTS Merchandise
GO 

CREATE TABLE Merchandise (
merchandiseID INT PRIMARY KEY NOT NULL IDENTITY,
merchandisename NVARCHAR(20) NOT NULL,
price MONEY NOT NULL,
);
GO

INSERT INTO Merchandise VALUES (N'desktopA', '1000')
INSERT INTO Merchandise VALUES (N'desktopB', '800')
INSERT INTO Merchandise VALUES (N'laptopA', '1500')
INSERT INTO Merchandise VALUES (N'laptopB', '1200')
INSERT INTO Merchandise VALUES (N'softwareA', '300')
INSERT INTO Merchandise VALUES (N'softwareB', '200')
GO

SELECT * FROM Merchandise
GO

--second table is the customer table, it will have a FK constraint of merchandiseID for the purchase of products
--a stored procedure of inserting new customer will also be created.
CREATE TABLE Customer (
customerID INT PRIMARY KEY NOT NULL IDENTITY,
name NVARCHAR(20) NOT NULL,
purchaseID INT NOT NULL,
totalinvoice MONEY NOT NULL,
);
GO
--foreign key constraints in needed for the merchandiseID, since the customer's purchase depends on the availability of merchandise
ALTER TABLE dbo.Customer
ADD CONSTRAINT FK_purchaseID_customer FOREIGN KEY (purchaseID)
				REFERENCES dbo.Merchandise (merchandiseID)
	ON UPDATE CASCADE ON DELETE CASCADE;
GO

--the third table created is the merchandise return table, this will record a list of the returned merchandise, the new list price, and the reason of return
CREATE TABLE Returned_Merchandise (
returnID INT PRIMARY KEY NOT NULL IDENTITY,
customerID INT NOT NULL,
merchandiseID INT NOT NULL,
merchandiseName NVARCHAR(10) NOT NULL,
purchaseprice MONEY NOT NULL,
reason NVARCHAR(MAX) NOT NULL,
);

ALTER TABLE dbo.Returned_Merchandise
ADD CONSTRAINT FK_merchandiseID_returned FOREIGN KEY (merchandiseID)
				REFERENCES dbo.Merchandise (merchandiseID)
	ON UPDATE CASCADE ON DELETE CASCADE;
GO

--below is the stored procedure to add new merchandise
CREATE PROCEDURE sp_InsertNewMerc
			@NewMerc NVARCHAR(20),
			@NewPrice FLOAT
	
	AS
	DECLARE	@MerchID AS INT
		BEGIN
			-- Insert new Merchandise data.
			
			INSERT INTO dbo.Merchandise VALUES(@NewMerc, @NewMerc)
				
			-- To get new merchandise ID surrogate key value.
			
			SELECT	@MerchID = merchandiseID ---merchID as the knife
			FROM	dbo.Merchandise
			WHERE	merchandisename = @NewMerc
				AND	price = @NewPrice;
				
			PRINT '******************************************************'
			PRINT ''
			PRINT '   The new merchandise is now in the database. '
			PRINT ''
			PRINT '   Merchandise Name is' + @NewMerc
			PRINT '   Merchandise Price ' + @NewPrice
			PRINT ''
			PRINT '******************************************************'
		END
Go

--below is a procedure to add new customers
CREATE PROCEDURE sp_InsertNewCust
			@NewCust NVARCHAR(20),
			@NewPurchaseID INT,
			@NewTotalInvoice MONEY
	
	AS
	DECLARE	@RowCount AS INT
	DECLARE	@CustID AS INT

	SELECT	@RowCount = COUNT(*)
	FROM	dbo.Customer
	WHERE	name = @NewCust
		AND	purchaseID = @NewPurchaseID
		AND totalinvoice = @NewTotalInvoice;
		IF (@RowCount > 0)  --customer already exists if it does not meet this condition
		BEGIN
			PRINT '******************************************************'
			PRINT ''
			PRINT '   The customer is already in the database. '
			PRINT ''
			PRINT '   Customer Name is ' + @NewCust
			PRINT '   Purchase ID is '  + @NewPurchaseID
			PRINT '   Total Price is ' + @NewTotalInvoice
			PRINT ''
			PRINT '******************************************************'
			RETURN
		END
	ELSE
		BEGIN
			-- Insert new customer data.
			
			INSERT INTO dbo.Customer VALUES(@NewCust, @NewPurchaseID, @NewTotalInvoice)
				
			-- To get new merchandise ID surrogate key value.
			
			SELECT	@CustID = customerID ---custID as the knife
			FROM	dbo.Customer
			WHERE	name = @NewCust
				AND purchaseID = @NewPurchaseID
				AND	totalinvoice = @NewTotalInvoice;
				
			PRINT '******************************************************'
			PRINT ''
			PRINT '   The customer is now in the database. '
			PRINT ''
			PRINT '   Customer Name is ' + @NewCust
			PRINT '   Purchase ID is '  + @NewPurchaseID
			PRINT '   Total Price is ' + @NewTotalInvoice
			PRINT ''
			PRINT '******************************************************'
		END
GO

--Below is the procedure for returned products
CREATE PROCEDURE sp_ReturnedMerchandise
			@ReturnCust INT,
			@ReturnMercID INT,
			@ReturnMerc NVARCHAR (10),
			@Returnprice MONEY,
			@ReturnReason NVARCHAR(MAX)	
	AS
	DECLARE	@RowCount AS INT
	DECLARE	@ReturnID AS INT
	
	SELECT	@RowCount = COUNT(*)
	FROM	dbo.Returned_Merchandise
	WHERE	customerID = @ReturnCust
		AND	merchandiseID = @ReturnMercID
		AND merchandiseName = @ReturnMerc
		AND purchaseprice = @Returnprice
		AND reason = @ReturnReason;
		IF (@RowCount > 0)  --merchandise was already returned if it does not meet this condition
		BEGIN
			PRINT '******************************************************'
			PRINT ''
			PRINT '   The merchandise was already returned. '
			PRINT ''
			PRINT '   Return ID is ' + @ReturnID
			PRINT '   Customer ID is '  + @ReturnCust
			PRINT ''
			PRINT '******************************************************'
			RETURN
		END
	ELSE
		BEGIN
			-- Insert new customer data.
			
			INSERT INTO dbo.Returned_Merchandise VALUES(@ReturnCust, @ReturnMercID, @ReturnMerc, @Returnprice, @ReturnReason)
				
			-- To get new merchandise ID surrogate key value.
			
			SELECT	@ReturnID = returnID ---custID as the knife
			FROM	dbo.Returned_Merchandise
			WHERE	customerID = @ReturnCust
				AND merchandiseID = @ReturnMercID
				AND merchandiseName = @ReturnMerc
				AND purchaseprice = @Returnprice
				AND	reason = @ReturnReason;
				
			PRINT '******************************************************'
			PRINT ''
			PRINT '   The merchandise return is now in the database. '
			PRINT ''
			PRINT '   Customer ID is ' + @ReturnCust
			PRINT '   Merchandise ID is '  + @ReturnMerc
			PRINT '   Merchandise Name is '  + @ReturnMerc
			PRINT '   Purchase Price was '  + @Returnprice
			PRINT '   Return Reason is ' + @ReturnReason
			PRINT ''
			PRINT '******************************************************'
		END
GO


--new a trigger is created to insert the returned merchandise back into the Merchandise table
CREATE TRIGGER trReturnMerchandise ON dbo.Returned_Merchandise
AFTER INSERT
AS
	DECLARE @mercname NVARCHAR(20)
	DECLARE @mercprice INT

	SELECT @mercname = i.merchandiseName FROM INSERTED i;
	SELECT @mercprice = (SELECT (purchaseprice * 1.15) from Returned_Merchandise WHERE @mercname = merchandiseName)

	INSERT INTO Merchandise VALUES (@mercname, @mercprice)
GO

EXEC sp_InsertNewMerc
			@NewMerc = 'LaptopC',
			@NewPrice = '800'

EXEC sp_InsertNewCust
			@NewCust = 'JOHN',
			@NewPurchaseID = '2',
			@NewTotalInvoice = '800'

EXEC sp_ReturnedMerchandise
			@ReturnCust = '1',
			@ReturnMercID = '2',
			@ReturnMerc = 'DesktopB',
			@Returnprice = '800',
			@ReturnReason = 'defective'


