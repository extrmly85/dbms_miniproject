USE asset_db;

-- Task 1: Triggers, procedure and function
DELIMITER //

CREATE TRIGGER trg_asset_init_book_value
BEFORE INSERT ON ASSET
FOR EACH ROW
BEGIN
    IF NEW.Current_book_value IS NULL THEN
        SET NEW.Current_book_value = NEW.Purchase_cost;
    END IF;
END//

CREATE TRIGGER trg_depr_update_book_value
AFTER INSERT ON DEPRECIATION_ENTRY
FOR EACH ROW
BEGIN
    UPDATE ASSET
    SET Current_book_value = Purchase_cost - NEW.Accumulated_depreciation
    WHERE Asset_id = NEW.Asset_id;
END//

CREATE TRIGGER trg_wo_open
AFTER INSERT ON WORK_ORDER
FOR EACH ROW
BEGIN
    IF NEW.Status <> 'Closed' THEN
        UPDATE ASSET SET Status = 'Under Maintenance' WHERE Asset_id = NEW.Asset_id;
    END IF;
END//

CREATE TRIGGER trg_wo_close
AFTER UPDATE ON WORK_ORDER
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Closed' AND OLD.Status <> 'Closed' THEN
        IF NOT EXISTS (SELECT 1 FROM WORK_ORDER WHERE Asset_id = NEW.Asset_id AND Status <> 'Closed') THEN
            UPDATE ASSET SET Status = 'Active' WHERE Asset_id = NEW.Asset_id;
        END IF;
    END IF;
END//

CREATE PROCEDURE sp_post_depreciation(IN p_asset_id INT, IN p_period DATE)
BEGIN
    DECLARE v_cost, v_salvage, v_annual, v_acc DECIMAL(12,2);
    DECLARE v_life, v_next INT;

    SELECT a.Purchase_cost, a.Salvage_value, c.Default_useful_life
    INTO v_cost, v_salvage, v_life
    FROM ASSET a JOIN ASSET_CATEGORY c ON a.Category_id = c.Category_id
    WHERE a.Asset_id = p_asset_id;

    SELECT COALESCE(MAX(Entry_no), 0) + 1, COALESCE(MAX(Accumulated_depreciation), 0)
    INTO v_next, v_acc
    FROM DEPRECIATION_ENTRY
    WHERE Asset_id = p_asset_id;

    SET v_annual = LEAST((v_cost - v_salvage) / v_life, (v_cost - v_salvage) - v_acc);

    IF v_annual > 0 THEN
        INSERT INTO DEPRECIATION_ENTRY
        VALUES (p_asset_id, v_next, p_period, v_annual, v_acc + v_annual);
    END IF;
END//

CREATE FUNCTION fn_work_order_cost(p_wo_id INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2);
    SELECT COALESCE(w.Labor_cost, 0) + COALESCE(SUM(wp.Quantity_used * wp.Cost_at_use), 0)
    INTO v_total
    FROM WORK_ORDER w
    LEFT JOIN WORK_ORDER_PART wp ON w.Work_order_id = wp.Work_order_id
    WHERE w.Work_order_id = p_wo_id
    GROUP BY w.Work_order_id, w.Labor_cost;
    RETURN v_total;
END//

DELIMITER ;

-- Task 2: Insert sample data
INSERT INTO ASSET_CATEGORY (Category_name, Default_useful_life) VALUES
('IT Equipment', 5), ('Machinery', 10), ('Vehicles', 8), ('Furniture', 7);

INSERT INTO LOCATION (Building, Floor) VALUES
('Main Block', 1), ('Main Block', 2), ('Workshop', 0), ('Admin Block', 3);

INSERT INTO DEPARTMENT (Department_name, Cost_center_code) VALUES
('Information Technology', 'CC-101'), ('Facilities', 'CC-102'), ('Production', 'CC-103');

INSERT INTO DEPARTMENT_SPECIALISTS VALUES
(1, 'Networking'), (1, 'Hardware Repair'), (2, 'HVAC'), (2, 'Electrical'), (3, 'Machine Maintenance');

INSERT INTO TECHNICIAN (Technician_name, Phone_number, Specialization) VALUES
('Ravi Kumar', '9876543210', 'Hardware Repair'),
('Anita Shetty', '9876501234', 'HVAC'),
('Mohan Rao', '9845012345', 'Machine Maintenance'),
('Suresh Nayak', '9900112233', 'Electrical');

INSERT INTO VENDOR (Vendor_name, Contact_phone) VALUES
('TechServe Pvt Ltd', '0824-2456789'),
('CoolAir Services', '0824-2345678'),
('Precision Tools Co', '0824-2987654');

INSERT INTO PART (Part_name, Unit_cost) VALUES
('Thermal Sensor', 450.00), ('Compressor Belt', 1200.00), ('Hydraulic Seal', 800.00),
('Cooling Fan', 650.00), ('Power Supply Unit', 2500.00);

INSERT INTO ASSET (Asset_name, Purchase_date, Purchase_cost, Salvage_value, Status, Category_id, Location_id) VALUES
('Dell PowerEdge Server', '2022-04-10', 250000.00, 25000.00, 'Active', 1, 2),
('Hydraulic Press HP-200', '2021-08-15', 1200000.00, 120000.00, 'Active', 2, 3),
('Toyota Innova', '2022-01-20', 1800000.00, 400000.00, 'Active', 3, 1),
('Conference Table Set', '2023-06-05', 85000.00, 5000.00, 'Active', 4, 4),
('Central AC Unit', '2023-03-12', 600000.00, 60000.00, 'Active', 2, 4),
('Laptop Fleet Lot-A', '2024-02-01', 450000.00, 45000.00, 'Active', 1, 2);

CALL sp_post_depreciation(1, '2023-03-31');
CALL sp_post_depreciation(1, '2024-03-31');
CALL sp_post_depreciation(1, '2025-03-31');
CALL sp_post_depreciation(2, '2022-03-31');
CALL sp_post_depreciation(2, '2023-03-31');
CALL sp_post_depreciation(2, '2024-03-31');
CALL sp_post_depreciation(2, '2025-03-31');
CALL sp_post_depreciation(3, '2023-03-31');
CALL sp_post_depreciation(3, '2024-03-31');
CALL sp_post_depreciation(4, '2024-03-31');
CALL sp_post_depreciation(5, '2024-03-31');
CALL sp_post_depreciation(5, '2025-03-31');
CALL sp_post_depreciation(6, '2025-03-31');

INSERT INTO WORK_ORDER (Asset_id, Issue_description, Priority, Status, Created_date, Labor_cost, Technician_id, Vendor_id) VALUES
(5, 'AC compressor overheating and tripping breaker', 'High', 'Open', '2025-09-10', 3500.00, 2, 2),
(2, 'Hydraulic leak near press cylinder', 'High', 'Open', '2025-08-22', 6000.00, 3, NULL),
(1, 'Server fan noise and thermal warnings', 'Medium', 'Open', '2025-07-15', 1500.00, 1, 1),
(3, 'Brake pad replacement and routine service', 'Low', 'Open', '2025-06-02', 2500.00, NULL, 3),
(6, 'Laptop battery swelling on three units', 'Medium', 'Open', '2025-10-05', 2000.00, 1, 1);

INSERT INTO WORK_ORDER_PART VALUES
(1, 1, 2, 450.00), (1, 4, 1, 650.00),
(2, 3, 4, 800.00),
(3, 4, 2, 650.00), (3, 1, 1, 450.00),
(5, 5, 3, 2500.00);

UPDATE WORK_ORDER SET Status = 'Closed' WHERE Work_order_id = 3;
UPDATE WORK_ORDER SET Status = 'Closed' WHERE Work_order_id = 4;
UPDATE WORK_ORDER SET Status = 'In Progress' WHERE Work_order_id = 2;

-- Task 3: Queries
SELECT w.Work_order_id, a.Asset_name, w.Priority, w.Status, t.Technician_name
FROM WORK_ORDER w
JOIN ASSET a ON w.Asset_id = a.Asset_id
LEFT JOIN TECHNICIAN t ON w.Technician_id = t.Technician_id;

SELECT a.Asset_name, c.Category_name, a.Purchase_cost, a.Current_book_value
FROM ASSET a JOIN ASSET_CATEGORY c ON a.Category_id = c.Category_id
ORDER BY a.Current_book_value DESC;

SELECT Asset_name, Purchase_cost
FROM ASSET
WHERE Purchase_cost > (SELECT AVG(Purchase_cost) FROM ASSET);

SELECT a.Asset_name, SUM(fn_work_order_cost(w.Work_order_id)) AS Total_maintenance_cost
FROM ASSET a JOIN WORK_ORDER w ON a.Asset_id = w.Asset_id
GROUP BY a.Asset_id, a.Asset_name
ORDER BY Total_maintenance_cost DESC;

SELECT a.Asset_name
FROM ASSET a
WHERE (SELECT SUM(fn_work_order_cost(w.Work_order_id)) FROM WORK_ORDER w WHERE w.Asset_id = a.Asset_id)
      > 0.01 * a.Purchase_cost;

SELECT Asset_name
FROM ASSET a
WHERE NOT EXISTS (SELECT 1 FROM WORK_ORDER w WHERE w.Asset_id = a.Asset_id);

SELECT p.Part_name, SUM(wp.Quantity_used) AS Total_used
FROM PART p JOIN WORK_ORDER_PART wp ON p.Part_id = wp.Part_id
GROUP BY p.Part_id, p.Part_name
HAVING SUM(wp.Quantity_used) >= 2;

SELECT c.Category_name, COUNT(*) AS Assets, SUM(a.Current_book_value) AS Total_book_value
FROM ASSET a JOIN ASSET_CATEGORY c ON a.Category_id = c.Category_id
GROUP BY c.Category_id, c.Category_name;