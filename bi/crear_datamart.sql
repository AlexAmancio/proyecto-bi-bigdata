-- =====================================================================
-- CREACIÓN DEL DATAMART hotel_dw - Tunki Lodge (SQL Server)
-- Modelo estrella: solo estructura (no carga datos). Ejecutar con F5.
--
--   5 dimensiones: tiempo, cliente, habitación, categoría, usuario
--   1 tabla de hechos: fact_estadia (4 medidas)
--   3 tablas de staging para los archivos planos
--   1 bitácora del ETL: etl_log (tiempo, CPU, lecturas y estado por paso)
--   1 registro de calidad: etl_calidad (reglas aplicadas a los datos)
--
-- Después de este script se ejecuta ETL_CARGA.sql
-- =====================================================================
SET NOCOUNT ON
GO
USE master
GO

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
    año          INT,
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
CREATE TABLE stg_estadia (            -- estadias.txt (sin PK: los duplicados se controlan en el ETL)
    id             INT,
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
    id             INT,
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

-- Bitácora del ETL: cada ejecución de ETL_CARGA.sql registra, por paso,
-- cuánto tardó y cuántos recursos del servidor consumió.
CREATE TABLE etl_log (
    id               INT PRIMARY KEY IDENTITY,
    ejecucion        INT,            -- número de ejecución del ETL (1, 2, 3...)
    paso             VARCHAR(60),
    inicio           DATETIME,
    fin              DATETIME,
    duracion_ms      INT,            -- tiempo total del paso
    cpu_ms           INT,            -- tiempo de CPU que usó el paso
    lecturas_logicas BIGINT,         -- páginas de 8 KB leídas en memoria
    filas            INT,            -- filas que quedaron cargadas
    cpu_inicio       INT,            -- valores al iniciar el paso (para la resta)
    lecturas_inicio  BIGINT,
    estado           VARCHAR(10),    -- OK / ERROR
    mensaje          VARCHAR(400)    -- detalle del error, si lo hubo
)
go

-- Calidad de datos: cada regla del ETL registra cuántos registros afectó y qué hizo con ellos
CREATE TABLE etl_calidad (
    id                  INT PRIMARY KEY IDENTITY,
    ejecucion           INT,
    regla               VARCHAR(10),
    descripcion         VARCHAR(150),
    tabla               VARCHAR(30),
    registros_afectados INT,
    accion              VARCHAR(60),
    fecha               DATETIME
)
go

