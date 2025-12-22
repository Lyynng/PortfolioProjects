USE restaurant_db;

---**Explore the "menu_items" table
--1. What is the number of items on the menu
SELECT DISTINCT COUNT (menu_item_id) AS total_menu_items
FROM menu_items

--2. What are the least and most expensive items on the menu?
SELECT menu_item_id, item_name, price
FROM menu_items
ORDER BY price DESC; --Most expensive

SELECT menu_item_id, item_name, price
FROM menu_items
ORDER BY price ASC; --Least expensive

--3. How many Italian dishes are on the menu?
SELECT category, COUNT(*) AS items_per_category
FROM menu_items
WHERE category = 'Italian'
GROUP BY category;

--4. What are the least and most expensive Italian dishes on the menu?
SELECT menu_item_id, item_name, category, price
FROM menu_items
WHERE category = 'Italian'
ORDER BY price DESC; ---Most expensive

SELECT menu_item_id, item_name, category, price
FROM menu_items
WHERE category = 'Italian'
ORDER BY price ASC; --Least expensive

--5. How many dishes are in each category? What is the average dish price within each category
SELECT
	category,
	COUNT(*) AS items_per_category, 
	CAST(AVG(price) AS decimal(18,2)) AS average_price
FROM menu_items
GROUP BY category
ORDER BY items_per_category ASC;

---***Explore the "order_details" table
--1. What is the date range of this table?
SELECT MIN(order_date) AS start_date,
	   MAX(order_date) AS end_date
FROM order_details;

--2. How many orders were made and items were ordered within this date range?
SELECT
	COUNT(DISTINCT(order_id)) AS total_orders,
	COUNT(order_details_id) AS total_items
FROM order_details;

--3. Which orders had the most number of items?
SELECT order_id, COUNT(order_details_id) AS num_of_items
FROM order_details
GROUP BY order_id
ORDER BY num_of_items DESC;

--4. How many orders had more than 12 items?
WITH greater_orders AS 
(
	SELECT order_id, COUNT(order_details_id) as items_ordered
	FROM order_details
	GROUP BY order_id
)

SELECT COUNT(order_id) AS num_orders_12
FROM greater_orders
WHERE items_ordered > 12;

---***Analyze customer behaviors
--1. What were the top 5 least and top 5 most ordered items? What categories were they in?
SELECT TOP 5 item_name, COUNT(item_id) as times_ordered, category
FROM order_details AS od LEFT JOIN menu_items AS mi
ON 	od.item_id = mi.menu_item_id
WHERE item_id IS NOT NULL
GROUP BY item_name, category
ORDER BY times_ordered DESC; --Most ordered

SELECT TOP 5 item_name, COUNT(item_id) AS times_ordered, category
FROM order_details AS od LEFT JOIN menu_items AS mi
ON od.item_id = mi.menu_item_id
WHERE item_id IS NOT NULL
GROUP BY item_name, category
ORDER BY times_ordered; --- Least ordered

--2. What were the top 5 orders that spent the most money?
WITH top5_table AS
(
	SELECT a.*, b.item_name, b.category, b.price
	FROM order_details AS a LEFT JOIN menu_items AS b
	ON a.item_id = b.menu_item_id
	WHERE b.menu_item_id IS NOT NULL
)

SELECT TOP 5 order_date, order_id, SUM(price) AS total_order_value
FROM top5_table
GROUP BY order_date, order_id
ORDER BY total_order_value DESC;

--3. In the highest spend order, which specific items were purchased?
WITH highest_spend AS
(
    SELECT a.order_id, SUM(b.price) AS total_order_value
    FROM order_details AS a LEFT JOIN menu_items AS b 
	ON a.item_id = b.menu_item_id
    WHERE b.menu_item_id IS NOT NULL
    GROUP BY a.order_id
), 
highest_spend_order AS 
(
    SELECT order_id,total_order_value,
		   ROW_NUMBER() OVER (ORDER BY total_order_value DESC) AS rn
    FROM highest_spend
)

SELECT 
    b.order_id, 
    b.item_id, 
    mi.item_name, 
    mi.category, 
    mi.price  
FROM 
    highest_spend_order AS a
JOIN 
    order_details AS b ON a.order_id = b.order_id
JOIN 
    menu_items AS mi ON b.item_id = mi.menu_item_id
WHERE 
    a.rn = 1;  -- Get only the highest spend order

--4. Which day of week that has the highest number of orders, highest revenue, and highest average order value?

WITH day_week AS
(
	SELECT a.*, b.item_name, b.category, b.price
	FROM order_details AS a LEFT JOIN menu_items AS b
	ON a.item_id = b.menu_item_id
	WHERE b.menu_item_id IS NOT NULL
)

SELECT CASE 
	WHEN DATEPART(WEEKDAY,order_date) = 1 THEN 'Sunday'
	WHEN DATEPART(WEEKDAY, order_date) = 2 THEN 'Monday'
	WHEN DATEPART(WEEKDAY, order_date) = 3 THEN 'Tuesday'
	WHEN DATEPART(WEEKDAY, order_date) = 4 THEN 'Wednesday'
	WHEN DATEPART(WEEKDAY, order_date) = 5 THEN 'Thursday'
	WHEN DATEPART(WEEKDAY, order_date) = 6 THEN 'Friday'
	WHEN DATEPART(WEEKDAY, order_date) = 7 THEN 'Saturday'
ELSE ''
END AS Day_Of_Week,
COUNT(DISTINCT(order_id)) AS total_orders,
CONCAT ('$', SUM(price)) AS total_revenue,
CONCAT('$', CAST(SUM(price)/COUNT(DISTINCT(order_id)) AS decimal(18,2))) AS avg_order_value
FROM day_week
GROUP BY CASE 
	WHEN DATEPART(WEEKDAY,order_date) = 1 THEN 'Sunday'
	WHEN DATEPART(WEEKDAY, order_date) = 2 THEN 'Monday'
	WHEN DATEPART(WEEKDAY, order_date) = 3 THEN 'Tuesday'
	WHEN DATEPART(WEEKDAY, order_date) = 4 THEN 'Wednesday'
	WHEN DATEPART(WEEKDAY, order_date) = 5 THEN 'Thursday'
	WHEN DATEPART(WEEKDAY, order_date) = 6 THEN 'Friday'
	WHEN DATEPART(WEEKDAY, order_date) = 7 THEN 'Saturday'
	ELSE ''
END
ORDER BY total_orders DESC, total_revenue DESC;