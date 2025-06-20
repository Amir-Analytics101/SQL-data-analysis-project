/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================
CREATE VIEW gold.report_customers AS
WITH base_query AS(
SELECT
f.order_date,
f.order_number,
f.product_key,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
DATEDIFF(year, c.birthdate, GETDATE()) age,
CONCAT(c.first_name, ' ', c.last_name) AS customer_name
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL)
, customer_segregation AS (
SELECT 
customer_key,
customer_number,
customer_name,
age,
COUNT(DISTINCT order_number) AS total_orders,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(DISTINCT product_key) AS total_products,
MAX(order_date) AS last_order,
DATEDIFF(month, MIN(order_date), MAX(order_date)) as lifespan
FROM base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age
)
SELECT
customer_key,
customer_number,
customer_name,
age,
CASE 
	WHEN age < 20 THEN 'Under 20'
	WHEN age BETWEEN 20 and 29 THEN '20-29'
	WHEN age BETWEEN 30 and 39 THEN '30-39'
	WHEN age BETWEEN 40 and 49 THEN '40-49'
	ELSE '50 and above'
END AS age_group,
CASE
	WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
	WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
	ELSE 'NEW'
END AS customer_segment,
DATEDIFF(month, last_order, GETDATE()) AS recency,
total_orders,
total_sales,
total_quantity,
total_products,
last_order,
lifespan,
-- Compute average order value (AVO)
CASE WHEN total_orders = 0 THEN 0
	 ELSE total_sales / total_orders
END AS AVO,
--Computate average monthly spend
CASE WHEN lifespan = 0 THEN total_sales
	 ELSE total_sales / lifespan
END AS avg_monthly_spent
FROM customer_segregation

