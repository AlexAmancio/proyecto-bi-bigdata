# Databricks notebook source
# MAGIC %md
# MAGIC # 00 · Configuración común — Solución Big Data Tunki Lodge
# MAGIC
# MAGIC Este notebook crea los **esquemas de la arquitectura Medallion** y el **Volume** donde se suben los archivos.
# MAGIC Los demás notebooks lo ejecutan al inicio con `%run ./00_configuracion`, así todos usan las mismas rutas y nombres.
# MAGIC
# MAGIC | Capa | Esquema | Contenido |
# MAGIC |---|---|---|
# MAGIC | Bronze | `workspace.tunki_bronze` | Datos crudos, tal como llegan del sistema Estadía (y el lote simulado) |
# MAGIC | Silver | `workspace.tunki_silver` | Datos limpios, validados y enriquecidos |
# MAGIC | Gold | `workspace.tunki_gold` | Indicadores (KPIs) listos para el dashboard y Genie |
# MAGIC
# MAGIC Plataforma: **Databricks Free Edition** (cómputo serverless, catálogo `workspace`).

# COMMAND ----------

CATALOGO = "workspace"
BRONZE = f"{CATALOGO}.tunki_bronze"
SILVER = f"{CATALOGO}.tunki_silver"
GOLD = f"{CATALOGO}.tunki_gold"

# Volume: carpeta dentro de Databricks donde se suben los archivos fuente
VOLUME = f"{BRONZE}.archivos"
RUTA_VOLUME = f"/Volumes/{CATALOGO}/tunki_bronze/archivos"
RUTA_SISTEMA = f"{RUTA_VOLUME}/sistema"     # archivos exportados del sistema Estadía
RUTA_SIMULADO = f"{RUTA_VOLUME}/simulado"   # archivos generados por 01_simulacion_datos

spark.sql(f"USE CATALOG {CATALOGO}")
for esquema in [BRONZE, SILVER, GOLD]:
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {esquema}")
spark.sql(f"CREATE VOLUME IF NOT EXISTS {VOLUME}")
dbutils.fs.mkdirs(RUTA_SISTEMA)
dbutils.fs.mkdirs(RUTA_SIMULADO)

# COMMAND ----------

# Esquemas de lectura (se declaran para no depender de inferSchema y detectar datos mal formados)
ESQUEMA_ESTADIAS = ("id INT, check_in TIMESTAMP, estado STRING, cliente_id INT, habitacion_id INT, "
                    "usuario_id INT, noches INT, num_huespedes INT, tarifa DOUBLE, monto_pagado DOUBLE, "
                    "metodo_pago STRING")
ESQUEMA_CONSUMOS = "id INT, registro_id INT, descripcion STRING, monto DOUBLE, fecha TIMESTAMP"
ESQUEMA_HABITACIONES = "id INT, numero STRING, piso INT, aforo INT, categoria_id INT"
ESQUEMA_CLIENTES = "id INT, pais STRING, ciudad STRING, ocupacion STRING"
ESQUEMA_CATEGORIAS = "id INT, nombre STRING, precio DOUBLE, precio_temporada_alta DOUBLE"
ESQUEMA_USUARIOS = "id INT, es_admin INT, activo INT"

# Ciudades a menos de un día de viaje de Oxapampa (misma regla que el ETL de la solución BI)
CIUDADES_CERCANAS = ["Huancayo", "La Merced", "Huánuco", "Cerro de Pasco", "Tarma", "Oxapampa"]
ESTADOS_VALIDOS = ["ACTIVA", "FINALIZADA", "CANCELADA", "NO_SHOW"]

from pyspark.sql import functions as F

def leer_txt(ruta, esquema, encabezado=True, separador="|"):
    """Lee un archivo de texto delimitado como DataFrame de Spark."""
    return (spark.read
            .option("header", encabezado)
            .option("sep", separador)
            .schema(esquema)
            .csv(ruta))

# COMMAND ----------

# MAGIC %md
# MAGIC ### Funciones de simulación (las usan `01_simulacion_datos` y `06_experimentos`)
# MAGIC
# MAGIC El sistema Estadía entrega datos limpios (las 11 reglas del ETL de BI encontraron 0 errores), así que,
# MAGIC para **probar la limpieza y la escalabilidad**, se genera un lote simulado:
# MAGIC
# MAGIC 1. **Volumen:** cada estadía real se copia `factor` veces con un id nuevo (`copia × 1 000 000 + id`).
# MAGIC    Se conservan fechas, clientes, habitaciones y montos, así que el lote mantiene la estacionalidad y los patrones del negocio.
# MAGIC 2. **Errores controlados:** a una fracción `tasa` de filas se le inyectan errores típicos de captura:
# MAGIC    estado en minúsculas o nulo, método de pago vacío, monto nulo, noches en 0, tarifa negativa,
# MAGIC    cliente inexistente, fecha nula, filas duplicadas y un mismo id con datos distintos.
# MAGIC
# MAGIC La elección de filas usa `hash(id)` en lugar de `rand()`: así **cada ejecución genera exactamente los mismos errores**
# MAGIC (reproducibilidad, necesaria para repetir los experimentos).

# COMMAND ----------

DESPLAZAMIENTO_ID = 1000000   # id simulado = copia * 1 000 000 + id original

def _azar(columna_id, k):
    """Número entre 0 y 1, siempre el mismo para el mismo id y la misma k (reproducible)."""
    return F.pmod(F.hash(F.col(columna_id), F.lit(k)), 10000) / 10000.0

def simular_estadias(estadias, factor, tasa):
    """Copia las estadías `factor` veces e inyecta errores en una fracción `tasa` de filas."""
    assert 1 <= factor <= 1000, "factor debe estar entre 1 y 1000"
    copias = spark.range(1, factor + 1).withColumnRenamed("id", "copia")
    sim = (estadias.crossJoin(copias)
           .withColumn("id", (F.col("copia") * DESPLAZAMIENTO_ID + F.col("id")).cast("int"))
           .drop("copia"))
    t = tasa
    sim = (sim
        # estado escrito en minúsculas con espacios, o vacío
        .withColumn("estado", F.when(_azar("id", 1) < t, F.concat(F.lower("estado"), F.lit("  ")))
                               .when(_azar("id", 1) < t * 1.3, F.lit(None).cast("string"))
                               .otherwise(F.col("estado")))
        # método de pago vacío o en minúsculas
        .withColumn("metodo_pago", F.when(_azar("id", 2) < t, F.lit(""))
                                    .when(_azar("id", 2) < t * 2, F.lower("metodo_pago"))
                                    .otherwise(F.col("metodo_pago")))
        # monto pagado nulo
        .withColumn("monto_pagado", F.when(_azar("id", 3) < t, F.lit(None).cast("double"))
                                     .otherwise(F.col("monto_pagado")))
        # noches en cero, tarifa negativa, cliente inexistente, fecha nula
        .withColumn("noches", F.when(_azar("id", 4) < t / 3, F.lit(0)).otherwise(F.col("noches")))
        .withColumn("tarifa", F.when(_azar("id", 5) < t / 3, -F.col("tarifa")).otherwise(F.col("tarifa")))
        .withColumn("cliente_id", F.when(_azar("id", 6) < t / 3, F.lit(999999)).otherwise(F.col("cliente_id")))
        .withColumn("check_in", F.when(_azar("id", 7) < t / 5, F.lit(None).cast("timestamp"))
                                 .otherwise(F.col("check_in"))))
    duplicados = sim.filter(_azar("id", 8) < t)                       # filas repetidas exactas
    conflictos = (sim.filter(_azar("id", 9) < t / 5)                  # mismo id, datos distintos
                  .withColumn("noches", F.col("noches") + 1))
    return sim.unionByName(duplicados).unionByName(conflictos)

def simular_consumos(consumos, factor, tasa):
    """Copia los consumos `factor` veces (apuntando a las estadías simuladas) e inyecta errores."""
    assert 1 <= factor <= 1000, "factor debe estar entre 1 y 1000"
    copias = spark.range(1, factor + 1).withColumnRenamed("id", "copia")
    sim = (consumos.crossJoin(copias)
           .withColumn("id", (F.col("copia") * DESPLAZAMIENTO_ID + F.col("id")).cast("int"))
           .withColumn("registro_id", (F.col("copia") * DESPLAZAMIENTO_ID + F.col("registro_id")).cast("int"))
           .drop("copia"))
    t = tasa
    return (sim
        .withColumn("registro_id", F.when(_azar("id", 11) < t / 3, F.lit(None).cast("int"))
                                    .otherwise(F.col("registro_id")))
        .withColumn("monto", F.when(_azar("id", 12) < t / 3, F.lit(0.0))
                              .when(_azar("id", 12) < t / 2, F.lit(None).cast("double"))
                              .otherwise(F.col("monto"))))

print("Configuración lista")
print("  Bronze :", BRONZE)
print("  Silver :", SILVER)
print("  Gold   :", GOLD)
print("  Subir los 6 archivos del sistema a:", RUTA_SISTEMA)
