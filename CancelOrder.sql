USE LittleLemonDB;

-- -----------------------------------------------------
-- CancelOrder(p_order_id)
--
-- Deletes an order record based on user input of the order id and
-- returns a confirmation message.
--
-- NOTE ON THE PARAMETER NAME
--   The parameter is p_order_id, NOT order_id. Inside a routine body a
--   parameter outranks a column of the same name, so writing
--       CREATE PROCEDURE CancelOrder(IN order_id INT) ...
--       DELETE FROM orders WHERE order_id = order_id;
--   resolves BOTH sides to the parameter. The predicate is always true
--   and the statement empties the entire orders table -- and, by
--   ON DELETE CASCADE, order_items and order_delivery_status with it.
--
-- WHAT THE DELETE TOUCHES
--   orders                 1 row removed
--   order_items            all lines for that order removed  (ON DELETE CASCADE)
--   order_delivery_status  its single row removed            (ON DELETE CASCADE)
--   bookings               untouched -- `orders` is the CHILD of `bookings`,
--                          and referential actions travel parent -> child only
-- -----------------------------------------------------

DROP PROCEDURE IF EXISTS CancelOrder;

DELIMITER //

CREATE PROCEDURE CancelOrder(IN p_order_id INT)
BEGIN
    DELETE FROM orders
     WHERE order_id = p_order_id;

    -- ROW_COUNT() reports the previous statement only, so it is read here
    -- and nowhere later -- any intervening statement resets it.
    IF ROW_COUNT() = 0 THEN
        SELECT CONCAT('Order ', p_order_id, ' not found - nothing cancelled.')
               AS Confirmation;
    ELSE
        SELECT CONCAT('Order ', p_order_id, ' is cancelled')
               AS Confirmation;
    END IF;
END//

DELIMITER ;

-- -----------------------------------------------------
-- Test
-- -----------------------------------------------------
-- CALL CancelOrder(5);
--   -> Confirmation: Order 5 is cancelled
-- CALL CancelOrder(999);
--   -> Confirmation: Order 999 not found - nothing cancelled.
--
-- This is a hard delete and is NOT undone by an enclosing ROLLBACK if the
-- session is in autocommit. Take a dump before running it if you still
-- need the seed data for the remaining tasks.
