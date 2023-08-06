DROP DATABASE if EXISTS pos;
CREATE DATABASE pos;

USE pos;
CREATE TABLE `city` (
	`zip` DECIMAL(5) UNSIGNED ZEROFILL NOT NULL PRIMARY KEY,       
	`city` VARCHAR(32),
	`state` VARCHAR(4)
)
ENGINE=INNODB;


CREATE TABLE `customer` (
	`ID` INT PRIMARY KEY,
	`firstName` VARCHAR(64),
	`lastName` VARCHAR(32),
	`email` VARCHAR(128),
	`address1` VARCHAR(128),
	`address2` VARCHAR(128),
	`phone` VARCHAR(32),
	`birthDate` DATE,
	`zip` DECIMAL(5) UNSIGNED ZEROFILL REFERENCES `city` (zip)
)
ENGINE=INNODB;


CREATE TABLE `status`(
	`status` TINYINT PRIMARY KEY,
	`description` VARCHAR(12)
)ENGINE=INNODB;



CREATE TABLE `order` (
	`ID` INT PRIMARY KEY,
	`datePlaced` DATE,
	`dateShipped` DATE,
	`status` TINYINT REFERENCES `status` (`status`),
	`customerID` INT REFERENCES `customer` (`ID`)
)ENGINE= INNODB;


CREATE TABLE `product` (
	`ID` INT PRIMARY KEY,
	`name` VARCHAR(128),
	`currentPrice` DECIMAL(6,2),
	`qtyOnHand` INT 
)ENGINE=INNODB;



CREATE TABLE `orderLine` (
	`orderID` INT NOT NULL,
	`productID` INT NOT NULL,
	`quantity` INT,
	FOREIGN KEY(`orderID`) REFERENCES `order`(`ID`),
	FOREIGN KEY(`productID`) REFERENCES `product`(`ID`),
	PRIMARY KEY(`orderID`, `productID`) 
)ENGINE=INNODB;



CREATE TABLE tempProduct LIKE `product`;

LOAD DATA LOCAL INFILE 'products.csv'
INTO TABLE tempProduct
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(ID, `name`, @price, qtyOnHand)
SET 
	currentPrice = REPLACE(REPLACE(@price,"$",""),",","") 
;  

INSERT INTO product (ID, `name`, `currentPrice`, `qtyOnHand`)
SELECT ID, `name`, `currentPrice`, `qtyOnHand`
FROM tempProduct;


CREATE TABLE `tempCust` (
	`ID` INT PRIMARY KEY,
	`firstName` VARCHAR(64),
	`lastName` VARCHAR(32),
	`city` VARCHAR(128),
	`state` VARCHAR(128),
	`zip` DECIMAL(5) UNSIGNED ZEROFILL NOT NULL,
	`address1` VARCHAR(32),
	`address2` VARCHAR(32),
	`email` VARCHAR(128),
	`birthDate` DATE
) ENGINE=INNODB;  

LOAD DATA LOCAL INFILE 'customers.csv'
INTO TABLE tempCust
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(ID, `firstName`, `lastName`, `city`, `state`, `zip`, `address1`, `address2`, `email`, @dob)
SET 
	birthDate = STR_TO_DATE(@dob, '%m/%d/%Y')
;

UPDATE tempCust SET birthDate = NULL WHERE birthDate ='0000-00-00';
UPDATE tempCust SET address2 = NULL WHERE address2 = "";


INSERT INTO city (zip, `city`, `state`)
SELECT DISTINCT zip, `city`, `state`
FROM tempCust
GROUP BY zip;


INSERT INTO customer (ID, `firstName`, `lastName`, `email`, `address1`, `address2`, `birthDate`, `zip`)
SELECT ID, `firstName`, `lastName`, `email`, `address1`, `address2`, `birthDate`, `zip`
FROM tempCust;


LOAD DATA LOCAL INFILE 'orders.csv'
INTO TABLE `order`
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(ID, customerID) 
;


CREATE TABLE `tempOrderLine` (
	`orderID` INT NOT NULL,
	`productID` INT NOT NULL
)ENGINE=INNODB;

LOAD DATA LOCAL INFILE 'orderlines.csv'
INTO TABLE tempOrderLine
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
(orderID, productID)
;

INSERT INTO orderLine (orderID, productID, quantity)
SELECT orderID, productID, COUNT(productID) 
FROM  tempOrderLine
GROUP BY orderID, productID;

DROP TABLE if EXISTS `tempCust`;
DROP TABLE if EXISTS `tempProduct`;
DROP TABLE if EXISTS `tempOrderLine`; 