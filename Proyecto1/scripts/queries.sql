-- Q1: Ventas por ciudad en un año (sin índices en orders.order_date ni orders.customer_id)
EXPLAIN
SELECT c.city, SUM(o.total_amount) AS total_sales
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= TIMESTAMPTZ '2023-01-01'
  AND o.order_date <  TIMESTAMPTZ '2024-01-01'
GROUP BY c.city
ORDER BY total_sales DESC;

-- Q2: Top productos vendidos (agregación masiva)
EXPLAIN
SELECT p.name, SUM(oi.quantity) AS total_sold
FROM order_item oi
JOIN product p ON oi.product_id = p.product_id
GROUP BY p.name
ORDER BY total_sold DESC
LIMIT 10;

-- Q3: Dashboard: últimas órdenes de un cliente (filtro + sort)
EXPLAIN
SELECT *
FROM orders
WHERE customer_id = 12345
ORDER BY order_date DESC
LIMIT 20;

-- Q4: Órdenes de mayor valor con información del cliente (join + filtro + ordenamiento)
EXPLAIN
SELECT c.name, o.total_amount
FROM customer c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.total_amount > 500
ORDER BY o.total_amount DESC
LIMIT 20;

-- Q5: Conteo de órdenes recientes (filtro por rango de fecha)
EXPLAIN
SELECT COUNT(*)
FROM orders
WHERE order_date >= now() - interval '30 days';

-- Q6: Órdenes más costosas de un cliente específico (filtro + sort + limit)
EXPLAIN
SELECT order_id, total_amount
FROM orders
WHERE customer_id = 9876
ORDER BY total_amount DESC
LIMIT 5;