-- =============================================================================
-- SI3009 | Proyecto 2 | Script 06: Replicación y configuración de consistencia
--
-- PARTE A: Configuración vía postgresql.conf (comentada, aplicar fuera de psql)
-- PARTE B: Experimentos de latencia con synchronous_commit
-- PARTE C: Monitoreo de replicación
-- PARTE D: Procedimiento de failover manual
-- =============================================================================

-- =============================================================================
-- PARTE A: Configuración recomendada (aplicar en postgresql.conf del Primary)
-- =============================================================================
/*
# ── postgresql.conf del PRIMARY ────────────────────────────────────────────
wal_level = replica              # habilita replicación
max_wal_senders = 5              # máximo de conexiones de réplicas
wal_keep_size = 256MB            # retener WAL para réplicas lentas
max_replication_slots = 5        # slots de replicación

# Replicación sincrónica: el PRIMARY espera ACK de la réplica antes de confirmar
# al cliente. Opciones:
#   off          → asincrónico (mayor velocidad, riesgo de pérdida de datos)
#   on           → sincrónico (espera que la réplica recibió el WAL en buffer)
#   remote_write → espera que la réplica escribió el WAL a disco
#   remote_apply → espera que la réplica aplicó el WAL (datos ya visibles en réplica)
synchronous_commit = on
synchronous_standby_names = 'replica1'

# ── pg_hba.conf del PRIMARY ─────────────────────────────────────────────────
# Agregar línea para permitir conexiones de replicación:
# host  replication  replicador  10.0.0.0/24  scram-sha-256

# ── Crear usuario de replicación ────────────────────────────────────────────
CREATE USER replicador WITH REPLICATION ENCRYPTED PASSWORD 'repl_secret_2026';

# ── En la RÉPLICA: recovery.conf / postgresql.conf ──────────────────────────
# primary_conninfo = 'host=10.0.0.1 port=5432 user=replicador password=repl_secret_2026 application_name=replica1'
# hot_standby = on    # permite lecturas en la réplica
# Crear archivo de señal: touch /var/lib/postgresql/data/standby.signal
*/

-- =============================================================================
-- PARTE B: Experimentos de latencia según synchronous_commit
-- Ejecutar en el PRIMARY para medir impacto de cada configuración.
-- =============================================================================

-- Función auxiliar para medir latencia de una inserción
CREATE OR REPLACE FUNCTION benchmark_insert_latency(
    p_sync_mode  TEXT,    -- 'off', 'on', 'remote_write', 'remote_apply'
    p_iterations INT DEFAULT 100
)
RETURNS TABLE(
    sync_mode      TEXT,
    iterations     INT,
    total_ms       NUMERIC,
    avg_ms         NUMERIC,
    min_ms         NUMERIC,
    max_ms         NUMERIC
) AS $$
DECLARE
    v_start    TIMESTAMPTZ;
    v_end      TIMESTAMPTZ;
    v_elapsed  NUMERIC;
    v_min      NUMERIC := 999999;
    v_max      NUMERIC := 0;
    v_total    NUMERIC := 0;
    i          INT;
    v_user_id  INT;
BEGIN
    -- Cambiar synchronous_commit para esta sesión
    EXECUTE format('SET synchronous_commit = %I', p_sync_mode);

    FOR i IN 1..p_iterations LOOP
        v_user_id := (random() * 2999 + 1)::INT;  -- user_id en rango Nodo 1
        v_start := clock_timestamp();

        INSERT INTO posts (user_id, content, created_at)
        VALUES (v_user_id, 'benchmark_' || i || '_sync_' || p_sync_mode, NOW())
        ON CONFLICT DO NOTHING;

        v_end := clock_timestamp();
        v_elapsed := EXTRACT(MILLISECONDS FROM (v_end - v_start));

        v_total := v_total + v_elapsed;
        IF v_elapsed < v_min THEN v_min := v_elapsed; END IF;
        IF v_elapsed > v_max THEN v_max := v_elapsed; END IF;
    END LOOP;

    -- Restaurar synchronous_commit a valor por defecto de la sesión
    RESET synchronous_commit;

    -- Limpiar datos de benchmark
    DELETE FROM posts WHERE content LIKE 'benchmark_%';

    sync_mode  := p_sync_mode;
    iterations := p_iterations;
    total_ms   := v_total;
    avg_ms     := round(v_total / p_iterations, 3);
    min_ms     := v_min;
    max_ms     := v_max;
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Ejecutar benchmark comparativo:
-- NOTA: 'remote_write' y 'remote_apply' requieren réplica activa para mostrar diferencia real
SELECT * FROM benchmark_insert_latency('off',  100);
SELECT * FROM benchmark_insert_latency('on',   100);
-- SELECT * FROM benchmark_insert_latency('remote_write', 100);
-- SELECT * FROM benchmark_insert_latency('remote_apply', 100);

-- =============================================================================
-- PARTE C: Monitoreo de replicación (ejecutar en el PRIMARY)
-- =============================================================================

-- Estado de las réplicas conectadas
SELECT
    client_addr,
    application_name,
    state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn,
    write_lag,
    flush_lag,
    replay_lag,
    sync_state
FROM pg_stat_replication;

-- Lag de replicación en bytes (cuánto WAL no ha llegado a la réplica)
SELECT
    application_name,
    pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn)   AS send_lag_bytes,
    pg_wal_lsn_diff(pg_current_wal_lsn(), write_lsn)  AS write_lag_bytes,
    pg_wal_lsn_diff(pg_current_wal_lsn(), flush_lsn)  AS flush_lag_bytes,
    pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS replay_lag_bytes
FROM pg_stat_replication;

-- En la RÉPLICA: verificar que está en modo standby
SELECT pg_is_in_recovery();   -- debe retornar TRUE

-- En la RÉPLICA: consultar el lag temporal
SELECT
    now() - pg_last_xact_replay_timestamp() AS replication_lag_seconds;

-- =============================================================================
-- PARTE D: Failover manual (comandos bash, documentados como comentario SQL)
-- =============================================================================
/*
── ESCENARIO: Primary (10.0.0.1) cae ──────────────────────────────────────────

1. Detectar la caída del Primary:
   pg_isready -h 10.0.0.1 -p 5432
   → retorna "no response" → Primary caído

2. En el servidor de la RÉPLICA (10.0.0.2), promover a Primary:
   # Opción A: archivo de trigger (PostgreSQL < 12)
   touch /var/lib/postgresql/data/failover.trigger

   # Opción B: pg_ctl promote (PostgreSQL >= 12)
   pg_ctl promote -D /var/lib/postgresql/data
   # o vía SQL si hay conexión:
   SELECT pg_promote();

3. Verificar que la réplica es ahora Primary:
   psql -h 10.0.0.2 -c "SELECT pg_is_in_recovery();"
   → debe retornar FALSE

4. Actualizar el router de la aplicación para apuntar a 10.0.0.2:
   UPDATE shard_metadata SET host = '10.0.0.2' WHERE shard_id = 1;

5. Reintegrar el nodo recuperado (10.0.0.1) como nueva réplica:
   # En 10.0.0.1: reconfigurar como standby del nuevo primary (10.0.0.2)
   pg_basebackup -h 10.0.0.2 -U replicador -D /var/lib/postgresql/data --wal-method=stream
   touch /var/lib/postgresql/data/standby.signal
   pg_ctl start -D /var/lib/postgresql/data

── PREVENCIÓN DE SPLIT-BRAIN ───────────────────────────────────────────────────
El split-brain ocurre cuando dos nodos creen ser el Primary simultáneamente.

Prevención con synchronous_standby_names:
  synchronous_standby_names = 'replica1'
  → El Primary no acepta commits si no hay al menos 1 réplica sincrónica disponible
  → Si la réplica cae, el Primary también se detiene → no hay split-brain

Con Patroni + etcd (recomendado en producción):
  → Patroni usa etcd/ZooKeeper como árbitro de quórum
  → Solo un nodo puede tener el "leader lock" de etcd
  → Al detectar fallo del Primary, Patroni promueve la réplica con mayor LSN
  → El Primary recuperado no puede reincorporarse como Primary sin pasar por etcd
*/

-- Verificar que no hay dos primaries (desde cualquier nodo que se crea primary):
SELECT pg_is_in_recovery() AS es_replica, inet_server_addr() AS ip_nodo;
-- Si dos nodos retornan FALSE, hay split-brain → situación de emergencia
