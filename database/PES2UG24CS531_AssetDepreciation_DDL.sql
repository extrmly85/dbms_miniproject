CREATE DATABASE IF NOT EXISTS asset_db;
USE asset_db;

-- Task 1: Create tables
CREATE TABLE ASSET_CATEGORY (
    Category_id INT AUTO_INCREMENT PRIMARY KEY,
    Category_name VARCHAR(100) NOT NULL UNIQUE,
    Default_useful_life INT NOT NULL CHECK (Default_useful_life > 0)
);

CREATE TABLE LOCATION (
    Location_id INT AUTO_INCREMENT PRIMARY KEY,
    Building VARCHAR(100) NOT NULL,
    Floor INT NOT NULL
);

CREATE TABLE DEPARTMENT (
    Department_id INT AUTO_INCREMENT PRIMARY KEY,
    Department_name VARCHAR(100) NOT NULL UNIQUE,
    Cost_center_code VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE DEPARTMENT_SPECIALISTS (
    Department_id INT NOT NULL,
    Specialization VARCHAR(100) NOT NULL,
    PRIMARY KEY (Department_id, Specialization),
    FOREIGN KEY (Department_id) REFERENCES DEPARTMENT(Department_id) ON DELETE CASCADE
);

CREATE TABLE TECHNICIAN (
    Technician_id INT AUTO_INCREMENT PRIMARY KEY,
    Technician_name VARCHAR(100) NOT NULL,
    Phone_number VARCHAR(15),
    Specialization VARCHAR(100)
);

CREATE TABLE VENDOR (
    Vendor_id INT AUTO_INCREMENT PRIMARY KEY,
    Vendor_name VARCHAR(100) NOT NULL,
    Contact_phone VARCHAR(15)
);

CREATE TABLE PART (
    Part_id INT AUTO_INCREMENT PRIMARY KEY,
    Part_name VARCHAR(100) NOT NULL,
    Unit_cost DECIMAL(10,2) NOT NULL CHECK (Unit_cost >= 0)
);

CREATE TABLE ASSET (
    Asset_id INT AUTO_INCREMENT PRIMARY KEY,
    Asset_name VARCHAR(100) NOT NULL,
    Purchase_date DATE NOT NULL,
    Purchase_cost DECIMAL(12,2) NOT NULL CHECK (Purchase_cost >= 0),
    Salvage_value DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (Salvage_value >= 0),
    Status VARCHAR(20) NOT NULL DEFAULT 'Active',
    Current_book_value DECIMAL(12,2),
    Category_id INT NOT NULL,
    Location_id INT NOT NULL,
    FOREIGN KEY (Category_id) REFERENCES ASSET_CATEGORY(Category_id),
    FOREIGN KEY (Location_id) REFERENCES LOCATION(Location_id),
    CHECK (Salvage_value <= Purchase_cost)
);

CREATE TABLE DEPRECIATION_ENTRY (
    Asset_id INT NOT NULL,
    Entry_no INT NOT NULL,
    Period_date DATE NOT NULL,
    Depreciation_amount DECIMAL(12,2) NOT NULL CHECK (Depreciation_amount >= 0),
    Accumulated_depreciation DECIMAL(12,2) NOT NULL CHECK (Accumulated_depreciation >= 0),
    PRIMARY KEY (Asset_id, Entry_no),
    FOREIGN KEY (Asset_id) REFERENCES ASSET(Asset_id) ON DELETE CASCADE
);

CREATE TABLE WORK_ORDER (
    Work_order_id INT AUTO_INCREMENT PRIMARY KEY,
    Asset_id INT NOT NULL,
    Issue_description VARCHAR(255) NOT NULL,
    Priority VARCHAR(10) NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Open',
    Created_date DATE NOT NULL,
    Labor_cost DECIMAL(10,2) DEFAULT 0 CHECK (Labor_cost >= 0),
    Technician_id INT,
    Vendor_id INT,
    FOREIGN KEY (Asset_id) REFERENCES ASSET(Asset_id),
    FOREIGN KEY (Technician_id) REFERENCES TECHNICIAN(Technician_id) ON DELETE SET NULL,
    FOREIGN KEY (Vendor_id) REFERENCES VENDOR(Vendor_id) ON DELETE SET NULL
);

CREATE TABLE WORK_ORDER_PART (
    Work_order_id INT NOT NULL,
    Part_id INT NOT NULL,
    Quantity_used INT NOT NULL CHECK (Quantity_used > 0),
    Cost_at_use DECIMAL(10,2) NOT NULL CHECK (Cost_at_use >= 0),
    PRIMARY KEY (Work_order_id, Part_id),
    FOREIGN KEY (Work_order_id) REFERENCES WORK_ORDER(Work_order_id) ON DELETE CASCADE,
    FOREIGN KEY (Part_id) REFERENCES PART(Part_id)
);