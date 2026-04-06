# Proyecto 2 — Bases de Datos Distribuidas

## Descripción general

Este proyecto implementa un sistema distribuido basado en PostgreSQL para simular el comportamiento de una red social. Se exploran conceptos como particionamiento horizontal (sharding), enrutamiento de consultas, transacciones distribuidas y comparación con sistemas NewSQL.

---

## Dominio del problema

Se modela una red social simplificada en la cual los usuarios pueden crear publicaciones (posts). El sistema está diseñado para simular un entorno con alta generación de datos y consultas frecuentes, similar a plataformas como Twitter o Instagram. Este dominio es adecuado para experimentar con particionamiento y distribución de datos, ya que permite segmentar la información de forma natural por usuario.

---

## Modelo de datos

Se definieron las siguientes tablas principales:

**1. users**

- id (PK)  
- username  
- email  
- created_at  

**2. posts**

- id (PK)  
- user_id (FK → users.id)  
- content  
- created_at  

**3. follows**

- follower_id (FK → users.id)  
- followed_id (FK → users.id)  
- created_at  

**4. likes**

- user_id (FK → users.id)  
- post_id (FK → posts.id)  
- created_at  

---

## Operaciones

### OLTP (transaccionales)

- Crear un post  
- Dar like a un post  
- Seguir a otro usuario  
- Consultar posts de un usuario específico  

Estas operaciones son frecuentes, de baja latencia y afectan pocas filas.

### OLAP (analíticas)

- Obtener los usuarios con más publicaciones  
- Calcular los posts más populares (más likes)  

Estas consultas requieren agregaciones y procesamiento de grandes volúmenes de datos.

---

## Arquitectura del sistema

El sistema está compuesto por múltiples nodos PostgreSQL desplegados en instancias independientes (AWS EC2). Cada nodo almacena una partición de los datos basada en rangos de `user_id`.


<img width="684" height="598" alt="Screenshot 2026-04-06 124112" src="https://github.com/user-attachments/assets/76d86fed-90c9-4dfe-b40d-5f56aacccad7" />

---

## Estrategia de distribución (Sharding)

El sistema utiliza sharding por rango de `user_id`, distribuyendo los datos entre múltiples nodos. Esto permite balancear la carga y mejorar el rendimiento en consultas dirigidas, simulando el comportamiento de sistemas distribuidos reales.

Se implementa la siguiente distribución:

- Nodo 1 → usuarios 1–3000  
- Nodo 2 → usuarios 3001–6000  
- Nodo 3 → usuarios 6001–10000  

---

## Configuración e instalación

1. Crear instancias PostgreSQL en AWS  
2. Ejecutar scripts en cada nodo:  

   - `01_create_tables.sql`  
   - `02_indexes.sql`  
   - `03_inserts.sql` (con datos segmentados)  

3. Verificar carga de datos  

---

## Enrutamiento de consultas

La lógica de enrutamiento se basa en el rango de `user_id`:

- Si `user_id <= 3000` → Nodo 1  
- Si `user_id <= 6000` → Nodo 2  
- En otro caso → Nodo 3  

Esto permite dirigir las consultas directamente al nodo que contiene los datos.

---

## Experimentos y resultados

Se evaluaron distintos tipos de consultas:

- Consultas selectivas (por usuario)  
- Consultas tipo feed (múltiples usuarios)  
- Consultas agregadas (GROUP BY)  
- Comparación con tabla no particionada  

Se utilizaron herramientas como `EXPLAIN ANALYZE` para medir rendimiento.

---

## Transacciones distribuidas

Se implementó un esquema de Two-Phase Commit (2PC) utilizando:

- `PREPARE TRANSACTION`  
- `COMMIT PREPARED`  

Esto permite garantizar consistencia entre múltiples nodos.

---

## Comparativa: PostgreSQL vs NewSQL (CockroachDB / YugabyteDB)

| Dimensión | PostgreSQL (clásico distribuido) | NewSQL (CockroachDB / YugabyteDB) |
|---|---|---|
| **Arquitectura base** | Motor monolítico, no distribuido de forma nativa. La distribución se logra manualmente con herramientas externas (Citus, pgPool, etc.) | Diseñado desde cero para distribución horizontal. Cada nodo es igual (arquitectura shared-nothing) |
| **Particionamiento** | Manual. El desarrollador define las particiones por rango, hash o lista con `PARTITION BY`. La lógica de enrutamiento la gestiona la aplicación o un proxy | Automático (auto-sharding). El motor divide los datos en rangos de claves y redistribuye los shards dinámicamente sin intervención manual |
| **Transparencia de enrutamiento** | Baja. La aplicación necesita saber en qué nodo está cada dato, o se usa un middleware (ej. pgBouncer, Citus). Un join entre particiones distintas requiere lógica explícita | Alta. El motor enruta internamente cualquier consulta al nodo correcto. El cliente conecta a cualquier nodo y obtiene el dato correcto de forma transparente |
| **Replicación** | Líder-seguidor (Primary-Replica). Se configura manualmente con `postgresql.conf` y `pg_hba.conf`. Soporta replicación sincrónica y asincrónica vía `synchronous_commit` | Basada en el protocolo Raft. Cada rango de datos tiene su propio grupo Raft con un líder y réplicas. El consenso es automático y continuo |
| **Consistencia** | ACID completo en un nodo. En configuración distribuida manual, la consistencia entre nodos depende del nivel de `synchronous_commit` y del diseño del sistema | Consistencia serializable global por defecto. Garantiza ACID en transacciones que abarcan múltiples nodos sin configuración adicional |
| **Modelo CAP** | Prioriza Consistencia (C) y Disponibilidad (A) en operación normal. Ante una partición de red (P), hay riesgo de split-brain si el failover no se gestiona correctamente | Prioriza Consistencia (C) y Tolerancia a particiones (P). Ante una partición, el sistema prefiere rechazar escrituras antes que aceptar datos inconsistentes |
| **PACELC** | PA/EL: ante partición sacrifica disponibilidad; en operación normal prioriza latencia baja sobre consistencia fuerte (depende de `synchronous_commit`) | PC/EC: ante partición sacrifica disponibilidad; en operación normal acepta mayor latencia para garantizar consistencia fuerte |
| **Transacciones distribuidas** | No nativas. Se implementan manualmente con el protocolo Two-Phase Commit (2PC): `PREPARE TRANSACTION` + `COMMIT PREPARED`. Complejidad alta y riesgo de bloqueo si el coordinador falla | Nativas y transparentes. El motor implementa internamente un protocolo similar a 2PC con Raft. El desarrollador escribe `BEGIN` / `COMMIT` como en cualquier BD relacional |
| **Failover** | Manual o semi-automático con herramientas externas (Patroni, repmgr). Requiere promover un seguidor a líder explícitamente. Riesgo de split-brain sin configuración cuidadosa | Automático. Raft elige un nuevo líder en segundos si el nodo líder de un rango falla. No requiere intervención del operador |
| **Failback** | Manual. Se debe reintegrar el nodo recuperado como réplica y sincronizarlo antes de reconvertirlo en líder | Automático. El nodo recuperado se reincorpora al cluster, sincroniza su estado vía Raft y comienza a recibir tráfico sin intervención manual |
| **Tolerancia a fallos (quórum)** | No tiene concepto de quórum nativo. La disponibilidad depende de cuántas réplicas estén activas y del valor de `synchronous_standby_names` | Basado en quórum Raft: con 3 nodos tolera 1 fallo; con 5 nodos tolera 2 fallos. Si se pierde el quórum, el cluster deja de aceptar escrituras (prioriza consistencia) |
| **Latencia de escritura** | Baja en configuración asincrónica (`synchronous_commit = off`). Alta en configuración sincrónica estricta, especialmente con múltiples réplicas geográficamente distribuidas | Mayor que PostgreSQL local debido al overhead del consenso Raft. En configuración de un solo datacenter, la penalización suele ser de 1–5 ms adicionales por escritura |
| **Latencia de lectura** | Muy baja en lecturas locales desde el nodo primario o réplicas locales | Variable. Lecturas consistentes van al líder del rango; lecturas "follower reads" (lectura desde réplicas) son más rápidas pero con posible staleness de milisegundos |
| **Escalabilidad horizontal** | Limitada y compleja. Agregar nodos requiere redistribuir particiones manualmente y actualizar la lógica de enrutamiento en la aplicación | Nativa. Se agrega un nodo al cluster y el motor redistribuye automáticamente los shards para balancear la carga |
| **Joins distribuidos** | Costosos. Un join entre tablas en nodos distintos requiere transferir datos entre nodos (network shuffle). Se detecta con `EXPLAIN ANALYZE` como `Gather` o `Append` nodes | El motor optimiza joins distribuidos internamente. Aun así, los joins entre rangos distintos tienen overhead de red; el planner los minimiza colocando datos relacionados juntos (locality) |
| **Complejidad operativa** | Alta en distribución. Configurar sharding, replicación, failover y monitoreo requiere conocimiento profundo y múltiples herramientas externas (Patroni, pgBouncer, etc.) | Baja a media. La distribución, replicación y failover son responsabilidad del motor. El operador gestiona el cluster (nodos, zonas) pero no el routing interno |
| **Complejidad de desarrollo** | Media-alta. El desarrollador debe conocer la topología de shards, escribir lógica de enrutamiento y manejar 2PC manualmente para transacciones cross-shard | Baja. El desarrollador usa SQL estándar. Las transacciones distribuidas, el routing y la consistencia son transparentes |
| **Compatibilidad SQL** | SQL estándar completo + extensiones propias de PostgreSQL (JSONB, arrays, full-text search, extensiones como PostGIS) | Compatible con el dialecto SQL de PostgreSQL (CockroachDB) o PostgreSQL + Cassandra (YugabyteDB). Algunas funciones avanzadas de PostgreSQL pueden no estar disponibles |
| **Costo de infraestructura** | Bajo si se usan instancias propias. El costo operativo (DBA, mantenimiento) es alto | Más alto en recursos por nodo (mínimo 3 nodos recomendados). El costo operativo es menor por la automatización, pero el hardware/cloud es más costoso |
| **Madurez y ecosistema** | Muy maduro (30+ años). Ecosistema enorme: ORMs, herramientas de migración, monitoreo, extensiones | Relativamente joven (CockroachDB desde 2015, YugabyteDB desde 2017). Ecosistema en crecimiento, pero menor que PostgreSQL |
| **Caso de uso ideal** | Aplicaciones con distribución moderada, equipos con experiencia en PostgreSQL, cuando se necesita control total sobre la topología | Aplicaciones que requieren escala global, alta disponibilidad automática, y donde la complejidad operativa debe ser mínima |

---

## Análisis crítico

El uso de PostgreSQL con particionamiento manual permite simular ciertos aspectos de sistemas distribuidos, como la segmentación de datos y la optimización de consultas mediante técnicas como partition pruning. Sin embargo, este enfoque implica una alta carga operativa, ya que la lógica de distribución, enrutamiento de consultas y consistencia entre nodos debe ser gestionada manualmente por el desarrollador. Esto incrementa la complejidad del sistema y lo hace propenso a errores, especialmente en escenarios con múltiples nodos y transacciones concurrentes.

En contraste, las bases de datos NewSQL como CockroachDB o YugabyteDB integran de forma nativa características como particionamiento automático, replicación y manejo de transacciones distribuidas. Esto reduce significativamente la complejidad de implementación, permitiendo a los desarrolladores enfocarse en la lógica del negocio en lugar de la infraestructura. No obstante, esta abstracción tiene un costo en términos de recursos y posibles latencias adicionales, debido a mecanismos internos como consenso distribuido (por ejemplo, Raft).

En términos prácticos, PostgreSQL resulta adecuado para sistemas donde se requiere control fino y el volumen de datos es manejable, mientras que las soluciones NewSQL son más apropiadas para aplicaciones a gran escala que demandan alta disponibilidad, tolerancia a fallos y escalabilidad horizontal. Este proyecto evidencia cómo la implementación manual de un sistema distribuido puede ser funcional, pero también resalta las ventajas de utilizar tecnologías diseñadas específicamente para este propósito.

---

## Conclusiones

El proyecto demuestra que es posible implementar un sistema distribuido utilizando PostgreSQL, aunque con una alta complejidad operativa. Tecnologías NewSQL ofrecen soluciones más automatizadas, pero con otros costos asociados.

---

## Estructura del repositorio

```
/scripts
/resultados
/docs
README.md
```

---



