-- =============================================================================
-- SI3009 | Proyecto 2 | Script 04: Enrutamiento y funciones de utilidad
-- Aplicar en CADA nodo. Estas funciones centralizan la lógica de sharding.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Función: get_shard_for_user
-- Devuelve el shard_id (1, 2 o 3) responsable de un user_id dado.
-- La aplicación puede llamar esta función para saber a qué nodo conectar.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_shard_for_user(p_user_id INT)
RETURNS INT AS $$
BEGIN
    IF p_user_id BETWEEN 1 AND 3000 THEN
        RETURN 1;
    ELSIF p_user_id BETWEEN 3001 AND 6000 THEN
        RETURN 2;
    ELSIF p_user_id BETWEEN 6001 AND 10000 THEN
        RETURN 3;
    ELSE
        RAISE EXCEPTION 'user_id % fuera del rango definido (1–10000)', p_user_id;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- -----------------------------------------------------------------------------
-- Función: get_connection_string
-- Devuelve el connection string del nodo responsable de un user_id.
-- Útil para logging y depuración desde la capa de aplicación.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_connection_string(p_user_id INT)
RETURNS TEXT AS $$
DECLARE
    v_shard INT;
    v_host  TEXT;
    v_port  INT;
BEGIN
    v_shard := get_shard_for_user(p_user_id);
    SELECT host, port INTO v_host, v_port
    FROM shard_metadata
    WHERE shard_id = v_shard;
    RETURN format('host=%s port=%s dbname=socialdb', v_host, v_port);
END;
$$ LANGUAGE plpgsql STABLE;

-- -----------------------------------------------------------------------------
-- Función: is_local_user
-- Retorna TRUE si el user_id pertenece al rango de ESTE nodo.
-- Requiere que cada nodo tenga configurada su variable personalizada.
-- Configurar en postgresql.conf: custom_variable_classes = 'app'
-- y en cada nodo: ALTER SYSTEM SET app.shard_id = '1'; (o 2, 3)
-- Seguido de: SELECT pg_reload_conf();
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION is_local_user(p_user_id INT)
RETURNS BOOLEAN AS $$
DECLARE
    v_local_shard INT;
BEGIN
    -- Leer el shard_id de este nodo desde la configuración
    BEGIN
        v_local_shard := current_setting('app.shard_id')::INT;
    EXCEPTION WHEN undefined_object THEN
        -- Si no está configurado, comparar por hostname o asumir shard 1
        RAISE NOTICE 'app.shard_id no configurado. Asumir shard 1.';
        v_local_shard := 1;
    END;
    RETURN get_shard_for_user(p_user_id) = v_local_shard;
END;
$$ LANGUAGE plpgsql STABLE;

-- -----------------------------------------------------------------------------
-- Vista: v_posts_with_likes
-- Agrega el conteo de likes a cada post de forma local.
-- En un entorno distribuido, cada nodo expone esta vista sobre sus propios datos.
-- La aplicación combina los resultados de los 3 nodos (application-side merge).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_posts_with_likes AS
SELECT
    p.id            AS post_id,
    p.user_id,
    u.username,
    p.content,
    p.created_at,
    COUNT(l.user_id) AS total_likes
FROM posts p
JOIN users u ON p.user_id = u.id
LEFT JOIN likes l ON p.id = l.post_id
GROUP BY p.id, p.user_id, u.username, p.content, p.created_at;

-- -----------------------------------------------------------------------------
-- Vista: v_user_stats
-- Estadísticas de un usuario: posts, likes recibidos, follows.
-- Parcialmente local (likes de posts de otros nodos no están aquí).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_user_stats AS
SELECT
    u.id            AS user_id,
    u.username,
    u.created_at    AS member_since,
    COUNT(DISTINCT p.id)          AS total_posts,
    COUNT(DISTINCT f_out.followed_id) AS following_count,
    COUNT(DISTINCT f_in.follower_id)  AS followers_count
FROM users u
LEFT JOIN posts   p    ON u.id = p.user_id
LEFT JOIN follows f_out ON u.id = f_out.follower_id
LEFT JOIN follows f_in  ON u.id = f_in.followed_id
GROUP BY u.id, u.username, u.created_at;

-- -----------------------------------------------------------------------------
-- Función de prueba: simulate_routing_decision
-- Muestra para una lista de user_ids a qué nodo iría cada operación.
-- Útil para demostrar transparencia vs opacidad del enrutamiento.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION simulate_routing_decision(p_user_ids INT[])
RETURNS TABLE(user_id INT, shard_id INT, connection_string TEXT) AS $$
DECLARE
    v_uid INT;
BEGIN
    FOREACH v_uid IN ARRAY p_user_ids LOOP
        user_id           := v_uid;
        shard_id          := get_shard_for_user(v_uid);
        connection_string := get_connection_string(v_uid);
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql STABLE;

-- Demo: ¿A qué nodo van estos user_ids?
SELECT * FROM simulate_routing_decision(ARRAY[100, 3500, 7200, 1, 6000, 10000]);

-- Comentario para el informe:
-- En CockroachDB/YugabyteDB esta función NO existe porque el enrutamiento
-- es transparente. El cliente conecta a cualquier nodo y el motor resuelve
-- internamente a qué rango (leaseholder) va la operación.
-- Esto representa una diferencia fundamental en complejidad de desarrollo.
