@echo off
REM =====================================================================
REM Ejecuta el proceso ETL de hotel_dw sin abrir SSMS.
REM Lo usa la tarea programada de Windows (ver programar_etl.bat).
REM El resultado queda en logs\ultima_ejecucion.log y en la tabla etl_log.
REM =====================================================================
set CARPETA=%~dp0
if not exist "%CARPETA%logs" mkdir "%CARPETA%logs"
sqlcmd -S localhost -E -C -f 1252 -i "%CARPETA%ETL_CARGA.sql" -o "%CARPETA%logs\ultima_ejecucion.log"
echo ETL ejecutado. Revise logs\ultima_ejecucion.log o la tabla hotel_dw.dbo.etl_log
