-- =====================================================================
-- ETL hacia el datamart hotel_dw (Tunki Lodge) - SQL Server
--
-- Fuentes:
--   1) Base OLTP alquiler (sistema Estadía): categoria, cliente, usuario
--      -> INSERT ... SELECT directo
--   2) estadias.txt     : extracto de las estadías     (sep. '|', con encabezado)
--   3) consumos.txt     : extracto de los consumos      (sep. '|', con encabezado)
--   4) habitaciones.txt : extracto de las habitaciones  (sep. ',', sin encabezado)
--   Los archivos planos se cargan con BULK INSERT a tablas de staging y
--   desde ahí pasan a las dimensiones y a la tabla de hechos.
--
-- Todo el proceso queda encapsulado en un procedimiento almacenado con
-- transacción y control de errores: se ejecuta con un solo EXEC.
-- =====================================================================
USE hotel_dw;
GO

CREATE OR ALTER PROCEDURE dbo.usp_etl_cargar_hotel_dw
    @ruta VARCHAR(200) = 'C:\txt\tunki\'   -- carpeta de los archivos planos
AS
BEGIN
    SET NOCOUNT ON;
    SET DATEFIRST 7;  -- 1 = domingo, para nombrar los días de la semana
    DECLARE @sql NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- -------------------------------------------------------------
        -- PASO 1: limpiar el datamart y las tablas de staging
        -- -------------------------------------------------------------
        DELETE FROM fact_estadia;
        DELETE FROM dim_tiempo;
        DELETE FROM dim_habitacion;
        DELETE FROM dim_categoria;
        DELETE FROM dim_cliente;
        DELETE FROM dim_usuario;
        TRUNCATE TABLE stg_estadia;
        TRUNCATE TABLE stg_consumo;
        TRUNCATE TABLE stg_habitacion;

        -- -------------------------------------------------------------
        -- PASO 2: archivos planos -> staging (BULK INSERT)
        -- -------------------------------------------------------------
        SET @sql = N'BULK INSERT hotel_dw.dbo.stg_estadia FROM ''' + @ruta + N'estadias.txt''
                     WITH (FIRSTROW = 2, FIELDTERMINATOR = ''|'', ROWTERMINATOR = ''\n'', CODEPAGE = ''65001'')';
        EXEC (@sql);

        SET @sql = N'BULK INSERT hotel_dw.dbo.stg_consumo FROM ''' + @ruta + N'consumos.txt''
                     WITH (FIRSTROW = 2, FIELDTERMINATOR = ''|'', ROWTERMINATOR = ''\n'', CODEPAGE = ''65001'')';
        EXEC (@sql);

        SET @sql = N'BULK INSERT hotel_dw.dbo.stg_habitacion FROM ''' + @ruta + N'habitaciones.txt''
                     WITH (FIRSTROW = 1, FIELDTERMINATOR = '','', ROWTERMINATOR = ''\n'')';
        EXEC (@sql);

        -- -------------------------------------------------------------
        -- PASO 3: dimensiones desde la base OLTP alquiler (INSERT ... SELECT)
        -- -------------------------------------------------------------
        INSERT INTO dim_categoria (id_categoria, nombre, precio_base)
        SELECT id, nombre, precio
        FROM alquiler.dbo.categoria;

        -- Limpieza: espacios y mayúscula inicial en la ciudad ("lima" -> "Lima")
        INSERT INTO dim_cliente (id_cliente, nombres, apellidos, pais, ciudad, ocupacion)
        SELECT id,
               LTRIM(RTRIM(nombres)),
               LTRIM(RTRIM(apellidos)),
               pais,
               UPPER(LEFT(LTRIM(RTRIM(ciudad)), 1)) + LOWER(SUBSTRING(LTRIM(RTRIM(ciudad)), 2, LEN(ciudad))),
               ocupacion
        FROM alquiler.dbo.cliente;

        INSERT INTO dim_usuario (id_usuario, nombres, apellidos, es_admin)
        SELECT id, LTRIM(RTRIM(nombres)), LTRIM(RTRIM(apellidos)), es_admin
        FROM alquiler.dbo.usuario;

        -- -------------------------------------------------------------
        -- PASO 4: dimensión habitación desde staging (habitaciones.txt)
        -- -------------------------------------------------------------
        INSERT INTO dim_habitacion (id_habitacion, numero, piso, aforo, id_categoria)
        SELECT id, LTRIM(RTRIM(numero)), piso, aforo, categoria_id
        FROM stg_habitacion;

        -- -------------------------------------------------------------
        -- PASO 5: dimensión tiempo, día por día entre el primer y el
        --         último check-in de estadias.txt
        -- -------------------------------------------------------------
        DECLARE @inicio DATE, @fin DATE;
        SELECT @inicio = MIN(CAST(check_in AS DATE)), @fin = MAX(CAST(check_in AS DATE))
        FROM stg_estadia;

        WHILE (@inicio <= @fin)
        BEGIN
            INSERT INTO dim_tiempo (id_tiempo, fecha, anio, mes, nombre_mes, dia, dia_semana, es_fin_semana, trimestre)
            SELECT CONVERT(INT, CONVERT(VARCHAR(8), @inicio, 112)),
                   @inicio,
                   DATEPART(yyyy, @inicio),
                   DATEPART(m, @inicio),
                   CASE DATEPART(m, @inicio)
                        WHEN 1 THEN 'Enero'     WHEN 2 THEN 'Febrero'  WHEN 3 THEN 'Marzo'
                        WHEN 4 THEN 'Abril'     WHEN 5 THEN 'Mayo'     WHEN 6 THEN 'Junio'
                        WHEN 7 THEN 'Julio'     WHEN 8 THEN 'Agosto'   WHEN 9 THEN 'Septiembre'
                        WHEN 10 THEN 'Octubre'  WHEN 11 THEN 'Noviembre' ELSE 'Diciembre' END,
                   DATEPART(d, @inicio),
                   CASE DATEPART(dw, @inicio)
                        WHEN 1 THEN 'Domingo'   WHEN 2 THEN 'Lunes'    WHEN 3 THEN 'Martes'
                        WHEN 4 THEN 'Miércoles' WHEN 5 THEN 'Jueves'   WHEN 6 THEN 'Viernes'
                        ELSE 'Sábado' END,
                   CASE WHEN DATEPART(dw, @inicio) IN (1, 7) THEN 1 ELSE 0 END,
                   DATEPART(q, @inicio);

            SET @inicio = DATEADD(d, 1, @inicio);
        END

        -- -------------------------------------------------------------
        -- PASO 6: tabla de hechos desde staging (estadias.txt + consumos.txt)
        -- -------------------------------------------------------------
        INSERT INTO fact_estadia (
            id_registro, id_cliente, id_habitacion, id_usuario, id_tiempo_checkin,
            noches, num_huespedes, tarifa, monto_pagado, total_consumos, saldo_pendiente,
            estado, es_no_show, es_cancelada, es_finalizada
        )
        SELECT
            e.id,
            e.cliente_id,
            e.habitacion_id,
            e.usuario_id,
            CONVERT(INT, CONVERT(VARCHAR(8), CAST(e.check_in AS DATE), 112)),
            e.noches,
            e.num_huespedes,
            e.tarifa,
            ISNULL(e.monto_pagado, 0),
            ISNULL(c.total_consumos, 0),
            e.tarifa + ISNULL(c.total_consumos, 0) - ISNULL(e.monto_pagado, 0),
            LTRIM(RTRIM(e.estado)),
            CASE WHEN LTRIM(RTRIM(e.estado)) = 'NO_SHOW'    THEN 1 ELSE 0 END,
            CASE WHEN LTRIM(RTRIM(e.estado)) = 'CANCELADA'  THEN 1 ELSE 0 END,
            CASE WHEN LTRIM(RTRIM(e.estado)) = 'FINALIZADA' THEN 1 ELSE 0 END
        FROM stg_estadia AS e
        LEFT JOIN (
            SELECT registro_id, SUM(monto) AS total_consumos
            FROM stg_consumo
            GROUP BY registro_id
        ) AS c ON c.registro_id = e.id;

        COMMIT TRANSACTION;
        PRINT 'ETL completado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT 'Error en el ETL: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

-- Ejecución del ETL (los .txt deben estar en la carpeta indicada)
EXEC dbo.usp_etl_cargar_hotel_dw @ruta = 'C:\txt\tunki\';
GO

-- Verificación: lo cargado debe coincidir con el sistema de origen
SELECT
    (SELECT COUNT(*) FROM alquiler.dbo.registro)        AS estadias_origen,
    (SELECT COUNT(*) FROM fact_estadia)                 AS estadias_destino,
    (SELECT SUM(monto) FROM alquiler.dbo.consumo)       AS consumos_origen,
    (SELECT SUM(total_consumos) FROM fact_estadia)      AS consumos_destino;
GO
