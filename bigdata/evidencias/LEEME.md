# Evidencias de la solución Big Data

Capturas de la ejecución del 27/11/2026 (despliegue del PR #24). Los números coinciden con el informe (secciones 3.5.5 y 6.3, Figuras 6 a 9).

| Archivo | Qué muestra | Evidencia del informe |
|---|---|---|
| [`01_github_actions_pipeline.png`](01_github_actions_pipeline.png) | Workflow **pipeline-databricks** disparado por el merge a `main`: los dos jobs en verde (validar → desplegar y ejecutar) | E-14 |
| [`02_github_actions_pasos.png`](02_github_actions_pasos.png) | Pasos del job de despliegue: CLI, conexión, esquema y Volume, subida de datos, `bundle deploy` y `bundle run` | E-14 |
| [`03_job_pipeline_medallion.png`](03_job_pipeline_medallion.png) | Job **Tunki Lodge - Pipeline Medallion** en Databricks: configuración → simulación → bronze → eda / silver → gold, todas las tareas con éxito (4 min) | E-08, E-14 |
| [`04_job_experimentos.png`](04_job_experimentos.png) | Job **Tunki Lodge - Experimentos Big Data** terminado con éxito (notebook 06 con sus resultados) | E-08 |
| [`05_dashboard_resumen.png`](05_dashboard_resumen.png) | Dashboard, página **Resumen**: filtro Año = 2026, tarjetas (2 179 reservas, −25.1 %, 10 % cancelación, 4.3 % no-show) y líneas por mes y año | E-08 (Figura 8) |
| [`06_dashboard_factores.png`](06_dashboard_factores.png) | Dashboard, página **Factores de no-llegada**: barras por año para cada segmento | E-08 (Figura 9) |
| [`07_dashboard_calidad_validacion.png`](07_dashboard_calidad_validacion.png) | Reglas de calidad de Silver con registros afectados y validación Gold frente a Power BI (7 métricas en **OK**) | E-08 |
| [`08_dashboard_experimentos.png`](08_dashboard_experimentos.png) | EXP-BD-01 (segundos según filas, ×1 a ×300) y tiempos promedio de EXP-BD-02 a 06 | E-08 |

**Notebooks ejecutados.** El código está en [`../notebooks/`](../notebooks/). Cada ejecución, con sus resultados, queda guardada en Databricks: *Jobs & Pipelines → (Job) → ejecución → tarea*. Desde ahí, **Export as HTML** descarga el notebook con los resultados, si se quiere agregar aquí.

**Dashboard publicado:** *Dashboards → Tunki Lodge - Reservas y no-llegada*.
