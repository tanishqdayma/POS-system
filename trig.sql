/* trig.sql  */

USE pos;

/* call stored Procedures  */
call proc_FillUnitPrice();
call proc_FillOrderTotal();
call proc_FillMVCustomerPurchases();

/* Create a new table named priceChangeLog */

CREATE TABLE priceChangeLog (
	ID INT UNSIGNED NOT NULL AUTO_INCREMENT,
	oldPrice DECIMAL(6,2),
	newPrice DECIMAL(6,2),
	changeTimestamp TIMESTAMP,
	productid INT REFERENCES product (`ID`),
	PRIMARY KEY(ID)
)
ENGINE=INNODB;

/* Trigger 1  */

/* After Update on product */
DELIMITER //
CREATE OR REPLACE TRIGGER tr_after_update_product
AFTER UPDATE ON product
FOR EACH ROW
BEGIN
	IF OLD.currentPrice<>NEW.currentPrice THEN
		INSERT INTO priceChangeLog (oldPrice, newPrice, changeTimestamp, productid) 
		VALUES (OLD.currentPrice, NEW.currentPrice, CURRENT_TIMESTAMP, OLD.ID);
	END IF;
	call proc_ProductBuyers(NEW.ID);
END; //
DELIMITER ;


/* Trigger 2 */

/* Before UPDATE on orderLine  */

DELIMITER //
CREATE OR REPLACE TRIGGER tr_before_update_orderLine
BEFORE UPDATE ON orderLine
FOR EACH ROW 
BEGIN
	/* To update unitPrice everytime a new row is inserted or an existing row is updated in orderLine */
	SET NEW.unitPrice = (SELECT currentPrice FROM product WHERE ID = New.productID);
	/* To set quantity as 1 where it is NULL */
	IF NEW.quantity IS NULL THEN 
		SET NEW.quantity = 1;
	END IF;
END; 
//
DELIMITER ;

/* Trigger 3 */

/* Before Insert on orderLine */
DELIMITER //
CREATE OR REPLACE TRIGGER tr_before_insert_orderLine
BEFORE INSERT ON orderLine
FOR EACH ROW
BEGIN
	/* To update unitPrice everytime a new row is inserted or an existing row is updated in orderLine */
	SET NEW.unitPrice = (SELECT currentPrice FROM product WHERE ID = New.productID);
	/* To set quantity as 1 where it is NULL */
	IF NEW.quantity IS NULL THEN 
		SET NEW.quantity = 1;
	END IF;
END; 
//
DELIMITER ;

/* Trigger 4  */

/* After Update on orderLine */

DELIMITER //
CREATE OR REPLACE TRIGGER tr_after_update_orderLine 
AFTER UPDATE ON orderLine
FOR EACH ROW 
BEGIN
	/* To update the orderTotal everytime a new row is inserted, or an existing row is updated or deleted */
	UPDATE `order` SET orderTotal = (SELECT SUM(lineTotal) FROM orderLine WHERE orderID = `order`.ID GROUP BY orderID);
	/* To keep mv_ProductBuyers up to DATE */
	call proc_ProductBuyers(NEW.productID);
	/*  To keep mv_CustomerPurchases up to date   */
	SET @cust_id = (SELECT `order`.customerID FROM `order` WHERE `order`.ID = NEW.orderID);
	call proc_CustomerPurchases(@cust_id);
	/* Trigger to handle quantity aspects  */
	SET @qty = (SELECT product.qtyOnHand FROM product WHERE product.ID = NEW.productID);
	SET @net_quantity = NEW.quantity - OLD.quantity;
	IF @net_quantity <= @qty THEN
		UPDATE product SET product.qtyOnHand = product.qtyOnHand - @net_quantity WHERE product.ID = NEW.productID;
	ELSE
		SIGNAL SQLSTATE '45000' SET message_text = 'Not enough available.';
	END IF;
END;
//
DELIMITER ;


/* Trigger 5  */

/* After Insert on orderLine */

DELIMITER //
CREATE OR REPLACE TRIGGER tr_after_insert_orderLine 
AFTER INSERT ON orderLine
FOR EACH ROW 
BEGIN
	/* To update the orderTotal everytime a new row is inserted, or an existing row is updated or deleted */
	UPDATE `order` SET orderTotal = (SELECT SUM(lineTotal) FROM orderLine WHERE orderID = `order`.ID GROUP BY orderID);
	/* To keep mv_ProductBuyers up to DATE */
	call proc_ProductBuyers(NEW.productID);
	/*  To keep mv_CustomerPurchases up to date   */
	SET @cust_id = (SELECT `order`.customerID FROM `order` WHERE `order`.ID = NEW.orderID);
	call proc_CustomerPurchases(@cust_id);
	/* Trigger to handle quantity aspects  */
	SET @qty = (SELECT product.qtyOnHand FROM product WHERE product.ID = NEW.productID);
	IF NEW.quantity <= @qty THEN
		UPDATE product SET product.qtyOnHand = product.qtyOnHand - NEW.quantity WHERE product.ID = NEW.productID;
	ELSE
		SIGNAL SQLSTATE '45000' SET message_text = 'Not enough available.';
	END IF;
END;
//
DELIMITER ;


/* TRIGGER 6 */

/* After Delete on orderLine */

DELIMITER //
CREATE OR REPLACE TRIGGER tr_after_delete_orderLine 
AFTER DELETE ON orderLine
FOR EACH ROW 
BEGIN
	/* To update the orderTotal everytime a new row is inserted, or an existing row is updated or deleted */
	UPDATE `order` SET orderTotal = (SELECT SUM(lineTotal) FROM orderLine WHERE orderID = `order`.ID GROUP BY orderID);
	/* To keep mv_ProductBuyers up to DATE */
	call proc_ProductBuyers(OLD.productID);
	/*  To keep mv_CustomerPurchases up to date   */
	SET @cust_id = (SELECT `order`.customerID FROM `order` WHERE `order`.ID = OLD.orderID);
	call proc_CustomerPurchases(@cust_id);
	/* Trigger to handle quantity aspects  */
	UPDATE product SET product.qtyOnHand = product.qtyOnHand + OLD.quantity WHERE product.ID = OLD.productID;
END;
//
DELIMITER ;

/*  Procedure to keep mv_ProductBuyers up to date   */

DELIMITER //
CREATE OR REPLACE PROCEDURE proc_ProductBuyers (IN pid INT)
 BEGIN
  DELETE FROM mv_ProductBuyers WHERE productID=pid;
  INSERT INTO mv_ProductBuyers SELECT * FROM v_ProductBuyers WHERE productID = pid; 
 END;
//
DELIMITER ;


/*  Procedure to keep mv_CustomerPurchases up to date   */

DELIMITER //
CREATE OR REPLACE PROCEDURE proc_CustomerPurchases (IN cid INT)
 BEGIN
  DELETE FROM mv_CustomerPurchases WHERE ID=cid;
  INSERT INTO mv_CustomerPurchases SELECT * FROM v_CustomerPurchases WHERE ID=cid; 
 END;
//
DELIMITER ;









