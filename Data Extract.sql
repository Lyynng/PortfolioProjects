USE restaurant_db;

--1. View the menu_items table
SELECT * FROM menu_items;

--2. Find the number of items on the menu
SELECT COUNT(*) AS Number_of_items
FROM menu_items;

--3. What are the least and most expensive items on the menu?
SELECT * FROM menu_items
ORDER BY price DESC;

--4. How many Italian dishes are on the menu? 
SELECT COUNT(*) AS Total_Italian_dishes
FROM menu_items
WHERE category = 'Italian';

--5. What are the least and most expensive Italian dishes on the menu?
SELECT * FROM menu_items
WHERE category = 'Italian'
ORDER BY price DESC;

--6. How many dishes are in each category? 
SELECT category, COUNT(menu_item_id) AS num_dishes
FROM menu_items
GROUP BY category;

--7. What is the average dish price within each category?
SELECT category, AVG(price) AS avg_dish_price
FROM menu_items
GROUP BY category;

--8. View the order_details table
SELECT * FROM order_details;

--9. What is the date range of the table?
SELECT MIN(order_date) AS start_day, MAX(order_date) AS end_day
FROM order_details;

--10. How many orders were made within this date range?
SELECT COUNT(DISTINCT order_id) AS Total_orders
FROM order_details;

--11. How many items were ordered within this date range?
SELECT COUNT(*) AS num_items
FROM order_details;

--12. Which orders had the most number of items?
SELECT order_id, COUNT(item_id) AS num_items
FROM order_details
GROUP BY order_id
ORDER BY num_items DESC;

--13. How many orders had more than 12 items?
SELECT order_id, COUNT(item_id) AS num_items
FROM order_details
GROUP BY order_id
HAVING COUNT(item_id) > 12;

--14. Combine the menu_items and order_details tables into a single table
SELECT * FROM order_details
JOIN menu_items ON order_details_id = menu_item_id;

--15. What were the least and most ordered items? What categories were they in?
SELECT mi.item_name, mi.category, COUNT(od.order_details_id) AS num_purchases
FROM order_details AS od JOIN menu_items AS mi
ON od.order_details_id = mi.menu_item_id
GROUP BY item_name, category
ORDER BY num_purchases DESC;

--16. What were the top 5 orders that spent the most money?
SELECT TOP 5 od.order_id, SUM(mi.price) AS total_spend
FROM order_details AS od JOIN menu_items AS mi
ON od.order_details_id = mi.menu_item_id
GROUP BY order_id
ORDER BY total_spend DESC;

--17. View the details of the highest spend order. Which specific items were purchased?
SELECT TOP 3 od.order_id, mi.item_name, SUM(mi.price) AS highest_spend
FROM order_details AS od JOIN menu_items AS mi
ON od.order_details_id = mi.menu_item_id
GROUP BY order_id, item_name
ORDER BY highest_spend DESC;

--18. View the details of the top 5 highest spend orders
SELECT TOP 5 od.order_id, SUM(mi.price) AS highest_spend
FROM order_details AS od JOIN menu_items AS mi
ON od.order_details_id = mi.menu_item_id
GROUP BY order_id
ORDER BY highest_spend DESC;

--19. How much was the most expensive order in the dataset?
SELECT TOP 1 od.order_id, SUM(mi.price) AS most_expensive
FROM order_details AS od JOIN menu_items AS mi
ON od.order_details_id = mi.menu_item_id
GROUP BY order_id
ORDER BY most_expensive DESC;