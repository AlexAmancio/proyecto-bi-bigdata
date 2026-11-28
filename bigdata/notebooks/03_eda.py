# Databricks notebook source
# MAGIC %md
# MAGIC # 03 · Análisis exploratorio de datos (EDA)
# MAGIC
# MAGIC **Objetivo:** entender el comportamiento y la calidad de los datos **antes** de limpiarlos.
# MAGIC Se trabaja sobre la capa Bronze (datos crudos). Lo que se encuentre aquí define las reglas de limpieza de `04_silver_limpieza`.
# MAGIC
# MAGIC Preguntas que guían el análisis (las mismas del problema de negocio):
# MAGIC 1. ¿Cuántas reservas hay, en qué periodo y cómo evolucionan en el tiempo?
# MAGIC 2. ¿Cómo se reparten por estado (finalizada, cancelada, no-show, activa)?
# MAGIC 3. ¿Qué segmentos concentran la no-llegada (cancelación + no-show)?
# MAGIC 4. ¿Qué problemas de calidad tienen los datos (nulos, duplicados, valores inválidos)?
# MAGIC
# MAGIC > Para cada `display(...)` se puede crear un gráfico con el botón **+ → Visualización** debajo del resultado.

# COMMAND ----------

# MAGIC %run ./00_configuracion

# COMMAND ----------

estadias = spark.table(f"{BRONZE}.estadias")
clientes = spark.table(f"{BRONZE}.clientes")
consumos = spark.table(f"{BRONZE}.consumos")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Inspección básica: tamaño, columnas y tipos

# COMMAND ----------

print("Filas   :", estadias.count())
print("Columnas:", len(estadias.columns))
print(estadias.columns)
estadias.printSchema()

# COMMAND ----------

display(estadias.limit(20))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Estadísticas descriptivas de las columnas numéricas
# MAGIC `describe()` da conteo, media, desviación estándar, mínimo y máximo.
# MAGIC Un **mínimo negativo** en tarifa o **0** en noches indica datos inválidos.

# COMMAND ----------

display(estadias.select("noches", "num_huespedes", "tarifa", "monto_pagado").describe())

# COMMAND ----------

# Percentiles (describe no los muestra)
display(estadias.selectExpr(
    "percentile_approx(noches, array(0.25, 0.5, 0.75)) AS noches_p25_p50_p75",
    "percentile_approx(tarifa, array(0.25, 0.5, 0.75)) AS tarifa_p25_p50_p75",
    "percentile_approx(monto_pagado, array(0.25, 0.5, 0.75)) AS monto_p25_p50_p75"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Calidad de datos
# MAGIC ### 3.1 Valores nulos por columna

# COMMAND ----------

nulos = estadias.select([F.count(F.when(F.col(c).isNull(), c)).alias(c) for c in estadias.columns])
display(nulos)

# COMMAND ----------

# MAGIC %md
# MAGIC ### 3.2 Duplicados

# COMMAND ----------

columnas_negocio = [c for c in estadias.columns if c not in ("archivo_origen", "fecha_carga")]
total = estadias.count()
distintas = estadias.select(columnas_negocio).distinct().count()
ids_repetidos = estadias.groupBy("id").count().filter("count > 1").count()
print("Filas repetidas exactas      :", total - distintas)
print("Ids que aparecen más de 1 vez:", ids_repetidos)

# COMMAND ----------

# MAGIC %md
# MAGIC ### 3.3 Valores fuera de dominio
# MAGIC Los estados válidos son `ACTIVA`, `FINALIZADA`, `CANCELADA` y `NO_SHOW`. Cualquier otro valor (minúsculas, espacios) es un error de captura.

# COMMAND ----------

display(estadias.groupBy("estado").count().orderBy(F.desc("count")))

# COMMAND ----------

display(estadias.groupBy("metodo_pago").count().orderBy(F.desc("count")))

# COMMAND ----------

display(estadias.select(
    F.count(F.when(F.col("noches") <= 0, 1)).alias("noches_<=_0"),
    F.count(F.when(F.col("num_huespedes") <= 0, 1)).alias("huespedes_<=_0"),
    F.count(F.when(F.col("tarifa") < 0, 1)).alias("tarifa_negativa"),
    F.count(F.when(F.col("monto_pagado") < 0, 1)).alias("monto_negativo")))

# COMMAND ----------

# Integridad: estadías cuyo cliente no existe en la tabla de clientes
huerfanas = estadias.join(clientes.select(F.col("id").alias("cliente_id")), "cliente_id", "left_anti")
print("Estadías con cliente inexistente:", huerfanas.count())

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Comportamiento del negocio (solo datos reales: `origen = 'sistema'`)
# MAGIC ### 4.1 Reservas por mes (sugerencia de gráfico: líneas, eje X = periodo, serie = año)

# COMMAND ----------

reales = estadias.filter(F.col("origen") == "sistema")

por_mes = (reales
    .withColumn("año", F.year("check_in"))
    .withColumn("mes", F.month("check_in"))
    .groupBy("año", "mes")
    .agg(F.count("*").alias("reservas"))
    .orderBy("año", "mes"))
display(por_mes)

# COMMAND ----------

# MAGIC %md
# MAGIC ### 4.2 Distribución por estado y año (gráfico de barras apiladas)

# COMMAND ----------

display(reales.withColumn("año", F.year("check_in"))
              .groupBy("año", "estado").count()
              .orderBy("año", "estado"))

# COMMAND ----------

# MAGIC %md
# MAGIC ### 4.3 No-llegada por zona de origen del cliente
# MAGIC La zona se calcula con la misma regla que el ETL de BI (Cercana, Lima, Lejana, Extranjero).

# COMMAND ----------

clientes_zona = clientes.withColumn("zona",
    F.when(F.col("pais") != "Perú", "Extranjero")
     .when(F.col("ciudad") == "Lima", "Lima")
     .when(F.col("ciudad").isin(CIUDADES_CERCANAS), "Cercana")
     .otherwise("Lejana"))

no_llegada_zona = (reales
    .join(clientes_zona.select(F.col("id").alias("cliente_id"), "zona"), "cliente_id")
    .groupBy("zona")
    .agg(F.count("*").alias("reservas"),
         F.sum(F.when(F.col("estado").isin("CANCELADA", "NO_SHOW"), 1).otherwise(0)).alias("no_llegadas"))
    .withColumn("pct_no_llegada", F.round(100 * F.col("no_llegadas") / F.col("reservas"), 1))
    .orderBy(F.desc("pct_no_llegada")))
display(no_llegada_zona)

# COMMAND ----------

# MAGIC %md
# MAGIC ### 4.4 No-llegada por método de pago

# COMMAND ----------

display(reales.groupBy("metodo_pago")
    .agg(F.count("*").alias("reservas"),
         F.sum(F.when(F.col("estado").isin("CANCELADA", "NO_SHOW"), 1).otherwise(0)).alias("no_llegadas"))
    .withColumn("pct_no_llegada", F.round(100 * F.col("no_llegadas") / F.col("reservas"), 1))
    .orderBy(F.desc("pct_no_llegada")))

# COMMAND ----------

# MAGIC %md
# MAGIC ### 4.5 Consulta con Spark SQL (misma información, otra forma de consultar)

# COMMAND ----------

reales.createOrReplaceTempView("v_estadias")

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT YEAR(check_in) AS `año`,
# MAGIC        COUNT(*) AS reservas,
# MAGIC        ROUND(100 * SUM(CASE WHEN estado = 'CANCELADA' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_cancelacion,
# MAGIC        ROUND(100 * SUM(CASE WHEN estado = 'NO_SHOW'   THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_no_show,
# MAGIC        ROUND(SUM(monto_pagado), 0) AS ingreso
# MAGIC FROM v_estadias
# MAGIC GROUP BY YEAR(check_in)
# MAGIC ORDER BY `año`

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Hallazgos del EDA y cómo se usaron
# MAGIC
# MAGIC Resultados de la ejecución del 27/11/2026 sobre Bronze: **18 392 estadías** (9 036 reales del sistema y 9 356 del lote simulado con 3 % de errores).
# MAGIC
# MAGIC ### 5.1 Calidad: cada problema encontrado se convirtió en una regla de `04_silver_limpieza`
# MAGIC
# MAGIC Los registros afectados son los que registró la bitácora `tunki_silver.calidad`. Los errores provienen del lote simulado: **ninguna estadía real se descartó**.
# MAGIC
# MAGIC | # | Hallazgo del EDA | Registros | Acción en Silver |
# MAGIC |---|---|---|---|
# MAGIC | 1 | Estado o método de pago en minúsculas o con espacios | 538 | Normalizar con `upper(trim())` (N01) |
# MAGIC | 2 | Filas repetidas exactas | 274 | `dropDuplicates` (R01) |
# MAGIC | 3 | Mismo id con datos distintos | 92 | Descartar (R01B) |
# MAGIC | 4 | Sin id o sin fecha de check-in | 49 | Descartar (R02) |
# MAGIC | 5 | Estado no válido | 82 | Descartar (R03) |
# MAGIC | 6 | Noches o huéspedes en cero o negativos | 82 | Descartar (R04) |
# MAGIC | 7 | Tarifa nula o negativa | 105 | Descartar (R05) |
# MAGIC | 8 | Monto pagado nulo | 264 | `na.fill(0)` (R06) |
# MAGIC | 9 | Método de pago vacío | 271 | `na.fill('NO_REGISTRADO')` (R07) |
# MAGIC | 10 | Cliente, habitación o usuario inexistente | 74 | Descartar (R08) |
# MAGIC | 11 | Consumo sin estadía válida | 405 | Descartar (R09) |
# MAGIC | 12 | Consumo con monto nulo o no positivo | 104 | Descartar (R10) |
# MAGIC
# MAGIC Resultado: Silver conserva **17 634 estadías**: el 100 % de las reales y el 91.9 % de las simuladas (758 descartadas y 535 corregidas).
# MAGIC
# MAGIC ### 5.2 Comportamiento del negocio (datos reales): se convirtió en los indicadores de `05_gold_kpis` y en el dashboard
# MAGIC
# MAGIC | Hallazgo | Resultado | Dónde se usa |
# MAGIC |---|---|---|
# MAGIC | Caída de reservas en 2026 | Enero–octubre: 2 909 reservas en 2025 frente a 2 179 en 2026 (**−25.1 %**); 2024 y 2025 siguen la temporada (picos en enero, julio y diciembre) y 2026 cae todos los meses | `kpi_mensual`, `kpi_anual`; página Resumen |
# MAGIC | Más cancelaciones | Tasa de cancelación de 5.0 % (2025) a **10.0 %** (2026), en el mismo periodo | `kpi_anual`; página Resumen |
# MAGIC | No-llegada por zona de origen | Lejana **15.2 %** frente a cercana a Oxapampa **4.5 %** (brecha de 10.7 pp) | `no_llegada_segmento`; página Factores |
# MAGIC | No-llegada por método de pago | Efectivo **13.5 %** frente a transferencia **6.8 %** | `no_llegada_segmento`; página Factores |
# MAGIC
# MAGIC Las tasas de no-llegada (cancelación + no-show) corresponden al periodo 2024–2026 y coinciden con la solución BI (informe, sección 6.3).
# MAGIC
# MAGIC **Conclusión del EDA:** los datos crudos necesitan las reglas de calidad antes de calcular indicadores, y el patrón del negocio ya es visible: la caída de 2026 coincide con más no-llegada en clientes de zonas lejanas y con pago en efectivo. Esto orienta la recomendación de ofertas de prepago y campañas en zonas cercanas.
