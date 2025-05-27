/*Analyze the yearly perfomance of products by comparing their sales
to both the average sales perfomance of the product and the prevoius years sales*/
WITH yearly_product_sales AS (
SELECT
YEAR(f.order_date) as order_year,
p.product_name,
SUM(f.sales_amount) as current_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_id
WHERE (product_name IS NOT NULL) AND (f.order_date IS NOT NULL) 
GROUP BY
YEAR(f.order_date),
p.product_name
)
SELECT order_year,
product_name,
current_sales,
AVG(current_sales) OVER (PARTITION BY product_name) avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'ABOVE AVG'
     WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'BELOW AVG'
	 ELSE 'AVG'
-- year-over-year changes
END avg_change,
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) previous_year_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) as diff_prevoius_year,
CASE WHEN LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'INCREASE'
     WHEN LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'DEACREASE'
	 ELSE 'No change'
END 'prevoius_year_change'
FROM yearly_product_sales
ORDER BY product_name, order_year