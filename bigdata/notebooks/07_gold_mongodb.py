# Databricks notebook source
# MAGIC %md
# MAGIC # 07 · Respaldo de la capa GOLD en MongoDB
# MAGIC
# MAGIC **Objetivo:** guardar una copia de las tablas Gold en **MongoDB Atlas**, una base de datos NoSQL de documentos,
# MAGIC para que otras aplicaciones consulten los indicadores sin entrar a Databricks.
# MAGIC
# MAGIC | Databricks (Gold) | MongoDB |
# MAGIC |---|---|
# MAGIC | Esquema `workspace.tunki_gold` | Base de datos `tunki_lodge` |
# MAGIC | Tabla (por ejemplo `kpi_anual`) | Colección con el mismo nombre |
# MAGIC | Fila | Documento JSON |
# MAGIC | Columna | Campo (los nulos no se guardan) |
# MAGIC
# MAGIC **Cómo funciona:** cada tabla Gold se convierte en documentos JSON con `toJSON()`, se **borra** el contenido anterior
# MAGIC de la colección y se **insertan** los documentos nuevos (así no se duplican en cada ejecución). Al final se verifica
# MAGIC que cada colección tenga las mismas filas que su tabla.
# MAGIC
# MAGIC **Credenciales:** la cadena de conexión se lee del secreto de Databricks `tunki / mongodb_uri`, que crea el pipeline
# MAGIC de GitHub Actions a partir del secreto `MONGODB_URI` del repositorio. **Nunca se escribe en el notebook.**
# MAGIC Si el secreto no existe, el notebook avisa y termina sin error (el resto del pipeline no se ve afectado).

# COMMAND ----------

# MAGIC %pip install pymongo

# COMMAND ----------

dbutils.library.restartPython()

# COMMAND ----------

# MAGIC %run ./00_configuracion

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Leer la cadena de conexión (secreto)

# COMMAND ----------

ALCANCE_SECRETO = "tunki"
CLAVE_SECRETO = "mongodb_uri"
BASE_MONGO = "tunki_lodge"

try:
    uri_mongo = dbutils.secrets.get(ALCANCE_SECRETO, CLAVE_SECRETO)
except Exception:
    uri_mongo = None

if not uri_mongo:
    print("AVISO: no existe el secreto tunki/mongodb_uri. Se omite el respaldo en MongoDB.")
    print("Para activarlo: crear el secreto MONGODB_URI en GitHub y volver a ejecutar el pipeline.")
    dbutils.notebook.exit("SIN_MONGODB")

print("Secreto encontrado (el valor no se muestra)")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Conectarse a MongoDB Atlas

# COMMAND ----------

from pymongo import MongoClient
import json

cliente = MongoClient(uri_mongo, serverSelectionTimeoutMS=15000)
cliente.admin.command("ping")          # falla aquí si la red o las credenciales no son correctas
base = cliente[BASE_MONGO]
print(f"Conectado a MongoDB. Base de datos: {BASE_MONGO}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Copiar cada tabla Gold a su colección

# COMMAND ----------

tablas_gold = ["kpi_mensual", "kpi_anual", "no_llegada_segmento", "ingreso_categoria", "validacion_bi"]
if spark.catalog.tableExists(f"{GOLD}.experimentos"):
    tablas_gold.append("experimentos")      # existe solo si ya se ejecutó 06_experimentos

from datetime import datetime, timezone
fecha_respaldo = datetime.now(timezone.utc).isoformat(timespec="seconds")

resumen = []
for nombre in tablas_gold:
    df = spark.table(f"{GOLD}.{nombre}")
    # toJSON convierte cada fila en un documento JSON (fechas como texto, nulos omitidos)
    documentos = [json.loads(fila) for fila in df.toJSON().collect()]
    for doc in documentos:
        doc["fecha_respaldo"] = fecha_respaldo     # cuándo se copió (linaje)
    coleccion = base[nombre]
    coleccion.delete_many({})                 # reemplaza la versión anterior
    if documentos:
        coleccion.insert_many(documentos)
    filas_tabla = df.count()
    docs_mongo = coleccion.count_documents({})
    resumen.append((nombre, filas_tabla, docs_mongo, "OK" if filas_tabla == docs_mongo else "DIFERENTE"))
    print(f"{nombre:22} tabla: {filas_tabla:6,}   MongoDB: {docs_mongo:6,}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Verificación

# COMMAND ----------

df_resumen = spark.createDataFrame(resumen, "coleccion STRING, filas_gold LONG, documentos_mongodb LONG, resultado STRING")
display(df_resumen)

# Ejemplo de cómo quedó un documento
print(json.dumps(base["kpi_anual"].find_one({"origen": "sistema"}, {"_id": 0}), ensure_ascii=False, indent=2))

cliente.close()

diferentes = [r[0] for r in resumen if r[3] != "OK"]
assert not diferentes, f"Las colecciones no coinciden con Gold: {', '.join(diferentes)}"
print("Respaldo en MongoDB completo: todas las colecciones coinciden con Gold")
