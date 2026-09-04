USE LittleLemonDB;

CREATE PROCEDURE GetMaxQuantity()
SELECT MAX(quantity)
FROM order_items;

