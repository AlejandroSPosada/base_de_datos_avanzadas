-- Q1: Ventas por ciudad en un año (sin índices en orders.order_date ni orders.customer_id)
CREATE INDEX ON orders(order_date);
CREATE INDEX ON orders(customer_id);

EXPLAIN (ANALYZE, BUFFERS)
SELECT c.city, SUM(o.total_amount) AS total_sales
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= TIMESTAMPTZ '2023-01-01'
  AND o.order_date <  TIMESTAMPTZ '2024-01-01'
GROUP BY c.city
ORDER BY total_sales DESC;



-- Q2: Top productos vendidos (agregación masiva)
CREATE INDEX ON orders(order_date);
CREATE INDEX ON orders(customer_id);

EXPLAIN
SELECT p.name, SUM(oi.quantity) AS total_sold
FROM order_item oi
JOIN product p ON oi.product_id = p.product_id
GROUP BY p.name
ORDER BY total_sold DESC
LIMIT 10;

-- Q3: Dashboard: últimas órdenes de un cliente (filtro + sort)
CREATE INDEX idx_orders_customer_date
ON orders (customer_id, order_date DESC);

EXPLAIN
SELECT *
FROM orders
WHERE customer_id = 12345
ORDER BY order_date DESC
LIMIT 20;

-- Q4
--
CREATE INDEX idx_orders_amount_customer
ON orders (total_amount DESC, customer_id);

EXPLAIN
SELECT c.name, o.total_amount
FROM customer c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.total_amount > 500
ORDER BY o.total_amount DESC
LIMIT 20;

-- Q5
CREATE INDEX idx_orders_order_date
ON orders (order_date);

EXPLAIN
SELECT COUNT(*)
FROM orders
WHERE order_date >= now() - interval '30 days';

-- Q6
CREATE INDEX idx_orders_customer_amount
ON orders (customer_id, total_amount DESC)
INCLUDE (order_id);

SELECT order_id, total_amount
FROM orders
WHERE customer_id = 9876
ORDER BY total_amount DESC
LIMIT 5;