# Proyecto 1 – Optimización de Bases de Datos (Caso EAFITShop)

Repositorio del **Proyecto 1** de la asignatura **Bases de Datos Avanzadas** de la Universidad EAFIT, donde se desarrolla un caso de estudio basado en **EAFITShop** enfocado en medición de rendimiento y optimización de bases de datos utilizando PostgreSQL.

El proyecto consiste en analizar el desempeño de una base de datos en un escenario de **big data**, aplicar técnicas de optimización de forma incremental y medir el impacto de cada una de ellas.

---

## Portada

**Asignatura:** Bases de Datos Avanzadas  
**Proyecto:** Caso de estudio – Optimización de Base de Datos EAFITShop  
**Profesor:** Edwin Nelson Montoya Múnera  
**Universidad:** Universidad EAFIT  
**Fecha de entrega:** Semana 5  
**Sustentación:** Semana 6  

**Integrantes del equipo:**
- Nombre Apellido
- Nombre Apellido
- Nombre Apellido

---

## Objetivo del trabajo

Analizar y optimizar el rendimiento de una base de datos en un escenario empresarial simulado utilizando **PostgreSQL**, aplicando técnicas avanzadas de optimización como:

- Uso de índices
- Particionamiento
- Reescritura de consultas
- Manejo de concurrencia
- Ajustes de configuración del servidor (performance tuning)

Todo esto acompañado de mediciones antes, durante y después del proceso de optimización.

---

## Descripción del caso

El caso de estudio se basa en **EAFITShop**, una plataforma simulada de comercio electrónico donde se analizará el comportamiento de consultas sobre grandes volúmenes de datos.

El proceso incluye:

1. Medición de línea base utilizando:
   - EXPLAIN
   - EXPLAIN ANALYZE

2. Aplicación incremental de técnicas de optimización:
   - Índices
   - Particionamiento
   - Reescritura de queries
   - Concurrencia
   - Performance tuning del servidor de base de datos

3. Medición incremental y final del impacto de las optimizaciones.

---

## Situación empresarial investigada

En esta sección se documenta un caso real empresarial donde se haya presentado un reto similar relacionado con:

- Optimización de consultas en bases de datos
- Escalabilidad en sistemas de datos
- Manejo de grandes volúmenes de información
- Problemas de rendimiento en bases de datos

Se deben incluir:

- Empresa o sector
- Problema presentado
- Solución implementada
- Resultados obtenidos

---

## Ambiente tecnológico utilizado

El proyecto se desarrollará en dos entornos:

1. Infraestructura en la nube
   - AWS EC2
   - Docker
   - PostgreSQL

2. Servicio administrado
   - AWS RDS para PostgreSQL

Herramientas adicionales:

- GitHub
- SQL
- Scripts de automatización
- Herramientas de monitoreo de base de datos

---

## Medición de línea base

Antes de aplicar optimizaciones se realiza un análisis inicial del rendimiento utilizando:

- EXPLAIN
- EXPLAIN ANALYZE
- Monitoreo del servidor
- Tiempo de ejecución de consultas
- Uso de recursos

Esta sección incluye:

- Métricas iniciales
- Cuellos de botella detectados
- Análisis de consultas críticas

---

## Técnicas de optimización aplicadas

Durante el proyecto se aplican de forma incremental las siguientes técnicas:

1. Creación y optimización de índices
2. Particionamiento de tablas
3. Reescritura de consultas SQL
4. Manejo de concurrencia
5. Ajustes de configuración del servidor PostgreSQL

Cada técnica debe incluir:

- Justificación
- Cambios realizados
- Impacto en el rendimiento

---

## Resultados antes de la optimización

Resumen de métricas obtenidas en el sistema sin optimizaciones:

- Tiempo promedio de ejecución de consultas
- Uso de CPU y memoria
- Planes de ejecución
- Problemas identificados

Conclusiones del estado inicial del sistema.

---

## Resultados después de la optimización

Resumen de métricas luego de aplicar las optimizaciones:

- Mejoras en tiempos de respuesta
- Cambios en los planes de ejecución
- Reducción en uso de recursos
- Impacto de cada técnica aplicada

Para esta sección se investigó documentación oficial y recursos sobre optimización en PostgreSQL:

- https://www.postgresql.org/docs/current/performance-tips.html
- https://www.mydbops.com/blog/postgresql-parameter-tuning-best-practices
- https://www.tigerdata.com/blog/how-to-reduce-your-postgresql-database-size
- https://postgresqlco.nf/doc/en/param/
- https://medium.com/@ankush.thavali/the-ultimate-guide-to-postgresql-performance-tuning-0d8134256125

---

## Líneas de trabajo futuras

Posibles mejoras o investigaciones futuras:

- Implementación de caching
- Uso de bases de datos distribuidas
- Optimización de almacenamiento
- Escalabilidad horizontal
- Uso de herramientas avanzadas de monitoreo

---

## Uso de herramientas de IA en el proyecto

En este proyecto se utilizaron herramientas de inteligencia artificial como ChatGPT para:

- Apoyo en investigación de optimización de bases de datos
- Comprensión de técnicas avanzadas de PostgreSQL
- Apoyo en redacción de documentación
- Generación de ideas para pruebas de rendimiento

Las herramientas de IA fueron utilizadas como apoyo al aprendizaje y desarrollo del proyecto.

---

## Replicación del proyecto

Este repositorio está diseñado para que cualquier persona pueda replicar el proyecto fácilmente.

Pasos generales:

1. Clonar el repositorio
2. Levantar el entorno Docker
3. Configurar la base de datos
4. Cargar el dataset de prueba
5. Ejecutar las pruebas de rendimiento
6. Aplicar las optimizaciones
7. Comparar resultados

---

## Estructura del repositorio

    /
    ├── docs/
    │   ├── informe-final.md
    │   ├── metricas
    │   └── resultados
    │
    ├── database/
    │   ├── schema.sql
    │   ├── data.sql
    │   ├── indexes.sql
    │   └── partitioning.sql
    │
    ├── docker/
    │   └── docker-compose.yml
    │
    ├── scripts/
    │   ├── baseline-tests.sql
    │   └── performance-tests.sql
    │
    └── README.md

---

## Entrega

Este proyecto debe ser entregado al final de la **semana 5** y será sustentado en la **semana 6**.