USE pos;

-- create view v_productNames Views
CREATE OR REPLACE VIEW v_productNames AS 
SELECT p.ID, p.`name` AS pname, ol.orderID, ol.lineTotal AS ltotal, ol.quantity AS qty, ol.unitPrice AS up
FROM orderLine ol JOIN product p
ON p.ID = ol.productID;

-- create json_object to create the appropriate aggregate
/* Select json_object("Name", CONCAT(first_name," ", last_name),"Address", CONCAT_WS(",",street1,city,state,zip_code),"Email",email,"Orders", 
json_arrayagg(JSON_OBJECT("Order ID",`order`.id,"Order Total",`order`.orderTotal, "Date Shipped", `order`.dateShipped,"Date Order Placed",`order`.datePlaced,"Products", (select json_arrayagg(JSON_OBJECT("productName", pname,"lineTotal", ltotal,"quantity",qty,"Unit Price",up)) 
FROM v_productNames WHERE orderID = `order`.ID)))) 
FROM v_customers JOIN `order` ON `order`.customerID = v_customers.customer_number WHERE v_customers.customer_number=1;
into OUTFILE 'bob.json'; */


-- CREATE PROCEDURE TO GENERATE JSON FILE FOR EACH CUSTOMER
DELIMITER %%
CREATE OR REPLACE PROCEDURE CREATE_JSON_FILE(IN cust_id INT)

BEGIN
SET @jsoncreate = CONCAT('Select json_object("Name", CONCAT(first_name," ", last_name),"Address", CONCAT_WS(",",street1,city,state,zip_code),"Email",email,"Orders", 
json_arrayagg(JSON_OBJECT("Order ID",`order`.id,"Order Total",`order`.orderTotal, "Date Shipped", `order`.dateShipped,"Date Order Placed",`order`.datePlaced,"Products", (select json_arrayagg(JSON_OBJECT("productName", pname,"lineTotal", ltotal,"quantity",qty,"Unit Price",up)) 
FROM v_productNames WHERE orderID = `order`.ID)))) 
FROM v_Customers JOIN `order` ON `order`.customerID = v_Customers.customer_number WHERE v_Customers.customer_number=',cust_id,' into OUTFILE "cust_json_',cust_id,'.json"');

PREPARE statement  FROM @jsoncreate;
EXECUTE statement;
DEALLOCATE PREPARE statement;

END %%

DELIMITER ;


-- CREATE LOOP TO CALL CREATE_JSON_FILE 
DELIMITER %% 
CREATE OR REPLACE PROCEDURE RUN_LOOP_THROUGH_CUST()

BEGIN
DECLARE i INT DEFAULT 0;
SET @n = (SELECT COUNT(*) FROM customer);
WHILE i < @n DO
CALL CREATE_JSON_FILE(i);
SET i = i + 1;
END while;

END %%

DELIMITER ;

-- Call the loop stored procedure
CALL RUN_LOOP_THROUGH_CUST();


