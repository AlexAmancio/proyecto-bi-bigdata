-- =====================================================================
-- Dashboard "Tunki Lodge - No-llegada de huéspedes" (Databricks AI/BI)
-- Cada consulta es un "dataset" del dashboard; debajo se indica el gráfico sugerido.
-- Requiere haber ejecutado los notebooks 01 a 05.
-- =====================================================================

-- ---------------------------------------------------------------------
-- D1. Tarjetas de KPIs del último año (mismo periodo comparable)
--     Gráfico: 4 "Counter": reservas (con var_interanual_reservas),
--     pct_cancelacion, pct_no_show, ingreso_por_estadia
-- ---------------------------------------------------------------------
SELECT `año`, periodo_comparado, reservas, `reservas_año_anterior`, var_interanual_reservas,
       pct_cancelacion, pct_no_show, pct_no_llegada, ingreso, ingreso_por_estadia
FROM workspace.tunki_gold.kpi_anual
WHERE origen = 'sistema'
ORDER BY `año`;

-- ---------------------------------------------------------------------
-- D2. Evolución mensual de reservas por año
--     Gráfico: líneas. X = mes, Y = reservas, color = `año`
-- ---------------------------------------------------------------------
SELECT `año`, mes, periodo, reservas, ingreso, var_interanual_reservas
FROM workspace.tunki_gold.kpi_mensual
WHERE origen = 'sistema'
ORDER BY periodo;

-- ---------------------------------------------------------------------
-- D3. % de cancelación y no-show por mes
--     Gráfico: barras apiladas. X = periodo, Y = pct_cancelacion y pct_no_show
-- ---------------------------------------------------------------------
SELECT periodo, pct_cancelacion, pct_no_show, pct_no_llegada
FROM workspace.tunki_gold.kpi_mensual
WHERE origen = 'sistema'
ORDER BY periodo;

-- ---------------------------------------------------------------------
-- D4. Factores de no-llegada (todos los años)
--     Gráfico: barras horizontales. X = pct_no_llegada, Y = segmento.
--     Agregar un filtro del dashboard sobre "dimension".
-- ---------------------------------------------------------------------
SELECT dimension, segmento,
       SUM(reservas) AS reservas,
       SUM(canceladas + no_show) AS no_llegadas,
       ROUND(SUM(canceladas + no_show) / SUM(reservas), 4) AS pct_no_llegada
FROM workspace.tunki_gold.no_llegada_segmento
WHERE origen = 'sistema'
GROUP BY dimension, segmento
ORDER BY dimension, pct_no_llegada DESC;

-- ---------------------------------------------------------------------
-- D5. No-llegada por zona y año (¿el problema empeora en 2026?)
--     Gráfico: barras agrupadas. X = segmento (zona), Y = pct_no_llegada, color = `año`
-- ---------------------------------------------------------------------
SELECT `año`, segmento AS zona, reservas, pct_no_llegada
FROM workspace.tunki_gold.no_llegada_segmento
WHERE origen = 'sistema' AND dimension = 'Zona de origen'
ORDER BY `año`, zona;

-- ---------------------------------------------------------------------
-- D6. Ingreso por categoría de habitación
--     Gráfico: barras. X = categoria, Y = ingreso, color = `año`
-- ---------------------------------------------------------------------
SELECT `año`, categoria, reservas, ingreso, ingreso_por_estadia
FROM workspace.tunki_gold.ingreso_categoria
WHERE origen = 'sistema'
ORDER BY `año`, ingreso DESC;

-- ---------------------------------------------------------------------
-- D7. Calidad de datos (última ejecución de Silver)
--     Gráfico: tabla o barras. X = regla, Y = registros_afectados
-- ---------------------------------------------------------------------
SELECT regla, descripcion, tabla, registros_afectados, accion
FROM workspace.tunki_silver.calidad
WHERE fecha_ejecucion = (SELECT MAX(fecha_ejecucion) FROM workspace.tunki_silver.calidad)
ORDER BY regla;

-- ---------------------------------------------------------------------
-- D8. Resultados de experimentos
--     Gráfico: líneas para EXP-BD-01 (X = filas, Y = promedio_s, color = escenario);
--     barras para los demás. Solo la última ejecución del Job de experimentos.
-- ---------------------------------------------------------------------
SELECT experimento, escenario, filas,
       ROUND(AVG(segundos), 3) AS promedio_s,
       ROUND(STDDEV(segundos), 3) AS desv_estandar_s
FROM workspace.tunki_gold.experimentos
WHERE fecha_ejecucion = (SELECT MAX(fecha_ejecucion) FROM workspace.tunki_gold.experimentos)
GROUP BY experimento, escenario, filas
ORDER BY experimento, filas, escenario;

-- ---------------------------------------------------------------------
-- D9. Validación cruzada con Power BI
--     Gráfico: tabla
-- ---------------------------------------------------------------------
SELECT metrica, power_bi, databricks, resultado
FROM workspace.tunki_gold.validacion_bi;
