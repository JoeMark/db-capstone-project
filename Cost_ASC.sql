USE LittleLemonDB;

SELECT customers.customer_id AS CustomerID, CONCAT(customers.first_name, ' ', customers.last_name) AS `Full Name`,
orders.order_id AS OrderID, order_items.line_total AS Cost, menu.item_name AS MenuName, 
menu.category AS CourseCategory
FROM customers
INNER JOIN orders
ON customers.customer_id = orders.customer_id
INNER JOIN order_items
ON orders.order_id = order_items.order_id
INNER JOIN menu
ON order_items.menu_item_id = menu.menu_item_id
ORDER BY Cost ASC;
