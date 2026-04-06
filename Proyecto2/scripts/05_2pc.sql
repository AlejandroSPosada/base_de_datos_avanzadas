-- =============================================================================
-- SI3009 | Proyecto 2 | Script 05: Two-Phase Commit (2PC)
-- Demostración de PREPARE TRANSACTION / COMMIT PREPARED / ROLLBACK PREPARED
--
-- PREREQUISITO: habilitar prepared transactions en postgresql.conf:
--   max_prepared_transactions = 10
-- Luego: SELECT pg_reload_conf(); o reiniciar el nodo.
-- =============================================================================

-- =============================================================================
-- CASO 1: FOLLOW CROSS-SHARD
-- Escenario: usuario 100 (Nodo 1) sigue a usuario 4500 (Nodo 2).
-- Ambas actualizaciones deben ser atómicas.
-- En producción, el coordinador (aplicación) ejecuta estos pasos secuencialmente.
-- =============================================================================

-- ── NODO 1 (follower_id = 100, rango 1–3000) ─────────────────────────────────

BEGIN;

-- Registrar el follow en el nodo del follower
INSERT INTO follows (follower_id, followed_id)
VALUES (100, 4500)
ON CONFLICT DO NOTHING;

-- Preparar (Fase 1 del 2PC): el nodo promete que puede hacer commit
-- El GID debe ser único a nivel de cluster
PREPARE TRANSACTION 'follow_100_4500_nodo1';

-- ── NODO 2 (followed_id = 4500, rango 3001–6000) ─────────────────────────────
-- (Ejecutar en la conexión al Nodo 2)

BEGIN;

-- Registrar el follow desde la perspectiva del seguido (opcional, si se mantiene
-- tabla de "mis seguidores" en cada nodo para data locality)
-- INSERT INTO follows (follower_id, followed_id) VALUES (100, 4500) ON CONFLICT DO NOTHING;
-- Aquí podría actualizarse un contador desnormalizado:
-- UPDATE users SET followers_count = followers_count + 1 WHERE id = 4500;

-- Por simplicidad, registrar la relación en el nodo del followed también:
INSERT INTO follows (follower_id, followed_id)
VALUES (100, 4500)
ON CONFLICT DO NOTHING;

PREPARE TRANSACTION 'follow_100_4500_nodo2';

-- ── COORDINADOR: Fase 2 ───────────────────────────────────────────────────────
-- Si AMBAS fases PREPARE fueron exitosas → COMMIT en ambos nodos.
-- Si ALGUNA falló → ROLLBACK en ambos nodos.

-- Commit exitoso:
COMMIT PREPARED 'follow_100_4500_nodo1';   -- en Nodo 1
COMMIT PREPARED 'follow_100_4500_nodo2';   -- en Nodo 2

-- Rollback ante fallo (alternativa):
-- ROLLBACK PREPARED 'follow_100_4500_nodo1';
-- ROLLBACK PREPARED 'follow_100_4500_nodo2';

-- =============================================================================
-- CASO 2: LIKE A POST CROSS-SHARD
-- Escenario: usuario 200 (Nodo 1) da like al post_id 9999 de usuario 7000 (Nodo 3).
-- =============================================================================

-- ── NODO 1 ────────────────────────────────────────────────────────────────────
BEGIN;
INSERT INTO likes (user_id, post_id)
VALUES (200, 9999)
ON CONFLICT DO NOTHING;
PREPARE TRANSACTION 'like_200_post9999_nodo1';

-- ── NODO 3 (donde vive el post 9999 del usuario 7000) ─────────────────────────
-- Aquí podría actualizarse un contador de likes desnormalizado en el post.
-- En este modelo sin contador desnormalizado, el Nodo 3 no necesita intervención.
-- Solo se demuestra el patrón 2PC.
BEGIN;
-- Simulamos una operación de auditoría/log en el nodo remoto:
INSERT INTO likes (user_id, post_id)
VALUES (200, 9999)
ON CONFLICT DO NOTHING;
PREPARE TRANSACTION 'like_200_post9999_nodo3';

-- Commit coordinado:
COMMIT PREPARED 'like_200_post9999_nodo1';
COMMIT PREPARED 'like_200_post9999_nodo3';

-- =============================================================================
-- MONITOREO: Transacciones preparadas pendientes (posible bloqueo)
-- Si el coordinador falla entre Fase 1 y Fase 2, las transacciones
-- quedan en estado PREPARED indefinidamente → bloquean recursos.
-- =============================================================================
SELECT
    gid,
    prepared,
    owner,
    database,
    transaction
FROM pg_prepared_xacts
ORDER BY prepared;

-- Limpiar transacciones huérfanas (con cuidado en producción):
-- ROLLBACK PREPARED 'gid_aqui';

-- =============================================================================
-- ANÁLISIS DE RIESGO DEL 2PC
-- =============================================================================
/*
Escenario de fallo del coordinador:

1. Coordinador envía PREPARE a Nodo 1 → OK
2. Coordinador envía PREPARE a Nodo 2 → OK
3. Coordinador FALLA (crash, network partition) antes de enviar COMMIT

Resultado:
- Nodo 1: transacción en estado PREPARED, locks retenidos
- Nodo 2: transacción en estado PREPARED, locks retenidos
- Ambos nodos esperan la decisión final del coordinador → BLOQUEO INDEFINIDO

Detección:
  SELECT gid, prepared FROM pg_prepared_xacts;
  -- Si aparecen transacciones con más de X minutos, son huérfanas

Resolución:
  -- Opción 1: Recuperar el coordinador y completar el commit
  -- Opción 2: Rollback manual (riesgo de inconsistencia si un nodo ya hizo commit)
  ROLLBACK PREPARED 'gid_huerfano';

Cómo NewSQL resuelve esto:
  - CockroachDB/YugabyteDB usan Raft: el consenso es parte del protocolo
  - No hay coordinador externo que pueda fallar
  - El failover es automático en ~seconds
  - No existen transacciones "huérfanas" en estado PREPARED indefinidamente
*/

-- =============================================================================
-- COMPARACIÓN: La misma operación cross-shard en CockroachDB / YugabyteDB
-- =============================================================================
/*
-- En CockroachDB, esto es TODO lo que el desarrollador escribe:
BEGIN;
INSERT INTO follows (follower_id, followed_id) VALUES (100, 4500);
COMMIT;
-- El motor maneja internamente el protocolo de consenso Raft.
-- No hay PREPARE, no hay COMMIT PREPARED, no hay coordinador externo.
-- El failover de cualquier nodo no afecta la atomicidad de la transacción.
*/
