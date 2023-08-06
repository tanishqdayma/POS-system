USE pos;

ALTER TABLE orderLine ADD unitPrice DECIMAL (6,2);

ALTER TABLE orderLine ADD lineTotal DECIMAL (7,2) GENERATED ALWAYS AS (quantity * unitPrice) VIRTUAL;

ALTER TABLE `order` ADD orderTotal DECIMAL (8,2);

ALTER TABLE customer DROP COLUMN phone;

/* SHOW CREATE TABLE `order`;

Name of the foreign key constraint of status in order: order_ibfk_1 */

ALTER TABLE `order` DROP FOREIGN KEY order_ibfk_1;

ALTER TABLE `order` DROP FOREIGN KEY order_ibfk_2;

ALTER TABLE `order` ADD CONSTRAINT FOREIGN KEY (customerID) REFERENCES customer(ID);

ALTER TABLE `order` DROP COLUMN `status`;

DROP TABLE `status`;

/* Create Procedure proc_FillUnitPrice to replace only the blank values of unitPrice of orderLine with currentPrice product */
DELIMITER //
CREATE OR REPLACE PROCEDURE proc_FillUnitPrice ()
 BEGIN
  UPDATE orderLine ol INNER JOIN product p ON ol.productID=p.ID
  SET ol.unitPrice = p.currentPrice 
  WHERE ol.unitPrice IS NULL;
 END;
//
DELIMITER ;

/* call proc_FillUnitPrice();  */


/* Create Procedure proc_FillOrderTotal to fill OrderTotal with the sum of all of the lineTotal from orderLine for a particular order */
DELIMITER //
CREATE OR REPLACE PROCEDURE proc_FillOrderTotal ()
 BEGIN
  UPDATE `order` o SET orderTotal = (SELECT SUM(lineTotal) FROM orderLine WHERE orderID = o.ID GROUP BY orderID); 
 END;
//
DELIMITER ;

/* call proc_FillOrderTotal(); */


/* Create Procedure proc_FillMVCustomerPurchases to refresh the contents of the materialized view called mv_CustomerPurchase */
DELIMITER //
CREATE OR REPLACE PROCEDURE proc_FillMVCustomerPurchases ()
 BEGIN
  DELETE FROM mv_CustomerPurchases;
  INSERT INTO mv_CustomerPurchases SELECT * FROM v_CustomerPurchases; 
 END;
//
DELIMITER ;

/* call proc_FillMVCustomerPurchases(); */