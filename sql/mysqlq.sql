CREATE DATABASE IF NOT EXISTS JualBeliDb;
USE JualBeliDb;

-- ============================================================
-- Schema Inspection Query (MySQL Version)
-- ============================================================

SELECT 
    c.TABLE_SCHEMA AS table_schema,
    c.TABLE_NAME AS table_name,
    c.ORDINAL_POSITION AS ordinal_position,
    c.COLUMN_NAME AS column_name,
    c.DATA_TYPE AS data_type,

    -- Character / binary length
    c.CHARACTER_MAXIMUM_LENGTH AS max_length,

    -- Numeric properties
    c.NUMERIC_PRECISION AS numeric_precision,
    c.NUMERIC_SCALE AS numeric_scale,

    -- Date/time precision
    c.DATETIME_PRECISION AS datetime_precision,

    -- NULL / NOT NULL
    c.IS_NULLABLE AS is_nullable,

    -- Default value
    c.COLUMN_DEFAULT AS column_default,

    -- Identity (AUTO_INCREMENT in MySQL)
    CASE 
        WHEN c.EXTRA LIKE '%auto_increment%'
        THEN 'YES'
        ELSE 'NO'
    END AS is_identity,

    -- Primary key
    CASE 
        WHEN c.COLUMN_KEY = 'PRI'
        THEN 'YES'
        ELSE 'NO'
    END AS is_primary_key

FROM INFORMATION_SCHEMA.COLUMNS c

WHERE 
    c.TABLE_SCHEMA = 'JualBeliDb'

ORDER BY 
    c.TABLE_SCHEMA,
    c.TABLE_NAME,
    c.ORDINAL_POSITION;


-- ============================================================
-- Users
-- ============================================================

CREATE TABLE IF NOT EXISTS Users (
    Id INT AUTO_INCREMENT NOT NULL,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(255) NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    CreatedAt DATETIME(7) NOT NULL 
        DEFAULT CURRENT_TIMESTAMP(7),

    CONSTRAINT PK_Users
        PRIMARY KEY (Id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- Products
-- ============================================================

CREATE TABLE IF NOT EXISTS Products (
    Id INT AUTO_INCREMENT NOT NULL,
    Name VARCHAR(255) NOT NULL,
    Price DECIMAL(30,2) NOT NULL,
    Image VARCHAR(1000) NULL,
    Category VARCHAR(100) NOT NULL,
    SellerName VARCHAR(255) NOT NULL,
    SellerEmail VARCHAR(320) NOT NULL 
        DEFAULT '',

    CONSTRAINT PK_Products
        PRIMARY KEY (Id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- Orders
-- ============================================================

CREATE TABLE IF NOT EXISTS Orders (
    id INT AUTO_INCREMENT NOT NULL,
    email VARCHAR(255) NOT NULL,
    total_amount DECIMAL(30,2) NOT NULL,
    status VARCHAR(30) NOT NULL 
        DEFAULT 'Pending',
    created_at DATETIME(7) NOT NULL 
        DEFAULT CURRENT_TIMESTAMP(7),

    CONSTRAINT PK_Orders
        PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- OrderItems
-- ============================================================

CREATE TABLE IF NOT EXISTS OrderItems (
    id INT AUTO_INCREMENT NOT NULL,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(30,2) NOT NULL,

    CONSTRAINT PK_OrderItems
        PRIMARY KEY (id),

    CONSTRAINT FK_OrderItems_Orders 
        FOREIGN KEY (order_id) REFERENCES Orders(id) ON DELETE CASCADE,

    CONSTRAINT FK_OrderItems_Products 
        FOREIGN KEY (product_id) REFERENCES Products(Id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- CartItems
-- ============================================================

CREATE TABLE IF NOT EXISTS CartItems (
    Id INT AUTO_INCREMENT NOT NULL,
    UserEmail VARCHAR(320) NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL 
        DEFAULT 1,

    CONSTRAINT PK_CartItems
        PRIMARY KEY (Id),

    -- Ensures ON DUPLICATE KEY UPDATE works correctly for upserts
    CONSTRAINT UQ_CartItems_User_Product 
        UNIQUE (UserEmail, ProductId),

    CONSTRAINT FK_CartItems_Products 
        FOREIGN KEY (ProductId) REFERENCES Products(Id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;