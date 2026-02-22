-- Q1: Ventas por ciudad en un año (sin índices en orders.order_date ni orders.customer_id)
CREATE INDEX ON orders(order_date);
CREATE INDEX ON orders(customer_id);

-- Q2: Top productos vendidos (agregación masiva)
CREATE INDEX ON orders(order_date);
CREATE INDEX ON orders(customer_id);

-- Q3: Dashboard: últimas órdenes de un cliente (filtro + sort)
CREATE INDEX idx_orders_customer_date
ON orders (customer_id, order_date DESC);

-- Q4: Órdenes de mayor valor con información del cliente (join + filtro + ordenamiento)
CREATE INDEX idx_orders_amount_customer
ON orders (total_amount DESC, customer_id);

-- Q5: Conteo de órdenes recientes (filtro por rango de fecha)
CREATE INDEX idx_orders_order_date
ON orders (order_date);

-- Q6: Órdenes más costosas de un cliente específico (filtro + sort + limit)
CREATE INDEX idx_orders_customer_amount
ON orders (customer_id, total_amount DESC)
INCLUDE (order_id);