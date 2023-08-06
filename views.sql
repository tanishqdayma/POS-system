USE pos;

/*creation of view for list of all customer name displaying just the FN and LN */
CREATE OR REPLACE VIEW v_CustomerNames AS 
SELECT lastName AS `LN`, firstName AS FN 
FROM customer ORDER BY lastName, firstName;

/* SELECT * FROM v_CustomerNames; */

/*creation of view for list of all customer information */
CREATE OR REPLACE VIEW v_Customers AS 
SELECT c.ID AS customer_number, c.firstName AS first_name, c.lastName AS last_name, c.address1 AS street1, c.address2 AS street2, ci.`city`, ci.state, c.zip as zip_code, email 
FROM customer AS c INNER JOIN city AS ci ON c.zip = ci.zip;

/* SELECT * FROM v_Customers; */

/*creation of view for list of all products with the information of customer ID and names who have purchased that product  */

CREATE OR REPLACE VIEW v_ProductBuyers AS 
SELECT p.ID AS productID, p.`name` AS productName,
GROUP_CONCAT(DISTINCT c.ID," ",c.firstName," ",c.lastName order BY c.ID SEPARATOR',') AS "customers"
FROM product p LEFT JOIN orderLine ol
ON p.ID=ol.productID
LEFT JOIN `order` o
ON ol.orderID=o.ID
LEFT JOIN customer c 
ON o.customerID=c.ID
GROUP BY p.ID
;

/* SELECT * FROM v_ProductBuyers; */

/*creation of view for list of all customers with the information of all the products purchased by that customer  */

CREATE OR REPLACE VIEW v_CustomerPurchases AS 
SELECT c.ID, c.firstName, c.lastName,
GROUP_CONCAT(DISTINCT p.ID," ",p.`name` order BY p.ID SEPARATOR'|') AS "products"
FROM customer c LEFT JOIN `order` o
ON c.ID=o.customerID	
LEFT JOIN orderLine ol
ON o.ID=ol.orderID
LEFT JOIN product p
ON ol.productID = p.ID
GROUP BY c.ID
;

/* SELECT * FROM v_CustomerPurchases; */

/*creation of materialized view for list of all products with the information of customer ID and names who have purchased that product  */
CREATE OR REPLACE TABLE mv_ProductBuyers ENGINE=INNODB AS 
	SELECT * FROM v_ProductBuyers;

/* SELECT * FROM mv_ProductBuyers; */

/*creation of materialized view for list of all customers with the information of all the products purchased by that customer  */
CREATE OR REPLACE TABLE mv_CustomerPurchases ENGINE=INNODB AS 
	SELECT * FROM v_CustomerPurchases;


/* SELECT * FROM mv_CustomerPurchases; */

/* create index for email in customer table */
CREATE OR REPLACE INDEX idx_CustomerEmail ON customer (email);

/* SHOW INDEXES FROM customer;  */

/* create index for product name in product table */

CREATE OR REPLACE INDEX idx_ProductName ON product (`name`);

/* SHOW INDEXES FROM product; */
