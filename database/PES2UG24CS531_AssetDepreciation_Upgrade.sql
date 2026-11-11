USE asset_db;

-- Task 1: ALTER
ALTER TABLE PART
    ADD COLUMN Stock_qty INT NOT NULL DEFAULT 0,
    ADD CONSTRAINT chk_part_stock CHECK (Stock_qty >= 0);

ALTER TABLE TECHNICIAN
    ADD CONSTRAINT uq_technician_phone UNIQUE (Phone_number);

UPDATE PART SET Stock_qty = 25 WHERE Part_id IN (1, 2, 3, 4, 5);

-- Task 2: Users and roles
CREATE TABLE APP_USER (
    User_id INT AUTO_INCREMENT PRIMARY KEY,
    Username VARCHAR(50) NOT NULL UNIQUE,
    Password_hash VARCHAR(255) NOT NULL,
    Role VARCHAR(20) NOT NULL CHECK (Role IN ('Admin', 'Technician')),
    Technician_id INT,
    FOREIGN KEY (Technician_id) REFERENCES TECHNICIAN(Technician_id) ON DELETE SET NULL
);

-- Task 3: Indexes and full-text search
CREATE INDEX idx_asset_status ON ASSET(Status);
CREATE INDEX idx_wo_asset_status ON WORK_ORDER(Asset_id, Status);
CREATE INDEX idx_depr_period ON DEPRECIATION_ENTRY(Period_date);
ALTER TABLE WORK_ORDER ADD FULLTEXT INDEX ft_wo_issue (Issue_description);

-- Task 4: Views
DROP VIEW IF EXISTS vw_asset_summary;
CREATE VIEW vw_asset_summary AS
SELECT a.Asset_id, a.Asset_name, c.Category_name, a.Status, a.Purchase_cost,
       a.Current_book_value, COALESCE(SUM(d.Depreciation_amount), 0) AS Total_depreciation
FROM ASSET a
JOIN ASSET_CATEGORY c ON a.Category_id = c.Category_id
LEFT JOIN DEPRECIATION_ENTRY d ON a.Asset_id = d.Asset_id
GROUP BY a.Asset_id, a.Asset_name, c.Category_name, a.Status, a.Purchase_cost, a.Current_book_value;

DROP VIEW IF EXISTS vw_open_work_orders;
CREATE VIEW vw_open_work_orders AS
SELECT w.Work_order_id, a.Asset_name, w.Issue_description, w.Priority, w.Status,
       w.Created_date, fn_work_order_cost(w.Work_order_id) AS Total_cost
FROM WORK_ORDER w JOIN ASSET a ON w.Asset_id = a.Asset_id
WHERE w.Status <> 'Closed';

DROP VIEW IF EXISTS vw_category_book_value;
CREATE VIEW vw_category_book_value AS
SELECT c.Category_name, COUNT(a.Asset_id) AS Assets,
       COALESCE(SUM(a.Purchase_cost), 0) AS Total_cost,
       COALESCE(SUM(a.Current_book_value), 0) AS Total_book_value
FROM ASSET_CATEGORY c LEFT JOIN ASSET a ON c.Category_id = a.Category_id
GROUP BY c.Category_id, c.Category_name;

-- Task 5: Transaction procedure
DROP PROCEDURE IF EXISTS sp_use_part;
DELIMITER //
CREATE PROCEDURE sp_use_part(IN p_wo INT, IN p_part INT, IN p_qty INT)
BEGIN
    DECLARE v_stock INT;
    DECLARE v_cost DECIMAL(10,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    SELECT Stock_qty, Unit_cost INTO v_stock, v_cost FROM PART WHERE Part_id = p_part FOR UPDATE;
    IF v_stock IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Part not found';
    END IF;
    IF v_stock < p_qty THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock';
    END IF;
    INSERT INTO WORK_ORDER_PART VALUES (p_wo, p_part, p_qty, v_cost)
    ON DUPLICATE KEY UPDATE Quantity_used = Quantity_used + VALUES(Quantity_used);
    UPDATE PART SET Stock_qty = Stock_qty - p_qty WHERE Part_id = p_part;
    COMMIT;
END//
DELIMITER ;

-- Task 6: Full-text search
SELECT Work_order_id, Issue_description
FROM WORK_ORDER
WHERE MATCH(Issue_description) AGAINST('overheating leak' IN NATURAL LANGUAGE MODE);