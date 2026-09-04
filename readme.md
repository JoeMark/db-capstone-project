# Little Lemon — Database Engineering Capstone

A relational database for the Little Lemon restaurant: customers, bookings,
orders, order lines, delivery tracking, menu and staff — with an analytics
view, triggers and the stored routines required by the capstone tasks.

MySQL 8.0+ / InnoDB.

---

## Reconstruct the database

Run these four scripts **in this order** — each depends on the one before:

```bash
mysql -u root -p < LittleLemonDB.sql              # schema, view, triggers
mysql -u root -p < insert_customers.sql           # customers, addresses
mysql -u root -p < insert_staff_menu.sql          # staff, menu
mysql -u root -p < insert_operational_data.sql    # bookings, orders, lines, deliveries
```

Then the task routines:

```bash
mysql -u root -p < GetMaxQuantity.sql
mysql -u root -p < CancelOrder.sql
mysql -u root -p < GetOrderDetail.sql
```

The first two install stored procedures and persist in the database.
`GetOrderDetail.sql` is a **prepared statement**, which is session-scoped: it
prepares, executes with `@id = 1`, prints its result and deallocates, leaving
nothing behind. Run it any time after the seed data is loaded — it needs
`order_item_id = 1` to exist. Expected output:

```
order_id  quantity  line_total
       1         1       89.00
```

Every script begins with `USE LittleLemonDB;`, so no database needs selecting.
`LittleLemonDB.sql` creates the schema itself.

**The seed scripts are not idempotent.** Run them once, on a clean database.
Re-running `insert_staff_menu.sql` duplicates all 10 staff rows before failing
on `menu`; the others are blocked by unique indexes. To start over:

```sql
DROP DATABASE IF EXISTS LittleLemonDB;
```

Verified on a clean MySQL 8.0.46 server, 2026-09-04:

| Table | Rows |
|---|---:|
| `customers` | 10 |
| `addresses` | 9 |
| `staff` | 10 |
| `menu` | 17 |
| `bookings` | 10 |
| `orders` | 12 |
| `order_items` | 41 |
| `order_delivery_status` | 3 |

The seed scripts print their own verification queries as they run, so you can
check these counts against your own output.

---

## Reverse engineer in MySQL Workbench

Two routes. Both produce an EER diagram.

### From the script — no server needed

1. **File → Import → Reverse Engineer MySQL Create Script…**
2. Choose `LittleLemonDB.sql`
3. Tick **Place imported objects on a diagram**
4. **Execute**

Use `LittleLemonDB.sql` for this, not a `mysqldump` file — Workbench's parser
handles a forward-engineered script cleanly, but stumbles on the conditional
comments and `DELIMITER` lines a dump contains.

### From the live database — after running the scripts above

1. **Database → Reverse Engineer…** (⌘R / Ctrl+R)
2. Pick your connection, **Next**
3. Select the **LittleLemonDB** schema
4. **Next** through object selection, then **Execute**

This route also brings across the data, which the script route cannot.

---

## What each file is

| File | Purpose |
|---|---|
| `LittleLemonDB.sql` | Schema, forward-engineered from Workbench, with the design reasoning in comment blocks. The Reverse Engineer input. |
| `insert_customers.sql` | Populates `customers` and `addresses`. |
| `insert_staff_menu.sql` | Populates `staff` and `menu`. |
| `insert_operational_data.sql` | Populates `bookings`, `orders`, `order_items`, `order_delivery_status`. |
| `GetMaxQuantity.sql` | Procedure returning the maximum quantity ordered. |
| `GetOrderDetail.sql` | Prepared statement returning order details by `order_item_id`. |
| `CancelOrder.sql` | Procedure deleting an order by id and confirming. |
| `little_lemon_conceptual_model_chen.png` | Conceptual model, Chen notation. |
| `little_lemon_erd_physical.png` | Physical ERD. |

---

## Referential integrity

`orders` is the hub. What happens to a related table depends on which end of
the relationship is deleted — referential actions travel from parent to child
only, never the reverse.

| Constraint | Child → Parent | `ON DELETE` | Reasoning |
|---|---|---|---|
| `fk_items_order` | `order_items` → `orders` | `CASCADE` | A line has no existence without its order. |
| `fk_ods_order` | `order_delivery_status` → `orders` | `CASCADE` | A 1:1 detail of the order. |
| `fk_orders_customer` | `orders` → `customers` | `RESTRICT` | A customer with order history cannot be deleted. |
| `fk_orders_booking` | `orders` → `bookings` | `SET NULL` | Cancelling a reservation must not erase a meal that was served. |
| `fk_orders_staff` | `orders` → `staff` | `SET NULL` | A departing employee does not take the sales record with them. |
| `fk_items_menu` | `order_items` → `menu` | `RESTRICT` | An item that has ever sold cannot be deleted; retire it with `is_available`. |
| `fk_ods_address` | `order_delivery_status` → `addresses` | `RESTRICT` | An address in use by a delivery cannot be deleted. |
| `fk_addresses_customer` | `addresses` → `customers` | `CASCADE` | An address is meaningless without its customer. |

So `CALL CancelOrder(5)` removes the order and its 3 line items and leaves
`bookings` untouched. Verified: `orders` 12 → 11, `order_items` for order 5
3 → 0, `bookings` unchanged at 10 with `booking_id = 5` still present.

`CancelOrder` is a hard delete and destroys revenue history. In production the
right operation is a status change — `order_delivery_status.status` already
carries `'cancelled'` for exactly that purpose.

---

## Design notes

`customers.phone` is `NOT NULL`; `customers.email` is nullable and `UNIQUE`.
Because `bookings.customer_id` and `orders.customer_id` are both `NOT NULL`,
no booking or order can exist without a `customers` row — so the table records
everyone the restaurant has served, not only registered account holders. A
mandatory email would bar the walk-in who declines to give one, and a
placeholder is worse than `NULL`: `NULL` honestly records "unknown", while a
placeholder pollutes mailing lists and, being `UNIQUE`, works exactly once.
The full argument is in the comment block above the table.

---

## Known gaps

- Nothing prevents `order_delivery_status.address_id` referencing an address
  belonging to a different customer than the order's. The fix is a composite
  foreign key on `(order_id, customer_id)` and `(address_id, customer_id)`;
  deferred because it changes the ERDs.
- `staff` has no unique constraint identifying a person, so the same employee
  can be entered twice.
- The seed scripts are not idempotent.
