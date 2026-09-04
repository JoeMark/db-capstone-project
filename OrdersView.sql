USE LittleLemonDB;

CREATE OR REPLACE VIEW OrdersView AS
SELECT order_id, quantity, unit_price, line_total
FROM order_items
WHERE quantity > 2;



