# INFORME FINAL

Este informe tendrá la siguiente estructura:

1. Primero se realizará un análisis de los queries en su estado base, es decir, sin ninguna optimización.
2. Luego se evaluará la mejora del rendimiento mediante la creación de índices.
3. Posteriormente se analizarán posibles optimizaciones utilizando particionamiento de tablas.
4. Finalmente, se propondrán mejoras a partir del replanteamiento o reescritura de los queries.

# 1. ANALISIS QUERIES EN ESTADO BASE

En este análisis se evaluaron varios queries en su estado base utilizando **EXPLAIN** y **EXPLAIN ANALYZE** para observar cómo el motor de la base de datos ejecuta cada consulta, identificar el flujo del plan de ejecución y medir su comportamiento real en términos de tiempo, filas procesadas y uso de recursos. En los queries analizados se realizaron distintos tipos de operaciones: agregaciones sobre grandes volúmenes de datos (por ejemplo, calcular métricas o conteos), joins entre tablas grandes como `orders`, `customer`, `product` y `order_item`, consultas que buscan los registros con mayores valores mediante ordenamientos y límites (`ORDER BY` + `LIMIT`), y filtros específicos por columnas como `customer_id`, fechas recientes o montos de compra. En todos los casos, el análisis se enfocó en observar cómo el optimizador utiliza paralelismo (workers), escaneos secuenciales paralelos, hash joins, agregaciones parciales y finales, y operaciones de ordenamiento para producir el resultado final, permitiendo entender el comportamiento del sistema antes de cualquier optimización y establecer una línea base del rendimiento de las consultas.

## Query 1

### Resumen de Métricas del Plan

| Nodo | Costo Estimado (Inicio..Fin) | Filas Estimadas | Tiempo Real (ms) | Filas Reales | Loops | Detalles Clave |
|------|------------------------------|-----------------|------------------|--------------|-------|----------------|
| Sort (final) | 98723.76..98723.78 | 10 | 3085.667..3093.618 | 10 | 1 | Ordena por `SUM(total_amount)` DESC, quicksort (25kB) |
| Finalize GroupAggregate | 98720.49..98723.59 | 10 | 3085.567..3093.568 | 10 | 1 | Agrupación final por `city` |
| Gather Merge | 98720.49..98723.29 | 24 | 3085.554..3093.527 | 30 | 1 | 2 workers lanzados |
| Sort (workers) | 97720.47..97720.49 | 10 | 3071.384..3071.396 | 10 | 3 | Orden intermedio por `city` |
| Partial HashAggregate | 97720.18..97720.30 | 10 | 3071.340..3071.354 | 10 | 3 | Agregación parcial, memoria ~32kB |
| Parallel Hash Join | 21568.00..95598.92 | 424252 | 975.215..2612.901 | 333785 | 3 | Join por `customer_id` |
| Parallel Seq Scan (orders) | 0.00..72917.25 | 424252 | 0.257..666.389 | 333785 | 3 | Filtro por fecha; 1,332,882 filas descartadas |
| Parallel Hash (customer) | 16359.67..16359.67 | 416667 | 972.426..972.428 | 333333 | 3 | Hash table ~59MB |
| Parallel Seq Scan (customer) | 0.00..16359.67 | 416667 | 0.385..434.284 | 333333 | 3 | Escaneo completo de tabla |
| Planning | — | — | 0.206 ms | — | — | Tiempo de planificación |
| Execution Total | — | — | **3093.692 ms** | — | — | Tiempo total del query |

---

### Uso de Buffers

| Tipo | Cantidad |
|------|----------|
| Shared Hit | 1144 |
| Shared Read | 52732 |

---

### Análisis

El principal costo del query se concentra en el **Parallel Hash Join** y en los **escaneos secuenciales paralelos** de las tablas `orders` y `customer`, donde se procesan grandes volúmenes de datos antes de poder realizar la agregación. En particular, el escaneo de `orders` muestra una cantidad significativa de filas eliminadas por el filtro de fecha, lo que indica que se está leyendo una porción grande de la tabla para luego descartar muchos registros. El join paralelo también consume tiempo considerable al construir y utilizar la tabla hash de `customer`, y aunque el paralelismo reduce el tiempo total, la mayor parte de la ejecución (más de 2.6 segundos) ocurre en esta etapa. Las fases de agregación y ordenamiento final tienen un costo relativamente bajo en comparación, por lo que el cuello de botella principal del plan está asociado al procesamiento inicial de datos (scans + join) más que a las operaciones de agrupación o sorting.

## Query 2

### Resumen de Métricas del Plan

| Nodo | Costo Estimado (Inicio..Fin) | Filas Estimadas | Tiempo Real (ms) | Filas Reales | Loops | Detalles Clave |
|------|------------------------------|-----------------|------------------|--------------|-------|----------------|
| Limit | 347000.18..347000.21 | 10 | 38842.179..38842.299 | 10 | 1 | Devuelve top 10 resultados |
| Sort | 347000.18..347250.18 | 100000 | 38728.539..38728.649 | 10 | 1 | Orden por `SUM(quantity)` DESC, top-N heapsort (26kB) |
| Finalize HashAggregate | 343839.22..344839.22 | 100000 | 38573.563..38652.428 | 100000 | 1 | Agregación final por `product name`, memoria ~9MB |
| Gather | 317639.22..342639.22 | 240000 | 37888.155..38252.181 | 300000 | 1 | 2 workers lanzados |
| Partial HashAggregate | 316639.22..317639.22 | 100000 | 37889.015..38004.600 | 100000 | 3 | Agregación parcial por worker (~7–9MB) |
| Hash Join | 3096.00..274972.47 | 8333350 | 245.244..26277.534 | 6666666 | 3 | Join por `product_id` |
| Parallel Seq Scan (order_item) | 0.00..250000.50 | 8333350 | 2.105..7825.658 | 6666666 | 3 | Escaneo masivo de tabla |
| Hash | 1846.00..1846.00 | 100000 | 242.509..242.512 | 100000 | 3 | Construcción de hash de `product` (~6.4MB) |
| Seq Scan (product) | 0.00..1846.00 | 100000 | 12.938..117.981 | 100000 | 3 | Escaneo completo de tabla |
| Planning | — | — | 6.642 ms | — | — | Tiempo de planificación |
| Execution Total | — | — | **39454.580 ms** | — | — | Tiempo total del query |

---

### Uso de Buffers

| Tipo | Cantidad |
|------|----------|
| Shared Hit | 1695 |
| Shared Read | 167513 |

---

### Análisis

El costo principal del query se concentra en el **Hash Join** y en el **Parallel Seq Scan de la tabla `order_item`**, donde se procesan decenas de millones de filas antes de realizar la agregación. Cada worker escanea millones de registros y genera un gran volumen intermedio que luego pasa por las fases de agregación parcial y final, lo que provoca que gran parte del tiempo total del query se consuma antes de llegar al ordenamiento y al `LIMIT`. Además, el plan muestra un uso intensivo de lectura desde disco (más de 167k páginas), lo que indica que la operación está fuertemente dominada por I/O. Aunque el paralelismo reduce el tiempo de ejecución, la mayor parte del tiempo del plan (más de 26 segundos) ocurre en la etapa de join y escaneo de datos, convirtiéndola en el principal cuello de botella del query.

## Query 3

### Resumen de Métricas del Plan

| Nodo | Costo Estimado (Inicio..Fin) | Filas Estimadas | Tiempo Real (ms) | Filas Reales | Loops | Detalles Clave |
|------|------------------------------|-----------------|------------------|--------------|-------|----------------|
| Limit | 68708.91..68709.49 | 5 | 219.050..222.638 | 6 | 1 | Devuelve los últimos pedidos |
| Gather Merge | 68708.91..68709.49 | 5 | 219.048..222.627 | 6 | 1 | 2 workers lanzados |
| Sort | 67708.88..67708.89 | 2 | 194.709..195.015 | 2 | 3 | Orden por `order_date DESC`, quicksort (25kB) |
| Parallel Seq Scan (orders) | 0.00..67708.88 | 2 | 108.191..194.662 | 2 | 3 | Filtro por `customer_id = 12345` |
| Planning | — | — | 0.131 ms | — | — | Tiempo de planificación |
| Execution Total | — | — | **222.671 ms** | — | — | Tiempo total del query |

---

### Uso de Buffers

| Tipo | Cantidad |
|------|----------|
| Shared Hit | 1204 |
| Shared Read | 40539 |

---

### Análisis

El principal costo del query proviene del **Parallel Seq Scan sobre la tabla `orders`**, donde se realiza un escaneo completo para encontrar muy pocas filas que cumplen la condición `customer_id = 12345`. Cada worker revisa millones de registros y descarta una gran cantidad de filas mediante el filtro, lo que evidencia que la mayor parte del tiempo del plan se invierte en la lectura y evaluación de datos más que en las etapas de ordenamiento o limitación del resultado. El paralelismo reduce el tiempo total, pero el cuello de botella sigue siendo el acceso a la tabla y la gran cantidad de filas removidas por el filtro, lo que además se refleja en el alto número de páginas leídas desde disco.

## Query 4

### Resumen de Métricas del Plan

| Nodo | Costo Estimado (Inicio..Fin) | Filas Estimadas | Tiempo Real (ms) | Filas Reales | Loops | Detalles Clave |
|------|------------------------------|-----------------|------------------|--------------|-------|----------------|
| Limit | 113895.90..113898.23 | 20 | 5146.532..5159.002 | 20 | 1 | Devuelve top 20 resultados |
| Gather Merge | 113895.90..339722.77 | 1938986 | 5140.455..5152.904 | 20 | 1 | 2 workers lanzados |
| Sort | 112895.88..114915.66 | 807911 | 5109.975..5109.994 | 19 | 3 | Orden por `total_amount DESC`, top-N heapsort (27kB) |
| Parallel Hash Join | 21568.00..91397.66 | 807911 | 984.970..4116.004 | 646219 | 3 | Join por `customer_id` |
| Parallel Seq Scan (orders) | 0.00..67708.88 | 807911 | 0.230..1198.985 | 646219 | 3 | Filtro `total_amount > 500` |
| Parallel Hash | 16359.67..16359.67 | 416667 | 982.126..982.129 | 333333 | 3 | Hash table ~63MB |
| Parallel Seq Scan (customer) | 0.00..16359.67 | 416667 | 10.339..467.941 | 333333 | 3 | Escaneo completo de tabla |
| Planning | — | — | 0.202 ms | — | — | Tiempo de planificación |
| Execution Total | — | — | **5159.550 ms** | — | — | Tiempo total del query |

---

### Uso de Buffers

| Tipo | Cantidad |
|------|----------|
| Shared Hit | 2834 |
| Shared Read | 51040 |

---

### Análisis

El mayor costo del query se concentra en el **Parallel Hash Join** y en el **Parallel Seq Scan de la tabla `orders`**, donde se procesan grandes volúmenes de datos antes de poder ordenar y limitar los resultados. Cada worker escanea cientos de miles de registros y elimina una cantidad significativa de filas mediante el filtro `total_amount > 500`, lo que implica que gran parte del tiempo se consume leyendo y evaluando datos. Además, la construcción de la tabla hash de `customer` también aporta un costo considerable debido al tamaño de la tabla y al uso de memoria. Aunque el `LIMIT` reduce el número final de filas y el ordenamiento usa un método eficiente (top-N heapsort), la mayor parte del tiempo del plan ocurre en las etapas iniciales de escaneo y join, que constituyen el principal cuello de botella del query.

## Query 5

### Resumen de Métricas del Plan

| Nodo | Costo Estimado (Inicio..Fin) | Filas Estimadas | Tiempo Real (ms) | Filas Reales | Loops | Detalles Clave |
|------|------------------------------|-----------------|------------------|--------------|-------|----------------|
| Finalize Aggregate | 79210.07..79210.08 | 1 | 534.742..539.913 | 1 | 1 | Resultado final de la agregación |
| Gather | 79209.86..79210.07 | 2 | 534.627..539.891 | 3 | 1 | 2 workers lanzados |
| Partial Aggregate | 78209.86..78209.87 | 1 | 510.918..510.921 | 1 | 3 | Agregación parcial por worker |
| Parallel Seq Scan (orders) | 0.00..78125.62 | 33694 | 0.599..472.602 | 27177 | 3 | Filtro por pedidos de los últimos 30 días |
| Planning | — | — | 0.071 ms | — | — | Tiempo de planificación |
| Execution Total | — | — | **539.944 ms** | — | — | Tiempo total del query |

---

### Uso de Buffers

| Tipo | Cantidad |
|------|----------|
| Shared Hit | 2256 |
| Shared Read | 39411 |

---

### Análisis

El costo principal del query se encuentra en el **Parallel Seq Scan de la tabla `orders`**, donde se realiza un escaneo completo para encontrar únicamente los registros de los últimos 30 días. Cada worker analiza millones de filas y descarta una gran cantidad mediante el filtro de fecha, lo que evidencia que la mayor parte del tiempo de ejecución se invierte en leer y evaluar datos más que en la agregación final, que resulta relativamente ligera. Aunque el paralelismo ayuda a reducir el tiempo total, el alto número de filas removidas por el filtro y la cantidad significativa de páginas leídas desde disco muestran que el cuello de botella del plan está en el acceso a la tabla y el procesamiento masivo de registros antes de calcular la agregación.

## Query 6

### Resumen de Métricas del Plan

| Nodo | Costo Estimado (Inicio..Fin) | Filas Estimadas | Tiempo Real (ms) | Filas Reales | Loops | Detalles Clave |
|------|------------------------------|-----------------|------------------|--------------|-------|----------------|
| Limit | 68708.91..68709.49 | 5 | 212.654..220.321 | 4 | 1 | Devuelve máximo 5 resultados |
| Gather Merge | 68708.91..68709.49 | 5 | 212.650..220.312 | 4 | 1 | 2 workers lanzados |
| Sort | 67708.88..67708.89 | 2 | 189.425..189.427 | 1.33 | 3 | Orden por `total_amount DESC`, quicksort (25kB) |
| Parallel Seq Scan (orders) | 0.00..67708.88 | 2 | 111.558..189.291 | 1.33 | 3 | Filtro por `customer_id = 9876` |
| Planning | — | — | 0.067 ms | — | — | Tiempo de planificación |
| Execution Total | — | — | **220.367 ms** | — | — | Tiempo total del query |

---

### Uso de Buffers

| Tipo | Cantidad |
|------|----------|
| Shared Hit | 2894 |
| Shared Read | 38847 |

---

### Análisis

El tiempo del query está dominado por el **Parallel Seq Scan sobre la tabla `orders`**, donde se realiza un escaneo completo para encontrar muy pocas filas que coinciden con `customer_id = 9876`. Cada worker revisa millones de registros y descarta casi todos mediante el filtro, lo que provoca que la mayor parte del tiempo se invierta en la lectura y evaluación de datos. Aunque el ordenamiento y el `LIMIT` son operaciones ligeras y el paralelismo ayuda a distribuir la carga, el cuello de botella principal sigue siendo el acceso masivo a la tabla y la gran cantidad de filas removidas por el filtro, evidenciado también por el alto número de páginas leídas desde disco.