USE asset_db;

-- Test 1: salvage value above purchase cost (expect CHECK violation)
INSERT INTO ASSET (Asset_name, Purchase_date, Purchase_cost, Salvage_value, Category_id, Location_id)
VALUES ('Test Asset', '2025-01-01', 1000, 5000, 1, 1);

-- Test 2: negative part cost (expect CHECK violation)
INSERT INTO PART (Part_name, Unit_cost) VALUES ('Bad Part', -10);

-- Test 3: work order for a missing asset (expect FOREIGN KEY violation)
INSERT INTO WORK_ORDER (Asset_id, Issue_description, Priority, Created_date)
VALUES (999, 'No such asset', 'Low', '2025-01-01');

-- Test 4: duplicate category name (expect UNIQUE violation)
INSERT INTO ASSET_CATEGORY (Category_name, Default_useful_life) VALUES ('IT Equipment', 3);

-- Test 5: invalid user role (expect CHECK violation)
INSERT INTO APP_USER (Username, Password_hash, Role) VALUES ('guest', 'x', 'Guest');

-- Test 6: opening a work order marks the asset Under Maintenance
INSERT INTO WORK_ORDER (Asset_id, Issue_description, Priority, Created_date)
VALUES (4, 'Test: table leg broken', 'Low', CURDATE());
SELECT Asset_id, Status FROM ASSET WHERE Asset_id = 4;

-- Test 7: closing it returns the asset to Active
UPDATE WORK_ORDER SET Status = 'Closed' WHERE Work_order_id = LAST_INSERT_ID();
SELECT Asset_id, Status FROM ASSET WHERE Asset_id = 4;

-- Test 8: depreciation trigger updates book value
SELECT Current_book_value FROM ASSET WHERE Asset_id = 6;
CALL sp_post_depreciation(6, '2026-03-31');
SELECT Current_book_value FROM ASSET WHERE Asset_id = 6;

-- Test 9: transaction commit, stock reduces by 2
SELECT Stock_qty FROM PART WHERE Part_id = 3;
CALL sp_use_part(2, 3, 2);
SELECT Stock_qty FROM PART WHERE Part_id = 3;

-- Test 10: transaction rollback on insufficient stock (expect error, stock unchanged)
CALL sp_use_part(2, 3, 1000);
SELECT Stock_qty FROM PART WHERE Part_id = 3;

-- Test 11: deleting a work order cascades to its parts
SELECT COUNT(*) FROM WORK_ORDER_PART WHERE Work_order_id = 5;
DELETE FROM WORK_ORDER WHERE Work_order_id = 5;
SELECT COUNT(*) FROM WORK_ORDER_PART WHERE Work_order_id = 5;

-- Test 12: full-text search
SELECT Work_order_id FROM WORK_ORDER WHERE MATCH(Issue_description) AGAINST('hydraulic leak');
