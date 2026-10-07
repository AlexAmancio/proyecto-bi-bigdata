# -*- coding: utf-8 -*-
"""
Extrae los datos reales de la base alquiler (fuente OLTP del sistema Estadia)
y genera un script T-SQL (SQL Server) que crea hotel_dw como esquema estrella
y lo carga con los valores reales extraidos, sin depender de un linked server
ni de un driver ODBC cruzado: los valores se materializan como INSERT VALUES.
"""
import subprocess
import csv
import io

def mysql_query(sql):
    out = subprocess.run(
        ["mysql", "-uroot", "alquiler", "-N", "-B", "-e", sql],
        capture_output=True, text=True, check=True,
    ).stdout
    reader = csv.reader(io.StringIO(out), delimiter="\t")
    return list(reader)


def sql_str(v):
    if v is None or v == "NULL" or v == "":
        return "NULL"
    return "N'" + str(v).replace("'", "''") + "'"


def sql_num(v):
    if v is None or v == "NULL" or v == "":
        return "NULL"
    return str(v)


categorias = mysql_query("SELECT id, nombre, precio FROM categoria")
habitaciones = mysql_query("SELECT id, numero, piso, aforo, categoria_id FROM habitacion")
clientes = mysql_query("SELECT id, nombres, apellidos, pais, ciudad, ocupacion FROM cliente")
usuarios = mysql_query("SELECT id, nombres, apellidos, es_admin FROM usuario")
tiempos = mysql_query("""
    SELECT DISTINCT
        CAST(DATE_FORMAT(check_in, '%Y%m%d') AS UNSIGNED) AS id_tiempo,
        DATE(check_in), YEAR(check_in), MONTH(check_in), MONTHNAME(check_in),
        DAY(check_in), DAYNAME(check_in),
        IF(DAYOFWEEK(check_in) IN (1,7), 1, 0), QUARTER(check_in)
    FROM registro WHERE check_in IS NOT NULL
""")
registros = mysql_query("""
    SELECT
        r.id, r.cliente_id, r.habitacion_id, r.usuario_id,
        CAST(DATE_FORMAT(r.check_in, '%Y%m%d') AS UNSIGNED),
        r.noches, r.num_huespedes, r.tarifa, IFNULL(r.monto_pagado, 0),
        IFNULL((SELECT SUM(c.monto) FROM consumo c WHERE c.registro_id = r.id), 0),
        (r.tarifa + IFNULL((SELECT SUM(c.monto) FROM consumo c WHERE c.registro_id = r.id), 0)) - IFNULL(r.monto_pagado, 0),
        r.estado,
        IF(r.estado = 'NO_SHOW', 1, 0), IF(r.estado = 'CANCELADA', 1, 0), IF(r.estado = 'FINALIZADA', 1, 0)
    FROM registro r
""")

out = []
out.append("-- =====================================================================")
out.append("-- DATAMART DE ESTADIAS - HOTEL TUNKI (SQL Server)")
out.append("-- Cargado con los valores reales extraidos de la base operativa alquiler")
out.append("-- =====================================================================")
out.append("IF DB_ID('hotel_dw') IS NOT NULL")
out.append("BEGIN")
out.append("    ALTER DATABASE hotel_dw SET SINGLE_USER WITH ROLLBACK IMMEDIATE;")
out.append("    DROP DATABASE hotel_dw;")
out.append("END")
out.append("CREATE DATABASE hotel_dw;")
out.append("GO")
out.append("USE hotel_dw;")
out.append("GO")
out.append("")
out.append("""CREATE TABLE dim_tiempo (
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
GO""")

for id_, nombre, precio in categorias:
    out.append(f"INSERT INTO dim_categoria VALUES ({id_}, {sql_str(nombre)}, {sql_num(precio)});")

for id_, numero, piso, aforo, cat_id in habitaciones:
    out.append(f"INSERT INTO dim_habitacion VALUES ({id_}, {sql_str(numero)}, {sql_num(piso)}, {sql_num(aforo)}, {sql_num(cat_id)});")

for id_, nombres, apellidos, pais, ciudad, ocupacion in clientes:
    out.append(f"INSERT INTO dim_cliente VALUES ({id_}, {sql_str(nombres)}, {sql_str(apellidos)}, {sql_str(pais)}, {sql_str(ciudad)}, {sql_str(ocupacion)});")

for id_, nombres, apellidos, es_admin in usuarios:
    bit = "1" if es_admin in ("1", 1, True, "b'1'") else "0"
    out.append(f"INSERT INTO dim_usuario VALUES ({id_}, {sql_str(nombres)}, {sql_str(apellidos)}, {bit});")

for id_tiempo, fecha, anio, mes, nombre_mes, dia, dia_semana, es_fs, trimestre in tiempos:
    out.append(
        f"INSERT INTO dim_tiempo VALUES ({id_tiempo}, '{fecha}', {anio}, {mes}, {sql_str(nombre_mes)}, "
        f"{dia}, {sql_str(dia_semana)}, {es_fs}, {trimestre});"
    )

for (rid, cid, hid, uid, tid, noches, huesp, tarifa, pagado, consumos, saldo,
     estado, no_show, cancelada, finalizada) in registros:
    out.append(
        f"INSERT INTO fact_estadia VALUES ({rid}, {sql_num(cid)}, {sql_num(hid)}, {sql_num(uid)}, {tid}, "
        f"{noches}, {huesp}, {tarifa}, {pagado}, {consumos}, {saldo}, {sql_str(estado)}, "
        f"{no_show}, {cancelada}, {finalizada});"
    )

out.append("GO")
out.append("")
out.append("-- ---------------------------------------------------------------------")
out.append("-- CONSULTAS OLAP")
out.append("-- ---------------------------------------------------------------------")
out.append("""
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
""")

with open("datamart_estadia_sqlserver.sql", "w", encoding="utf-8") as f:
    f.write("\n".join(out))

print(f"Generado datamart_estadia_sqlserver.sql con {len(registros)} registros, "
      f"{len(clientes)} clientes, {len(habitaciones)} habitaciones, {len(tiempos)} fechas.")
