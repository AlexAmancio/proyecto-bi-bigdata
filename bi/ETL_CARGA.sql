-- =====================================================================
-- PROCESO ETL: carga del datamart hotel_dw - Tunki Lodge (SQL Server)
-- Ejecutar con F5 después de crear_datamart.sql. Se puede volver a
-- ejecutar: el paso 1 limpia las tablas antes de cargar.
--
-- Cada paso queda registrado en etl_log con su estado (OK/ERROR), duración,
-- CPU, lecturas y filas (se toma de sys.dm_exec_sessions, la vista de SQL Server con los
-- recursos consumidos por la sesión actual). Las cargas usan TRY/CATCH: si
-- un paso falla, queda como ERROR en etl_log con el mensaje (ERROR_MESSAGE).
-- El paso 6 aplica 10 reglas de calidad y las registra en etl_calidad.
--
-- Fuentes: base OLTP alquiler (creada con bd/respaldo_bd_actual.sql)
--          + estadias.txt, consumos.txt, habitaciones.txt (C:\txt\tunki\)
-- =====================================================================
SET NOCOUNT ON
GO
USE hotel_dw
go

-- ---------------------------------------------------------------------
-- PASO 1: Limpiamos tablas (hechos, dimensiones y staging)
-- ---------------------------------------------------------------------
-- [bitácora] inicio del paso: hora, CPU y lecturas acumuladas de esta sesión
INSERT INTO hotel_dw.dbo.etl_log (ejecucion, paso, inicio, cpu_inicio, lecturas_inicio)
SELECT (SELECT CASE WHEN MAX(ejecucion) IS NULL THEN 1 ELSE MAX(ejecucion) + 1 END FROM hotel_dw.dbo.etl_log),
       'PASO 1: Limpieza de tablas', GETDATE(), cpu_time, logical_reads
FROM sys.dm_exec_sessions
WHERE session_id = @@SPID
go
delete from fact_estadia
go
delete from dim_tiempo
go
delete from dim_habitacion
go
delete from dim_categoria
go
delete from dim_cliente
go
delete from dim_usuario
go
truncate table stg_estadia
go
truncate table stg_consumo
go
truncate table stg_habitacion
go

-- [bitácora] fin del paso: lo consumido = valor actual - valor al inicio
UPDATE L
SET fin              = GETDATE(),
    duracion_ms      = DATEDIFF(ms, L.inicio, GETDATE()),
    cpu_ms           = S.cpu_time - L.cpu_inicio,
    lecturas_logicas = S.logical_reads - L.lecturas_inicio,
    estado           = CASE WHEN L.estado IS NULL THEN 'OK' ELSE L.estado END,
    filas            = (SELECT COUNT(*) FROM hotel_dw.dbo.fact_estadia)
FROM hotel_dw.dbo.etl_log L
JOIN sys.dm_exec_sessions S ON S.session_id = @@SPID
WHERE L.id = (SELECT MAX(id) FROM hotel_dw.dbo.etl_log)
go


-- ---------------------------------------------------------------------
-- PASO 2: Cargamos las dimensiones desde la base operativa alquiler
-- ---------------------------------------------------------------------
-- [bitácora] inicio del paso: hora, CPU y lecturas acumuladas de esta sesión
INSERT INTO hotel_dw.dbo.etl_log (ejecucion, paso, inicio, cpu_inicio, lecturas_inicio)
SELECT (SELECT MAX(ejecucion) FROM hotel_dw.dbo.etl_log),
       'PASO 2: Dimensiones desde alquiler', GETDATE(), cpu_time, logical_reads
FROM sys.dm_exec_sessions
WHERE session_id = @@SPID
go
USE alquiler
go

-- Dimensión categoría
INSERT INTO hotel_dw.dbo.dim_categoria (id_categoria, nombre, precio_base)
SELECT id, nombre, precio
FROM dbo.categoria
go

-- Dimensión cliente (zona según la ciudad de origen)
INSERT INTO hotel_dw.dbo.dim_cliente (id_cliente, nombres, apellidos, pais, ciudad, zona, ocupacion)
SELECT id,
       nombres,
       apellidos,
       pais,
       ciudad,
       CASE WHEN pais <> 'Perú' THEN 'Extranjero'
            WHEN ciudad = 'Lima' THEN 'Lima'
            WHEN ciudad IN ('Huancayo', 'La Merced', 'Huánuco', 'Cerro de Pasco', 'Tarma', 'Oxapampa') THEN 'Cercana'
            ELSE 'Lejana'
       END AS zona,
       ocupacion
FROM dbo.cliente
go

-- Dimensión usuario
INSERT INTO hotel_dw.dbo.dim_usuario (id_usuario, nombres, apellidos, es_admin)
SELECT id, nombres, apellidos, es_admin
FROM dbo.usuario
go

-- [bitácora] fin del paso: lo consumido = valor actual - valor al inicio
UPDATE L
SET fin              = GETDATE(),
    duracion_ms      = DATEDIFF(ms, L.inicio, GETDATE()),
    cpu_ms           = S.cpu_time - L.cpu_inicio,
    lecturas_logicas = S.logical_reads - L.lecturas_inicio,
    estado           = CASE WHEN L.estado IS NULL THEN 'OK' ELSE L.estado END,
    filas            = (SELECT COUNT(*) FROM hotel_dw.dbo.dim_categoria) + (SELECT COUNT(*) FROM hotel_dw.dbo.dim_cliente) + (SELECT COUNT(*) FROM hotel_dw.dbo.dim_usuario)
FROM hotel_dw.dbo.etl_log L
JOIN sys.dm_exec_sessions S ON S.session_id = @@SPID
WHERE L.id = (SELECT MAX(id) FROM hotel_dw.dbo.etl_log)
go


-- ---------------------------------------------------------------------
-- PASO 3: Cargamos staging de estadías (estadias.txt)
-- ---------------------------------------------------------------------
-- [bitácora] inicio del paso: hora, CPU y lecturas acumuladas de esta sesión
INSERT INTO hotel_dw.dbo.etl_log (ejecucion, paso, inicio, cpu_inicio, lecturas_inicio)
SELECT (SELECT MAX(ejecucion) FROM hotel_dw.dbo.etl_log),
       'PASO 3: Staging estadias.txt', GETDATE(), cpu_time, logical_reads
FROM sys.dm_exec_sessions
WHERE session_id = @@SPID
go
USE hotel_dw
go

BEGIN TRY
    DECLARE @ARCHIVO VARCHAR(100), @sql VARCHAR(MAX)
    SET @ARCHIVO = 'C:\txt\tunki\estadias.txt'
    -- cargar datos a partir de un archivo plano (SQL dinámico: así TRY/CATCH
    -- captura también el error de archivo inexistente)
    SET @sql = 'BULK INSERT hotel_dw.dbo.stg_estadia FROM ''' + @ARCHIVO + ''' WITH (FIRSTROW = 2, FIELDTERMINATOR = ''|'', ROWTERMINATOR = ''\n'', CODEPAGE = ''65001'')'
    EXEC(@sql)
END TRY
BEGIN CATCH
    -- control de errores: el paso queda marcado como ERROR con su mensaje
    UPDATE hotel_dw.dbo.etl_log
    SET estado = 'ERROR', mensaje = LEFT(ERROR_MESSAGE(), 400)
    WHERE id = (SELECT MAX(id) FROM hotel_dw.dbo.etl_log)
    PRINT 'ERROR en el ETL: ' + ERROR_MESSAGE()
END CATCH
go

-- [bitácora] fin del paso: lo consumido = valor actual - valor al inicio
UPDATE L
SET fin              = GETDATE(),
    duracion_ms      = DATEDIFF(ms, L.inicio, GETDATE()),
    cpu_ms           = S.cpu_time - L.cpu_inicio,
    lecturas_logicas = S.logical_reads - L.lecturas_inicio,
    estado           = CASE WHEN L.estado IS NULL THEN 'OK' ELSE L.estado END,
    filas            = (SELECT COUNT(*) FROM hotel_dw.dbo.stg_estadia)
FROM hotel_dw.dbo.etl_log L
JOIN sys.dm_exec_sessions S ON S.session_id = @@SPID
WHERE L.id = (SELECT MAX(id) FROM hotel_dw.dbo.etl_log)
go


-- ---------------------------------------------------------------------
-- PASO 4: Cargamos staging de consumos (consumos.txt)
-- ---------------------------------------------------------------------
-- [bitácora] inicio del paso: hora, CPU y lecturas acumuladas de esta sesión
INSERT INTO hotel_dw.dbo.etl_log (ejecucion, paso, inicio, cpu_inicio, lecturas_inicio)
SELECT (SELECT MAX(ejecucion) FROM hotel_dw.dbo.etl_log),
       'PASO 4: Staging consumos.txt', GETDATE(), cpu_time, logical_reads
FROM sys.dm_exec_sessions
WHERE session_id = @@SPID
go
BEGIN TRY
    DECLARE @ARCHIVO VARCHAR(100), @sql VARCHAR(MAX)
    SET @ARCHIVO = 'C:\txt\tunki\consumos.txt'
    -- cargar datos a partir de un archivo plano (SQL dinámico: así TRY/CATCH
    -- captura también el error de archivo inexistente)
    SET @sql = 'BULK INSERT hotel_dw.dbo.stg_consumo FROM ''' + @ARCHIVO + ''' WITH (FIRSTROW = 2, FIELDTERMINATOR = ''|'', ROWTERMINATOR = ''\n'', CODEPAGE = ''65001'')'
    EXEC(@sql)
END TRY
BEGIN CATCH
    -- control de errores: el paso queda marcado como ERROR con su mensaje
    UPDATE hotel_dw.dbo.etl_log
    SET estado = 'ERROR', mensaje = LEFT(ERROR_MESSAGE(), 400)
    WHERE id = (SELECT MAX(id) FROM hotel_dw.dbo.etl_log)
    PRINT 'ERROR en el ETL: ' + ERROR_MESSAGE()
END CATCH
go

-- [bitácora] fin del paso: lo consumido = valor actual - valor al inicio
UPDATE L
SET fin              = GETDATE(),
    duracion_ms      = DATEDIFF(ms, L.inicio, GETDATE()),
    cpu_ms           = S.cpu_time - L.cpu_inicio,
    lecturas_logicas = S.logical_reads - L.lecturas_inicio,
    estado           = CASE WHEN L.estado IS NULL THEN 'OK' ELSE L.estado END,
    filas            = (SELECT COUNT(*) FROM hotel_dw.dbo.stg_consumo)
FROM hotel_dw.dbo.etl_log L
JOIN sys.dm_exec_sessions S ON S.session_id = @@SPID
WHERE L.id = (SELECT MAX(id) FROM hotel_dw.dbo.etl_log)
go


-- ---------------------------------------------------------------------
-- PASO 5: Cargamos DIM_HABITACION desde habitaciones.txt
-- ---------------------------------------------------------------------
-- [bitácora] inicio del paso: hora, CPU y lecturas acumuladas de esta sesión
INSERT INTO hotel_dw.dbo.etl_log (ejecucion, paso, inicio, cpu_inicio, lecturas_inicio)
SELECT (SELECT MAX(ejecucion) FROM hotel_dw.dbo.etl_log),
       'PASO 5: dim_habitacion (habitaciones.txt)', GETDATE(), cpu_time, logical_reads
FROM sys.dm_exec_sessions
WHERE session_id = @@SPID
go
BEGIN TRY
    DECLARE @ARCHIVO VARCHAR(100), @sql VARCHAR(MAX)
    SET @ARCHIVO = 'C:\txt\tunki\habitaciones.txt'
    -- cargar datos a partir de un archivo plano (SQL dinámico: así TRY/CATCH
    -- captura también el error de archivo inexistente)
    SET @sql = 'BULK INSERT hotel_dw.dbo.stg_habitacion FROM ''' + @ARCHIVO + ''' WITH (FIRSTROW = 1, FIELDTERMINATOR = '','', ROWTERMINATOR = ''\n'')'
    EXEC(@sql)
END TRY
BEGIN CATCH
    -- control de errores: el paso queda marcado como ERROR con su mensaje
    UPDATE hotel_dw.dbo.etl_log
    SET estado = 'ERROR', mensaje = LEFT(ERROR_MESSAGE(), 400)
    WHERE id = (SELECT MAX(id) FROM hotel_dw.dbo.etl_log)
    PRINT 'ERROR en el ETL: ' + ERROR_MESSAGE()
END CATCH
go

INSERT INTO dim_habitacion (id_habitacion, numero, piso, aforo)
SELECT id, numero, piso, aforo
FROM stg_habitacion
go

-- [bitácora] fin del paso: lo consumido = valor actual - valor al inicio
UPDATE L
SET fin              = GETDATE(),
    duracion_ms      = DATEDIFF(ms, L.inicio, GETDATE()),
    cpu_ms           = S.cpu_time - L.cpu_inicio,
    lecturas_logicas = S.logical_reads - L.lecturas_inicio,
    estado           = CASE WHEN L.estado IS NULL THEN 'OK' ELSE L.estado END,
    filas            = (SELECT COUNT(*) FROM hotel_dw.dbo.dim_habitacion)
FROM hotel_dw.dbo.etl_log L
JOIN sys.dm_exec_sessions S ON S.session_id = @@SPID
WHERE L.id = (SELECT MAX(id) FROM hotel_dw.dbo.etl_log)
go


-- ---------------------------------------------------------------------
-- PASO 6: Calidad de datos sobre el staging (antes de cargar los hechos)
--         Cada regla cuenta los registros afectados, los registra en
--         etl_calidad y los corrige o los descarta.
-- ---------------------------------------------------------------------
-- [bitácora] inicio del paso: hora, CPU y lecturas acumuladas de esta sesión
INSERT INTO hotel_dw.dbo.etl_log (ejecucion, paso, inicio, cpu_inicio, lecturas_inicio)
SELECT (SELECT MAX(ejecucion) FROM hotel_dw.dbo.etl_log),
       'PASO 6: Calidad de datos', GETDATE(), cpu_time, logical_reads
FROM sys.dm_exec_sessions
WHERE session_id = @@SPID
go

-- R01: filas repetidas exactamente: se conserva una sola copia
INSERT INTO etl_calidad (ejecucion, regla, descripcion, tabla, registros_afectados, accion, fecha)
SELECT (SELECT MAX(ejecucion) FROM etl_log), 'R01', 'Estadía duplicada (fila repetida)', 'stg_estadia',
       (SELECT COUNT(*) FROM stg_estadia) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM stg_estadia) T),
       'Duplicado eliminado', GETDATE()
go
SELECT DISTINCT * INTO #estadias_unicas FROM stg_estadia
TRUNCATE TABLE stg_estadia
INSERT INTO stg_estadia SELECT * FROM #estadias_unicas
DROP TABLE #estadias_unicas
go

-- R01B: mismo id con datos distintos: no se sabe cuál es el correcto, se descartan
INSERT INTO etl_calidad (ejecucion, regla, descripcion, tabla, registros_afectados, accion, fecha)
SELECT (SELECT MAX(ejecucion) FROM etl_log), 'R01B', 'Mismo id con datos distintos', 'stg_estadia', COUNT(*), 'Registro descartado', GETDATE()
FROM stg_estadia WHERE id IN (SELECT id FROM stg_estadia GROUP BY id HAVING COUNT(*) > 1)
DELETE FROM stg_estadia WHERE id IN (SELECT id FROM stg_estadia GROUP BY id HAVING COUNT(*) > 1)
go

-- R02: Estadía sin id o sin fecha de check-in
INSERT INTO etl_calidad (ejecucion, regla, descripcion, tabla, registros_afectados, accion, fecha)
SELECT (SELECT MAX(ejecucion) FROM etl_log), 'R02', 'Estadía sin id o sin fecha de check-in', 'stg_estadia', COUNT(*), 'Registro descartado', GETDATE()
FROM stg_estadia
WHERE id IS NULL OR check_in IS NULL
DELETE FROM stg_estadia
WHERE id IS NULL OR check_in IS NULL
go

-- R03: Estado no válido
INSERT INTO etl_calidad (ejecucion, regla, descripcion, tabla, registros_afectados, accion, fecha)
SELECT (SELECT MAX(ejecucion) FROM etl_log), 'R03', 'Estado no válido', 'stg_estadia', COUNT(*), 'Registro descartado', GETDATE()
FROM stg_estadia
WHERE estado IS NULL OR estado NOT IN ('ACTIVA', 'FINALIZADA', 'CANCELADA', 'NO_SHOW')
DELETE FROM stg_estadia
WHERE estado IS NULL OR estado NOT IN ('ACTIVA', 'FINALIZADA', 'CANCELADA', 'NO_SHOW')
go

-- R04: Noches o huéspedes en cero o negativos
INSERT INTO etl_calidad (ejecucion, regla, descripcion, tabla, registros_afectados, accion, fecha)
SELECT (SELECT MAX(ejecucion) FROM etl_log), 'R04', 'Noches o huéspedes en cero o negativos', 'stg_estadia', COUNT(*), 'Registro descartado', GETDATE()
FROM stg_estadia
WHERE noches IS NULL OR noches <= 0 OR num_huespedes IS NULL OR num_huespedes <= 0
DELETE FROM stg_estadia
WHERE noches IS NULL OR noches <= 0 OR num_huespedes IS NULL OR num_huespedes <= 0
go

-- R05: Tarifa nula o negativa
INSERT INTO etl_calidad (ejecucion, regla, descripcion, tabla, registros_afectados, accion, fecha)
SELECT (SELECT MAX(ejecucion) FROM etl_log), 'R05', 'Tarifa nula o negativa', 'stg_estadia', COUNT(*), 'Registro descartado', GETDATE()
FROM stg_estadia
WHERE tarifa IS NULL OR tarifa < 0
DELETE FROM stg_estadia
WHERE tarifa IS NULL OR tarifa < 0
go

-- R06: Monto pagado nulo
INSERT INTO etl_calidad (ejecucion, regla, descripcion, tabla, registros_afectados, accion, fecha)
SELECT (SELECT MAX(ejecucion) FROM etl_log), 'R06', 'Monto pagado nulo', 'stg_estadia', COUNT(*), 'Corregido a 0', GETDATE()
FROM stg_estadia
WHERE monto_pagado IS NULL
UPDATE stg_estadia SET monto_pagado = 0
WHERE monto_pagado IS NULL
go

-- R07: Método de pago vacío
INSERT INTO etl_calidad (ejecucion, regla, descripcion, tabla, registros_afectados, accion, fecha)
SELECT (SELECT MAX(ejecucion) FROM etl_log), 'R07', 'Método de pago vacío', 'stg_estadia', COUNT(*), 'Corregido a NO_REGISTRADO', GETDATE()
FROM stg_estadia
WHERE metodo_pago IS NULL OR metodo_pago = ''
UPDATE stg_estadia SET metodo_pago = 'NO_REGISTRADO'
WHERE metodo_pago IS NULL OR metodo_pago = ''
go

-- R08: Cliente, habitación o usuario inexistente
INSERT INTO etl_calidad (ejecucion, regla, descripcion, tabla, registros_afectados, accion, fecha)
SELECT (SELECT MAX(ejecucion) FROM etl_log), 'R08', 'Cliente, habitación o usuario inexistente', 'stg_estadia', COUNT(*), 'Registro descartado', GETDATE()
FROM stg_estadia
WHERE NOT EXISTS (SELECT * FROM dim_cliente D WHERE D.id_cliente = stg_estadia.cliente_id) OR NOT EXISTS (SELECT * FROM stg_habitacion H WHERE H.id = stg_estadia.habitacion_id) OR NOT EXISTS (SELECT * FROM dim_usuario U WHERE U.id_usuario = stg_estadia.usuario_id)
DELETE FROM stg_estadia
WHERE NOT EXISTS (SELECT * FROM dim_cliente D WHERE D.id_cliente = stg_estadia.cliente_id) OR NOT EXISTS (SELECT * FROM stg_habitacion H WHERE H.id = stg_estadia.habitacion_id) OR NOT EXISTS (SELECT * FROM dim_usuario U WHERE U.id_usuario = stg_estadia.usuario_id)
go

-- R09: Consumo sin estadía válida (huérfano)
INSERT INTO etl_calidad (ejecucion, regla, descripcion, tabla, registros_afectados, accion, fecha)
SELECT (SELECT MAX(ejecucion) FROM etl_log), 'R09', 'Consumo sin estadía válida (huérfano)', 'stg_consumo', COUNT(*), 'Registro descartado', GETDATE()
FROM stg_consumo
WHERE registro_id IS NULL OR NOT EXISTS (SELECT * FROM stg_estadia E WHERE E.id = stg_consumo.registro_id)
DELETE FROM stg_consumo
WHERE registro_id IS NULL OR NOT EXISTS (SELECT * FROM stg_estadia E WHERE E.id = stg_consumo.registro_id)
go

-- R10: Consumo con monto nulo o no positivo
INSERT INTO etl_calidad (ejecucion, regla, descripcion, tabla, registros_afectados, accion, fecha)
SELECT (SELECT MAX(ejecucion) FROM etl_log), 'R10', 'Consumo con monto nulo o no positivo', 'stg_consumo', COUNT(*), 'Registro descartado', GETDATE()
FROM stg_consumo
WHERE monto IS NULL OR monto <= 0
DELETE FROM stg_consumo
WHERE monto IS NULL OR monto <= 0
go

-- [bitácora] fin del paso: lo consumido = valor actual - valor al inicio
UPDATE L
SET fin              = GETDATE(),
    duracion_ms      = DATEDIFF(ms, L.inicio, GETDATE()),
    cpu_ms           = S.cpu_time - L.cpu_inicio,
    lecturas_logicas = S.logical_reads - L.lecturas_inicio,
    estado           = CASE WHEN L.estado IS NULL THEN 'OK' ELSE L.estado END,
    filas            = (SELECT SUM(registros_afectados) FROM hotel_dw.dbo.etl_calidad WHERE ejecucion = L.ejecucion)
FROM hotel_dw.dbo.etl_log L
JOIN sys.dm_exec_sessions S ON S.session_id = @@SPID
WHERE L.id = (SELECT MAX(id) FROM hotel_dw.dbo.etl_log)
go


-- ---------------------------------------------------------------------
-- PASO 7: Cargamos la dimensión tiempo (día por día, desde el primer
--         hasta el último check-in)
-- ---------------------------------------------------------------------
-- [bitácora] inicio del paso: hora, CPU y lecturas acumuladas de esta sesión
INSERT INTO hotel_dw.dbo.etl_log (ejecucion, paso, inicio, cpu_inicio, lecturas_inicio)
SELECT (SELECT MAX(ejecucion) FROM hotel_dw.dbo.etl_log),
       'PASO 7: dim_tiempo', GETDATE(), cpu_time, logical_reads
FROM sys.dm_exec_sessions
WHERE session_id = @@SPID
go
DECLARE @inicio DATE, @fin DATE
SELECT @inicio = MIN(CAST(check_in AS DATE)), @fin = MAX(CAST(check_in AS DATE))
FROM stg_estadia

WHILE (@inicio <= @fin)
BEGIN
    INSERT INTO dim_tiempo
        (id_tiempo, fecha, año, mes, nombre_mes, dia, dia_semana, es_fin_semana, trimestre)
    SELECT DATEPART(yyyy, @inicio) * 10000 + DATEPART(m, @inicio) * 100 + DATEPART(d, @inicio) id_tiempo,
           @inicio fecha,
           DATEPART(yyyy, @inicio) año,
           DATEPART(m, @inicio) mes,
           CASE DATEPART(m, @inicio)
                WHEN 1 THEN 'Enero'     WHEN 2 THEN 'Febrero'  WHEN 3 THEN 'Marzo'
                WHEN 4 THEN 'Abril'     WHEN 5 THEN 'Mayo'     WHEN 6 THEN 'Junio'
                WHEN 7 THEN 'Julio'     WHEN 8 THEN 'Agosto'   WHEN 9 THEN 'Septiembre'
                WHEN 10 THEN 'Octubre'  WHEN 11 THEN 'Noviembre' ELSE 'Diciembre'
           END AS nombre_mes,
           DATEPART(d, @inicio) dia,
           CASE DATEPART(dw, @inicio)
                WHEN 1 THEN 'Domingo'
                WHEN 2 THEN 'Lunes'
                WHEN 3 THEN 'Martes'
                WHEN 4 THEN 'Miércoles'
                WHEN 5 THEN 'Jueves'
                WHEN 6 THEN 'Viernes'
                WHEN 7 THEN 'Sábado'
           END AS dia_semana,
           CASE WHEN DATEPART(dw, @inicio) IN (1, 7) THEN 1 ELSE 0 END AS es_fin_semana,
           DATEPART(q, @inicio) AS trimestre

    SET @inicio = DATEADD(d, 1, @inicio)
END
go

-- [bitácora] fin del paso: lo consumido = valor actual - valor al inicio
UPDATE L
SET fin              = GETDATE(),
    duracion_ms      = DATEDIFF(ms, L.inicio, GETDATE()),
    cpu_ms           = S.cpu_time - L.cpu_inicio,
    lecturas_logicas = S.logical_reads - L.lecturas_inicio,
    estado           = CASE WHEN L.estado IS NULL THEN 'OK' ELSE L.estado END,
    filas            = (SELECT COUNT(*) FROM hotel_dw.dbo.dim_tiempo)
FROM hotel_dw.dbo.etl_log L
JOIN sys.dm_exec_sessions S ON S.session_id = @@SPID
WHERE L.id = (SELECT MAX(id) FROM hotel_dw.dbo.etl_log)
go


-- ---------------------------------------------------------------------
-- PASO 8: Cargamos la FACT_ESTADIA (tabla de hechos)
--         estadías (stg_estadia) + suma de consumos (stg_consumo)
--         + categoría de la habitación + cliente recurrente
-- ---------------------------------------------------------------------
-- [bitácora] inicio del paso: hora, CPU y lecturas acumuladas de esta sesión
INSERT INTO hotel_dw.dbo.etl_log (ejecucion, paso, inicio, cpu_inicio, lecturas_inicio)
SELECT (SELECT MAX(ejecucion) FROM hotel_dw.dbo.etl_log),
       'PASO 8: fact_estadia', GETDATE(), cpu_time, logical_reads
FROM sys.dm_exec_sessions
WHERE session_id = @@SPID
go
BEGIN TRY
    INSERT INTO fact_estadia (
        id_registro, id_tiempo_checkin, id_cliente, id_habitacion, id_categoria, id_usuario,
        noches, cantidad_estadias, monto_pagado, total_consumos,
        num_huespedes, tarifa, saldo_pendiente, estado, metodo_pago,
        es_cliente_recurrente, es_cancelada, es_no_show, es_finalizada
    )
    SELECT E.id,
           D_TI.id_tiempo,
           D_CL.id_cliente,
           D_HA.id_habitacion,
           H.categoria_id,
           D_US.id_usuario,
           E.noches,
           1                                                                  AS cantidad_estadias,
           E.monto_pagado,
           -- estadía sin consumos: 0
           CASE WHEN C.total_consumos IS NULL THEN 0 ELSE C.total_consumos END   AS total_consumos,
           E.num_huespedes,
           E.tarifa,
           E.tarifa
             + CASE WHEN C.total_consumos IS NULL THEN 0 ELSE C.total_consumos END
             - E.monto_pagado                                                    AS saldo_pendiente,
           E.estado,
           E.metodo_pago,
           -- recurrente: el cliente ya tenía una reserva anterior a esta
           CASE WHEN EXISTS (SELECT * FROM stg_estadia A
                             WHERE A.cliente_id = E.cliente_id
                               AND (A.check_in < E.check_in
                                    OR (A.check_in = E.check_in AND A.id < E.id)))
                THEN 1 ELSE 0 END                                                AS es_cliente_recurrente,
           CASE WHEN E.estado = 'CANCELADA'  THEN 1 ELSE 0 END,
           CASE WHEN E.estado = 'NO_SHOW'    THEN 1 ELSE 0 END,
           CASE WHEN E.estado = 'FINALIZADA' THEN 1 ELSE 0 END
    FROM stg_estadia E
    LEFT JOIN (SELECT registro_id, SUM(monto) AS total_consumos
               FROM stg_consumo
               GROUP BY registro_id) C ON C.registro_id = E.id
    JOIN stg_habitacion H      ON H.id             = E.habitacion_id
    JOIN dim_cliente    D_CL   ON D_CL.id_cliente    = E.cliente_id
    JOIN dim_habitacion D_HA   ON D_HA.id_habitacion = E.habitacion_id
    JOIN dim_usuario    D_US   ON D_US.id_usuario    = E.usuario_id
    JOIN dim_tiempo     D_TI   ON D_TI.fecha         = CAST(E.check_in AS DATE)
END TRY
BEGIN CATCH
    -- control de errores: el paso queda marcado como ERROR con su mensaje
    UPDATE hotel_dw.dbo.etl_log
    SET estado = 'ERROR', mensaje = LEFT(ERROR_MESSAGE(), 400)
    WHERE id = (SELECT MAX(id) FROM hotel_dw.dbo.etl_log)
    PRINT 'ERROR en el ETL: ' + ERROR_MESSAGE()
END CATCH
go

-- [bitácora] fin del paso: lo consumido = valor actual - valor al inicio
UPDATE L
SET fin              = GETDATE(),
    duracion_ms      = DATEDIFF(ms, L.inicio, GETDATE()),
    cpu_ms           = S.cpu_time - L.cpu_inicio,
    lecturas_logicas = S.logical_reads - L.lecturas_inicio,
    estado           = CASE WHEN L.estado IS NULL THEN 'OK' ELSE L.estado END,
    filas            = (SELECT COUNT(*) FROM hotel_dw.dbo.fact_estadia)
FROM hotel_dw.dbo.etl_log L
JOIN sys.dm_exec_sessions S ON S.session_id = @@SPID
WHERE L.id = (SELECT MAX(id) FROM hotel_dw.dbo.etl_log)
go


-- =====================================================================
-- VERIFICACIÓN
-- =====================================================================

-- Lo cargado debe coincidir con el sistema de origen
SELECT
    (SELECT COUNT(*) FROM alquiler.dbo.registro)                AS estadias_origen,
    (SELECT COUNT(*) FROM hotel_dw.dbo.fact_estadia)            AS estadias_destino,
    (SELECT SUM(monto) FROM alquiler.dbo.consumo)               AS consumos_origen,
    (SELECT SUM(total_consumos) FROM hotel_dw.dbo.fact_estadia) AS consumos_destino
go

-- Filas por tabla del modelo estrella
SELECT 'dim_tiempo' AS tabla, COUNT(*) AS filas FROM dim_tiempo
UNION ALL SELECT 'dim_cliente', COUNT(*) FROM dim_cliente
UNION ALL SELECT 'dim_habitacion', COUNT(*) FROM dim_habitacion
UNION ALL SELECT 'dim_categoria', COUNT(*) FROM dim_categoria
UNION ALL SELECT 'dim_usuario', COUNT(*) FROM dim_usuario
UNION ALL SELECT 'fact_estadia', COUNT(*) FROM fact_estadia
go

-- Indicadores por mes: caída de reservas y aumento de cancelaciones
SELECT T.año, T.mes, T.nombre_mes,
       SUM(F.cantidad_estadias)                                              AS reservas,
       SUM(F.noches)                                                         AS noches,
       SUM(F.monto_pagado)                                                   AS monto_pagado,
       SUM(F.total_consumos)                                                 AS total_consumos,
       CAST(100.0 * SUM(CAST(F.es_cancelada AS INT)) / SUM(F.cantidad_estadias) AS DECIMAL(5,1)) AS pct_cancelacion,
       CAST(100.0 * SUM(CAST(F.es_no_show AS INT))   / SUM(F.cantidad_estadias) AS DECIMAL(5,1)) AS pct_no_show
FROM fact_estadia F
JOIN dim_tiempo T ON T.id_tiempo = F.id_tiempo_checkin
GROUP BY T.año, T.mes, T.nombre_mes
ORDER BY T.año, T.mes
go


-- Consumo del ETL en esta ejecución (bitácora)
SELECT paso, estado, duracion_ms, cpu_ms, lecturas_logicas, filas, mensaje
FROM etl_log
WHERE ejecucion = (SELECT MAX(ejecucion) FROM etl_log)
ORDER BY id
go

SELECT ejecucion, SUM(duracion_ms) AS duracion_total_ms, SUM(cpu_ms) AS cpu_total_ms,
       SUM(lecturas_logicas) AS lecturas_totales
FROM etl_log
GROUP BY ejecucion
ORDER BY ejecucion
go

-- Reglas de calidad aplicadas en esta ejecución
SELECT regla, descripcion, tabla, registros_afectados, accion
FROM etl_calidad
WHERE ejecucion = (SELECT MAX(ejecucion) FROM etl_log)
ORDER BY regla
go
