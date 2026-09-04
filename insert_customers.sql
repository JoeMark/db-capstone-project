-- -----------------------------------------------------
-- LittleLemonDB : sample data for `customers`
-- Inserts 10 representative customer records.
--
-- Notes:
--   * `customer_id` is AUTO_INCREMENT, so it is omitted.
--   * `created_at` defaults to CURRENT_TIMESTAMP; explicit values are
--     supplied here so the sample set has a realistic signup spread.
--   * `phone` is NOT NULL, so every row carries one.
--   * `email` is nullable and UNIQUE. One row leaves it NULL, standing
--     for the walk-in who declined to give an address -- and proving the
--     UNIQUE index tolerates that. Add a second such customer and it
--     still inserts; MySQL does not compare NULLs in a unique index.
-- -----------------------------------------------------

USE `LittleLemonDB`;

INSERT INTO `customers`
    (`first_name`, `last_name`, `phone`, `email`, `created_at`)
VALUES
    ('Thandiwe', 'Mokoena',   '+27 82 415 7788', 'thandiwe.mokoena@gmail.com',   '2025-01-14 09:12:00'),
    ('Sipho',    'Dlamini',   '+27 71 302 4419', 'sipho.dlamini@webmail.co.za',  '2025-02-03 17:45:00'),
    ('Ayesha',   'Patel',     '+27 83 776 1230', 'ayesha.patel@outlook.com',     '2025-02-21 12:30:00'),
    ('Johan',    'van Wyk',   '+27 84 559 8802', 'jvanwyk@mweb.co.za',           '2025-03-08 19:05:00'),
    ('Lerato',   'Nkosi',     '+27 79 214 6653', 'lerato.nkosi@gmail.com',       '2025-03-27 11:20:00'),
    ('Michelle', 'Adams',     '+27 72 908 3374', 'michelle.adams@yahoo.com',     '2025-04-11 20:40:00'),
    ('Kagiso',   'Molefe',    '+27 76 133 5590', NULL,                           '2025-05-02 13:55:00'),
    ('Priya',    'Naidoo',    '+27 74 512 3096', 'priya.naidoo@gmail.com',       '2025-05-19 18:10:00'),
    ('Bongani',  'Zulu',      '+27 81 447 2265', 'bongani.zulu@webmail.co.za',   '2025-06-07 08:35:00'),
    ('Elmarie',  'Botha',     '+27 82 660 9143', 'elmarie.botha@gmail.com',      '2025-06-25 16:22:00');

-- Verify
SELECT `customer_id`, `first_name`, `last_name`, `phone`, `email`, `created_at`
FROM `customers`
ORDER BY `customer_id`;
