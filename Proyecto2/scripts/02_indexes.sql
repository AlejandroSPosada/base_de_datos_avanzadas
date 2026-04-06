-- =============================================================================
-- SI3009 | Proyecto 2 | Script 02: Índices por partición
-- Aplicar en CADA nodo después de 01_create_tables.sql
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Índices sobre posts
-- El índice más crítico: búsqueda por user_id + ordenamiento por fecha.
-- Soporta la consulta OLTP más frecuente: feed de un usuario.
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_posts_user_id
    ON posts (user_id);

CREATE INDEX IF NOT EXISTS idx_posts_user_created
    ON posts (user_id, created_at DESC);

-- Índice para búsqueda por rango de fechas (útil en OLAP)
CREATE INDEX IF NOT EXISTS idx_posts_created_at
    ON posts (created_at DESC);

-- -----------------------------------------------------------------------------
-- Índices sobre follows
-- Dos patrones de acceso:
--   1. ¿A quién sigo? (follower_id → followed_id)  ← cubierto por PK
--   2. ¿Quién me sigue? (followed_id → follower_id) ← necesita índice explícito
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_follows_followed_id
    ON follows (followed_id);

CREATE INDEX IF NOT EXISTS idx_follows_follower_created
    ON follows (follower_id, created_at DESC);

-- -----------------------------------------------------------------------------
-- Índices sobre likes
-- Dos patrones:
--   1. ¿Qué posts le gustaron a un usuario? (user_id)   ← cubierto por PK
--   2. ¿Cuántos likes tiene un post?        (post_id)   ← índice explícito
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_likes_post_id
    ON likes (post_id);

CREATE INDEX IF NOT EXISTS idx_likes_post_created
    ON likes (post_id, created_at DESC);

-- -----------------------------------------------------------------------------
-- Índices sobre users
-- La búsqueda por username es frecuente en login y menciones.
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_users_username
    ON users (username);

CREATE INDEX IF NOT EXISTS idx_users_created_at
    ON users (created_at DESC);

-- -----------------------------------------------------------------------------
-- Verificación: mostrar índices creados con su tamaño estimado
-- -----------------------------------------------------------------------------
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY tablename, indexname;
