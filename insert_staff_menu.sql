-- -----------------------------------------------------
-- LittleLemonDB : sample data for `staff` and `menu`
--
-- Both tables are FK-independent, so this script can run before or
-- after `insert_customers.sql`. Together the three give you enough
-- referential material to seed `bookings`, `orders` and `order_items`.
--
-- Notes:
--   * Surrogate keys are AUTO_INCREMENT and are omitted, so on a clean
--     table staff_id runs 1-10 and menu_item_id runs 1-17.
--   * `staff.role` is an ENUM; all six values are represented so
--     role-filtered queries return rows for every case.
--   * `staff.phone` is NOT NULL here (unlike customers.phone).
--   * `menu.price` is DECIMAL(8,2) and carries CHECK (price >= 0).
--   * `menu` has UNIQUE (item_name, category), so the same dish may
--     appear under two categories but not twice under one.
-- -----------------------------------------------------

USE `LittleLemonDB`;

-- -----------------------------------------------------
-- staff : 10 records, all six roles, one former employee
-- -----------------------------------------------------
INSERT INTO `staff`
    (`first_name`, `last_name`, `role`, `phone`, `hire_date`, `is_active`)
VALUES
    ('Nadia',     'Fourie',    'manager',     '+27 82 331 0092', '2021-03-15', 1),
    ('Adam',      'Ndlovu',    'head_waiter', '+27 71 884 5517', '2021-07-01', 1),
    ('Chuma',     'Sithole',   'chef',        '+27 83 220 7741', '2021-09-20', 1),
    ('Reza',      'Mahomed',   'chef',        '+27 84 617 3308', '2022-02-14', 1),
    ('Tebogo',    'Maseko',    'waiter',      '+27 79 445 9926', '2022-06-05', 1),
    ('Chantelle', 'Louw',      'waiter',      '+27 72 108 6634', '2023-01-16', 1),
    ('Sindi',     'Khumalo',   'host',        '+27 76 592 4180', '2023-04-03', 1),
    ('Farai',     'Chikwanda', 'driver',      '+27 81 736 2255', '2023-11-20', 1),
    ('Pieter',    'Steyn',     'driver',      '+27 82 904 7713', '2024-05-08', 1),
    ('Zanele',    'Mthembu',   'waiter',      '+27 73 261 8840', '2024-09-12', 0);

-- -----------------------------------------------------
-- menu : 17 items across five categories, one off the menu
-- -----------------------------------------------------
INSERT INTO `menu`
    (`item_name`, `category`, `price`, `is_available`)
VALUES
    -- Starters
    ('Hummus and Pita',        'Starters', 89.00,  1),
    ('Greek Salad',            'Starters', 115.00, 1),
    ('Bruschetta',             'Starters', 79.00,  1),
    ('Grilled Halloumi',       'Starters', 105.00, 1),
    -- Mains
    ('Lemon Herb Chicken',     'Mains',    189.00, 1),
    ('Lamb Souvlaki',          'Mains',    235.00, 1),
    ('Seafood Linguine',       'Mains',    265.00, 0),   -- seasonal, currently off
    ('Moussaka',               'Mains',    205.00, 1),
    ('Falafel Plate',          'Mains',    165.00, 1),
    -- Sides
    ('Rosemary Fries',         'Sides',    55.00,  1),
    ('Grilled Vegetables',     'Sides',    69.00,  1),
    -- Desserts
    ('Baklava',                'Desserts', 85.00,  1),
    ('Lemon Tart',             'Desserts', 95.00,  1),
    ('Greek Yoghurt and Honey','Desserts', 72.00,  1),
    -- Drinks
    ('Mint Lemonade',          'Drinks',   45.00,  1),
    ('Turkish Coffee',         'Drinks',   38.00,  1),
    ('House Red (Glass)',      'Drinks',   95.00,  1);

-- -----------------------------------------------------
-- Verify
-- -----------------------------------------------------
SELECT `staff_id`, `first_name`, `last_name`, `role`, `hire_date`, `is_active`
FROM `staff`
ORDER BY `staff_id`;

SELECT `menu_item_id`, `item_name`, `category`, `price`, `is_available`
FROM `menu`
ORDER BY `category`, `item_name`;

-- Roles actually on the books, for a quick sanity check
SELECT `role`, COUNT(*) AS headcount
FROM `staff`
WHERE `is_active` = 1
GROUP BY `role`
ORDER BY headcount DESC, `role`;
