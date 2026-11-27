# Databricks notebook source
# MAGIC %md
# MAGIC # 01 · Simulación de datos (lote ampliado con errores)
# MAGIC
# MAGIC **Objetivo:** generar, a partir de las estadías reales del sistema Estadía, un **lote simulado** que se suma a la fuente real en Bronze. Sirve para dos cosas:
# MAGIC
# MAGIC 1. **Probar la limpieza:** el sistema entrega datos sin errores, así que se inyectan errores típicos de captura para que la capa Silver tenga trabajo real.
# MAGIC 2. **Probar la escalabilidad:** el parámetro `factor` multiplica el volumen (×1, ×5, ×10, ×20…).
# MAGIC
# MAGIC **Parámetros (widgets arriba del notebook):**
# MAGIC - `factor`: cuántas copias de las 9 036 estadías se generan (1 = 9 036 filas simuladas).
# MAGIC - `tasa_errores`: fracción de filas con errores (0.03 = 3 %).
# MAGIC
# MAGIC **Requisito:** haber subido los archivos del sistema a `/Volumes/workspace/tunki_bronze/archivos/sistema/` (ver `00_configuracion`).
# MAGIC
# MAGIC > Los datos simulados se identifican siempre con `origen = 'simulado'`, para no mezclarlos con los reales al interpretar resultados.

# COMMAND ----------

# MAGIC %run ./00_configuracion

# COMMAND ----------

dbutils.widgets.text("factor", "1", "Factor de volumen")
dbutils.widgets.text("tasa_errores", "0.03", "Tasa de errores")
factor = int(dbutils.widgets.get("factor"))
tasa = float(dbutils.widgets.get("tasa_errores"))
print(f"factor = {factor}   tasa de errores = {tasa:.1%}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Leer las estadías y consumos reales

# COMMAND ----------

estadias = leer_txt(f"{RUTA_SISTEMA}/estadias.txt", ESQUEMA_ESTADIAS)
consumos = leer_txt(f"{RUTA_SISTEMA}/consumos.txt", ESQUEMA_CONSUMOS)
print("Estadías reales:", estadias.count())
print("Consumos reales:", consumos.count())
display(estadias.limit(5))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Generar el lote simulado
# MAGIC Las funciones `simular_estadias` y `simular_consumos` están en `00_configuracion` (allí se explica cada error inyectado).

# COMMAND ----------

estadias_sim = simular_estadias(estadias, factor, tasa)
consumos_sim = simular_consumos(consumos, factor, tasa)

print("Estadías simuladas:", estadias_sim.count())
print("Consumos simulados:", consumos_sim.count())

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Revisar los errores inyectados
# MAGIC Estos conteos son los que la capa Silver (`04_silver_limpieza`) debe detectar y corregir o descartar.

# COMMAND ----------

errores = estadias_sim.select(
    F.count(F.when(F.col("estado").isNull(), 1)).alias("estado_nulo"),
    F.count(F.when(F.col("estado") != F.upper(F.trim(F.col("estado"))), 1)).alias("estado_mal_escrito"),
    F.count(F.when(F.col("metodo_pago") == "", 1)).alias("metodo_pago_vacio"),
    F.count(F.when(F.col("monto_pagado").isNull(), 1)).alias("monto_nulo"),
    F.count(F.when(F.col("noches") <= 0, 1)).alias("noches_cero"),
    F.count(F.when(F.col("tarifa") < 0, 1)).alias("tarifa_negativa"),
    F.count(F.when(F.col("cliente_id") == 999999, 1)).alias("cliente_inexistente"),
    F.count(F.when(F.col("check_in").isNull(), 1)).alias("fecha_nula"),
)
display(errores)
print("Filas repetidas (total - distintas):", estadias_sim.count() - estadias_sim.distinct().count())

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Guardar el lote en el Volume (como archivos de texto, igual que llega una fuente real)
# MAGIC Spark escribe **varios archivos en paralelo** (uno por partición): es el procesamiento distribuido en acción.

# COMMAND ----------

def guardar_txt(df, ruta):
    (df.write.mode("overwrite")
       .option("header", True)
       .option("sep", "|")
       .option("timestampFormat", "yyyy-MM-dd HH:mm:ss")
       .option("ignoreLeadingWhiteSpace", False)    # conservar los espacios inyectados
       .option("ignoreTrailingWhiteSpace", False)
       .csv(ruta))

guardar_txt(estadias_sim, f"{RUTA_SIMULADO}/estadias")
guardar_txt(consumos_sim, f"{RUTA_SIMULADO}/consumos")

display(dbutils.fs.ls(f"{RUTA_SIMULADO}/estadias"))

# COMMAND ----------

# MAGIC %md
# MAGIC **Siguiente paso:** ejecutar `02_bronze_ingesta`, que carga la fuente real y el lote simulado en la capa Bronze.
