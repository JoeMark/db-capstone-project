USE LittleLemonDB;

SELECT item_name AS MenuName
FROM menu
WHERE menu_item_id = ANY (
    SELECT menu_item_id
    FROM order_items
    WHERE quantity > 2
);