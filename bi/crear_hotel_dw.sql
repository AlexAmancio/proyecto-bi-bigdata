-- =====================================================================
-- DATAMART hotel_dw - Tunki Lodge (SQL Server)
-- Esquema estrella: fact_estadia + 5 dimensiones + 3 tablas de staging.
-- Solo estructura (DDL). La carga la hace bi/etl_insert_select.sql.
-- =====================================================================
IF DB_ID('hotel_dw') IS NOT NULL
BEGIN
    ALTER DATABASE hotel_dw SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE hotel_dw;
END
GO
CREATE DATABASE hotel_dw;
GO
USE hotel_dw;
GO

-- Dimensión tiempo: una fila por fecha de check-in (clave inteligente AAAAMMDD)
CREATE TABLE dim_tiempo (
    id_tiempo     INT          NOT NULL,
    fecha         DATE         NOT NULL,
    anio          INT,
    mes           INT,
    nombre_mes    VARCHAR(20),
    dia           INT,
    dia_semana    VARCHAR(15),
    es_fin_semana BIT,
    trimestre     INT,
    CONSTRAINT PK_dim_tiempo PRIMARY KEY (id_tiempo)
);

-- Dimensión categoría de habitación
CREATE TABLE dim_categoria (
    id_categoria INT           NOT NULL,
    nombre       VARCHAR(50),
    precio_base  DECIMAL(10,2),
    CONSTRAINT PK_dim_categoria PRIMARY KEY (id_categoria)
);

-- Dimensión habitación (referencia a su categoría)
CREATE TABLE dim_habitacion (
    id_habitacion INT         NOT NULL,
    numero        VARCHAR(10),
    piso          INT,
    aforo         INT,
    id_categoria  INT,
    CONSTRAINT PK_dim_habitacion PRIMARY KEY (id_habitacion),
    CONSTRAINT FK_habitacion_categoria FOREIGN KEY (id_categoria)
        REFERENCES dim_categoria (id_categoria)
);

-- Dimensión cliente
CREATE TABLE dim_cliente (
    id_cliente INT          NOT NULL,
    nombres    VARCHAR(255),
    apellidos  VARCHAR(255),
    pais       VARCHAR(255),
    ciudad     VARCHAR(255),
    ocupacion  VARCHAR(255),
    CONSTRAINT PK_dim_cliente PRIMARY KEY (id_cliente)
);

-- Dimensión usuario (quién registró la estadía)
CREATE TABLE dim_usuario (
    id_usuario INT          NOT NULL,
    nombres    VARCHAR(255),
    apellidos  VARCHAR(255),
    es_admin   BIT,
    CONSTRAINT PK_dim_usuario PRIMARY KEY (id_usuario)
);

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
    monto_pagado   DECIMAL(10,2)
);
CREATE TABLE stg_consumo (            -- consumos.txt
    id             INT NOT NULL PRIMARY KEY,
    registro_id    INT,
    descripcion    VARCHAR(255),
    monto          DECIMAL(10,2),
    fecha          DATETIME2(0)
);
CREATE TABLE stg_habitacion (         -- habitaciones.txt
    id             INT,
    numero         VARCHAR(10),
    piso           INT,
    aforo          INT,
    categoria_id   INT
);

-- Tabla de hechos: grano = una estadía (un registro de check-in)
CREATE TABLE fact_estadia (
    id_registro       INT NOT NULL,
    id_cliente        INT,
    id_habitacion     INT,
    id_usuario        INT,
    id_tiempo_checkin INT,
    noches            INT,            -- medida: noches vendidas
    num_huespedes     INT,
    tarifa            DECIMAL(10,2),
    monto_pagado      DECIMAL(10,2),  -- medida: dinero cobrado
    total_consumos    DECIMAL(10,2),  -- medida: consumos adicionales
    saldo_pendiente   DECIMAL(10,2),
    estado            VARCHAR(20),
    es_no_show        BIT,
    es_cancelada      BIT,
    es_finalizada     BIT,
    CONSTRAINT PK_fact_estadia PRIMARY KEY (id_registro),
    CONSTRAINT FK_fact_cliente    FOREIGN KEY (id_cliente)        REFERENCES dim_cliente (id_cliente),
    CONSTRAINT FK_fact_habitacion FOREIGN KEY (id_habitacion)     REFERENCES dim_habitacion (id_habitacion),
    CONSTRAINT FK_fact_usuario    FOREIGN KEY (id_usuario)        REFERENCES dim_usuario (id_usuario),
    CONSTRAINT FK_fact_tiempo     FOREIGN KEY (id_tiempo_checkin) REFERENCES dim_tiempo (id_tiempo)
);
GO
