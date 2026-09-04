-- -----------------------------------------------------
-- LittleLemonDB : sample data for the operational tables
--
--   addresses -> bookings -> orders -> order_items -> order_delivery_status
--
-- Run AFTER insert_customers.sql and insert_staff_menu.sql. The order of
-- the sections below is the foreign-key dependency order, so the script
-- runs top to bottom on a clean database with FOREIGN_KEY_CHECKS on.
--
-- Assumes the ID ranges produced by those two scripts on empty tables:
--   customer_id 1-10, staff_id 1-10, menu_item_id 1-17.
--
-- Constraints this data deliberately exercises:
--   * addresses  UNIQUE (customer_id, line1, postal_code)
--   * bookings   UNIQUE (table_number, booking_date), CHECK party_size > 0
--   * orders     nullable booking_id / staff_id (takeaway, delivery, unassigned)
--   * order_items UNIQUE (order_id, menu_item_id), CHECK quantity > 0,
--                 CHECK unit_price >= 0, generated line_total (never inserted)
--   * order_delivery_status  UNIQUE (order_id) and the BEFORE INSERT trigger
--                 that rejects a delivery order with no address_id
-- -----------------------------------------------------

USE `LittleLemonDB`;

-- -----------------------------------------------------
-- addresses : 9 rows for 8 customers
-- Customer 1 has two (home + work) to show the UNIQUE index keys on
-- (customer_id, line1, postal_code), not on customer_id alone.
-- Customers 7 and 10 have no address on file, which is legal and keeps
-- them out of any delivery flow.
-- -----------------------------------------------------
INSERT INTO `addresses`
    (`customer_id`, `line1`, `line2`, `city`, `region`, `postal_code`, `country_code`, `label`, `is_default`)
VALUES
    (1,  '12 Long Street',       'Unit 4B',   'Cape Town',    'Western Cape',  '8001', 'ZA', 'home',  1),
    (1,  '45 Adderley Street',   '3rd Floor', 'Cape Town',    'Western Cape',  '8000', 'ZA', 'work',  0),
    (2,  '8 Juta Street',        NULL,        'Johannesburg', 'Gauteng',       '2001', 'ZA', 'home',  1),
    (3,  '221 Florida Road',     'Flat 12',   'Durban',       'KwaZulu-Natal', '4001', 'ZA', 'home',  1),
    (4,  '17 Church Street',     NULL,        'Stellenbosch', 'Western Cape',  '7600', 'ZA', 'home',  1),
    (5,  '90 Jan Smuts Avenue',  'Block C',   'Johannesburg', 'Gauteng',       '2196', 'ZA', 'home',  1),
    (6,  '3 Marine Drive',       NULL,        'Gqeberha',     'Eastern Cape',  '6001', 'ZA', 'home',  1),
    (8,  '56 Umgeni Road',       NULL,        'Durban',       'KwaZulu-Natal', '4051', 'ZA', 'home',  1),
    (9,  '74 Voortrekker Road',  'Unit 9',    'Pretoria',     'Gauteng',       '0002', 'ZA', 'home',  1);

-- -----------------------------------------------------
-- bookings : 10 rows
-- Every (table_number, booking_date) pair is distinct, as the UNIQUE
-- index requires -- table 5 appears three times, always at a different
-- slot. Booking 8 leaves staff_id NULL (nobody assigned yet); bookings 6
-- and 7 are a no_show and a cancellation and so have no order attached.
-- -----------------------------------------------------
INSERT INTO `bookings`
    (`customer_id`, `staff_id`, `booking_date`, `table_number`, `party_size`, `status`)
VALUES
    (1,  2,    '2026-06-06 19:00:00', 5, 2, 'completed'),
    (2,  5,    '2026-06-06 19:30:00', 6, 4, 'completed'),
    (3,  6,    '2026-06-20 18:00:00', 3, 2, 'completed'),
    (4,  2,    '2026-07-04 20:00:00', 5, 6, 'completed'),
    (5,  7,    '2026-07-18 19:00:00', 8, 3, 'completed'),
    (6,  5,    '2026-07-25 18:30:00', 2, 2, 'no_show'),
    (7,  6,    '2026-08-01 19:00:00', 4, 5, 'cancelled'),
    (8,  NULL, '2026-08-08 20:30:00', 7, 2, 'completed'),
    (9,  2,    '2026-08-24 19:00:00', 5, 4, 'seated'),
    (10, 7,    '2026-08-29 18:00:00', 1, 8, 'reserved');

-- -----------------------------------------------------
-- orders : 12 rows
-- Seven dine_in orders tied to their booking, two takeaway and three
-- delivery orders with booking_id NULL. Orders 6 and 9 have no staff
-- member recorded, exercising the ON DELETE SET NULL side of the FK.
-- -----------------------------------------------------
INSERT INTO `orders`
    (`customer_id`, `booking_id`, `staff_id`, `order_date`, `order_type`)
VALUES
    (1,  1,    2,    '2026-06-06 19:45:00', 'dine_in'),   -- order 1
    (2,  2,    5,    '2026-06-06 20:10:00', 'dine_in'),   -- order 2
    (3,  3,    6,    '2026-06-20 18:40:00', 'dine_in'),   -- order 3
    (4,  4,    2,    '2026-07-04 20:35:00', 'dine_in'),   -- order 4
    (5,  5,    7,    '2026-07-18 19:40:00', 'dine_in'),   -- order 5
    (8,  8,    NULL, '2026-08-08 21:00:00', 'dine_in'),   -- order 6
    (9,  9,    2,    '2026-08-24 19:20:00', 'dine_in'),   -- order 7
    (3,  NULL, 6,    '2026-07-02 12:30:00', 'takeaway'),  -- order 8
    (6,  NULL, NULL, '2026-08-03 13:15:00', 'takeaway'),  -- order 9
    (1,  NULL, 8,    '2026-07-12 18:20:00', 'delivery'),  -- order 10
    (5,  NULL, 9,    '2026-08-05 19:05:00', 'delivery'),  -- order 11
    (9,  NULL, 8,    '2026-08-19 18:50:00', 'delivery');  -- order 12

-- -----------------------------------------------------
-- order_items : 41 lines across the 12 orders
--
-- `line_total` is a GENERATED column and is never listed in the INSERT --
-- MySQL computes quantity * unit_price for you.
--
-- `unit_price` is a snapshot of what the item cost on the day, which is
-- exactly why the column is duplicated off `menu` rather than joined:
--   * order 1 sold Lamb Souvlaki at 219.00, before the rise to 235.00
--   * order 3 sold Seafood Linguine, which is now is_available = 0
-- Both rows would be unreconstructable if totals joined to menu.price.
-- -----------------------------------------------------
INSERT INTO `order_items` (`order_id`, `menu_item_id`, `quantity`, `unit_price`) VALUES
    -- order 1 -- dine_in, table 5
    (1,  1,  1, 89.00),
    (1,  6,  2, 219.00),   -- historic price
    (1,  17, 2, 95.00),
    (1,  12, 1, 85.00),
    -- order 2 -- dine_in, party of 4
    (2,  2,  2, 115.00),
    (2,  5,  2, 189.00),
    (2,  8,  1, 205.00),
    (2,  10, 2, 55.00),
    (2,  15, 4, 45.00),
    -- order 3 -- dine_in
    (3,  7,  1, 265.00),   -- item since taken off the menu
    (3,  9,  1, 165.00),
    (3,  15, 2, 45.00),
    -- order 4 -- dine_in, party of 6, the big one
    (4,  4,  2, 105.00),
    (4,  6,  3, 235.00),
    (4,  8,  2, 205.00),
    (4,  11, 2, 69.00),
    (4,  13, 3, 95.00),
    (4,  17, 4, 95.00),
    -- order 5 -- dine_in
    (5,  3,  1, 79.00),
    (5,  5,  3, 189.00),
    (5,  16, 3, 38.00),
    -- order 6 -- dine_in, no staff recorded
    (6,  2,  1, 115.00),
    (6,  9,  2, 165.00),
    (6,  14, 2, 72.00),
    -- order 7 -- dine_in, in progress today
    (7,  1,  2, 89.00),
    (7,  6,  2, 235.00),
    (7,  10, 1, 55.00),
    (7,  15, 4, 45.00),
    -- order 8 -- takeaway
    (8,  9,  1, 165.00),
    (8,  10, 1, 55.00),
    -- order 9 -- takeaway
    (9,  2,  1, 115.00),
    (9,  16, 1, 38.00),
    -- order 10 -- delivery
    (10, 5,  2, 189.00),
    (10, 10, 2, 55.00),
    (10, 12, 2, 85.00),
    -- order 11 -- delivery
    (11, 8,  1, 205.00),
    (11, 11, 1, 69.00),
    (11, 15, 2, 45.00),
    -- order 12 -- delivery
    (12, 6,  1, 235.00),
    (12, 9,  1, 165.00),
    (12, 13, 2, 95.00);

-- -----------------------------------------------------
-- order_delivery_status : one row per delivery order
--
-- The UNIQUE index on order_id makes this effectively 1-to-1 with the
-- orders it tracks. Each address_id belongs to that order's customer:
--   order 10 -> customer 1 -> address 1
--   order 11 -> customer 5 -> address 6
--   order 12 -> customer 9 -> address 9
-- Order 12 is still in transit, so delivery_date stays NULL.
-- -----------------------------------------------------
INSERT INTO `order_delivery_status`
    (`order_id`, `address_id`, `delivery_date`, `status`)
VALUES
    (10, 1, '2026-07-12 19:05:00', 'delivered'),
    (11, 6, '2026-08-05 19:50:00', 'delivered'),
    (12, 9, NULL,                  'in_transit');


-- =====================================================================
-- VERIFICATION
-- =====================================================================

-- Row counts across every table
SELECT 'customers' AS table_name, COUNT(*) AS rows_loaded FROM `customers`
UNION ALL SELECT 'staff',                 COUNT(*) FROM `staff`
UNION ALL SELECT 'menu',                  COUNT(*) FROM `menu`
UNION ALL SELECT 'addresses',             COUNT(*) FROM `addresses`
UNION ALL SELECT 'bookings',              COUNT(*) FROM `bookings`
UNION ALL SELECT 'orders',                COUNT(*) FROM `orders`
UNION ALL SELECT 'order_items',           COUNT(*) FROM `order_items`
UNION ALL SELECT 'order_delivery_status', COUNT(*) FROM `order_delivery_status`;

-- The view earns its keep: totals derived from the line items
SELECT * FROM `v_order_totals` ORDER BY `order_id`;

-- Highest-spending customers
SELECT `customer_name`, COUNT(*) AS orders_placed, SUM(`total_cost`) AS lifetime_value
FROM `v_order_totals`
GROUP BY `customer_id`, `customer_name`
ORDER BY lifetime_value DESC
LIMIT 5;

-- Revenue by order type
SELECT `order_type`, COUNT(*) AS orders_placed, SUM(`total_cost`) AS revenue
FROM `v_order_totals`
GROUP BY `order_type`
ORDER BY revenue DESC;

-- Generated column check: line_total must equal quantity * unit_price
SELECT COUNT(*) AS mismatched_line_totals
FROM `order_items`
WHERE `line_total` <> `quantity` * `unit_price`;


-- =====================================================================
-- TRIGGER DEMONSTRATION -- commented out so the script runs clean.
-- Uncomment either statement to watch trg_ods_delivery_needs_address_ins
-- reject it with "A delivery order requires address_id."
-- =====================================================================
-- INSERT INTO `order_delivery_status` (`order_id`, `address_id`, `status`)
-- VALUES (10, NULL, 'pending');          -- fails: order 10 is a delivery
--
-- UPDATE `order_delivery_status` SET `address_id` = NULL WHERE `order_id` = 11;
--                                        -- fails on the UPDATE trigger
