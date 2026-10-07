-- =====================================================================
-- DATAMART DE ESTADIAS - HOTEL TUNKI (SQL Server)
-- Cargado con los valores reales extraidos de la base operativa alquiler
-- =====================================================================
IF DB_ID('hotel_dw') IS NOT NULL
BEGIN
    ALTER DATABASE hotel_dw SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE hotel_dw;
END
CREATE DATABASE hotel_dw;
GO
USE hotel_dw;
GO

CREATE TABLE dim_tiempo (
    id_tiempo     INT PRIMARY KEY,
    fecha         DATE NOT NULL,
    anio          INT, mes INT, nombre_mes VARCHAR(20),
    dia           INT, dia_semana VARCHAR(15), es_fin_semana BIT, trimestre INT
);
CREATE TABLE dim_categoria (
    id_categoria  INT PRIMARY KEY,
    nombre        VARCHAR(50),
    precio_base   DECIMAL(10,2)
);
CREATE TABLE dim_habitacion (
    id_habitacion INT PRIMARY KEY,
    numero        VARCHAR(10),
    piso          INT,
    aforo         INT,
    id_categoria  INT REFERENCES dim_categoria(id_categoria)
);
CREATE TABLE dim_cliente (
    id_cliente    INT PRIMARY KEY,
    nombres       VARCHAR(255),
    apellidos     VARCHAR(255),
    pais          VARCHAR(255),
    ciudad        VARCHAR(255),
    ocupacion     VARCHAR(255)
);
CREATE TABLE dim_usuario (
    id_usuario    INT PRIMARY KEY,
    nombres       VARCHAR(255),
    apellidos     VARCHAR(255),
    es_admin      BIT
);
CREATE TABLE fact_estadia (
    id_registro         INT PRIMARY KEY,
    id_cliente          INT REFERENCES dim_cliente(id_cliente),
    id_habitacion       INT REFERENCES dim_habitacion(id_habitacion),
    id_usuario          INT REFERENCES dim_usuario(id_usuario),
    id_tiempo_checkin   INT REFERENCES dim_tiempo(id_tiempo),
    noches              INT,
    num_huespedes       INT,
    tarifa              DECIMAL(10,2),
    monto_pagado        DECIMAL(10,2),
    total_consumos      DECIMAL(10,2),
    saldo_pendiente     DECIMAL(10,2),
    estado              VARCHAR(20),
    es_no_show          BIT,
    es_cancelada        BIT,
    es_finalizada       BIT
);
GO
INSERT INTO dim_categoria VALUES (1, N'Habitación Estándar', 150);
INSERT INTO dim_categoria VALUES (2, N'Habitación Deluxe', 260);
INSERT INTO dim_categoria VALUES (3, N'Suite Junior', 380);
INSERT INTO dim_habitacion VALUES (1, N'101', 1, 2, 1);
INSERT INTO dim_habitacion VALUES (2, N'102', 1, 2, 1);
INSERT INTO dim_habitacion VALUES (3, N'201', 2, 2, 2);
INSERT INTO dim_habitacion VALUES (4, N'202', 2, 3, 2);
INSERT INTO dim_habitacion VALUES (5, N'301', 3, 4, 3);
INSERT INTO dim_cliente VALUES (1, N'Lucía', N'Fernández Rojas', N'Perú', N'Lima', N'Ingeniera');
INSERT INTO dim_cliente VALUES (3, N'ALEX', N'VALENCIA AMANCIO', N'Perú', N'lima', NULL);
INSERT INTO dim_usuario VALUES (1, N'Admin', N'Admin', 0);
INSERT INTO dim_usuario VALUES (2, N'alex ', N'valencia ', 0);
INSERT INTO dim_usuario VALUES (3, N'Staff', N'Recepcion Editado OK', 0);
INSERT INTO dim_usuario VALUES (4, N'Sonia', N'Tapia', 0);
INSERT INTO dim_usuario VALUES (7, N'Elon', N'Musk', 0);
INSERT INTO dim_usuario VALUES (8, N'Gerardo', NULL, 0);
INSERT INTO dim_tiempo VALUES (20260826, '2026-08-26', 2026, 8, N'August', 26, N'Wednesday', 0, 3);
INSERT INTO dim_tiempo VALUES (20260828, '2026-08-28', 2026, 8, N'August', 28, N'Friday', 0, 3);
INSERT INTO dim_tiempo VALUES (20260829, '2026-08-29', 2026, 8, N'August', 29, N'Saturday', 1, 3);
INSERT INTO dim_tiempo VALUES (20260827, '2026-08-27', 2026, 8, N'August', 27, N'Thursday', 0, 3);
INSERT INTO dim_tiempo VALUES (20261001, '2026-10-01', 2026, 10, N'October', 1, N'Thursday', 0, 4);
INSERT INTO dim_tiempo VALUES (20260904, '2026-09-04', 2026, 9, N'September', 4, N'Friday', 0, 3);
INSERT INTO dim_tiempo VALUES (20260920, '2026-09-20', 2026, 9, N'September', 20, N'Sunday', 1, 3);
INSERT INTO dim_tiempo VALUES (20261005, '2026-10-05', 2026, 10, N'October', 5, N'Monday', 0, 4);
INSERT INTO dim_tiempo VALUES (20260919, '2026-09-19', 2026, 9, N'September', 19, N'Saturday', 1, 3);
INSERT INTO fact_estadia VALUES (1, 1, 3, 1, 20260826, 3, 2, 750, 750, 0, 0, N'FINALIZADA', 0, 0, 1);
INSERT INTO fact_estadia VALUES (3, 1, 4, 1, 20260828, 3, 3, 750, 750, 0, 0, N'CANCELADA', 0, 1, 0);
INSERT INTO fact_estadia VALUES (5, 1, 2, 1, 20260829, 2, 2, 300, 200, 0, 100, N'FINALIZADA', 0, 0, 1);
INSERT INTO fact_estadia VALUES (6, 1, 1, 1, 20260827, 12, 1, 1800, 150, 35, 1685, N'FINALIZADA', 0, 0, 1);
INSERT INTO fact_estadia VALUES (7, 1, 3, 1, 20260827, 1, 1, 250, 0, 0, 250, N'NO_SHOW', 1, 0, 0);
INSERT INTO fact_estadia VALUES (8, 1, 2, 1, 20260827, 1, 2, 150, 0, 1170, 1320, N'FINALIZADA', 0, 0, 1);
INSERT INTO fact_estadia VALUES (9, 1, 1, 1, 20261001, 2, 1, 300, 0, 0, 300, N'ACTIVA', 0, 0, 0);
INSERT INTO fact_estadia VALUES (10, 1, 4, 1, 20261001, 2, 1, 500, 0, 0, 500, N'ACTIVA', 0, 0, 0);
INSERT INTO fact_estadia VALUES (11, 1, 2, 1, 20260827, 3, 1, 450, 0, 0, 450, N'ACTIVA', 0, 0, 0);
INSERT INTO fact_estadia VALUES (12, 1, 3, 1, 20260827, 3, 1, 750, 0, 0, 750, N'FINALIZADA', 0, 0, 1);
INSERT INTO fact_estadia VALUES (13, 1, 4, 1, 20260827, 3, 1, 750, 0, 0, 750, N'FINALIZADA', 0, 0, 1);
INSERT INTO fact_estadia VALUES (15, 1, 5, 1, 20260827, 1, 1, 380, 0, 0, 380, N'FINALIZADA', 0, 0, 1);
INSERT INTO fact_estadia VALUES (16, 1, 3, 1, 20260827, 2, 1, 500, 500, 0, 0, N'FINALIZADA', 0, 0, 1);
INSERT INTO fact_estadia VALUES (17, 1, 3, 1, 20260827, 2, 1, 500, 0, 800, 1300, N'ACTIVA', 0, 0, 0);
INSERT INTO fact_estadia VALUES (18, 1, 4, 1, 20260827, 2, 1, 500, 0, 0, 500, N'ACTIVA', 0, 0, 0);
INSERT INTO fact_estadia VALUES (19, 1, 4, 1, 20260904, 1, 1, 250, 150, 0, 100, N'FINALIZADA', 0, 0, 1);
INSERT INTO fact_estadia VALUES (20, 3, 3, 2, 20260829, 1, 2, 250, 250, 70, 70, N'ACTIVA', 0, 0, 0);
INSERT INTO fact_estadia VALUES (21, 1, 1, 2, 20260920, 3, 2, 450, 200, 0, 250, N'FINALIZADA', 0, 0, 1);
INSERT INTO fact_estadia VALUES (22, 1, 1, 7, 20261005, 3, 1, 450, 0, 0, 450, N'CANCELADA', 0, 1, 0);
INSERT INTO fact_estadia VALUES (23, 1, 2, 7, 20261005, 5, 1, 450, 0, 0, 450, N'ACTIVA', 0, 0, 0);
INSERT INTO fact_estadia VALUES (24, 1, 4, 7, 20260919, 1, 1, 260, 260, 0, 0, N'ACTIVA', 0, 0, 0);
GO

-- ---------------------------------------------------------------------
-- CONSULTAS OLAP
-- ---------------------------------------------------------------------

SELECT t.anio, t.mes, COUNT(*) AS estadias,
    SUM(CAST(f.es_no_show AS INT) + CAST(f.es_cancelada AS INT)) AS no_llegaron,
    ROUND(100.0 * SUM(CAST(f.es_no_show AS INT) + CAST(f.es_cancelada AS INT)) / COUNT(*), 1) AS pct_no_llega
FROM fact_estadia f JOIN dim_tiempo t ON f.id_tiempo_checkin = t.id_tiempo
GROUP BY t.anio, t.mes ORDER BY t.anio, t.mes;

SELECT cat.nombre AS categoria, COUNT(*) AS total_estadias,
    SUM(CAST(f.es_no_show AS INT)) AS no_shows, SUM(CAST(f.es_cancelada AS INT)) AS canceladas,
    ROUND(100.0 * SUM(CAST(f.es_no_show AS INT) + CAST(f.es_cancelada AS INT)) / COUNT(*), 1) AS pct_no_llega
FROM fact_estadia f
JOIN dim_habitacion h ON f.id_habitacion = h.id_habitacion
JOIN dim_categoria cat ON h.id_categoria = cat.id_categoria
GROUP BY cat.nombre ORDER BY pct_no_llega DESC;

SELECT t.dia_semana, COUNT(*) AS total_estadias,
    SUM(CAST(f.es_no_show AS INT)) AS no_shows, SUM(CAST(f.es_cancelada AS INT)) AS canceladas,
    ROUND(100.0 * SUM(CAST(f.es_no_show AS INT) + CAST(f.es_cancelada AS INT)) / COUNT(*), 1) AS pct_no_llega
FROM fact_estadia f JOIN dim_tiempo t ON f.id_tiempo_checkin = t.id_tiempo
GROUP BY t.dia_semana ORDER BY pct_no_llega DESC;

SELECT estado, COUNT(*) AS n,
    ROUND(SUM(tarifa), 2) AS ingresos_por_tarifa,
    ROUND(SUM(total_consumos), 2) AS ingresos_por_consumos,
    ROUND(SUM(saldo_pendiente), 2) AS saldo_pendiente_total
FROM fact_estadia GROUP BY estado;
GO
