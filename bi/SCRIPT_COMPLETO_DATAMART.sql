-- =====================================================================
-- SCRIPT COMPLETO: DATAMART hotel_dw - Tunki Lodge (SQL Server)
-- Crea el modelo estrella y ejecuta todo el proceso ETL de una sola vez (F5).
--
-- Requisito: la base alquiler ya creada con bd/respaldo_bd_actual.sql.
--
-- PARTE 1: Creación del entorno
--          5 dimensiones: tiempo, cliente, habitación, categoría, usuario
--          1 tabla de hechos: fact_estadia (4 medidas)
--          3 tablas de staging para los archivos planos
-- PARTE 2: Proceso ETL
--          Fuentes: base OLTP alquiler + estadias.txt, consumos.txt,
--          habitaciones.txt (ubicados en C:\txt\tunki\)
-- PARTE 3: Verificación e indicadores por mes
-- =====================================================================
SET NOCOUNT ON
GO
USE master
GO

-- =====================================================================
-- PARTE 1: CREACIÓN DEL ENTORNO
-- =====================================================================
if exists (select * from sysdatabases where name='hotel_dw')
BEGIN
    ALTER DATABASE hotel_dw SET SINGLE_USER WITH ROLLBACK IMMEDIATE
    DROP DATABASE hotel_dw
END
go

create database hotel_dw
go
USE hotel_dw
go
set dateformat ymd
go

-- Dimensión 1: tiempo (una fila por día, clave inteligente AAAAMMDD)
CREATE TABLE dim_tiempo (
    id_tiempo     INT NOT NULL,
    fecha         DATE NOT NULL,
    anio          INT,
    mes           INT,
    nombre_mes    VARCHAR(20),
    dia           INT,
    dia_semana    VARCHAR(15),
    es_fin_semana BIT,
    trimestre     INT,
    CONSTRAINT PK_dim_tiempo PRIMARY KEY (id_tiempo)
)
go

-- Dimensión 2: cliente (zona = origen respecto a Oxapampa)
CREATE TABLE dim_cliente (
    id_cliente INT NOT NULL,
    nombres    VARCHAR(255),
    apellidos  VARCHAR(255),
    pais       VARCHAR(255),
    ciudad     VARCHAR(255),
    zona       VARCHAR(20),     -- Cercana / Lima / Lejana / Extranjero
    ocupacion  VARCHAR(255),
    CONSTRAINT PK_dim_cliente PRIMARY KEY (id_cliente)
)
go

-- Dimensión 3: categoría de habitación
CREATE TABLE dim_categoria (
    id_categoria INT NOT NULL,
    nombre       VARCHAR(100),
    precio_base  DECIMAL(10,2),
    CONSTRAINT PK_dim_categoria PRIMARY KEY (id_categoria)
)
go

-- Dimensión 4: habitación
CREATE TABLE dim_habitacion (
    id_habitacion INT NOT NULL,
    numero        VARCHAR(10),
    piso          INT,
    aforo         INT,
    CONSTRAINT PK_dim_habitacion PRIMARY KEY (id_habitacion)
)
go

-- Dimensión 5: usuario (quién registró la estadía)
CREATE TABLE dim_usuario (
    id_usuario INT NOT NULL,
    nombres    VARCHAR(255),
    apellidos  VARCHAR(255),
    es_admin   BIT,
    CONSTRAINT PK_dim_usuario PRIMARY KEY (id_usuario)
)
go

-- Tablas de STAGING: reciben tal cual los archivos planos (BULK INSERT)
CREATE TABLE stg_estadia (            -- estadias.txt
    id             INT NOT NULL PRIMARY KEY,
    check_in       DATETIME2(0),
    estado         VARCHAR(20),
    cliente_id     INT,
    habitacion_id  INT,
    usuario_id     INT,
    noches         INT,
    num_huespedes  INT,
    tarifa         DECIMAL(10,2),
    monto_pagado   DECIMAL(10,2),
    metodo_pago    VARCHAR(20)
)
go
CREATE TABLE stg_consumo (            -- consumos.txt
    id             INT NOT NULL PRIMARY KEY,
    registro_id    INT,
    descripcion    VARCHAR(255),
    monto          DECIMAL(10,2),
    fecha          DATETIME2(0)
)
go
CREATE TABLE stg_habitacion (         -- habitaciones.txt
    id             INT,
    numero         VARCHAR(10),
    piso           INT,
    aforo          INT,
    categoria_id   INT
)
go

-- Tabla de hechos: grano = una estadía (un registro de check-in).
-- Las 5 dimensiones se conectan directamente aquí (estrella).
CREATE TABLE fact_estadia (
    id_registro           INT NOT NULL,
    id_tiempo_checkin     INT,
    id_cliente            INT,
    id_habitacion         INT,
    id_categoria          INT,
    id_usuario            INT,
    -- 4 medidas
    noches                INT,            -- medida 1: noches vendidas
    cantidad_estadias     INT,            -- medida 2: cantidad (1 por fila)
    monto_pagado          DECIMAL(10,2),  -- medida 3: dinero cobrado
    total_consumos        DECIMAL(10,2),  -- medida 4: consumos adicionales
    -- atributos de la estadía (para filtrar y calcular los indicadores)
    num_huespedes         INT,
    tarifa                DECIMAL(10,2),
    saldo_pendiente       DECIMAL(10,2),
    estado                VARCHAR(20),
    metodo_pago           VARCHAR(20),
    es_cliente_recurrente BIT,
    es_cancelada          BIT,
    es_no_show            BIT,
    es_finalizada         BIT,
    CONSTRAINT PK_fact_estadia PRIMARY KEY (id_registro),
    CONSTRAINT FK_fact_tiempo     FOREIGN KEY (id_tiempo_checkin) REFERENCES dim_tiempo (id_tiempo),
    CONSTRAINT FK_fact_cliente    FOREIGN KEY (id_cliente)        REFERENCES dim_cliente (id_cliente),
    CONSTRAINT FK_fact_habitacion FOREIGN KEY (id_habitacion)     REFERENCES dim_habitacion (id_habitacion),
    CONSTRAINT FK_fact_categoria  FOREIGN KEY (id_categoria)      REFERENCES dim_categoria (id_categoria),
    CONSTRAINT FK_fact_usuario    FOREIGN KEY (id_usuario)        REFERENCES dim_usuario (id_usuario)
)
go


-- =====================================================================
-- PARTE 2: PROCESO ETL (CARGA DE TODA LA INFORMACIÓN)
-- =====================================================================

-- ---------------------------------------------------------------------
-- PASO 1: Cargamos las dimensiones desde la base operativa alquiler
-- ---------------------------------------------------------------------
USE alquiler
go

-- Dimensión categoría
INSERT INTO hotel_dw.dbo.dim_categoria (id_categoria, nombre, precio_base)
SELECT id, LTRIM(RTRIM(nombre)), precio
FROM dbo.categoria
go

-- Dimensión cliente (limpieza de espacios y zona según la ciudad de origen)
INSERT INTO hotel_dw.dbo.dim_cliente (id_cliente, nombres, apellidos, pais, ciudad, zona, ocupacion)
SELECT id,
       LTRIM(RTRIM(nombres)),
       LTRIM(RTRIM(apellidos)),
       LTRIM(RTRIM(pais)),
       LTRIM(RTRIM(ciudad)),
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
SELECT id, LTRIM(RTRIM(nombres)), LTRIM(RTRIM(ISNULL(apellidos, ''))), es_admin
FROM dbo.usuario
go


-- ---------------------------------------------------------------------
-- PASO 2: Cargamos staging de estadías (estadias.txt)
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
-- PASO 3: Cargamos staging de consumos (consumos.txt)
-- ---------------------------------------------------------------------
BULK INSERT hotel_dw.dbo.stg_consumo
      FROM 'C:\txt\tunki\consumos.txt'
      WITH
      (FIRSTROW = 2,
      FIELDTERMINATOR = '|', ROWTERMINATOR = '\n',
      CODEPAGE = '65001')
go


-- ---------------------------------------------------------------------
-- PASO 4: Cargamos DIM_HABITACION desde habitaciones.txt
-- ---------------------------------------------------------------------
BULK INSERT hotel_dw.dbo.stg_habitacion
      FROM 'C:\txt\tunki\habitaciones.txt'
      WITH
      (FIRSTROW = 1,
      FIELDTERMINATOR = ',', ROWTERMINATOR = '\n')
go

INSERT INTO dim_habitacion (id_habitacion, numero, piso, aforo)
SELECT id, LTRIM(RTRIM(numero)), piso, aforo
FROM stg_habitacion
go


-- ---------------------------------------------------------------------
-- PASO 5: Cargamos la dimensión tiempo (calendario completo de los
--         años que cubren las estadías, día por día)
-- ---------------------------------------------------------------------
SET DATEFIRST 7   -- 1 = domingo
go

DECLARE @inicio DATE, @fin DATE
SELECT @inicio = DATEFROMPARTS(YEAR(MIN(check_in)), 1, 1),
       @fin    = DATEFROMPARTS(YEAR(MAX(check_in)), 12, 31)
FROM stg_estadia

WHILE (@inicio <= @fin)
BEGIN
    INSERT INTO dim_tiempo
        (id_tiempo, fecha, anio, mes, nombre_mes, dia, dia_semana, es_fin_semana, trimestre)
    SELECT CONVERT(INT, CONVERT(VARCHAR(8), @inicio, 112)) id_tiempo,
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
-- PASO 6: Cargamos la FACT_ESTADIA (tabla de hechos)
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
       ISNULL(E.monto_pagado, 0)                                          AS monto_pagado,
       ISNULL(C.total_consumos, 0)                                        AS total_consumos,
       E.num_huespedes,
       E.tarifa,
       E.tarifa + ISNULL(C.total_consumos, 0) - ISNULL(E.monto_pagado, 0) AS saldo_pendiente,
       LTRIM(RTRIM(E.estado)),
       LTRIM(RTRIM(E.metodo_pago)),
       -- recurrente: el cliente ya tenía una reserva anterior a esta
       CASE WHEN ROW_NUMBER() OVER (PARTITION BY E.cliente_id ORDER BY E.check_in, E.id) > 1
            THEN 1 ELSE 0 END                                             AS es_cliente_recurrente,
       CASE WHEN LTRIM(RTRIM(E.estado)) = 'CANCELADA'  THEN 1 ELSE 0 END,
       CASE WHEN LTRIM(RTRIM(E.estado)) = 'NO_SHOW'    THEN 1 ELSE 0 END,
       CASE WHEN LTRIM(RTRIM(E.estado)) = 'FINALIZADA' THEN 1 ELSE 0 END
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
-- PARTE 3: VERIFICACIÓN
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
