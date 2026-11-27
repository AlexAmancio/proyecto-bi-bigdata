# Databricks notebook source
# MAGIC %md
# MAGIC # 02 · Capa BRONZE — Ingesta de datos crudos
# MAGIC
# MAGIC **Objetivo:** cargar los archivos fuente en tablas Delta **sin modificar su contenido**. Bronze es la copia fiel de lo que llegó:
# MAGIC si algo sale mal en Silver o Gold, siempre se puede reprocesar desde aquí.
# MAGIC
# MAGIC Solo se agregan 3 columnas de control (linaje):
# MAGIC
# MAGIC | Columna | Para qué |
# MAGIC |---|---|
# MAGIC | `origen` | `sistema` (exportación real del sistema Estadía) o `simulado` (lote de `01_simulacion_datos`) |
# MAGIC | `archivo_origen` | Ruta del archivo del que vino cada fila |
# MAGIC | `fecha_carga` | Momento en que se cargó |
# MAGIC
# MAGIC **Fuentes** (subidas al Volume `/Volumes/workspace/tunki_bronze/archivos/`):
# MAGIC
# MAGIC | Archivo | Filas | Contenido |
# MAGIC |---|---|---|
# MAGIC | `sistema/estadias.txt` | 9 036 | Estadías (check-in, estado, noches, huéspedes, tarifa, pago) |
# MAGIC | `sistema/consumos.txt` | 7 096 | Consumos durante la estadía |
# MAGIC | `sistema/habitaciones.txt` | 45 | Habitaciones (sin encabezado, separado por comas) |
# MAGIC | `sistema/clientes.txt` | 6 594 | Clientes **sin datos personales** (solo país, ciudad y ocupación) |
# MAGIC | `sistema/categorias.txt` | 6 | Categorías de habitación y precios |
# MAGIC | `sistema/usuarios.txt` | 9 | Usuarios del sistema (solo id y rol) |
# MAGIC | `simulado/estadias/`, `simulado/consumos/` | según `factor` | Lote simulado (opcional) |

# COMMAND ----------

# MAGIC %run ./00_configuracion

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Verificar que los archivos están en el Volume

# COMMAND ----------

display(dbutils.fs.ls(RUTA_SISTEMA))

# COMMAND ----------

# Primeras líneas del archivo tal como llegó (equivale a %fs head, que en serverless no está permitido)
print(dbutils.fs.head(f"{RUTA_SISTEMA}/estadias.txt", 500))

# COMMAND ----------

def existe(ruta):
    try:
        dbutils.fs.ls(ruta)
        return True
    except Exception:
        return False

hay_simulado = existe(f"{RUTA_SIMULADO}/estadias")
print("¿Hay lote simulado?", hay_simulado)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Leer cada fuente como DataFrame y agregar columnas de control
# MAGIC `_metadata.file_path` es la columna que Databricks agrega con la ruta del archivo leído.

# COMMAND ----------

def con_control(df, origen):
    return (df.select("*", F.col("_metadata.file_path").alias("archivo_origen"))
              .withColumn("origen", F.lit(origen))
              .withColumn("fecha_carga", F.current_timestamp()))

estadias = con_control(leer_txt(f"{RUTA_SISTEMA}/estadias.txt", ESQUEMA_ESTADIAS), "sistema")
consumos = con_control(leer_txt(f"{RUTA_SISTEMA}/consumos.txt", ESQUEMA_CONSUMOS), "sistema")

if hay_simulado:
    estadias = estadias.unionByName(con_control(leer_txt(f"{RUTA_SIMULADO}/estadias", ESQUEMA_ESTADIAS), "simulado"))
    consumos = consumos.unionByName(con_control(leer_txt(f"{RUTA_SIMULADO}/consumos", ESQUEMA_CONSUMOS), "simulado"))

habitaciones = con_control(leer_txt(f"{RUTA_SISTEMA}/habitaciones.txt", ESQUEMA_HABITACIONES,
                                    encabezado=False, separador=","), "sistema")
clientes = con_control(leer_txt(f"{RUTA_SISTEMA}/clientes.txt", ESQUEMA_CLIENTES), "sistema")
categorias = con_control(leer_txt(f"{RUTA_SISTEMA}/categorias.txt", ESQUEMA_CATEGORIAS), "sistema")
usuarios = con_control(leer_txt(f"{RUTA_SISTEMA}/usuarios.txt", ESQUEMA_USUARIOS), "sistema")

estadias.printSchema()
display(estadias.limit(10))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Guardar como tablas Delta en el esquema Bronze
# MAGIC `mode("overwrite")` permite volver a ejecutar el notebook sin duplicar datos.

# COMMAND ----------

tablas_bronze = {
    "estadias": estadias,
    "consumos": consumos,
    "habitaciones": habitaciones,
    "clientes": clientes,
    "categorias": categorias,
    "usuarios": usuarios,
}

for nombre, df in tablas_bronze.items():
    (df.write.mode("overwrite")
       .option("overwriteSchema", "true")
       .saveAsTable(f"{BRONZE}.{nombre}"))
    print(f"{BRONZE}.{nombre}: {spark.table(f'{BRONZE}.{nombre}').count():,} filas")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Resumen de la carga por origen

# COMMAND ----------

display(spark.table(f"{BRONZE}.estadias").groupBy("origen").count())

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Delta guarda el historial de versiones de cada tabla (permite auditar y volver atrás)
# MAGIC DESCRIBE HISTORY workspace.tunki_bronze.estadias

# COMMAND ----------

# MAGIC %md
# MAGIC **Siguiente paso:** `03_eda` (análisis exploratorio sobre Bronze).
