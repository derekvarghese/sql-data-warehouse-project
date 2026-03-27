-- =========================================================
-- Analysis: Sales Performance Over Time
-- Description: Monthly aggregation of sales, customers, and quantity
-- Source Table: gold.fact_sales
-- =========================================================

SELECT
    YEAR(order_date)  AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers, -- unique customers per month
    SUM(quantity)     AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL  -- exclude records with missing dates
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY order_year, order_month;
