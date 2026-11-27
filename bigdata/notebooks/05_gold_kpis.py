# Databricks notebook source
# MAGIC %md
# MAGIC # 05 · Capa GOLD — Indicadores de negocio (KPIs)
# MAGIC
# MAGIC **Objetivo:** calcular, a partir de Silver, las tablas agregadas que responden al problema de negocio
# MAGIC (*¿qué factores explican la no-llegada de huéspedes y la caída de reservas?*). Estas tablas alimentan el
# MAGIC **dashboard de Databricks** y **Genie**.
# MAGIC
# MAGIC Los KPIs son los **mismos de la solución BI (Power BI)**, con la misma fórmula:
# MAGIC
# MAGIC | KPI | Fórmula (igual que la medida DAX) |
# MAGIC |---|---|
# MAGIC | Variación interanual de reservas | (reservas − reservas del mismo periodo del año anterior) / reservas año anterior |
# MAGIC | % Cancelación | canceladas / reservas |
# MAGIC | % No-show | no-show / reservas |
# MAGIC | Ingreso por estadía | ingreso / estadías finalizadas |
# MAGIC | % No-llegada (apoyo) | (canceladas + no-show) / reservas |
# MAGIC
# MAGIC Todas las tablas tienen la columna `origen` para separar los datos reales (`sistema`) del lote simulado.

# COMMAND ----------

# MAGIC %run ./00_configuracion

# COMMAND ----------

est = spark.table(f"{SILVER}.estadias")

def dividir(numerador, denominador, decimales=4):
    """División segura: devuelve nulo si el denominador es 0 o nulo (como DIVIDE en DAX)."""
    return F.round(F.when(denominador != 0, numerador / denominador), decimales)

def metricas(df, *grupo):
    """Agrega las métricas base y los KPIs para el nivel de detalle indicado."""
    return (df.groupBy(*grupo)
        .agg(F.count("*").alias("reservas"),
             F.sum("es_cancelada").alias("canceladas"),
             F.sum("es_no_show").alias("no_show"),
             F.sum("es_finalizada").alias("finalizadas"),
             F.sum("noches").alias("noches"),
             F.round(F.sum("monto_pagado"), 2).alias("ingreso"),
             F.round(F.sum("total_consumos"), 2).alias("consumos"))
        .withColumn("pct_cancelacion", dividir(F.col("canceladas"), F.col("reservas")))
        .withColumn("pct_no_show", dividir(F.col("no_show"), F.col("reservas")))
        .withColumn("pct_no_llegada", dividir(F.col("canceladas") + F.col("no_show"), F.col("reservas")))
        .withColumn("ingreso_por_estadia", dividir(F.col("ingreso"), F.col("finalizadas"), 2)))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. KPIs mensuales (con variación interanual del mismo mes)

# COMMAND ----------

mensual = metricas(est, "origen", "anio", "mes")

anterior = (mensual.select("origen", "anio", "mes",
                           F.col("reservas").alias("reservas_anio_anterior"),
                           F.col("ingreso").alias("ingreso_anio_anterior"))
                   .withColumn("anio", F.col("anio") + 1))   # el año anterior se "corre" un año para unirlo

kpi_mensual = (mensual.join(anterior, ["origen", "anio", "mes"], "left")
    .withColumn("var_interanual_reservas",
                dividir(F.col("reservas") - F.col("reservas_anio_anterior"), F.col("reservas_anio_anterior")))
    .withColumn("var_interanual_ingreso",
                dividir(F.col("ingreso") - F.col("ingreso_anio_anterior"), F.col("ingreso_anio_anterior")))
    .withColumn("periodo", F.to_date(F.concat_ws("-", F.col("anio").cast("string"),
                                                 F.lpad(F.col("mes").cast("string"), 2, "0"), F.lit("01"))))
    .orderBy("origen", "anio", "mes"))

kpi_mensual.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(f"{GOLD}.kpi_mensual")
display(kpi_mensual.filter("origen = 'sistema'"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. KPIs anuales comparables (mismo periodo del año: enero hasta el día de corte)
# MAGIC Igual que `SAMEPERIODLASTYEAR` en Power BI: 2026 tiene datos hasta octubre, así que se compara con enero–octubre de 2025.

# COMMAND ----------

corte = est.filter("origen = 'sistema'").agg(F.max("fecha")).first()[0]
print("Fecha de corte de los datos:", corte)

comparable = est.filter((F.month("fecha") < corte.month) |
                        ((F.month("fecha") == corte.month) & (F.dayofmonth("fecha") <= corte.day)))

anual = metricas(comparable, "origen", "anio")
anual_anterior = (anual.select("origen", "anio",
                               F.col("reservas").alias("reservas_anio_anterior"),
                               F.col("ingreso").alias("ingreso_anio_anterior"))
                       .withColumn("anio", F.col("anio") + 1))

kpi_anual = (anual.join(anual_anterior, ["origen", "anio"], "left")
    .withColumn("var_interanual_reservas",
                dividir(F.col("reservas") - F.col("reservas_anio_anterior"), F.col("reservas_anio_anterior")))
    .withColumn("var_interanual_ingreso",
                dividir(F.col("ingreso") - F.col("ingreso_anio_anterior"), F.col("ingreso_anio_anterior")))
    .withColumn("periodo_comparado", F.lit(f"01-ene al {corte.day:02d}-{corte.month:02d}"))
    .orderBy("origen", "anio"))

kpi_anual.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(f"{GOLD}.kpi_anual")
display(kpi_anual.filter("origen = 'sistema'"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. No-llegada por segmento (factores asociados)
# MAGIC Una sola tabla con todos los factores: cada fila es un segmento de una dimensión.
# MAGIC Facilita el dashboard (filtro por `dimension`) y las preguntas a Genie.

# COMMAND ----------

dimensiones = {
    "Zona de origen": "zona",
    "Método de pago": "metodo_pago",
    "Tamaño de grupo": "tamano_grupo",
    "Tipo de cliente": "tipo_cliente",
    "Categoría": "categoria",
    "Día de llegada": "dia_semana",
}

segmentos = None
for nombre, columna in dimensiones.items():
    parte = (metricas(est, "origen", "anio", columna)
             .withColumnRenamed(columna, "segmento")
             .withColumn("dimension", F.lit(nombre)))
    segmentos = parte if segmentos is None else segmentos.unionByName(parte)

no_llegada_segmento = segmentos.select(
    "origen", "dimension", "segmento", "anio", "reservas", "canceladas", "no_show",
    "pct_cancelacion", "pct_no_show", "pct_no_llegada", "ingreso", "ingreso_por_estadia")

no_llegada_segmento.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(f"{GOLD}.no_llegada_segmento")

# Vista de todos los años juntos, ordenada por mayor no-llegada
display(metricas(est.filter("origen = 'sistema'"), "zona").orderBy(F.desc("pct_no_llegada")))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Ingreso por categoría de habitación

# COMMAND ----------

ingreso_categoria = metricas(est, "origen", "anio", "categoria").orderBy("origen", "anio", F.desc("ingreso"))
ingreso_categoria.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(f"{GOLD}.ingreso_categoria")
display(ingreso_categoria.filter("origen = 'sistema'"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Validación cruzada con la solución BI
# MAGIC Si la limpieza y los cálculos son correctos, los datos reales (`origen = 'sistema'`) deben dar **exactamente**
# MAGIC los mismos totales que el datamart `hotel_dw` / Power BI.

# COMMAND ----------

esperado_bi = {   # valores de hotel_dw (fact_estadia) — solución BI
    "reservas": 9036, "canceladas": 559, "no_show": 303, "finalizadas": 8129,
    "noches": 24072, "ingreso": 5783274.00, "consumos": 200014.00,
}

real = metricas(est.filter("origen = 'sistema'")).first().asDict()
filas = [(k, float(v), float(real[k]), "OK" if abs(float(v) - float(real[k])) < 0.01 else "DIFERENTE")
         for k, v in esperado_bi.items()]
validacion = spark.createDataFrame(filas, "metrica STRING, power_bi DOUBLE, databricks DOUBLE, resultado STRING")
validacion.write.mode("overwrite").saveAsTable(f"{GOLD}.validacion_bi")
display(validacion)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 6. Tablas Gold creadas
# MAGIC
# MAGIC | Tabla | Uso |
# MAGIC |---|---|
# MAGIC | `tunki_gold.kpi_mensual` | Evolución mensual de reservas, ingresos y KPIs; variación interanual por mes |
# MAGIC | `tunki_gold.kpi_anual` | KPIs por año en el mismo periodo comparable |
# MAGIC | `tunki_gold.no_llegada_segmento` | Factores de no-llegada (zona, pago, grupo, tipo de cliente, categoría, día) |
# MAGIC | `tunki_gold.ingreso_categoria` | Ingresos por categoría de habitación |
# MAGIC | `tunki_gold.validacion_bi` | Comparación con Power BI |
# MAGIC
# MAGIC **Siguiente paso:** crear el dashboard (ver `bigdata/dashboard/consultas_dashboard.sql`) y ejecutar `06_experimentos`.
