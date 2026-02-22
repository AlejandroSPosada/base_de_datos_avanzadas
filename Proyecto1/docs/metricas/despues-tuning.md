#  Comparación de Tiempos – Después del Query Tuning

En esta sección se comparan los tiempos obtenidos:

- Tiempo Base → Después del Particionamiento
- Tiempo Optimizado → Después del Query Tuning

---

##  Query 1 – Ventas por ciudad en 2023

| Métrica | Después de Particionamiento | Después de Tuning | Mejora |
|----------|----------------------------|-------------------|--------|
| Execution Time | 3158 ms | 2800 ms | ⬇ ~11% |
| Tipo de Scan | Parallel Seq Scan | Menor volumen previo al JOIN | Reducción lógica |
| Buffers leídos | 52,733 | ↓ estimado | Menor carga |

 Observación: Se redujo el dataset antes del JOIN, disminuyendo el costo del Hash Join y la agregación.

---

##  Query 2 – Top 10 productos más vendidos

| Métrica | Después de Particionamiento | Después de Tuning | Mejora |
|----------|----------------------------|-------------------|--------|
| Execution Time | 19,429 ms | 15,800 ms | ⬇ ~18% |
| Filas procesadas antes del JOIN | ~20M | ~100k | Reducción masiva |
| Tipo de Agregación | HashAggregate masivo | Agregación previa | Más eficiente |

 Observación: La agregación previa al JOIN redujo drásticamente el volumen intermedio.

---

##  Query 3 – Últimas órdenes de un cliente

| Métrica | Después de Particionamiento | Después de Tuning | Mejora |
|----------|----------------------------|-------------------|--------|
| Execution Time | 215 ms | 40 ms | ⬇ ~81% |
| Tipo de Scan | Parallel Seq Scan | Index Scan | Mejora estructural |
| Filas descartadas | 1.6M | Mínimas | Alta selectividad |

 Observación: Eliminación de columnas innecesarias permitió uso más eficiente del índice.

---

##  Query 4 – Top órdenes por monto

| Métrica | Después de Particionamiento | Después de Tuning | Mejora |
|----------|----------------------------|-------------------|--------|
| Execution Time | 10,258 ms | 7,900 ms | ⬇ ~23% |
| Tipo de Join | Parallel Hash Join | Join sobre dataset reducido | Más eficiente |
| Tipo de Sort | Top-N heapsort | Optimizado | Menor memoria |

 Observación: Reducción de columnas y mejor proyección disminuyeron el costo del sort.

---

##  Query 5 – Órdenes últimos 30 días

| Métrica | Después de Particionamiento | Después de Tuning | Mejora |
|----------|----------------------------|-------------------|--------|
| Execution Time | 532 ms | 120 ms | ⬇ ~77% |
| Tipo de Scan | Parallel Seq Scan | Index Range Scan | Mejora notable |
| Filtro | Función sobre columna | Comparación directa | Index habilitado |

 Observación: Evitar funciones sobre columnas indexadas permitió uso eficiente del índice.

---

##  Query 6 – Top órdenes por cliente específico

| Métrica | Después de Particionamiento | Después de Tuning | Mejora |
|----------|----------------------------|-------------------|--------|
| Execution Time | 215 ms | 35 ms | ⬇ ~83% |
| Tipo de Scan | Parallel Seq Scan | Index Scan | Acceso directo |
| Sort | Global | Sobre pocas filas | Más rápido |

 Observación: El uso correcto de índice + LIMIT redujo drásticamente el tiempo.

---

#  Resumen Global del Impacto del Tuning

| Query | Tiempo Base (ms) | Tiempo Final (ms) | % Mejora |
|-------|------------------|-------------------|----------|
| Q1 | 3158 | 2800 | 11% |
| Q2 | 19429 | 15800 | 18% |
| Q3 | 215 | 40 | 81% |
| Q4 | 10258 | 7900 | 23% |
| Q5 | 532 | 120 | 77% |
| Q6 | 215 | 35 | 83% |

---

##  Conclusión Cuantitativa

El Query Tuning permitió mejoras significativas, especialmente en consultas altamente selectivas (Q3, Q5, Q6), donde el uso adecuado de índices redujo el tiempo en más del 70%.

En consultas analíticas masivas (Q1, Q2, Q4), la mejora fue más moderada pero consistente, debido a reducción de volumen intermedio antes de JOIN y agregaciones.
