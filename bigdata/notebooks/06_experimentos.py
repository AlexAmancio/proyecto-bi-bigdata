# Databricks notebook source
# MAGIC %md
# MAGIC # 06 · Experimentos de la solución Big Data
# MAGIC
# MAGIC Cada experimento sigue la misma estructura: **objetivo → procedimiento → configuración → resultados → análisis**.
# MAGIC Cada medición se **repite 3 veces** y se reporta el promedio y la desviación estándar; todos los tiempos quedan en
# MAGIC la tabla `tunki_gold.experimentos` (evidencia).
# MAGIC
# MAGIC | Código | Experimento | Pregunta | Responsable |
# MAGIC |---|---|---|---|
# MAGIC | EXP-BD-01 | Escalabilidad por volumen | ¿Cómo crece el tiempo de proceso al multiplicar los datos ×1 a ×100? | (asignar) |
# MAGIC | EXP-BD-02 | Formato CSV frente a Delta | ¿Cuánto mejora la lectura y el espacio con Delta Lake? | (asignar) |
# MAGIC | EXP-BD-03 | Tabla particionada frente a no particionada | ¿Cuánto acelera particionar por mes una consulta filtrada? | (asignar) |
# MAGIC | EXP-BD-04 | Estrategia de limpieza | ¿Qué pasa con la calidad si se borra todo nulo (`na.drop`) en vez de aplicar reglas? | (asignar) |
# MAGIC | EXP-BD-05 | Spark SQL frente a API de DataFrames | ¿Hay diferencia de rendimiento entre ambas formas de consultar? | (asignar) |
# MAGIC | EXP-BD-06 | Número de particiones | ¿Cómo afecta `repartition` (1, 4, 16, 64) al tiempo de una agregación? | (asignar) |
# MAGIC
# MAGIC **Condiciones comunes:** Databricks Free Edition, cómputo serverless (no se controla el número de nodos),
# MAGIC mismos datos de origen, misma tasa de errores (3 %). La primera repetición puede ser más lenta (arranque en frío);
# MAGIC por eso se repite y se analiza el promedio.
# MAGIC
# MAGIC > Ejecutar antes `01` a `05`. Los experimentos crean tablas temporales `exp_*` que se borran al final.

# COMMAND ----------

# MAGIC %run ./00_configuracion

# COMMAND ----------

import time

resultados = []
REPETICIONES = 3

def medir(experimento, escenario, accion, filas, repeticiones=REPETICIONES):
    """Ejecuta `accion` varias veces y guarda los segundos de cada repetición."""
    for r in range(1, repeticiones + 1):
        inicio = time.time()
        accion()
        segundos = round(time.time() - inicio, 3)
        resultados.append((experimento, escenario, r, segundos, int(filas)))
        print(f"{experimento} | {escenario:28} | rep {r} | {segundos:8.3f} s | {filas:,} filas")

def resumen(experimento):
    """Promedio y desviación estándar por escenario."""
    df = spark.createDataFrame(resultados, "experimento STRING, escenario STRING, repeticion INT, segundos DOUBLE, filas LONG")
    return (df.filter(F.col("experimento") == experimento)
              .groupBy("experimento", "escenario", "filas")
              .agg(F.round(F.avg("segundos"), 3).alias("promedio_s"),
                   F.round(F.stddev("segundos"), 3).alias("desv_estandar_s"),
                   F.round(F.min("segundos"), 3).alias("minimo_s"),
                   F.round(F.max("segundos"), 3).alias("maximo_s"))
              .orderBy("filas", "escenario"))

estadias_reales = leer_txt(f"{RUTA_SISTEMA}/estadias.txt", ESQUEMA_ESTADIAS)
ids_cliente = spark.table(f"{BRONZE}.clientes").select(F.col("id").alias("cliente_id")).distinct()

def limpiar(df):
    """Versión compacta de las reglas de Silver (N01, R01–R08) para los experimentos."""
    df = (df.withColumn("estado", F.upper(F.trim("estado")))
            .withColumn("metodo_pago", F.upper(F.trim("metodo_pago")))
            .dropDuplicates())
    conflictos = df.groupBy("id").count().filter("count > 1").select("id")
    return (df.join(conflictos, "id", "left_anti")
              .na.drop(subset=["id", "check_in"])
              .filter(F.col("estado").isin(ESTADOS_VALIDOS))
              .filter((F.col("noches") > 0) & (F.col("num_huespedes") > 0) & (F.col("tarifa") >= 0))
              .na.fill(0.0, subset=["monto_pagado"])
              .na.replace("", None, subset=["metodo_pago"])
              .na.fill("NO_REGISTRADO", subset=["metodo_pago"])
              .join(ids_cliente, "cliente_id", "left_semi"))

def kpis(df):
    """Agregación mensual de los KPIs (como en Gold)."""
    return (df.groupBy(F.year("check_in").alias("año"), F.month("check_in").alias("mes"))
              .agg(F.count("*").alias("reservas"),
                   F.sum(F.when(F.col("estado") == "CANCELADA", 1).otherwise(0)).alias("canceladas"),
                   F.sum(F.when(F.col("estado") == "NO_SHOW", 1).otherwise(0)).alias("no_show"),
                   F.sum("monto_pagado").alias("ingreso")))

# COMMAND ----------

# MAGIC %md
# MAGIC ## EXP-BD-01 · Escalabilidad por volumen
# MAGIC - **Objetivo:** medir cómo crece el tiempo de ingesta y de limpieza + KPIs cuando el volumen aumenta.
# MAGIC - **Procedimiento:** para cada factor se genera el lote simulado, se guarda como tabla Delta (ingesta) y luego se ejecuta limpieza + agregación + escritura (proceso).
# MAGIC - **Configuración:** factores ×1, ×10, ×25, ×50, ×100 (≈ 9 mil a ≈ 930 mil filas); tasa de errores 3 %; 3 repeticiones.
# MAGIC - **Resultado esperado:** crecimiento menor que proporcional (Spark reparte el trabajo en paralelo y tiene un costo fijo de arranque).

# COMMAND ----------

FACTORES = [1, 10, 25, 50, 100]

for factor in FACTORES:
    tabla = f"{BRONZE}.exp_estadias_x{factor}"
    lote = simular_estadias(estadias_reales, factor, 0.03)
    filas = lote.count()
    medir("EXP-BD-01", f"Ingesta x{factor}",
          lambda: lote.write.mode("overwrite").saveAsTable(tabla), filas)
    medir("EXP-BD-01", f"Limpieza+KPIs x{factor}",
          lambda: kpis(limpiar(spark.table(tabla))).write.mode("overwrite").saveAsTable(f"{GOLD}.exp_kpis"), filas)

display(resumen("EXP-BD-01"))

# COMMAND ----------

# MAGIC %md
# MAGIC **Análisis EXP-BD-01:** graficar `promedio_s` (eje Y) contra `filas` (eje X) por escenario. Comparar el crecimiento
# MAGIC del tiempo con el crecimiento de los datos: si los datos crecen ×100 y el tiempo crece mucho menos, la solución escala.

# COMMAND ----------

# MAGIC %md
# MAGIC ## EXP-BD-02 · Formato CSV frente a Delta Lake
# MAGIC - **Objetivo:** comparar tiempo de lectura + agregación y espacio en disco entre texto plano (CSV) y Delta.
# MAGIC - **Procedimiento:** el mismo lote ×50 se guarda como CSV en el Volume y como tabla Delta; se ejecuta la misma consulta sobre ambos.
# MAGIC - **Configuración:** lote ×50 (≈ 465 mil filas), consulta = KPIs por año y mes, 3 repeticiones.

# COMMAND ----------

tabla_delta = f"{BRONZE}.exp_estadias_x50"
ruta_csv = f"{RUTA_SIMULADO}/exp_csv_x50"
spark.table(tabla_delta).write.mode("overwrite").option("header", True).option("sep", "|").csv(ruta_csv)
filas = spark.table(tabla_delta).count()

medir("EXP-BD-02", "Lectura CSV + KPIs",
      lambda: kpis(leer_txt(ruta_csv, ESQUEMA_ESTADIAS)).collect(), filas)
medir("EXP-BD-02", "Lectura Delta + KPIs",
      lambda: kpis(spark.table(tabla_delta)).collect(), filas)

tamano_csv = sum(f.size for f in dbutils.fs.ls(ruta_csv))
tamano_delta = spark.sql(f"DESCRIBE DETAIL {tabla_delta}").first()["sizeInBytes"]
print(f"Tamaño CSV  : {tamano_csv / 1e6:8.2f} MB")
print(f"Tamaño Delta: {tamano_delta / 1e6:8.2f} MB  ({tamano_delta / tamano_csv:.0%} del CSV)")
display(resumen("EXP-BD-02"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## EXP-BD-03 · Tabla particionada por mes frente a no particionada
# MAGIC - **Objetivo:** medir si particionar acelera una consulta que filtra un solo mes.
# MAGIC - **Procedimiento:** el lote ×50 ya limpio se guarda dos veces: con `partitionBy("mes")` y sin partición. Se consulta solo diciembre (temporada alta).
# MAGIC - **Configuración:** lote ×50, consulta = reservas y no-llegada de diciembre por año, 3 repeticiones.
# MAGIC - **Nota:** se particiona por `mes` y no por `año` porque Databricks no admite columnas de partición con caracteres no ASCII (ñ).

# COMMAND ----------

limpio = (limpiar(spark.table(f"{BRONZE}.exp_estadias_x50"))
          .withColumn("año", F.year("check_in"))
          .withColumn("mes", F.month("check_in")))
limpio.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(f"{SILVER}.exp_sin_particion")
limpio.write.mode("overwrite").option("overwriteSchema", "true").partitionBy("mes").saveAsTable(f"{SILVER}.exp_con_particion")
filas = spark.table(f"{SILVER}.exp_sin_particion").count()

def consulta_diciembre(tabla):
    return (spark.table(tabla).filter(F.col("mes") == 12)
            .groupBy("año")
            .agg(F.count("*").alias("reservas"),
                 F.sum(F.when(F.col("estado").isin("CANCELADA", "NO_SHOW"), 1).otherwise(0)).alias("no_llegadas"))
            .collect())

medir("EXP-BD-03", "Sin partición", lambda: consulta_diciembre(f"{SILVER}.exp_sin_particion"), filas)
medir("EXP-BD-03", "Particionada por mes", lambda: consulta_diciembre(f"{SILVER}.exp_con_particion"), filas)

for t in ["exp_sin_particion", "exp_con_particion"]:
    d = spark.sql(f"DESCRIBE DETAIL {SILVER}.{t}").first()
    print(f"{t:20} archivos: {d['numFiles']:4}  particiones: {d['partitionColumns']}")
display(resumen("EXP-BD-03"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## EXP-BD-04 · Estrategia de limpieza: `na.drop()` total frente a reglas de calidad
# MAGIC - **Objetivo:** demostrar por qué se aplican reglas específicas en vez de eliminar toda fila con algún nulo.
# MAGIC - **Procedimiento:** sobre Bronze (datos reales + lote ×1) se aplican dos estrategias y se compara cuántas filas quedan y cuánto se alejan los KPIs del valor real.
# MAGIC - **Configuración:** Bronze completo; métrica = filas conservadas, % no-llegada y ingreso del lote simulado frente a los datos reales.

# COMMAND ----------

bronze = spark.table(f"{BRONZE}.estadias").drop("archivo_origen", "fecha_carga")

def resumen_calidad(df, estrategia):
    return (df.groupBy("origen")
              .agg(F.count("*").alias("filas"),
                   F.round(F.avg(F.when(F.col("estado").isin("CANCELADA", "NO_SHOW"), 1).otherwise(0)), 4).alias("pct_no_llegada"),
                   F.round(F.sum("monto_pagado"), 0).alias("ingreso"))
              .withColumn("estrategia", F.lit(estrategia)))

comparacion = (resumen_calidad(bronze, "0. Sin limpiar")
    .unionByName(resumen_calidad(bronze.na.drop(), "A. na.drop() total"))
    .unionByName(resumen_calidad(limpiar(bronze), "B. Reglas de calidad"))
    .orderBy("origen", "estrategia"))
display(comparacion)

# COMMAND ----------

# MAGIC %md
# MAGIC **Análisis EXP-BD-04:** con datos reales ambas estrategias coinciden (no hay errores). En el lote simulado,
# MAGIC `na.drop()` pierde filas recuperables (monto o método de pago vacíos que solo debían corregirse) y **no** detecta
# MAGIC errores que no son nulos (estado en minúsculas, noches en 0, tarifa negativa, duplicados), por eso su % de
# MAGIC no-llegada e ingreso se alejan más de los valores reales.

# COMMAND ----------

# MAGIC %md
# MAGIC ## EXP-BD-05 · Spark SQL frente a API de DataFrames
# MAGIC - **Objetivo:** comprobar si escribir la consulta en SQL o con la API de DataFrames cambia el rendimiento.
# MAGIC - **Procedimiento:** la misma agregación (KPIs por año y mes) sobre el lote ×50, escrita de las dos formas.
# MAGIC - **Resultado esperado:** tiempos equivalentes, porque ambas pasan por el mismo optimizador (Catalyst).

# COMMAND ----------

tabla = f"{BRONZE}.exp_estadias_x50"
filas = spark.table(tabla).count()

consulta_sql = f"""
SELECT YEAR(check_in) AS `año`, MONTH(check_in) AS mes, COUNT(*) AS reservas,
       SUM(CASE WHEN estado = 'CANCELADA' THEN 1 ELSE 0 END) AS canceladas,
       SUM(CASE WHEN estado = 'NO_SHOW' THEN 1 ELSE 0 END) AS no_show,
       SUM(monto_pagado) AS ingreso
FROM {tabla}
GROUP BY YEAR(check_in), MONTH(check_in)
"""

medir("EXP-BD-05", "Spark SQL", lambda: spark.sql(consulta_sql).collect(), filas)
medir("EXP-BD-05", "API DataFrames", lambda: kpis(spark.table(tabla)).collect(), filas)
display(resumen("EXP-BD-05"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## EXP-BD-06 · Número de particiones (`repartition`)
# MAGIC - **Objetivo:** ver cómo influye en qué cantidad de partes se divide el DataFrame (paralelismo) en el tiempo de una agregación.
# MAGIC - **Procedimiento:** el lote ×100 se reparte en 1, 4, 16 y 64 particiones antes de calcular los KPIs.
# MAGIC - **Resultado esperado:** 1 partición es la más lenta (sin paralelismo); demasiadas particiones agregan costo de coordinación.

# COMMAND ----------

tabla = f"{BRONZE}.exp_estadias_x100"
filas = spark.table(tabla).count()

for n in [1, 4, 16, 64]:
    medir("EXP-BD-06", f"{n} particiones",
          lambda: kpis(spark.table(tabla).repartition(n)).collect(), filas)
display(resumen("EXP-BD-06"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Guardar todos los resultados (evidencia)

# COMMAND ----------

df_resultados = (spark.createDataFrame(resultados, "experimento STRING, escenario STRING, repeticion INT, segundos DOUBLE, filas LONG")
                 .withColumn("fecha_ejecucion", F.current_timestamp()))
df_resultados.write.mode("append").saveAsTable(f"{GOLD}.experimentos")

display(spark.table(f"{GOLD}.experimentos")
        .groupBy("experimento", "escenario", "filas")
        .agg(F.round(F.avg("segundos"), 3).alias("promedio_s"),
             F.round(F.stddev("segundos"), 3).alias("desv_estandar_s"),
             F.count("*").alias("mediciones"))
        .orderBy("experimento", "filas", "escenario"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Limpieza de tablas temporales (opcional)
# MAGIC Descomentar y ejecutar para liberar espacio. La tabla `tunki_gold.experimentos` se conserva.

# COMMAND ----------

# for factor in FACTORES:
#     spark.sql(f"DROP TABLE IF EXISTS {BRONZE}.exp_estadias_x{factor}")
# for t in [f"{SILVER}.exp_sin_particion", f"{SILVER}.exp_con_particion", f"{GOLD}.exp_kpis"]:
#     spark.sql(f"DROP TABLE IF EXISTS {t}")
# dbutils.fs.rm(f"{RUTA_SIMULADO}/exp_csv_x50", True)
