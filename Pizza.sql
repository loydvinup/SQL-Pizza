/*
SQL Case Study Project
*/

--CREATE DATABASE pizza_project;
--USE pizza_project;

-- Let's import the CSV files
-- Now understand each table (all columns)

SELECT * FROM order_details;  -- order_details_id, order_id, pizza_id, quantity
SELECT * FROM pizzas;         -- pizza_id, pizza_type_id, size, price
SELECT * FROM orders;         -- order_id, date, time
SELECT * FROM pizza_types;    -- pizza_type_id, name, category, ingredients

/*
Basic:
Retrieve the total number of orders placed.
Calculate the total revenue generated from pizza sales.
Identify the highest-priced pizza.
Identify the most common pizza size ordered.
List the top 5 most ordered pizza types along with their quantities.

Intermediate:
Join the necessary tables to find the total quantity of each pizza category ordered.
Determine the distribution of orders by hour of the day.
Join relevant tables to find the category-wise distribution of pizzas.
Group the orders by date and calculate the average number of pizzas ordered per day.
Determine the top 3 most ordered pizza types based on revenue.

Advanced:
Calculate the percentage contribution of each pizza type to total revenue.
Analyze the cumulative revenue generated over time.
Determine the top 3 most ordered pizza types based on revenue for each pizza category.
*/

-- Retrieve the total number of orders placed
SELECT COUNT(DISTINCT order_id) AS 'Total Orders'
FROM orders;

-- Calculate the total revenue generated from pizza sales
SELECT 
    CAST(SUM(order_details.quantity * pizzas.price) AS DECIMAL(10,2)) AS 'Total Revenue'
FROM order_details 
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id;

-- Identify the highest-priced pizza
SELECT TOP 1 
    pizza_types.name AS 'Pizza Name', 
    CAST(pizzas.price AS DECIMAL(10,2)) AS 'Price'
FROM pizzas 
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY price DESC;

-- Alternative (using window function)
WITH cte AS (
    SELECT 
        pizza_types.name AS 'Pizza Name', 
        CAST(pizzas.price AS DECIMAL(10,2)) AS 'Price',
        RANK() OVER (ORDER BY price DESC) AS rnk
    FROM pizzas
    JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
)
SELECT [Pizza Name], Price 
FROM cte 
WHERE rnk = 1;

-- Identify the most common pizza size ordered
SELECT 
    pizzas.size, 
    COUNT(DISTINCT order_id) AS 'No of Orders', 
    SUM(quantity) AS 'Total Quantity Ordered'
FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizzas.size
ORDER BY COUNT(DISTINCT order_id) DESC;

-- List the top 5 most ordered pizza types along with their quantities
SELECT TOP 5 
    pizza_types.name AS 'Pizza', 
    SUM(quantity) AS 'Total Ordered'
FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.name
ORDER BY SUM(quantity) DESC;

-- Join the necessary tables to find the total quantity of each pizza category ordered
SELECT 
    pizza_types.category, 
    SUM(quantity) AS 'Total Quantity Ordered'
FROM order_details
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.category
ORDER BY SUM(quantity) DESC;

-- Determine the distribution of orders by hour of the day
SELECT 
    DATEPART(HOUR, time) AS 'Hour of the Day', 
    COUNT(DISTINCT order_id) AS 'No of Orders'
FROM orders
GROUP BY DATEPART(HOUR, time)
ORDER BY [No of Orders] DESC;

-- Find the category-wise distribution of pizzas
SELECT 
    category, 
    COUNT(DISTINCT pizza_type_id) AS [No of Pizzas]
FROM pizza_types
GROUP BY category
ORDER BY [No of Pizzas];

-- Calculate the average number of pizzas ordered per day
WITH cte AS (
    SELECT 
        orders.date AS 'Date', 
        SUM(order_details.quantity) AS 'Total Pizza Ordered That Day'
    FROM order_details
    JOIN orders ON order_details.order_id = orders.order_id
    GROUP BY orders.date
)
SELECT 
    AVG([Total Pizza Ordered That Day]) AS [Avg Number of Pizzas Ordered Per Day]
FROM cte;

-- Determine the top 3 most ordered pizza types based on revenue
SELECT TOP 3 
    pizza_types.name, 
    SUM(order_details.quantity * pizzas.price) AS 'Revenue from Pizza'
FROM order_details 
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.name
ORDER BY [Revenue from Pizza] DESC;

-- Calculate the percentage contribution of each pizza type to total revenue
SELECT 
    pizza_types.category, 
    CONCAT(
        CAST((SUM(order_details.quantity * pizzas.price) / 
        (SELECT SUM(order_details.quantity * pizzas.price) 
         FROM order_details 
         JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id)
        ) * 100 AS DECIMAL(10,2)), '%'
    ) AS 'Revenue Contribution from Pizza'
FROM order_details 
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.category;

-- Revenue contribution from each pizza by pizza name
SELECT 
    pizza_types.name, 
    CONCAT(
        CAST((SUM(order_details.quantity * pizzas.price) / 
        (SELECT SUM(order_details.quantity * pizzas.price) 
         FROM order_details 
         JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id)
        ) * 100 AS DECIMAL(10,2)), '%'
    ) AS 'Revenue Contribution from Pizza'
FROM order_details 
JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
GROUP BY pizza_types.name
ORDER BY [Revenue Contribution from Pizza] DESC;

-- Analyze the cumulative revenue generated over time
WITH cte AS (
    SELECT 
        date AS 'Date', 
        CAST(SUM(quantity * price) AS DECIMAL(10,2)) AS Revenue
    FROM order_details 
    JOIN orders ON order_details.order_id = orders.order_id
    JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
    GROUP BY date
)
SELECT 
    Date, 
    Revenue, 
    SUM(Revenue) OVER (ORDER BY date) AS 'Cumulative Revenue'
FROM cte
GROUP BY Date, Revenue;

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category
WITH cte AS (
    SELECT 
        category, 
        name, 
        CAST(SUM(quantity * price) AS DECIMAL(10,2)) AS Revenue
    FROM order_details 
    JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id
    JOIN pizza_types ON pizza_types.pizza_type_id = pizzas.pizza_type_id
    GROUP BY category, name
),
cte1 AS (
    SELECT 
        category, 
        name, 
        Revenue,
        RANK() OVER (PARTITION BY category ORDER BY Revenue DESC) AS rnk
    FROM cte
)
SELECT category, name, Revenue
FROM cte1 
WHERE rnk IN (1,2,3)
ORDER BY category, name, Revenue;
