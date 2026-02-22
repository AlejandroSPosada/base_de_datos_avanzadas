## Análisis de Planes de Ejecución por Query

---

## Query 1 – Ventas por ciudad (Filtro por año)

### Análisis del Plan

El plan muestra la siguiente estructura:

- **Parallel Bitmap Heap Scan** sobre `orders`
- **Bitmap Index Scan** sobre `idx_orders_order_date`
- **Parallel Hash Join**
- **Partial HashAggregate**
- **Finalize GroupAggregate**
- **Gather Merge**
- **Sort**

---

### Puntos Técnicos Clave

#### Uso de Índice por Rango de Fecha

Se utiliza **Bitmap Index Scan** sobre `idx_orders_order_date`. El índice reduce el conjunto inicial de ~1M filas a las que cumplen el rango 2023, y luego se realiza **Bitmap Heap Scan** para acceder a los bloques reales.

#### Lectura de Buffers

| Métrica | Valor |
|---------|-------|
| Shared Read | 56599 |
| Shared Hit | 17 |

Esto indica una carga importante desde disco y poca reutilización en caché.

#### Paralelismo

| Métrica | Valor |
|---------|-------|
| Workers lanzados | 2 |
| Procesos totales | 3 |
| Filas por worker | ~333k |

#### Costo Dominante

El mayor tiempo ocurre en el **Parallel Hash Join** y el **GroupAggregate**. La agregación masiva es el verdadero cuello de botella.

---

### Conclusión

El índice funciona correctamente y reduce el acceso inicial, pero el costo dominante es la agregación y el join masivo. El particionamiento ayuda solo si existe *pruning* efectivo; en este caso el peso lo tiene el volumen agregado.

**Execution Time: ~3265 ms**

---

## Query 2 – Top productos por cantidad vendida

### Análisis del Plan

Componentes principales:

- **Parallel Seq Scan** sobre `order_item`
- **Hash Join** con `product`
- **Partial HashAggregate**
- **Finalize HashAggregate**
- **Top-N Heapsort**

---

### Puntos Técnicos Clave

#### Sin filtro por fecha

No existe condición sobre `order_date`, por lo que no se activa *Partition Pruning* y PostgreSQL debe escanear completamente `order_item`.

#### Lectura Masiva de Disco

| Métrica | Valor |
|---------|-------|
| Shared Read | 167513 |

Esto explica el tiempo elevado (~40 segundos).

#### Join Masivo

| Métrica | Valor |
|---------|-------|
| Filas por worker | ~6.6 millones |
| Memoria por worker (Hash Join) | ~9 MB |

#### Ordenamiento Final

Se usa **top-N heapsort** optimizado para `LIMIT 10`. El *sort* no es el problema principal.

---

### Conclusión

El cuello de botella es el escaneo completo de `order_item`. El particionamiento no aporta mejora porque no existe filtro sobre la columna particionada.

**Execution Time: ~40126 ms**

---

## Query 3 – Últimas órdenes por cliente

### Análisis del Plan

- **Index Scan** sobre `idx_orders_customer_date`
- Uso de `LIMIT`
- Muy bajo consumo de buffers

---

### Puntos Técnicos Clave

#### Búsqueda Altamente Selectiva

Filtro directo por `customer_id` con uso correcto del índice compuesto.

#### Muy Bajo I/O

| Métrica | Valor |
|---------|-------|
| Shared Hit | 6 |
| Shared Read | 3 |

Acceso mínimo a disco, sin agregación ni join pesado.

---

### Conclusión

Consulta completamente optimizada por índice. El particionamiento es irrelevante aquí porque el índice ya resuelve eficientemente.

**Execution Time: ~0.098 ms**

---

## Query 4 – Órdenes mayores a 500

### Análisis del Plan

- **Index Only Scan** sobre `idx_orders_amount_customer`
- **Nested Loop**
- **Memoize**
- **Index Scan** sobre `customer`

---

### Puntos Técnicos Clave

#### Index Only Scan

No hay *Heap Fetches*. Toda la información está cubierta por el índice.

#### Memoize

PostgreSQL almacena resultados intermedios, reduciendo búsquedas repetidas en `customer`.

#### Buffers

| Métrica | Valor |
|---------|-------|
| Shared Hit | 89 |

Casi todo está en memoria.

---

### Conclusión

Consulta extremadamente eficiente gracias al índice compuesto y la *memoization*.

**Execution Time: ~1.94 ms**

---

## Query 5 – Órdenes últimos 30 días

### Análisis del Plan

- **Index Only Scan** sobre `idx_orders_order_date`
- **Aggregate**
- Sin necesidad de *heap access*

---

### Puntos Técnicos Clave

#### Uso de Índice por Rango

Condición: `order_date >= now() - interval '30 days'`. Excelente caso para índice por fecha.

#### Heap Fetches = 0

Consulta totalmente cubierta por el índice.

#### Buffers

| Métrica | Valor |
|---------|-------|
| Shared Hit | 27319 |
| Shared Read | 223 |

Gran parte ya estaba en caché.

---

### Conclusión

Este es el escenario ideal para la combinación de índice + particionamiento por fecha.

**Execution Time: ~114 ms**

---

## Query 6 – Órdenes por cliente específico

### Análisis del Plan

- **Index Only Scan** sobre `idx_orders_customer_amount`
- Uso de `LIMIT`
- *Heap Fetches* = 0

---

### Puntos Técnicos Clave

#### Búsqueda Puntual

Altamente selectiva, retornando solo 4 filas.

#### Costo Mínimo

| Métrica | Valor |
|---------|-------|
| Shared Hit | 6 |
| Shared Read | 0 |

Sin lectura desde disco ni necesidad de paralelismo.

---

### Conclusión

Consulta optimizada al máximo por índice. El particionamiento no influye en búsquedas puntuales.

**Execution Time: ~0.05 ms**

---

## Conclusión Global del Informe

### El particionamiento es útil cuando:

- Existe filtro directo sobre la columna particionada.
- No se aplican funciones sobre esa columna.
- El volumen por rango es grande.

### Los índices son el factor más determinante en:

- Consultas selectivas.
- Búsquedas por clave.
- Consultas con `LIMIT`.

### El particionamiento **no** mejora:

- Consultas sin filtro por la columna particionada.
- *Joins* masivos sin restricciones.
