-- Crear nueva tabla particionada
CREATE TABLE orders_part (
    order_id      BIGINT NOT NULL,
    customer_id   BIGINT NOT NULL,
    order_date    TIMESTAMPTZ NOT NULL,
    status        order_status,
    total_amount  NUMERIC(10,2)
) PARTITION BY RANGE (order_date);

-- Crear particiones por año 
CREATE TABLE orders_2021 PARTITION OF orders_part
FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');

CREATE TABLE orders_2022 PARTITION OF orders_part
FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');

CREATE TABLE orders_2023 PARTITION OF orders_part
FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE orders_2024 PARTITION OF orders_part
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE orders_2025 PARTITION OF orders_part
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- Particion default
CREATE TABLE orders_default PARTITION OF orders_part
DEFAULT;

-- Copiar datos
INSERT INTO orders_part
SELECT * FROM orders;
