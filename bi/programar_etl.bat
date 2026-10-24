@echo off
REM =====================================================================
REM Programa el ETL para que se ejecute solo, todos los dias a las 23:00,
REM con el Programador de tareas de Windows.
REM Para ejecutarlo en cualquier momento:  schtasks /run /tn "ETL hotel_dw"
REM Para quitar la programacion:           schtasks /delete /tn "ETL hotel_dw" /f
REM =====================================================================
schtasks /create /tn "ETL hotel_dw" /tr "\"%~dp0ejecutar_etl.bat\"" /sc daily /st 23:00 /f
