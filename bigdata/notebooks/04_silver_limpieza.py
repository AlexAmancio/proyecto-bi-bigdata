# Databricks notebook source
# MAGIC %md
# MAGIC # 04 · Capa SILVER — Limpieza, validación y enriquecimiento
# MAGIC
# MAGIC **Objetivo:** convertir los datos crudos de Bronze en datos **de calidad**, listos para el análisis.
# MAGIC Se aplican las **mismas reglas de calidad del ETL de la solución BI** (R01–R10), ahora con DataFrames de Spark,
# MAGIC más una regla de normalización (N01). Cada regla **cuenta** los registros afectados, los **corrige o descarta**
# MAGIC y lo **registra** en la tabla `tunki_silver.calidad` (equivalente a `etl_calidad` del datamart).
# MAGIC
# MAGIC | Regla | Problema | Acción | Operación Spark |
# MAGIC |---|---|---|---|
# MAGIC | N01 | Estado / método de pago en minúsculas o con espacios | Normalizar | `withColumn` + `upper(trim())` |
# MAGIC | R01 | Fila repetida exacta | Conservar una | `dropDuplicates` |
# MAGIC | R01B | Mismo id con datos distintos | Descartar | `groupBy` + `join left_anti` |
# MAGIC | R02 | Sin id o sin fecha de check-in | Descartar | `na.drop(subset=...)` |
# MAGIC | R03 | Estado no válido | Descartar | `filter` + `isin` |
# MAGIC | R04 | Noches o huéspedes ≤ 0 | Descartar | `filter` |
# MAGIC | R05 | Tarifa nula o negativa | Descartar | `filter` |
# MAGIC | R06 | Monto pagado nulo | Corregir a 0 | `na.fill` |
# MAGIC | R07 | Método de pago vacío | Corregir a `NO_REGISTRADO` | `na.replace` + `na.fill` |
# MAGIC | R08 | Cliente, habitación o usuario inexistente | Descartar | `join left_semi` |
# MAGIC | R09 | Consumo sin estadía válida | Descartar | `join left_semi` |
# MAGIC | R10 | Consumo con monto nulo o ≤ 0 | Descartar | `filter` |

# COMMAND ----------

# MAGIC %run ./00_configuracion

# COMMAND ----------

from pyspark.sql.window import Window

calidad = []

def registrar(regla, descripcion, tabla, afectados, accion):
    calidad.append((regla, descripcion, tabla, int(afectados), accion))
    print(f"{regla:5} {descripcion:55} {afectados:>8,}  → {accion}")

est = spark.table(f"{BRONZE}.estadias")
total_bronze = est.count()
print(f"Estadías en Bronze: {total_bronze:,}\n")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Reglas sobre las estadías

# COMMAND ----------

# N01: normalizar texto (antes de validar, para no descartar datos recuperables)
n = est.filter((F.col("estado") != F.upper(F.trim(F.col("estado")))) |
               (F.col("metodo_pago") != F.upper(F.trim(F.col("metodo_pago"))))).count()
est = (est.withColumn("estado", F.upper(F.trim(F.col("estado"))))
          .withColumn("metodo_pago", F.upper(F.trim(F.col("metodo_pago")))))
registrar("N01", "Estado o método de pago con minúsculas/espacios", "estadias", n, "Normalizado")

# R01: filas repetidas exactas (sin contar las columnas de control)
columnas_negocio = [c for c in est.columns if c not in ("archivo_origen", "fecha_carga")]
antes = est.count()
est = est.dropDuplicates(columnas_negocio)
registrar("R01", "Estadía duplicada (fila repetida)", "estadias", antes - est.count(), "Duplicado eliminado")

# R01B: mismo id con datos distintos: no se sabe cuál es el correcto
ids_conflicto = est.groupBy("id").count().filter("count > 1").select("id")
n = est.join(ids_conflicto, "id", "left_semi").count()
est = est.join(ids_conflicto, "id", "left_anti")
registrar("R01B", "Mismo id con datos distintos", "estadias", n, "Registro descartado")

# R02: sin id o sin fecha de check-in
antes = est.count()
est = est.na.drop(subset=["id", "check_in"])
registrar("R02", "Estadía sin id o sin fecha de check-in", "estadias", antes - est.count(), "Registro descartado")

# R03: estado fuera del dominio (incluye nulos)
antes = est.count()
est = est.filter(F.col("estado").isin(ESTADOS_VALIDOS))
registrar("R03", "Estado no válido", "estadias", antes - est.count(), "Registro descartado")

# R04: noches o huéspedes en cero o negativos
antes = est.count()
est = est.filter((F.col("noches") > 0) & (F.col("num_huespedes") > 0))
registrar("R04", "Noches o huéspedes en cero o negativos", "estadias", antes - est.count(), "Registro descartado")

# R05: tarifa nula o negativa
antes = est.count()
est = est.filter(F.col("tarifa") >= 0)
registrar("R05", "Tarifa nula o negativa", "estadias", antes - est.count(), "Registro descartado")

# R06: monto pagado nulo → 0
n = est.filter(F.col("monto_pagado").isNull()).count()
est = est.na.fill(0.0, subset=["monto_pagado"])
registrar("R06", "Monto pagado nulo", "estadias", n, "Corregido a 0")

# R07: método de pago vacío → NO_REGISTRADO
n = est.filter(F.col("metodo_pago").isNull() | (F.col("metodo_pago") == "")).count()
est = (est.na.replace("", None, subset=["metodo_pago"])
          .na.fill("NO_REGISTRADO", subset=["metodo_pago"]))
registrar("R07", "Método de pago vacío", "estadias", n, "Corregido a NO_REGISTRADO")

# R08: integridad referencial (cliente, habitación y usuario deben existir)
ids_cliente = spark.table(f"{BRONZE}.clientes").select(F.col("id").alias("cliente_id")).distinct()
ids_habitacion = spark.table(f"{BRONZE}.habitaciones").select(F.col("id").alias("habitacion_id")).distinct()
ids_usuario = spark.table(f"{BRONZE}.usuarios").select(F.col("id").alias("usuario_id")).distinct()
antes = est.count()
est = (est.join(ids_cliente, "cliente_id", "left_semi")
          .join(ids_habitacion, "habitacion_id", "left_semi")
          .join(ids_usuario, "usuario_id", "left_semi"))
registrar("R08", "Cliente, habitación o usuario inexistente", "estadias", antes - est.count(), "Registro descartado")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Reglas sobre los consumos

# COMMAND ----------

con = spark.table(f"{BRONZE}.consumos")

# R09: consumo sin estadía válida (huérfano, incluye registro_id nulo)
ids_estadia = est.select(F.col("id").alias("registro_id"))
antes = con.count()
con = con.join(ids_estadia, "registro_id", "left_semi")
registrar("R09", "Consumo sin estadía válida (huérfano)", "consumos", antes - con.count(), "Registro descartado")

# R10: monto nulo o no positivo
antes = con.count()
con = con.filter(F.col("monto") > 0)
registrar("R10", "Consumo con monto nulo o no positivo", "consumos", antes - con.count(), "Registro descartado")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Dimensiones limpias y enriquecidas
# MAGIC - **Clientes:** se agrega la **zona de origen** respecto a Oxapampa (misma regla que el ETL de BI).
# MAGIC - **Habitaciones:** se unen con su **categoría** (nombre y precio).

# COMMAND ----------

clientes = (spark.table(f"{BRONZE}.clientes")
    .withColumnRenamed("id", "id_cliente")
    .withColumn("zona",
        F.when(F.col("pais") != "Perú", "Extranjero")
         .when(F.col("ciudad") == "Lima", "Lima")
         .when(F.col("ciudad").isin(CIUDADES_CERCANAS), "Cercana")
         .otherwise("Lejana"))
    .select("id_cliente", "pais", "ciudad", "zona", "ocupacion"))

categorias = (spark.table(f"{BRONZE}.categorias")
    .withColumnRenamed("id", "id_categoria")
    .withColumnRenamed("nombre", "categoria")
    .withColumnRenamed("precio", "precio_base")
    .select("id_categoria", "categoria", "precio_base"))

habitaciones = (spark.table(f"{BRONZE}.habitaciones")
    .withColumnRenamed("id", "id_habitacion")
    .withColumnRenamed("categoria_id", "id_categoria")
    .join(categorias, "id_categoria", "left")
    .select("id_habitacion", "numero", "piso", "aforo", "id_categoria", "categoria", "precio_base"))

display(clientes.groupBy("zona").count())

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Estadías enriquecidas
# MAGIC Se renombran columnas a nombres de negocio y se agregan columnas derivadas para el análisis:
# MAGIC fecha, año, mes, día de la semana, indicadores de estado (0/1), tamaño de grupo, tipo de cliente
# MAGIC (nuevo / recurrente) y total de consumos de la estadía.

# COMMAND ----------

total_consumos = con.groupBy("registro_id").agg(F.sum("monto").alias("total_consumos"))

nombre_dia = (F.when(F.dayofweek("fecha") == 1, "Domingo")
               .when(F.dayofweek("fecha") == 2, "Lunes")
               .when(F.dayofweek("fecha") == 3, "Martes")
               .when(F.dayofweek("fecha") == 4, "Miércoles")
               .when(F.dayofweek("fecha") == 5, "Jueves")
               .when(F.dayofweek("fecha") == 6, "Viernes")
               .otherwise("Sábado"))

# Cliente recurrente: ya tenía una reserva anterior (misma regla que el ETL de BI)
orden_cliente = Window.partitionBy("origen", "id_cliente").orderBy("fecha_checkin", "id_estadia")

estadias = (est
    .withColumnRenamed("id", "id_estadia")
    .withColumnRenamed("check_in", "fecha_checkin")
    .withColumnRenamed("cliente_id", "id_cliente")
    .withColumnRenamed("habitacion_id", "id_habitacion")
    .withColumnRenamed("usuario_id", "id_usuario")
    .withColumn("fecha", F.to_date("fecha_checkin"))
    .withColumn("año", F.year("fecha"))
    .withColumn("mes", F.month("fecha"))
    .withColumn("trimestre", F.quarter("fecha"))
    .withColumn("dia_semana", nombre_dia)
    .withColumn("es_cancelada", F.when(F.col("estado") == "CANCELADA", 1).otherwise(0))
    .withColumn("es_no_show", F.when(F.col("estado") == "NO_SHOW", 1).otherwise(0))
    .withColumn("es_finalizada", F.when(F.col("estado") == "FINALIZADA", 1).otherwise(0))
    .withColumn("es_no_llegada", F.col("es_cancelada") + F.col("es_no_show"))
    .withColumn("tamano_grupo", F.when(F.col("num_huespedes") >= 5, "5 o más huéspedes")
                                 .otherwise("1 a 4 huéspedes"))
    .withColumn("tipo_cliente", F.when(F.row_number().over(orden_cliente) > 1, "Recurrente")
                                 .otherwise("Nuevo"))
    .join(total_consumos.withColumnRenamed("registro_id", "id_estadia"), "id_estadia", "left")
    .na.fill(0.0, subset=["total_consumos"])
    .join(clientes.select("id_cliente", "zona", "pais", "ciudad"), "id_cliente", "left")
    .join(habitaciones.select("id_habitacion", "id_categoria", "categoria"), "id_habitacion", "left")
    .drop("archivo_origen", "fecha_carga"))

estadias.printSchema()
display(estadias.limit(10))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Guardar la capa Silver
# MAGIC La tabla de estadías se guarda **particionada por año** (`partitionBy("año")`): las consultas que filtran por año
# MAGIC leen solo los archivos de ese año (se evalúa en `06_experimentos`).

# COMMAND ----------

(estadias.write.mode("overwrite").option("overwriteSchema", "true")
    .partitionBy("año").saveAsTable(f"{SILVER}.estadias"))
con.drop("archivo_origen", "fecha_carga").write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(f"{SILVER}.consumos")
clientes.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(f"{SILVER}.clientes")
habitaciones.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(f"{SILVER}.habitaciones")

# Bitácora de calidad: se agrega una fila por regla en cada ejecución (historial)
df_calidad = (spark.createDataFrame(calidad, "regla STRING, descripcion STRING, tabla STRING, registros_afectados LONG, accion STRING")
              .withColumn("fecha_ejecucion", F.current_timestamp()))
df_calidad.write.mode("append").saveAsTable(f"{SILVER}.calidad")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 6. Resultado de la limpieza

# COMMAND ----------

total_silver = spark.table(f"{SILVER}.estadias").count()
print(f"Estadías Bronze : {total_bronze:,}")
print(f"Estadías Silver : {total_silver:,}")
print(f"Conservadas     : {total_silver / total_bronze:.1%}")
display(df_calidad)

# COMMAND ----------

display(spark.table(f"{SILVER}.estadias").groupBy("origen").count())

# COMMAND ----------

# MAGIC %md
# MAGIC **Siguiente paso:** `05_gold_kpis` (indicadores de negocio).
