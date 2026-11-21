-- ====================================================================
-- PROJECT: Zepto E-Commerce Data Analysis Project
-- Author: Abdullahi Abdi Hassan
-- Database: PostgreSQL
-- ====================================================================

-- 1. DROP AND CREATE TABLE SCHEMA

DROP TABLE IF EXISTS zepto;

CREATE TABLE zepto (
    sku_id SERIAL PRIMARY KEY,
    category VARCHAR(120),
    name VARCHAR(150) NOT NULL,
    mrp NUMERIC(8,2),
    discountPercent NUMERIC(5,2),
    availableQuantity INTEGER,
    discountedSellingPrice NUMERIC(8,2),
    weightInGms INTEGER,
    OutOfStock BOOLEAN,
    quantity INTEGER
);

-- ====================================================================
-- PHASE 1: DATA EXPLORATION
-- ====================================================================

-- Total count of rows in the dataset (3,732 raw records)
SELECT COUNT(*) AS total_rows
FROM zepto;

-- Preview sample data (first 10 records)
SELECT *
FROM zepto
LIMIT 10;

-- Check for NULL values across critical columns
SELECT *
FROM zepto
WHERE name IS NULL
   OR category IS NULL
   OR mrp IS NULL
   OR discountPercent IS NULL
   OR availableQuantity IS NULL
   OR discountedSellingPrice IS NULL
   OR weightInGms IS NULL
   OR OutOfStock IS NULL
   OR quantity IS NULL;

-- View distinct product categories (14 categories)
SELECT DISTINCT category
FROM zepto
ORDER BY category;

-- Analyze stock availability (In Stock vs Out of Stock)
SELECT OutOfStock, COUNT(sku_id) AS sku_count
FROM zepto
GROUP BY OutOfStock;

-- Find products appearing multiple times across different pack sizes or categories
SELECT name, COUNT(sku_id) AS number_of_sku
FROM zepto
GROUP BY name
HAVING COUNT(sku_id) > 1
ORDER BY number_of_sku DESC;

-- ====================================================================
-- PHASE 2: DATA CLEANING
-- ====================================================================

-- Check for anomalous records where price or weight is 0
SELECT *
FROM zepto
WHERE mrp = 0
   OR discountedSellingPrice = 0
   OR weightInGms = 0;

-- Remove corrupted/invalid rows with 0 MRP (removes 1 invalid record; 3,731 remain)
DELETE FROM zepto
WHERE mrp = 0;

-- Convert raw price units from paise to standard Indian Rupees (INR)
-- IMPORTANT: Run this UPDATE only once after loading raw CSV data
UPDATE zepto
SET mrp = mrp / 100.0,
    discountedSellingPrice = discountedSellingPrice / 100.0;

-- Verify unit conversion
SELECT name, mrp, discountedSellingPrice
FROM zepto
LIMIT 5;

-- ====================================================================
-- PHASE 3: BUSINESS QUESTIONS & ADVANCED QUERIES
-- ====================================================================

-- 1. Find the top 10 best value products based on the discount percentage
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
ORDER BY discountPercent DESC
LIMIT 10;

-- 2. Identify high-MRP products (> ₹300) that are currently out of stock
SELECT DISTINCT name, mrp
FROM zepto
WHERE OutOfStock = TRUE
  AND mrp > 300
ORDER BY mrp DESC;

-- 3. Calculate estimated revenue by each category (sorted highest to lowest)
SELECT category,
       SUM(discountedSellingPrice * availableQuantity) AS total_revenue
FROM zepto
GROUP BY category
ORDER BY total_revenue DESC;

-- 4. Find premium products (MRP > ₹500) with minimal discounts (< 10%)
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
WHERE mrp > 500
  AND discountPercent < 10
ORDER BY mrp DESC, discountPercent DESC;

-- 5. Identify the top 5 categories offering the highest average discount percentage
SELECT category,
       ROUND(AVG(discountPercent), 2) AS avg_discount
FROM zepto
GROUP BY category
ORDER BY avg_discount DESC
LIMIT 5;

-- 6. Find the price per gram for products above 100g and sort by best value
SELECT DISTINCT name,
       weightInGms,
       discountedSellingPrice,
       ROUND(discountedSellingPrice / weightInGms, 2) AS price_per_gram
FROM zepto
WHERE weightInGms > 100
ORDER BY price_per_gram ASC;

-- 7. Group products into weight tiers: Low (<1kg), Medium (1kg–<5kg), and Bulk (>=5kg)
SELECT DISTINCT name,
       weightInGms,
       CASE
           WHEN weightInGms < 1000 THEN 'Low'
           WHEN weightInGms < 5000 THEN 'Medium'
           ELSE 'Bulk'
       END AS weight_category
FROM zepto
ORDER BY weightInGms DESC;

-- 8. Calculate total available inventory weight (in grams and kg) per category
SELECT category,
       ROUND(SUM(weightInGms * availableQuantity), 2) AS total_weight_grams,
       ROUND(SUM(weightInGms * availableQuantity) / 1000.0, 2) AS total_weight_kg
FROM zepto
GROUP BY category
ORDER BY total_weight_grams DESC;
