SELECT * FROM  city;
SELECT * FROM  customers;
SELECT * FROM  products;
SELECT * FROM  sales;

-- Q.1 Coffee customers count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT city_name,
ROUND(population * 0.25) as pop_drinkers,
city_rank
FROM city
ORDER BY 2 DESC
limit 5;


-- Q.2 Total revenue from coffee shops
-- What is the total reveneu generated for coffee sales across all cities in the last quarter of 2023?

SELECT *,
YEAR(sale_date) as year,
EXTRACT(quarter FROM sale_date) as qtr
FROM sales
WHERE YEAR(sale_date) = 2023
AND  EXTRACT(quarter FROM sale_date) = 4;

SELECT SUM(total) as total_reveneu
FROM sales
WHERE YEAR(sale_date) = 2023
AND  EXTRACT(quarter FROM sale_date) = 4;


SELECT ci.city_name,
SUM(s.total) as total_reveneu
FROM sales s
JOIN customers c
	ON s.customer_id = c.customer_id
JOIN city ci
	ON ci.city_id = c.city_id
    WHERE YEAR(s.sale_date) = 2023
AND  EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
limit 5;


-- Q.3 Sales count for each product
-- How many units of each coffee product have been sold?

SELECT * FROM products;
SELECT * FROM sales;

SELECT p.product_name,
COUNT(s.sale_id) as total_orders
FROM products p
LEFT JOIN sales s
	ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY 2 DESC;


-- Q.4 Average sales amount per city
-- What is the avverage sales amount per costumer in each city?

SELECT ci.city_name,
SUM(s.total) as total_sales,
COUNT(DISTINCT s.customer_id) as total_cx,
ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id)) as avg_sale_cx
FROM sales s
JOIN customers c
	ON s.customer_id = c.customer_id
JOIN city ci
	ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;

-- Q.5 City population and coffee consumers
-- Provide a list of cities along whit their populations and estimated coffee consumers

WITH city_table AS
(
	SELECT 
		city_name,
	ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customer_table AS
(
	SELECT
		ci.city_name,
        COUNT(DISTINCT c.customer_id) as unique_cx
     FROM sales as s
     JOIN customers as c
		ON c.customer_id = s.customer_id
	JOIN city as ci
		ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
customer_table.city_name,
city_table.coffee_consumers as cx_per_million,
customer_table.unique_cx
FROM city_table
JOIN
customer_table
ON city_table.city_name = customer_table.city_name;

-- Q-6 Top selling products by city
-- What are the top 3 selling products in each city based on sales volume?

SELECT *
FROM
(
SELECT 
ci.city_name,
p.product_name,
COUNT(s.sale_id) as total_orders,
dense_rank() OVER(partition by ci.city_name ORDER BY COUNT(s.sale_id) DESC) as ranking
FROM sales s
JOIN products p
	ON s.product_id = p.product_id
JOIN customers c
	ON c.customer_id = s.customer_id
JOIN city ci
	ON ci.city_id = c.city_id
GROUP BY ci.city_name, p.product_name
) as t1
Where ranking <= 3;


-- Q.7 Customer segmentation by city
-- How many unique customers are there in each city who have purchased coffee products

SELECT 
	ci.city_name,
    COUNT(distinct c.customer_id) as unique_cx
FROM city ci
LEFT JOIN customers c
ON ci.city_id = c.city_id
JOIN sales s
ON s.customer_id = c.customer_id
WHERE s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY ci.city_name;
-- We take only till 14, couse after that is merchandaizing, not coffee products per se 

-- Q. 8 Average sale vs rent
-- Find each city and their average sale per customer and average rent per customer
WITH city_cx AS
(
SELECT ci.city_name,
COUNT(DISTINCT s.customer_id) as total_cx,
ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id)) as avg_sale_cx
FROM sales s
JOIN customers c
	ON s.customer_id = c.customer_id
JOIN city ci
	ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 1
),
city_rent AS
(
SELECT 
	city_name, 
    estimated_rent
FROM city
)
SELECT cr.city_name,
cr.estimated_rent,
ccx.total_cx,
ccx.avg_sale_cx,
ROUND(cr.estimated_rent/ccx.total_cx, 2) as avg_rent_per_cx
FROM city_rent cr
JOIN city_cx ccx
	ON cr.city_name = ccx.city_name
ORDER BY avg_sale_cx DESC;

-- Q.9 Monthly sales growth
-- Sales growth rate: calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city

WITH monthly_sales AS
(
SELECT 
	ci.city_name,
    EXTRACT(MONTH from sale_date) as month,
    extract(YEAR from sale_date) as year,
    SUM(s.total) as total_sale
FROM sales s
JOIN customers c
	ON c.customer_id = s.customer_id
JOIN city ci
	ON ci.city_id = c.city_id
GROUP BY 1, 2, 3
ORDER BY 1, 3, 2
),
growth_ratio AS
(
SELECT
city_name,
month,
year,
total_sale as month_sale,
LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
FROM monthly_sales
)
SELECT city_name,
month,
year,
month_sale,
last_month_sale,
ROUND((month_sale-last_month_sale)/last_month_sale * 100, 2) as growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL;

-- Q.10 Market potential analysis
-- Identify top 3 city basen on highest sales, total sale, total rent, total customers, estimated coffee consumers

WITH city_cx AS
(
SELECT ci.city_name,
SUM(s.total) as total_reveneu,
COUNT(DISTINCT s.customer_id) as total_cx,
ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id)) as avg_sale_cx
FROM sales s
JOIN customers c
	ON s.customer_id = c.customer_id
JOIN city ci
	ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 1
),
city_rent AS
(
SELECT 
	city_name, 
    estimated_rent,
    ROUND((population * 0.25)/1000000, 3) as estimeted_consumer_in_millions
FROM city
)
SELECT cr.city_name,
total_reveneu,
cr.estimated_rent as total_rent,
ccx.total_cx,
estimeted_consumer_in_millions,
ccx.avg_sale_cx,
ROUND(cr.estimated_rent/ccx.total_cx, 2) as avg_rent_per_cx
FROM city_rent cr
JOIN city_cx ccx
	ON cr.city_name = ccx.city_name
ORDER BY total_reveneu  DESC; 
