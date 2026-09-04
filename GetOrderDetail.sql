USE LittleLemonDB;

-- Prepare the statement
SET @sql = 'SELECT order_id, quantity, line_total FROM order_items WHERE order_item_id = ?';
PREPARE GetOrderDetail FROM @sql;

-- Set the input variable
SET @id = 1;

-- Execute the statement
EXECUTE GetOrderDetail USING @id;

DEALLOCATE PREPARE GetOrderDetail;