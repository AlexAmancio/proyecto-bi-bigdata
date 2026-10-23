-- =====================================================================
-- PROCESO ETL: carga del datamart hotel_dw - Tunki Lodge (SQL Server)
-- Ejecutar con F5 después de crear_datamart.sql. Se puede volver a
-- ejecutar: el paso 1 limpia las tablas antes de cargar.
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


-- ---------------------------------------------------------------------
-- PASO 2: Cargamos las dimensiones desde la base operativa alquiler
-- ---------------------------------------------------------------------
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


-- ---------------------------------------------------------------------
-- PASO 3: Cargamos staging de estadías (estadias.txt)
-- ---------------------------------------------------------------------
USE hotel_dw
go

BULK INSERT hotel_dw.dbo.stg_estadia
      FROM 'C:\txt\tunki\estadias.txt'
      WITH
      (FIRSTROW = 2,
      FIELDTERMINATOR = '|', ROWTERMINATOR = '\n',
      CODEPAGE = '65001')
go


-- ---------------------------------------------------------------------
-- PASO 4: Cargamos staging de consumos (consumos.txt)
-- ---------------------------------------------------------------------
BULK INSERT hotel_dw.dbo.stg_consumo
      FROM 'C:\txt\tunki\consumos.txt'
      WITH
      (FIRSTROW = 2,
      FIELDTERMINATOR = '|', ROWTERMINATOR = '\n',
      CODEPAGE = '65001')
go


-- ---------------------------------------------------------------------
-- PASO 5: Cargamos DIM_HABITACION desde habitaciones.txt
-- ---------------------------------------------------------------------
BULK INSERT hotel_dw.dbo.stg_habitacion
      FROM 'C:\txt\tunki\habitaciones.txt'
      WITH
      (FIRSTROW = 1,
      FIELDTERMINATOR = ',', ROWTERMINATOR = '\n')
go

INSERT INTO dim_habitacion (id_habitacion, numero, piso, aforo)
SELECT id, numero, piso, aforo
FROM stg_habitacion
go


-- ---------------------------------------------------------------------
-- PASO 6: Cargamos la dimensión tiempo (día por día, desde el primer
--         hasta el último check-in)
-- ---------------------------------------------------------------------
DECLARE @inicio DATE, @fin DATE
SELECT @inicio = MIN(CAST(check_in AS DATE)), @fin = MAX(CAST(check_in AS DATE))
FROM stg_estadia

WHILE (@inicio <= @fin)
BEGIN
    INSERT INTO dim_tiempo
        (id_tiempo, fecha, anio, mes, nombre_mes, dia, dia_semana, es_fin_semana, trimestre)
    SELECT DATEPART(yyyy, @inicio) * 10000 + DATEPART(m, @inicio) * 100 + DATEPART(d, @inicio) id_tiempo,
           @inicio fecha,
           DATEPART(yyyy, @inicio) anio,
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


-- ---------------------------------------------------------------------
-- PASO 7: Cargamos la FACT_ESTADIA (tabla de hechos)
--         estadías (stg_estadia) + suma de consumos (stg_consumo)
--         + categoría de la habitación + cliente recurrente
-- ---------------------------------------------------------------------
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
SELECT T.anio, T.mes, T.nombre_mes,
       SUM(F.cantidad_estadias)                                              AS reservas,
       SUM(F.noches)                                                         AS noches,
       SUM(F.monto_pagado)                                                   AS monto_pagado,
       SUM(F.total_consumos)                                                 AS total_consumos,
       CAST(100.0 * SUM(CAST(F.es_cancelada AS INT)) / SUM(F.cantidad_estadias) AS DECIMAL(5,1)) AS pct_cancelacion,
       CAST(100.0 * SUM(CAST(F.es_no_show AS INT))   / SUM(F.cantidad_estadias) AS DECIMAL(5,1)) AS pct_no_show
FROM fact_estadia F
JOIN dim_tiempo T ON T.id_tiempo = F.id_tiempo_checkin
GROUP BY T.anio, T.mes, T.nombre_mes
ORDER BY T.anio, T.mes
go
