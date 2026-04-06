-- =============================================================================
-- SI3009 | Proyecto 2 | Script 01: Creación de tablas base
-- Aplicar en CADA nodo PostgreSQL (nodo1, nodo2, nodo3)
-- =============================================================================

-- Extensión para UUID (opcional, usamos SERIAL por simplicidad)
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- Tabla: users
-- Distribuida por rango de user_id entre los 3 nodos:
--   Nodo 1 → user_id 1–3000
--   Nodo 2 → user_id 3001–6000
--   Nodo 3 → user_id 6001–10000
-- Cada nodo almacena solo su rango, pero la tabla existe en todos
-- para soportar foreign keys locales.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id         SERIAL PRIMARY KEY,
    username   VARCHAR(50)  NOT NULL UNIQUE,
    email      VARCHAR(100) NOT NULL UNIQUE,
    bio        TEXT,
    created_at TIMESTAMP    DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- Tabla: posts
-- Particionada por user_id (mismo rango que users).
-- Permite data locality: los posts de un usuario viven en el mismo nodo.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS posts (
    id         SERIAL PRIMARY KEY,
    user_id    INT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content    TEXT         NOT NULL,
    created_at TIMESTAMP    DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- Tabla: follows
-- Relación follower → followed.
-- ATENCIÓN: esta tabla es cross-shard cuando follower y followed están
-- en nodos distintos. Cada nodo almacena una copia completa (desnormalizado)
-- o se usa la lógica de la aplicación para enrutar.
-- Para este proyecto: cada nodo almacena los follows donde follower_id
-- pertenece a su rango.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS follows (
    follower_id INT         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    followed_id INT         NOT NULL,   -- puede ser de otro nodo, no FK cruzada
    created_at  TIMESTAMP   DEFAULT NOW(),
    PRIMARY KEY (follower_id, followed_id)
);

-- -----------------------------------------------------------------------------
-- Tabla: likes
-- Similar a follows: cada nodo almacena los likes donde user_id
-- pertenece a su rango.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS likes (
    user_id    INT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id    INT          NOT NULL,   -- puede ser de otro nodo
    created_at TIMESTAMP    DEFAULT NOW(),
    PRIMARY KEY (user_id, post_id)
);

-- -----------------------------------------------------------------------------
-- Tabla auxiliar: shard_metadata
-- Permite a la aplicación descubrir qué nodo maneja qué rango.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS shard_metadata (
    shard_id    INT         PRIMARY KEY,
    host        VARCHAR(50) NOT NULL,
    port        INT         NOT NULL DEFAULT 5432,
    user_id_min INT         NOT NULL,
    user_id_max INT         NOT NULL,
    is_active   BOOLEAN     DEFAULT TRUE,
    updated_at  TIMESTAMP   DEFAULT NOW()
);

-- Poblar shard_metadata (ajustar IPs según ambiente)
INSERT INTO shard_metadata (shard_id, host, port, user_id_min, user_id_max)
VALUES
  (1, '10.0.0.1', 5432, 1,    3000),
  (2, '10.0.0.2', 5432, 3001, 6000),
  (3, '10.0.0.3', 5432, 6001, 10000)
ON CONFLICT (shard_id) DO NOTHING;

-- Verificación
SELECT 'Tablas creadas correctamente en nodo ' || current_setting('listen_addresses') AS status;
SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
