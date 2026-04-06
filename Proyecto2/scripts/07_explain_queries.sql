-- =============================================================================
-- SI3009 | Proyecto 2 | Script 07: Consultas con EXPLAIN ANALYZE
-- Documentar los planes de ejecución y su interpretación.
-- Ejecutar en el nodo correspondiente según el user_id.
-- =============================================================================

-- =============================================================================
-- CONSULTA 1: Feed de un usuario (OLTP — shard local, con índice)
-- Patrón más frecuente: mostrar los últimos 20 posts de un usuario.
-- ESPERADO: Index Scan usando idx_posts_user_created → muy rápido
-- =============================================================================
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT p.id, p.content, p.created_at, u.username
FROM posts p
JOIN users u ON p.user_id = u.id
WHERE p.user_id = 1500
ORDER BY p.created_at DESC
LIMIT 20;

/*
Plan esperado (Nodo 1, user_id 1500 está en rango 1–3000):
  Limit  (cost=0.28..25.42 rows=20)
    -> Nested Loop
       -> Index Scan Backward using idx_posts_user_created on posts p
          Index Cond: (user_id = 1500)
       -> Index Scan using users_pkey on users u
          Index Cond: (id = 1500)
  Planning Time: 0.3 ms
  Execution Time: 0.8 ms   ← objetivo: < 2 ms en shard local
*/

-- =============================================================================
-- CONSULTA 2: Full scan sin índice (OLTP mal optimizada — para comparar)
-- =============================================================================
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT p.id, p.content, p.created_at
FROM posts p
WHERE p.content LIKE '%PostgreSQL%'
ORDER BY p.created_at DESC;

/*
Plan esperado:
  Sort  (cost=1500.00..1502.00 rows=500)
    -> Seq Scan on posts p
       Filter: (content ~~ '%PostgreSQL%')
       Rows Removed by Filter: ~49900
  Execution Time: 42 ms   ← sin índice en content, full scan inevitable
  
  Enseñanza: las búsquedas por texto requieren índice GIN/trigram para escalar.
  CREATE EXTENSION pg_trgm;
  CREATE INDEX idx_posts_content_trgm ON posts USING gin(content gin_trgm_ops);
*/

-- =============================================================================
-- CONSULTA 3: Analítica — usuarios con más publicaciones (OLAP)
-- Requiere full scan y agregación → latencia esperada alta (>30 ms)
-- =============================================================================
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    u.username,
    COUNT(p.id) AS total_posts,
    MAX(p.created_at) AS ultimo_post
FROM users u
JOIN posts p ON u.id = p.user_id
GROUP BY u.id, u.username
ORDER BY total_posts DESC
LIMIT 10;

/*
Plan esperado:
  Limit  (cost=2500.00..2500.03 rows=10)
    -> Sort (on total_posts DESC)
       -> HashAggregate (Group Key: u.id)
          -> Hash Join (Hash Cond: p.user_id = u.id)
             -> Seq Scan on posts p
             -> Hash on users u
  Execution Time: ~40–90 ms   ← depende del volumen y de si hay stats actualizadas

  Recomendación: ANALYZE posts; antes de correr OLAP pesadas.
*/

-- =============================================================================
-- CONSULTA 4: Posts más populares por likes (OLAP cross-shard)
-- Esta consulta en entorno distribuido requiere combinar resultados de 3 nodos.
-- En un nodo individual solo ve los likes locales → resultado parcial.
-- =============================================================================
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    p.id          AS post_id,
    p.content,
    p.user_id,
    COUNT(l.user_id) AS total_likes
FROM posts p
LEFT JOIN likes l ON p.id = l.post_id
GROUP BY p.id, p.content, p.user_id
ORDER BY total_likes DESC
LIMIT 10;

/*
Plan esperado:
  Limit
    -> Sort
       -> HashAggregate
          -> Hash Left Join (Hash Cond: l.post_id = p.id)
             -> Seq Scan on posts p
             -> Hash on likes l  (using idx_likes_post_id)
  Execution Time: ~30–60 ms por nodo

  NOTA IMPORTANTE para el informe:
  En el entorno distribuido de este proyecto, esta consulta se ejecuta en los 3 nodos
  y los resultados se combinan en la aplicación (application-side merge).
  Eso implica 3 round-trips de red + lógica de merge en la app.
  
  En CockroachDB, la misma consulta se ejecuta en el motor, que paraleliza
  automáticamente entre rangos y devuelve el resultado consolidado.
*/

-- =============================================================================
-- CONSULTA 5: Join cross-shard simulado (impacto en rendimiento)
-- Buscar posts de usuarios en DISTINTOS nodos (simulado con IN)
-- En producción, requeriría 3 conexiones separadas + merge en la app.
-- =============================================================================
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT p.id, p.content, p.created_at, u.username
FROM posts p
JOIN users u ON p.user_id = u.id
WHERE p.user_id IN (100, 3500, 7200)   -- nodos 1, 2 y 3 respectivamente
ORDER BY p.created_at DESC;

/*
En UN solo nodo (Nodo 1), solo retornará los posts de user_id = 100.
Los user_ids 3500 y 7200 no existen en este nodo → 0 resultados para ellos.

Plan:
  Sort
    -> Nested Loop
       -> Index Scan on posts using idx_posts_user_id
          Index Cond: (user_id = ANY('{100,3500,7200}'))   ← solo 100 existe aquí
       -> Index Scan on users using users_pkey
  Execution Time: ~0.9 ms   ← rápido porque pocos resultados locales

  ANÁLISIS CROSS-SHARD COMPLETO:
  Para obtener todos los posts de los 3 usuarios, la aplicación debe:
    1. Conectar a Nodo 1 → WHERE user_id = 100      (~0.8 ms)
    2. Conectar a Nodo 2 → WHERE user_id = 3500     (+1 ms round-trip)
    3. Conectar a Nodo 3 → WHERE user_id = 7200     (+1 ms round-trip)
    4. Merge en memoria ordenado por created_at
  Total: ~80–200 ms dependiendo de latencia de red entre nodos

  En CockroachDB: 1 query, ~35 ms (el motor hace el merge internamente)
*/

-- =============================================================================
-- CONSULTA 6: Verificación de partition pruning (si se usa particionamiento nativo)
-- Si se hubiera usado PostgreSQL Table Partitioning, esta consulta mostraría
-- que el motor evita escanear particiones irrelevantes.
-- =============================================================================
-- Este proyecto usa sharding manual (tablas separadas por nodo), no
-- pg_partman/declarative partitioning, por lo que no aplica partition pruning.
-- Se documenta como comparación conceptual:
/*
-- Con PARTICIONAMIENTO DECLARATIVO en un solo nodo (referencia):
CREATE TABLE posts_partitioned (LIKE posts INCLUDING ALL)
PARTITION BY RANGE (created_at);

CREATE TABLE posts_2024 PARTITION OF posts_partitioned
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE posts_2025 PARTITION OF posts_partitioned
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

EXPLAIN SELECT * FROM posts_partitioned WHERE created_at >= '2025-06-01';
-- Plan mostraría: SOLO escanea posts_2025, ignora posts_2024 (partition pruning)
-- Esto reduce drásticamente I/O en consultas por rango de fechas.
*/

-- =============================================================================
-- RESUMEN: Tabla de tiempos de ejecución medidos
-- (Actualizar con los valores reales del experimento)
-- =============================================================================
SELECT
    'CONSULTA 1: Feed local (Index Scan)'        AS consulta,
    'PostgreSQL Nodo 1'                           AS motor,
    '~0.8 ms'                                     AS latencia_p50,
    '~2 ms'                                       AS latencia_p99
UNION ALL SELECT 'CONSULTA 3: OLAP GROUP BY (Full Scan)', 'PostgreSQL Nodo 1', '~40 ms', '~90 ms'
UNION ALL SELECT 'CONSULTA 5: Cross-shard join (app merge)', 'PostgreSQL 3 nodos', '~80 ms', '~200 ms'
UNION ALL SELECT 'CONSULTA 5: Cross-shard join', 'CockroachDB cluster', '~35 ms', '~90 ms';
