/*
==========================================================================================================================
Product Report
==========================================================================================================================
Purpose:
    - Consolidates key product-level metrics and performance indicators

Highlights:
    1. Retrieves essential product details (name, category, subcategory, cost)
    2. Segments products based on revenue performance
    3. Aggregates product-level metrics:
        - total orders
        - total sales
        - total quantity sold
        - total customers (unique)
        - lifespan (in months)
    4. Calculates KPIs:
        - recency (months since last sale)
        - average order revenue (AOR)
        - average monthly revenue
==========================================================================================================================
*/

CREATE VIEW gold.report_products AS

WITH base_query AS (
    /* ---------------------------------------------------------------------------------------------------------------
       1) Base Query: Extract core transactional and product-level data
    --------------------------------------------------------------------------------------------------------------- */
    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.product_cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE order_date IS NOT NULL        -- Consider only valid sales records
),

product_aggregation AS (
    /* ---------------------------------------------------------------------------------------------------------------
       2) Aggregation Query: Compute product-level metrics
    --------------------------------------------------------------------------------------------------------------- */
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        product_cost,

        -- Product lifespan (in months)
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,

        -- Most recent sale date
        MAX(order_date) AS last_sale_date,

        -- Key aggregations
        COUNT(DISTINCT order_number) AS total_orders,
        COUNT(DISTINCT customer_key) AS total_customers,
        SUM(sales_amount)            AS total_sales,
        SUM(quantity)                AS total_quantity,

        -- Average selling price per unit
        ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1) AS avg_selling_price

    FROM base_query
    GROUP BY
        product_key,
        product_name,
        category,
        subcategory,
        product_cost
)

-- ---------------------------------------------------------------------------------------------------------------
-- 3) Final Query: Combine all metrics and derive KPIs
-- ---------------------------------------------------------------------------------------------------------------
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    product_cost,
    last_sale_date,

    -- Recency: months since last sale
    DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency,

    -- Product segmentation based on total sales
    CASE
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,

    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,

    -- Average Order Revenue (AOR)
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_revenue,

    -- Average Monthly Revenue
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_revenue

FROM product_aggregation;
