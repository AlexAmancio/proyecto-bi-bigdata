/* ============================================================================
   Base de datos alquiler (sistema Estadía) — script para SQL Server
   Convertido desde el respaldo MySQL de sistema-hotel.
   Crea las 13 tablas y carga 369 filas conservando los IDs originales.

   ATENCIÓN: borra y vuelve a crear las tablas de la base alquiler.
   Ejecutar completo en SSMS (F5) o con:
     sqlcmd -S localhost -U sa -C -i bd\respaldo_bd_actual.sql
   ============================================================================ */

-- Necesarias para el índice filtrado de comprobante (sqlcmd las trae en OFF).
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
USE master;
GO
IF DB_ID(N'alquiler') IS NULL
    CREATE DATABASE [alquiler];
GO
USE [alquiler];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ---------- 1. Borrar tablas existentes (hijas primero) ---------- */
DROP TABLE IF EXISTS [dbo].[usuarios_roles];
DROP TABLE IF EXISTS [dbo].[rol];
DROP TABLE IF EXISTS [dbo].[password_reset_token];
DROP TABLE IF EXISTS [dbo].[login_attempts];
DROP TABLE IF EXISTS [dbo].[consumo];
DROP TABLE IF EXISTS [dbo].[producto_consumo];
DROP TABLE IF EXISTS [dbo].[comprobante];
DROP TABLE IF EXISTS [dbo].[registro];
DROP TABLE IF EXISTS [dbo].[habitacion];
DROP TABLE IF EXISTS [dbo].[reserva];
DROP TABLE IF EXISTS [dbo].[usuario];
DROP TABLE IF EXISTS [dbo].[cliente];
DROP TABLE IF EXISTS [dbo].[categoria];
GO

/* ---------- 2. Crear tablas ---------- */
CREATE TABLE [dbo].[categoria] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [descripcion] NVARCHAR(255) NULL,
    [nombre] NVARCHAR(255) NULL,
    [precio] FLOAT NOT NULL,
    [slug] NVARCHAR(255) NULL,
    [url_imagen] NVARCHAR(255) NULL,
    [precio_temporada_alta] FLOAT NULL,
    [temporada_alta_fin] DATETIME2(6) NULL,
    [temporada_alta_inicio] DATETIME2(6) NULL,
    CONSTRAINT PK_categoria PRIMARY KEY ([id])
);

CREATE TABLE [dbo].[cliente] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [apellidos] NVARCHAR(255) NULL,
    [ciudad] NVARCHAR(255) NULL,
    [correo] NVARCHAR(255) NULL,
    [fecha_nacimiento] DATETIME2(6) NULL,
    [identificacion] NVARCHAR(255) NULL,
    [nombres] NVARCHAR(255) NULL,
    [ocupacion] NVARCHAR(255) NULL,
    [pais] NVARCHAR(255) NULL,
    [telefono] NVARCHAR(255) NULL,
    [tipo_documento] NVARCHAR(255) NULL,
    CONSTRAINT PK_cliente PRIMARY KEY ([id]),
    CONSTRAINT CK_cliente_tipo_documento CHECK ([tipo_documento] IN ('CARNE_EXTRANJERIA','DNI','PASAPORTE'))
);

CREATE TABLE [dbo].[comprobante] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [correlativo] INT NOT NULL,
    [datos_json] NVARCHAR(MAX) NULL,
    [fecha_emision] DATETIME2(6) NULL,
    [igv] FLOAT NULL,
    [serie] NVARCHAR(255) NULL,
    [total] FLOAT NULL,
    [valor_venta] FLOAT NULL,
    [registro_id] INT NULL,
    CONSTRAINT PK_comprobante PRIMARY KEY ([id])
);
CREATE UNIQUE INDEX [UK_9uhiw5nd5el3h0wko2d7qbxtu] ON [dbo].[comprobante] ([registro_id]) WHERE [registro_id] IS NOT NULL;

CREATE TABLE [dbo].[consumo] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [descripcion] NVARCHAR(255) NULL,
    [fecha] DATETIME2(6) NULL,
    [monto] FLOAT NOT NULL,
    [registro_id] INT NULL,
    [producto_consumo_id] INT NULL,
    CONSTRAINT PK_consumo PRIMARY KEY ([id])
);
CREATE INDEX [FKgp6py4ydstf8voa6if4b9r1ha] ON [dbo].[consumo] ([registro_id]);
CREATE INDEX [FKc0b9ttddssx7idxnrv2gek9vo] ON [dbo].[consumo] ([producto_consumo_id]);

CREATE TABLE [dbo].[habitacion] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [aforo] INT NOT NULL,
    [numero] NVARCHAR(255) NULL,
    [piso] INT NOT NULL,
    [url_imagen] NVARCHAR(255) NULL,
    [categoria_id] INT NULL,
    [estado] NVARCHAR(255) NULL,
    [version] BIGINT NULL,
    CONSTRAINT PK_habitacion PRIMARY KEY ([id]),
    CONSTRAINT CK_habitacion_estado CHECK ([estado] IN ('DISPONIBLE','LIMPIEZA','MANTENIMIENTO','OCUPADA'))
);
CREATE INDEX [FKmlrva0wqqhpr6xg0fkx7muy4u] ON [dbo].[habitacion] ([categoria_id]);

CREATE TABLE [dbo].[login_attempts] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [attempt_time] DATETIME2(6) NOT NULL,
    [ip_address] NVARCHAR(45) NOT NULL,
    [successful] BIT NOT NULL,
    [username] NVARCHAR(255) NULL,
    CONSTRAINT PK_login_attempts PRIMARY KEY ([id])
);

CREATE TABLE [dbo].[password_reset_token] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [fecha_expiracion] DATETIME2(6) NULL,
    [token] NVARCHAR(255) NULL,
    [usado] BIT NOT NULL,
    [usuario_id] INT NULL,
    CONSTRAINT PK_password_reset_token PRIMARY KEY ([id])
);
CREATE INDEX [FKaehv7qqwsde87cy79hxhy4lke] ON [dbo].[password_reset_token] ([usuario_id]);

CREATE TABLE [dbo].[producto_consumo] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [activo] BIT NOT NULL,
    [nombre] NVARCHAR(255) NULL,
    [precio_sugerido] FLOAT NOT NULL,
    CONSTRAINT PK_producto_consumo PRIMARY KEY ([id])
);

CREATE TABLE [dbo].[registro] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [check_in] DATETIME2(6) NULL,
    [noches] INT NOT NULL,
    [num_huespedes] INT NOT NULL,
    [observaciones] NVARCHAR(255) NULL,
    [tarifa] FLOAT NULL,
    [cliente_id] INT NULL,
    [habitacion_id] INT NULL,
    [usuario_id] INT NULL,
    [check_out_real] DATETIME2(6) NULL,
    [estado] NVARCHAR(255) NULL,
    [metodo_pago] NVARCHAR(255) NULL,
    [monto_pagado] FLOAT NULL,
    [version] BIGINT NULL,
    [reserva_id] INT NULL,
    CONSTRAINT PK_registro PRIMARY KEY ([id]),
    CONSTRAINT CK_registro_estado CHECK ([estado] IN ('ACTIVA','CANCELADA','FINALIZADA','NO_SHOW')),
    CONSTRAINT CK_registro_metodo_pago CHECK ([metodo_pago] IN ('EFECTIVO','TARJETA','TRANSFERENCIA'))
);
CREATE INDEX [FKhhvhc05dls8gcil8hfr4yvw18] ON [dbo].[registro] ([cliente_id]);
CREATE INDEX [FK8jlgra1srn0uxvlxba7swgtlw] ON [dbo].[registro] ([habitacion_id]);
CREATE INDEX [FKqfbdwuu2isbwwnx1uky39930w] ON [dbo].[registro] ([usuario_id]);
CREATE INDEX [FK101aahenl319n647ge5763uyc] ON [dbo].[registro] ([reserva_id]);

CREATE TABLE [dbo].[reserva] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [fecha_creacion] DATETIME2(6) NULL,
    [cliente_id] INT NULL,
    [usuario_id] INT NULL,
    CONSTRAINT PK_reserva PRIMARY KEY ([id])
);
CREATE INDEX [FK7cg2jiyn5cf6f6elccvb6963k] ON [dbo].[reserva] ([cliente_id]);
CREATE INDEX [FKiad9w96t12u3ms2ul93l97mel] ON [dbo].[reserva] ([usuario_id]);

CREATE TABLE [dbo].[rol] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [name] NVARCHAR(255) NULL,
    CONSTRAINT PK_rol PRIMARY KEY ([id]),
    CONSTRAINT CK_rol_name CHECK ([name] IN ('ADMIN','INVITED','USER'))
);

CREATE TABLE [dbo].[usuario] (
    [id] INT IDENTITY(1,1) NOT NULL,
    [apellidos] NVARCHAR(255) NULL,
    [contrasena] NVARCHAR(255) NULL,
    [correo] NVARCHAR(255) NULL,
    [es_admin] BIT NOT NULL,
    [logout_time] DATETIME2(6) NULL,
    [nombres] NVARCHAR(255) NULL,
    [username] NVARCHAR(255) NULL,
    [activo] BIT NOT NULL,
    CONSTRAINT PK_usuario PRIMARY KEY ([id])
);

CREATE TABLE [dbo].[usuarios_roles] (
    [usuario_id] INT NOT NULL,
    [rol_id] INT NOT NULL,
    CONSTRAINT PK_usuarios_roles PRIMARY KEY ([usuario_id], [rol_id])
);
CREATE INDEX [FK6yxg1lhuv5nievqea7rvn6afm] ON [dbo].[usuarios_roles] ([rol_id]);

GO

/* ---------- 3. Cargar datos ---------- */
BEGIN TRANSACTION;

-- categoria (6 filas)
SET IDENTITY_INSERT [dbo].[categoria] ON;
INSERT INTO [dbo].[categoria] ([id], [descripcion], [nombre], [precio], [slug], [url_imagen], [precio_temporada_alta], [temporada_alta_fin], [temporada_alta_inicio]) VALUES (1, N'Cama queen, baño propio, agua caliente 24h, TV cable, wifi y parlante Alexa. Vista a la piscina y áreas verdes.', N'Habitación Matrimonial', 180, N'habitacion-matrimonial', N'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', NULL, NULL, NULL);
INSERT INTO [dbo].[categoria] ([id], [descripcion], [nombre], [precio], [slug], [url_imagen], [precio_temporada_alta], [temporada_alta_fin], [temporada_alta_inicio]) VALUES (2, N'Acabados en madera de la zona, baño privado, agua caliente 24h, wifi y parlante Alexa. Vista panorámica a la Plaza de Armas de Oxapampa.', N'Habitación Familiar (3 personas)', 220, N'habitacion-familiar-3-personas', N'https://www.tunkilodge.com/imagenes/habitacionfamiliar3personas.png', NULL, NULL, NULL);
INSERT INTO [dbo].[categoria] ([id], [descripcion], [nombre], [precio], [slug], [url_imagen], [precio_temporada_alta], [temporada_alta_fin], [temporada_alta_inicio]) VALUES (3, N'Bungalow 100% en madera, 1 cama matrimonial y 2 de plaza y media, baño propio, agua caliente 24h.', N'Habitación Familiar (4 personas)', 260, N'habitacion-familiar-4-personas', N'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', NULL, NULL, NULL);
INSERT INTO [dbo].[categoria] ([id], [descripcion], [nombre], [precio], [slug], [url_imagen], [precio_temporada_alta], [temporada_alta_fin], [temporada_alta_inicio]) VALUES (4, N'1 cama matrimonial y 4 camas individuales, baño propio, agua caliente, wifi y TV cable. Vista a la plaza y la campiña oxapampina.', N'Habitación 5-6 Personas', 320, N'habitacion-5-6-personas', N'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', NULL, NULL, NULL);
INSERT INTO [dbo].[categoria] ([id], [descripcion], [nombre], [precio], [slug], [url_imagen], [precio_temporada_alta], [temporada_alta_fin], [temporada_alta_inicio]) VALUES (5, N'1 cama matrimonial y 2 camarotes, baño con ducha española, agua caliente 24h, smart TV y wifi en amplias áreas verdes.', N'Domo Colibrí', 350, N'domo-colibri', N'https://www.tunkilodge.com/imagenes/domo.jpeg', NULL, NULL, NULL);
INSERT INTO [dbo].[categoria] ([id], [descripcion], [nombre], [precio], [slug], [url_imagen], [precio_temporada_alta], [temporada_alta_fin], [temporada_alta_inicio]) VALUES (6, N'Cabaña histórica de colonos austro-alemanes con más de 90 años, 4 habitaciones y 2 baños completos. Acceso a piscina y áreas de juegos.', N'Cabaña Bungalow (8-10 personas)', 450, N'cabana-bungalow-8-10-personas', N'/carrusel-login/foto-4.jpg', 550, N'2027-01-15 00:00:00.000000', N'2026-12-15 00:00:00.000000');
SET IDENTITY_INSERT [dbo].[categoria] OFF;

-- cliente (162 filas)
SET IDENTITY_INSERT [dbo].[cliente] ON;
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (1, N'Salazar Vega', N'Lima', N'andrea.salazar@gmail.com', N'1992-03-11 00:00:00.000000', N'41234567', N'Andrea', N'Diseñadora UX', N'Perú', N'945112233', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (2, N'Castillo Paredes', N'Arequipa', N'renzo.castillo@gmail.com', N'1988-07-22 00:00:00.000000', N'42345678', N'Renzo', N'Contador', N'Perú', N'956223344', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (3, N'Guzmán Torres', N'Lima', N'fiorella.guzman@gmail.com', N'1995-01-30 00:00:00.000000', N'43456789', N'Fiorella', N'Abogada', N'Perú', N'967334455', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (4, N'Chávez Ríos', N'Huánuco', N'esteban.chavez@gmail.com', N'1985-09-14 00:00:00.000000', N'44567890', N'Esteban', N'Comerciante', N'Perú', N'978445566', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (5, N'Paredes Luna', N'Lima', N'milagros.paredes@gmail.com', N'1990-11-02 00:00:00.000000', N'45678901', N'Milagros', N'Médica', N'Perú', N'989556677', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (6, N'Rivas Medina', N'Cusco', N'gonzalo.rivas@gmail.com', N'1993-05-18 00:00:00.000000', N'46789012', N'Gonzalo', N'Ingeniero', N'Perú', N'912667788', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (7, N'Delgado Soto', N'Lima', N'ximena.delgado@gmail.com', N'1991-12-25 00:00:00.000000', N'47890123', N'Ximena', N'Profesora', N'Perú', N'923778899', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (8, N'Aranda Campos', N'Trujillo', N'bruno.aranda@gmail.com', N'1987-04-09 00:00:00.000000', N'48901234', N'Bruno', N'Arquitecto', N'Perú', N'934889900', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (9, N'Núñez Herrera', N'Lima', N'camila.nunez@gmail.com', N'1994-08-07 00:00:00.000000', N'49012345', N'Camila', N'Psicóloga', N'Perú', N'945990011', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (10, N'Pérez Rondón', N'Lima', N'valentina.perez@gmail.com', N'1994-06-20 00:00:00.000000', N'001234567', N'Valentina', N'Enfermera', N'Perú', N'978112233', N'CARNE_EXTRANJERIA');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (12, N'Fernandes Souza', N'Lima', N'thiago.fernandes@gmail.com', N'1991-10-05 00:00:00.000000', N'001345678', N'Thiago', N'Chef', N'Perú', N'989223344', N'CARNE_EXTRANJERIA');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (13, N'Martin', N'París', N'sophie.martin@gmail.com', N'1996-02-14 00:00:00.000000', N'19FR45678', N'Sophie', N'Fotógrafa', N'Francia', N'998334455', N'PASAPORTE');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (14, N'Mendoza Castillo', N'Cajamarca', N'pedro.mendoza28@gmail.com', N'1969-06-13 00:00:00.000000', N'13337116', N'Pedro', N'Contador', N'Perú', N'961881023', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (15, N'Fernández Ramos', N'Trujillo', N'jorge.fernandez91@gmail.com', N'1990-11-12 00:00:00.000000', N'48008803', N'Jorge', N'Médico', N'Perú', N'972179148', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (16, N'Núñez Herrera', N'Huancayo', N'jose.nuñez23@gmail.com', N'1967-06-15 00:00:00.000000', N'45807472', N'José', N'Diseñador', N'Perú', N'942206376', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (17, N'Ortiz Reyes', N'Cajamarca', N'luis.ortiz93@gmail.com', N'1991-12-09 00:00:00.000000', N'73190837', N'Luis', N'Programador', N'Perú', N'965067214', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (18, N'Mendoza Quispe', N'Cajamarca', N'carmen.mendoza72@gmail.com', N'1965-12-20 00:00:00.000000', N'36105014', N'Carmen', N'Periodista', N'Perú', N'963894841', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (19, N'García Flores', N'Cajamarca', N'maria.garcia11@gmail.com', N'1991-04-02 00:00:00.000000', N'37685718', N'María', N'Chef', N'Perú', N'980435341', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (20, N'Flores Sánchez', N'Ica', N'diana.flores12@gmail.com', N'1985-05-09 00:00:00.000000', N'11183708', N'Diana', N'Estudiante', N'Perú', N'967526955', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (21, N'Salazar Vargas', N'Ica', N'sergio.salazar5@gmail.com', N'1973-11-25 00:00:00.000000', N'26752287', N'Sergio', N'Estudiante', N'Perú', N'921364822', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (22, N'Romero Díaz', N'Huánuco', N'jorge.romero14@gmail.com', N'1975-04-03 00:00:00.000000', N'50597279', N'Jorge', N'Contador', N'Perú', N'945738162', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (23, N'Torres Martínez', N'Oxapampa', N'lourdes.torres53@gmail.com', N'1988-06-13 00:00:00.000000', N'75026997', N'Lourdes', N'Técnico', N'Perú', N'978301425', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (24, N'Quispe Ortiz', N'Puno', N'carlos.quispe21@gmail.com', N'1971-06-03 00:00:00.000000', N'75510509', N'Carlos', N'Diseñador', N'Perú', N'971659953', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (25, N'Sánchez Vargas', N'Puno', N'milagros.sanchez52@gmail.com', N'2005-08-21 00:00:00.000000', N'15300111', N'Milagros', N'Estudiante', N'Perú', N'999125475', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (26, N'Chávez Chávez', N'Cajamarca', N'silvia.chavez72@gmail.com', N'1992-04-26 00:00:00.000000', N'47656613', N'Silvia', N'Arquitecto', N'Perú', N'968698668', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (27, N'Gutiérrez Martínez', N'Oxapampa', N'miguel.gutierrez77@gmail.com', N'1987-03-13 00:00:00.000000', N'56805206', N'Miguel', N'Chef', N'Perú', N'983507605', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (28, N'Castillo Castillo', N'Iquitos', N'pedro.castillo33@gmail.com', N'2001-11-09 00:00:00.000000', N'36756434', N'Pedro', N'Arquitecto', N'Perú', N'950703431', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (29, N'Medina Ortiz', N'Iquitos', N'sandra.medina98@gmail.com', N'1985-03-01 00:00:00.000000', N'16490038', N'Sandra', N'Técnico', N'Perú', N'950306011', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (30, N'Flores Medina', N'Huánuco', N'patricia.flores73@gmail.com', N'1985-09-09 00:00:00.000000', N'53884514', N'Patricia', N'Chef', N'Perú', N'926203466', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (31, N'Sánchez Rojas', N'Piura', N'ricardo.sanchez28@gmail.com', N'2001-02-19 00:00:00.000000', N'65738102', N'Ricardo', N'Enfermera', N'Perú', N'970228157', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (32, N'Mendoza Gómez', N'Chiclayo', N'rosa.mendoza32@gmail.com', N'1973-03-21 00:00:00.000000', N'37878238', N'Rosa', N'Periodista', N'Perú', N'925376594', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (33, N'Castillo Salazar', N'Piura', N'luz.castillo46@gmail.com', N'1976-03-24 00:00:00.000000', N'44455849', N'Luz', N'Enfermera', N'Perú', N'971597495', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (34, N'Aguilar Medina', N'Ica', N'karen.aguilar67@gmail.com', N'1985-07-18 00:00:00.000000', N'65414213', N'Karen', N'Diseñador', N'Perú', N'977266658', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (35, N'Paredes Fernández', N'Cusco', N'jose.paredes81@gmail.com', N'1993-11-28 00:00:00.000000', N'30502371', N'José', N'Médico', N'Perú', N'911426255', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (36, N'Martínez Gutiérrez', N'Chiclayo', N'milagros.martinez4@gmail.com', N'1986-12-28 00:00:00.000000', N'70141304', N'Milagros', N'Chef', N'Perú', N'937787797', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (37, N'Fernández Cruz', N'Arequipa', N'pedro.fernandez38@gmail.com', N'1992-10-08 00:00:00.000000', N'30979393', N'Pedro', N'Diseñador', N'Perú', N'944999145', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (38, N'Romero Ramos', N'Lima', N'alejandro.romero89@gmail.com', N'1996-06-01 00:00:00.000000', N'62650287', N'Alejandro', N'Docente', N'Perú', N'943698072', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (39, N'Mendoza Rojas', N'Tacna', N'karen.mendoza71@gmail.com', N'2002-12-02 00:00:00.000000', N'10368346', N'Karen', N'Docente', N'Perú', N'912671815', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (40, N'Castillo Reyes', N'Lima', N'lourdes.castillo94@gmail.com', N'1980-05-12 00:00:00.000000', N'23552682', N'Lourdes', N'Vendedor', N'Perú', N'914907608', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (41, N'Salazar Gómez', N'Tacna', N'silvia.salazar41@gmail.com', N'1988-12-27 00:00:00.000000', N'48815126', N'Silvia', N'Arquitecto', N'Perú', N'970028702', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (42, N'Reyes Romero', N'Iquitos', N'katherine.reyes40@gmail.com', N'1970-08-06 00:00:00.000000', N'38532523', N'Katherine', N'Comerciante', N'Perú', N'916348373', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (43, N'Martínez Ortiz', N'Puno', N'vanessa.martinez60@gmail.com', N'1986-04-16 00:00:00.000000', N'18713439', N'Vanessa', N'Administrador', N'Perú', N'980872688', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (44, N'Gutiérrez Gutiérrez', N'Arequipa', N'jessica.gutierrez4@gmail.com', N'1971-03-12 00:00:00.000000', N'57597889', N'Jéssica', N'Programador', N'Perú', N'972343189', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (45, N'Herrera Ramos', N'Cajamarca', N'sandra.herrera56@gmail.com', N'2002-07-09 00:00:00.000000', N'40215069', N'Sandra', N'Administrador', N'Perú', N'961211623', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (46, N'Núñez Medina', N'Trujillo', N'sandra.nuñez2@gmail.com', N'1978-02-22 00:00:00.000000', N'14539791', N'Sandra', N'Docente', N'Perú', N'911938972', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (47, N'Gutiérrez Torres', N'Puno', N'fernando.gutierrez78@gmail.com', N'2004-03-24 00:00:00.000000', N'54489262', N'Fernando', N'Chef', N'Perú', N'955140043', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (48, N'Chávez Paredes', N'Huancayo', N'jorge.chavez6@gmail.com', N'1988-08-11 00:00:00.000000', N'17566278', N'Jorge', N'Diseñador', N'Perú', N'991129471', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (49, N'Castillo Ramos', N'Lima', N'diego.castillo42@gmail.com', N'2005-04-26 00:00:00.000000', N'16085248', N'Diego', N'Comerciante', N'Perú', N'964114054', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (50, N'Salazar Gómez', N'Huánuco', N'patricia.salazar44@gmail.com', N'1970-01-27 00:00:00.000000', N'78589058', N'Patricia', N'Administrador', N'Perú', N'918757672', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (51, N'Ortiz Gutiérrez', N'Cusco', N'silvia.ortiz85@gmail.com', N'1995-02-05 00:00:00.000000', N'23455290', N'Silvia', N'Médico', N'Perú', N'994366783', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (52, N'Ortiz Torres', N'Oxapampa', N'alejandro.ortiz61@gmail.com', N'1972-04-10 00:00:00.000000', N'32074967', N'Alejandro', N'Contador', N'Perú', N'959288400', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (53, N'Flores Gonzáles', N'Puno', N'patricia.flores72@gmail.com', N'1988-02-09 00:00:00.000000', N'78764631', N'Patricia', N'Enfermera', N'Perú', N'930838531', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (54, N'López López', N'Cusco', N'jose.lopez29@gmail.com', N'1992-10-26 00:00:00.000000', N'30737167', N'José', N'Periodista', N'Perú', N'990188528', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (55, N'Torres Fernández', N'Arequipa', N'silvia.torres47@gmail.com', N'1965-10-17 00:00:00.000000', N'65976728', N'Silvia', N'Programador', N'Perú', N'912822774', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (56, N'Fernández Gonzáles', N'Pucallpa', N'katherine.fernandez4@gmail.com', N'1977-09-21 00:00:00.000000', N'76258418', N'Katherine', N'Ingeniero', N'Perú', N'989237688', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (57, N'Mendoza Gonzáles', N'Iquitos', N'vanessa.mendoza31@gmail.com', N'2002-04-10 00:00:00.000000', N'29848090', N'Vanessa', N'Técnico', N'Perú', N'976816536', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (58, N'Reyes Gómez', N'Huancayo', N'alberto.reyes42@gmail.com', N'1976-09-14 00:00:00.000000', N'50434050', N'Alberto', N'Técnico', N'Perú', N'958368457', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (59, N'Gutiérrez Fernández', N'Trujillo', N'silvia.gutierrez89@gmail.com', N'1968-04-14 00:00:00.000000', N'50325919', N'Silvia', N'Docente', N'Perú', N'981106552', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (60, N'Cruz Chávez', N'Trujillo', N'silvia.cruz2@gmail.com', N'1978-06-04 00:00:00.000000', N'47504085', N'Silvia', N'Chef', N'Perú', N'912126129', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (61, N'Ortiz Gutiérrez', N'Chiclayo', N'marco.ortiz72@gmail.com', N'1993-01-18 00:00:00.000000', N'58309640', N'Marco', N'Diseñador', N'Perú', N'978451328', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (62, N'Mendoza Herrera', N'Iquitos', N'giuliana.mendoza3@gmail.com', N'1985-01-19 00:00:00.000000', N'61936371', N'Giuliana', N'Diseñador', N'Perú', N'978961517', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (63, N'Aguilar Cruz', N'Trujillo', N'jessica.aguilar52@gmail.com', N'1971-09-08 00:00:00.000000', N'13373823', N'Jéssica', N'Programador', N'Perú', N'923751674', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (64, N'Rojas Romero', N'Trujillo', N'maria.rojas66@gmail.com', N'1984-12-08 00:00:00.000000', N'79435383', N'María', N'Técnico', N'Perú', N'953232917', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (65, N'Mendoza Cruz', N'Huánuco', N'milagros.mendoza81@gmail.com', N'1999-09-09 00:00:00.000000', N'58832350', N'Milagros', N'Abogado', N'Perú', N'921048234', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (66, N'Herrera López', N'Iquitos', N'rosa.herrera46@gmail.com', N'2001-10-19 00:00:00.000000', N'39860765', N'Rosa', N'Arquitecto', N'Perú', N'934800750', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (67, N'Torres Rodríguez', N'Huancayo', N'raul.torres87@gmail.com', N'2005-10-01 00:00:00.000000', N'39511742', N'Raúl', N'Arquitecto', N'Perú', N'961638996', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (68, N'Ramos Flores', N'Iquitos', N'estefania.ramos29@gmail.com', N'1976-05-28 00:00:00.000000', N'72993790', N'Estefanía', N'Docente', N'Perú', N'948069031', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (69, N'Herrera Quispe', N'Oxapampa', N'victor.herrera89@gmail.com', N'1975-05-01 00:00:00.000000', N'26613178', N'Víctor', N'Docente', N'Perú', N'980749609', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (70, N'Medina Reyes', N'Piura', N'ivan.medina46@gmail.com', N'1971-04-18 00:00:00.000000', N'27182732', N'Iván', N'Comerciante', N'Perú', N'925769971', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (71, N'Salazar López', N'Oxapampa', N'ricardo.salazar89@gmail.com', N'1992-06-23 00:00:00.000000', N'52499677', N'Ricardo', N'Contador', N'Perú', N'917197583', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (72, N'Romero Salazar', N'Cusco', N'maria.romero97@gmail.com', N'2005-01-28 00:00:00.000000', N'75177712', N'María', N'Periodista', N'Perú', N'943206133', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (73, N'Núñez Rojas', N'Arequipa', N'alejandro.nuñez91@gmail.com', N'1984-08-25 00:00:00.000000', N'67261539', N'Alejandro', N'Arquitecto', N'Perú', N'980591961', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (74, N'Gonzáles Gómez', N'Iquitos', N'luis.gonzales26@gmail.com', N'1969-03-21 00:00:00.000000', N'45800177', N'Luis', N'Técnico', N'Perú', N'929314844', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (75, N'Chávez Núñez', N'Trujillo', N'veronica.chavez84@gmail.com', N'2003-07-05 00:00:00.000000', N'60767090', N'Verónica', N'Vendedor', N'Perú', N'995095882', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (76, N'Castillo Gómez', N'Cajamarca', N'monica.castillo2@gmail.com', N'1977-11-15 00:00:00.000000', N'10663326', N'Mónica', N'Programador', N'Perú', N'918176893', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (77, N'Torres Medina', N'Iquitos', N'jessica.torres49@gmail.com', N'1969-05-26 00:00:00.000000', N'65721934', N'Jéssica', N'Ingeniero', N'Perú', N'921569436', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (78, N'Romero García', N'Oxapampa', N'jessica.romero99@gmail.com', N'1996-02-08 00:00:00.000000', N'33928134', N'Jéssica', N'Abogado', N'Perú', N'939773679', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (79, N'Herrera Herrera', N'Lima', N'lourdes.herrera91@gmail.com', N'1984-11-11 00:00:00.000000', N'35117253', N'Lourdes', N'Enfermera', N'Perú', N'913839169', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (80, N'Gonzáles Torres', N'Huánuco', N'vanessa.gonzales12@gmail.com', N'1998-12-05 00:00:00.000000', N'41338586', N'Vanessa', N'Administrador', N'Perú', N'935430838', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (81, N'López Rodríguez', N'Ica', N'monica.lopez25@gmail.com', N'1981-01-11 00:00:00.000000', N'16309823', N'Mónica', N'Abogado', N'Perú', N'933553828', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (82, N'Ramos Gómez', N'Tacna', N'martin.ramos90@gmail.com', N'1989-11-02 00:00:00.000000', N'24623112', N'Martín', N'Vendedor', N'Perú', N'995172269', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (83, N'Sánchez Pérez', N'Huánuco', N'giuliana.sanchez5@gmail.com', N'1980-05-07 00:00:00.000000', N'41381732', N'Giuliana', N'Docente', N'Perú', N'997555759', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (84, N'Ortiz Flores', N'Arequipa', N'francisco.ortiz76@gmail.com', N'1972-09-11 00:00:00.000000', N'53198505', N'Francisco', N'Programador', N'Perú', N'980073073', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (85, N'Rodríguez Ramos', N'Tacna', N'sergio.rodriguez44@gmail.com', N'1985-05-09 00:00:00.000000', N'55312507', N'Sergio', N'Comerciante', N'Perú', N'984526238', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (86, N'Aguilar Mendoza', N'Arequipa', N'carmen.aguilar72@gmail.com', N'1984-04-12 00:00:00.000000', N'64240721', N'Carmen', N'Estudiante', N'Perú', N'958021421', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (87, N'Ramos Herrera', N'Iquitos', N'jose.ramos59@gmail.com', N'1978-04-18 00:00:00.000000', N'28429120', N'José', N'Enfermera', N'Perú', N'922312565', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (88, N'Romero Salazar', N'Huánuco', N'milagros.romero1@gmail.com', N'1986-08-14 00:00:00.000000', N'74277701', N'Milagros', N'Administrador', N'Perú', N'931663084', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (89, N'Rodríguez Ramos', N'Piura', N'jose.rodriguez17@gmail.com', N'1988-08-15 00:00:00.000000', N'21178357', N'José', N'Comerciante', N'Perú', N'965189811', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (90, N'Castillo Aguilar', N'Tacna', N'victor.castillo4@gmail.com', N'1973-10-02 00:00:00.000000', N'22342533', N'Víctor', N'Médico', N'Perú', N'935309786', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (91, N'Flores Castillo', N'Tacna', N'rodrigo.flores9@gmail.com', N'1974-04-20 00:00:00.000000', N'75364582', N'Rodrigo', N'Programador', N'Perú', N'930118112', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (92, N'Castillo Medina', N'Oxapampa', N'victor.castillo80@gmail.com', N'1974-03-19 00:00:00.000000', N'71512698', N'Víctor', N'Ingeniero', N'Perú', N'920329781', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (93, N'Díaz Martínez', N'Tacna', N'pedro.diaz74@gmail.com', N'1984-12-26 00:00:00.000000', N'37008571', N'Pedro', N'Vendedor', N'Perú', N'985402935', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (94, N'Quispe Gómez', N'Oxapampa', N'sergio.quispe54@gmail.com', N'1977-09-18 00:00:00.000000', N'69167925', N'Sergio', N'Comerciante', N'Perú', N'943163616', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (95, N'García Rojas', N'Ica', N'yolanda.garcia36@gmail.com', N'1988-09-28 00:00:00.000000', N'73582441', N'Yolanda', N'Programador', N'Perú', N'998017382', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (96, N'Martínez Fernández', N'Cajamarca', N'maria.martinez17@gmail.com', N'1977-12-18 00:00:00.000000', N'75365084', N'María', N'Comerciante', N'Perú', N'915904042', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (97, N'Martínez Herrera', N'Arequipa', N'rosa.martinez57@gmail.com', N'1979-02-01 00:00:00.000000', N'28339573', N'Rosa', N'Médico', N'Perú', N'948574225', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (98, N'Martínez Salazar', N'Oxapampa', N'raul.martinez51@gmail.com', N'1983-11-10 00:00:00.000000', N'33302636', N'Raúl', N'Enfermera', N'Perú', N'948364090', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (99, N'Fernández Gutiérrez', N'Tacna', N'ana.fernandez13@gmail.com', N'2004-07-24 00:00:00.000000', N'40908977', N'Ana', N'Médico', N'Perú', N'980285482', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (100, N'Pérez Quispe', N'Cajamarca', N'marco.perez68@gmail.com', N'1993-06-28 00:00:00.000000', N'45234557', N'Marco', N'Chef', N'Perú', N'957007127', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (101, N'Gonzáles Gómez', N'Huancayo', N'diego.gonzales99@gmail.com', N'1974-03-13 00:00:00.000000', N'54080003', N'Diego', N'Docente', N'Perú', N'957106319', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (102, N'Rodríguez Salazar', N'Trujillo', N'pedro.rodriguez34@gmail.com', N'1990-07-01 00:00:00.000000', N'58589158', N'Pedro', N'Chef', N'Perú', N'942263944', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (103, N'Mendoza García', N'Piura', N'sandra.mendoza92@gmail.com', N'1967-01-02 00:00:00.000000', N'52402376', N'Sandra', N'Vendedor', N'Perú', N'975241418', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (104, N'Martínez Quispe', N'Tacna', N'ana.martinez86@gmail.com', N'1992-08-15 00:00:00.000000', N'65724211', N'Ana', N'Diseñador', N'Perú', N'928557310', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (105, N'Sánchez Reyes', N'Arequipa', N'raul.sanchez56@gmail.com', N'1966-10-07 00:00:00.000000', N'74619313', N'Raúl', N'Contador', N'Perú', N'961313340', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (106, N'Romero Chávez', N'Chiclayo', N'diana.romero48@gmail.com', N'1982-01-14 00:00:00.000000', N'41977517', N'Diana', N'Chef', N'Perú', N'948122882', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (107, N'Ortiz Ortiz', N'Cajamarca', N'eduardo.ortiz41@gmail.com', N'1970-05-28 00:00:00.000000', N'19030609', N'Eduardo', N'Docente', N'Perú', N'952981272', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (108, N'Núñez Torres', N'Cusco', N'diego.nuñez56@gmail.com', N'1998-05-03 00:00:00.000000', N'37712954', N'Diego', N'Enfermera', N'Perú', N'929725493', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (109, N'Rodríguez Rojas', N'Iquitos', N'luz.rodriguez48@gmail.com', N'2001-11-16 00:00:00.000000', N'33296990', N'Luz', N'Enfermera', N'Perú', N'967116103', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (110, N'Quispe Salazar', N'Chiclayo', N'lourdes.quispe88@gmail.com', N'1987-12-21 00:00:00.000000', N'17592189', N'Lourdes', N'Arquitecto', N'Perú', N'952209829', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (111, N'Torres Castillo', N'Lima', N'martin.torres6@gmail.com', N'1972-04-11 00:00:00.000000', N'63850849', N'Martín', N'Médico', N'Perú', N'959281270', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (112, N'Mendoza Ramos', N'Puno', N'maria.mendoza88@gmail.com', N'1998-06-13 00:00:00.000000', N'31134191', N'María', N'Enfermera', N'Perú', N'929889481', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (113, N'Flores Cruz', N'Cajamarca', N'patricia.flores89@gmail.com', N'1978-04-02 00:00:00.000000', N'21239468', N'Patricia', N'Chef', N'Perú', N'926748702', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (114, N'Gómez Torres', N'Cajamarca', N'rosa.gomez64@gmail.com', N'1993-10-14 00:00:00.000000', N'55142339', N'Rosa', N'Chef', N'Perú', N'957002151', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (115, N'López Aguilar', N'Chiclayo', N'alberto.lopez16@gmail.com', N'1970-04-16 00:00:00.000000', N'18024728', N'Alberto', N'Administrador', N'Perú', N'926284327', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (116, N'Chávez Reyes', N'Huancayo', N'silvia.chavez26@gmail.com', N'1967-07-08 00:00:00.000000', N'69544442', N'Silvia', N'Diseñador', N'Perú', N'940034598', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (117, N'Ramos Ramos', N'Cajamarca', N'carlos.ramos28@gmail.com', N'1971-12-19 00:00:00.000000', N'65515700', N'Carlos', N'Administrador', N'Perú', N'947320396', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (118, N'Fernández Paredes', N'Chiclayo', N'miguel.fernandez56@gmail.com', N'1971-08-07 00:00:00.000000', N'33532571', N'Miguel', N'Enfermera', N'Perú', N'931642564', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (119, N'Mendoza Fernández', N'Iquitos', N'alejandro.mendoza79@gmail.com', N'2002-09-10 00:00:00.000000', N'63455673', N'Alejandro', N'Enfermera', N'Perú', N'953210027', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (120, N'García Rojas', N'Lima', N'sandra.garcia71@gmail.com', N'1973-10-24 00:00:00.000000', N'52542544', N'Sandra', N'Administrador', N'Perú', N'935422410', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (121, N'Castillo Sánchez', N'Chiclayo', N'pedro.castillo36@gmail.com', N'1997-07-09 00:00:00.000000', N'73449253', N'Pedro', N'Docente', N'Perú', N'976204972', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (122, N'Martínez Cruz', N'Lima', N'sergio.martinez23@gmail.com', N'1978-01-19 00:00:00.000000', N'40258675', N'Sergio', N'Ingeniero', N'Perú', N'999047278', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (123, N'Gómez Ramos', N'Tacna', N'alberto.gomez21@gmail.com', N'2000-03-16 00:00:00.000000', N'68684362', N'Alberto', N'Programador', N'Perú', N'954351854', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (124, N'Ramos Cruz', N'Piura', N'miguel.ramos57@gmail.com', N'1992-05-11 00:00:00.000000', N'32411265', N'Miguel', N'Diseñador', N'Perú', N'942177634', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (125, N'Chávez Díaz', N'Lima', N'alejandro.chavez45@gmail.com', N'1974-11-15 00:00:00.000000', N'59103254', N'Alejandro', N'Abogado', N'Perú', N'913959211', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (126, N'García Paredes', N'Cajamarca', N'pamela.garcia43@gmail.com', N'1983-04-27 00:00:00.000000', N'78038431', N'Pamela', N'Arquitecto', N'Perú', N'912758699', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (127, N'Díaz Medina', N'Pucallpa', N'monica.diaz99@gmail.com', N'1975-07-03 00:00:00.000000', N'79833947', N'Mónica', N'Abogado', N'Perú', N'999157188', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (128, N'Romero Pérez', N'Iquitos', N'veronica.romero42@gmail.com', N'1980-06-10 00:00:00.000000', N'67380916', N'Verónica', N'Médico', N'Perú', N'930352594', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (129, N'Gómez Vargas', N'Ica', N'rodrigo.gomez34@gmail.com', N'1986-11-20 00:00:00.000000', N'60375589', N'Rodrigo', N'Contador', N'Perú', N'969192773', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (130, N'Rodríguez Díaz', N'Arequipa', N'jessica.rodriguez61@gmail.com', N'1996-07-19 00:00:00.000000', N'67062358', N'Jéssica', N'Administrador', N'Perú', N'930146059', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (131, N'Reyes Chávez', N'Chiclayo', N'marco.reyes16@gmail.com', N'1973-02-04 00:00:00.000000', N'65465338', N'Marco', N'Periodista', N'Perú', N'947502923', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (132, N'Díaz Rojas', N'Lima', N'monica.diaz55@gmail.com', N'1986-02-20 00:00:00.000000', N'61919684', N'Mónica', N'Médico', N'Perú', N'983086211', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (133, N'García Rojas', N'Iquitos', N'pedro.garcia99@gmail.com', N'1971-11-20 00:00:00.000000', N'34953093', N'Pedro', N'Estudiante', N'Perú', N'969354808', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (134, N'Núñez Gutiérrez', N'Trujillo', N'estefania.nuñez66@gmail.com', N'1979-11-11 00:00:00.000000', N'18980105', N'Estefanía', N'Chef', N'Perú', N'919798851', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (135, N'Gutiérrez Torres', N'Huancayo', N'silvia.gutierrez93@gmail.com', N'1977-04-12 00:00:00.000000', N'59165423', N'Silvia', N'Técnico', N'Perú', N'962242662', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (136, N'Quispe Paredes', N'Trujillo', N'luis.quispe56@gmail.com', N'2000-05-28 00:00:00.000000', N'53955451', N'Luis', N'Vendedor', N'Perú', N'967467825', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (137, N'Mendoza García', N'Pucallpa', N'ivan.mendoza4@gmail.com', N'1975-04-25 00:00:00.000000', N'39517195', N'Iván', N'Periodista', N'Perú', N'920483922', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (138, N'Reyes Díaz', N'Puno', N'katherine.reyes24@gmail.com', N'1966-11-08 00:00:00.000000', N'64321531', N'Katherine', N'Diseñador', N'Perú', N'941894586', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (139, N'Vargas Chávez', N'Huancayo', N'jose.vargas1@gmail.com', N'1984-02-12 00:00:00.000000', N'47831004', N'José', N'Abogado', N'Perú', N'921757416', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (140, N'Díaz Romero', N'Huánuco', N'rodrigo.diaz64@gmail.com', N'1986-12-14 00:00:00.000000', N'49153728', N'Rodrigo', N'Estudiante', N'Perú', N'953189688', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (141, N'Aguilar Núñez', N'Lima', N'luz.aguilar5@gmail.com', N'1969-12-11 00:00:00.000000', N'28245372', N'Luz', N'Abogado', N'Perú', N'959176269', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (142, N'García Chávez', N'Cusco', N'fernando.garcia40@gmail.com', N'1973-11-05 00:00:00.000000', N'75675194', N'Fernando', N'Programador', N'Perú', N'940564026', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (143, N'Paredes Flores', N'Piura', N'katherine.paredes65@gmail.com', N'1978-07-14 00:00:00.000000', N'37457307', N'Katherine', N'Administrador', N'Perú', N'959284439', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (144, N'Vargas Sánchez', N'Huancayo', N'maria.vargas57@gmail.com', N'1994-03-19 00:00:00.000000', N'56953116', N'María', N'Programador', N'Perú', N'940153432', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (145, N'Ramos Díaz', N'Cajamarca', N'elena.ramos39@gmail.com', N'1999-10-08 00:00:00.000000', N'15584467', N'Elena', N'Arquitecto', N'Perú', N'921733312', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (146, N'Sánchez Díaz', N'Chiclayo', N'fernando.sanchez52@gmail.com', N'1974-02-26 00:00:00.000000', N'73621807', N'Fernando', N'Vendedor', N'Perú', N'918931748', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (147, N'Castillo Núñez', N'Huánuco', N'pedro.castillo10@gmail.com', N'1997-03-06 00:00:00.000000', N'50830180', N'Pedro', N'Enfermera', N'Perú', N'925978378', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (148, N'Ramos Pérez', N'Arequipa', N'diego.ramos19@gmail.com', N'1998-12-28 00:00:00.000000', N'69857282', N'Diego', N'Vendedor', N'Perú', N'978513131', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (149, N'Gonzáles Ramos', N'Tacna', N'gabriela.gonzales14@gmail.com', N'2002-12-28 00:00:00.000000', N'54909885', N'Gabriela', N'Contador', N'Perú', N'965138990', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (150, N'Gutiérrez Mendoza', N'Tacna', N'francisco.gutierrez36@gmail.com', N'1983-05-06 00:00:00.000000', N'73243623', N'Francisco', N'Técnico', N'Perú', N'955521589', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (151, N'Castillo Gómez', N'Huánuco', N'elena.castillo42@gmail.com', N'1999-05-01 00:00:00.000000', N'40036307', N'Elena', N'Diseñador', N'Perú', N'930869395', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (152, N'Flores Martínez', N'Arequipa', N'patricia.flores68@gmail.com', N'1994-01-03 00:00:00.000000', N'77607258', N'Patricia', N'Programador', N'Perú', N'924440165', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (153, N'Paredes Aguilar', N'Cusco', N'ana.paredes48@gmail.com', N'2004-10-07 00:00:00.000000', N'11646358', N'Ana', N'Chef', N'Perú', N'942354918', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (154, N'Ramos Cruz', N'Puno', N'raul.ramos57@gmail.com', N'1970-11-04 00:00:00.000000', N'66332562', N'Raúl', N'Abogado', N'Perú', N'981982425', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (155, N'Vargas Díaz', N'Chiclayo', N'ivan.vargas57@gmail.com', N'1972-02-11 00:00:00.000000', N'14694227', N'Iván', N'Diseñador', N'Perú', N'977849074', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (156, N'Salazar Gonzáles', N'Huánuco', N'victor.salazar74@gmail.com', N'1984-03-07 00:00:00.000000', N'11432655', N'Víctor', N'Ingeniero', N'Perú', N'924523990', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (157, N'Gómez Aguilar', N'Cajamarca', N'sergio.gomez16@gmail.com', N'1979-09-03 00:00:00.000000', N'37059023', N'Sergio', N'Diseñador', N'Perú', N'918153857', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (158, N'Flores García', N'Trujillo', N'victor.flores54@gmail.com', N'1971-08-06 00:00:00.000000', N'77268710', N'Víctor', N'Chef', N'Perú', N'951436942', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (159, N'Paredes Vargas', N'Ica', N'roberto.paredes97@gmail.com', N'1982-01-16 00:00:00.000000', N'61807823', N'Roberto', N'Abogado', N'Perú', N'939469152', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (160, N'Cruz Cruz', N'Ica', N'patricia.cruz6@gmail.com', N'1970-06-05 00:00:00.000000', N'13335060', N'Patricia', N'Arquitecto', N'Perú', N'997405807', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (161, N'Martínez Castillo', N'Lima', N'roberto.martinez10@gmail.com', N'1973-07-23 00:00:00.000000', N'48871159', N'Roberto', N'Docente', N'Perú', N'984818316', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (162, N'Díaz Pérez', N'Lima', N'karen.diaz66@gmail.com', N'1966-09-28 00:00:00.000000', N'23928914', N'Karen', N'Médico', N'Perú', N'932286375', N'DNI');
INSERT INTO [dbo].[cliente] ([id], [apellidos], [ciudad], [correo], [fecha_nacimiento], [identificacion], [nombres], [ocupacion], [pais], [telefono], [tipo_documento]) VALUES (163, N'Herrera Rojas', N'Huánuco', N'carmen.herrera68@gmail.com', N'1998-01-16 00:00:00.000000', N'79257439', N'Carmen', N'Diseñador', N'Perú', N'913774269', N'DNI');
SET IDENTITY_INSERT [dbo].[cliente] OFF;

-- usuario (9 filas)
SET IDENTITY_INSERT [dbo].[usuario] ON;
INSERT INTO [dbo].[usuario] ([id], [apellidos], [contrasena], [correo], [es_admin], [logout_time], [nombres], [username], [activo]) VALUES (7, N'Musk', N'$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', N'avalencia4902@gmail.com', 1, N'2026-10-21 00:18:15.188593', N'Elon', N'elon', 1);
INSERT INTO [dbo].[usuario] ([id], [apellidos], [contrasena], [correo], [es_admin], [logout_time], [nombres], [username], [activo]) VALUES (11, N'Quispe', N'$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', N'mquispe@hoteltunki.com', 0, NULL, N'María', N'mquispe', 1);
INSERT INTO [dbo].[usuario] ([id], [apellidos], [contrasena], [correo], [es_admin], [logout_time], [nombres], [username], [activo]) VALUES (12, N'Huamán', N'$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', N'jhuaman@hoteltunki.com', 0, NULL, N'Jorge', N'jhuaman', 1);
INSERT INTO [dbo].[usuario] ([id], [apellidos], [contrasena], [correo], [es_admin], [logout_time], [nombres], [username], [activo]) VALUES (13, N'Rojas', N'$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', N'lrojas@hoteltunki.com', 0, NULL, N'Lucía', N'lrojas', 1);
INSERT INTO [dbo].[usuario] ([id], [apellidos], [contrasena], [correo], [es_admin], [logout_time], [nombres], [username], [activo]) VALUES (14, N'Mendoza', N'$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', N'cmendoza@hoteltunki.com', 0, NULL, N'Carlos', N'cmendoza', 1);
INSERT INTO [dbo].[usuario] ([id], [apellidos], [contrasena], [correo], [es_admin], [logout_time], [nombres], [username], [activo]) VALUES (15, N'Flores', N'$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', N'rflores@hoteltunki.com', 0, NULL, N'Rosa', N'rflores', 1);
INSERT INTO [dbo].[usuario] ([id], [apellidos], [contrasena], [correo], [es_admin], [logout_time], [nombres], [username], [activo]) VALUES (16, N'Torres', N'$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', N'mtorres@hoteltunki.com', 0, NULL, N'Miguel', N'mtorres', 1);
INSERT INTO [dbo].[usuario] ([id], [apellidos], [contrasena], [correo], [es_admin], [logout_time], [nombres], [username], [activo]) VALUES (17, N'Ramírez', N'$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', N'pramirez@hoteltunki.com', 0, NULL, N'Paola', N'pramirez', 1);
INSERT INTO [dbo].[usuario] ([id], [apellidos], [contrasena], [correo], [es_admin], [logout_time], [nombres], [username], [activo]) VALUES (18, N'Vásquez', N'$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', N'dvasquez@hoteltunki.com', 0, NULL, N'Daniel', N'dvasquez', 1);
SET IDENTITY_INSERT [dbo].[usuario] OFF;

-- habitacion (45 filas)
SET IDENTITY_INSERT [dbo].[habitacion] ON;
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (1, 2, N'101', 1, N'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', 1, N'DISPONIBLE', 5);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (2, 2, N'102', 1, N'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', 1, N'DISPONIBLE', 1);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (3, 2, N'103', 1, N'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', 1, N'DISPONIBLE', 2);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (4, 2, N'104', 1, N'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', 1, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (5, 2, N'105', 1, N'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', 1, N'LIMPIEZA', 1);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (6, 2, N'106', 1, N'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', 1, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (7, 2, N'107', 1, N'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', 1, N'DISPONIBLE', 1);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (8, 2, N'108', 1, N'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', 1, N'DISPONIBLE', 1);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (9, 3, N'109', 1, N'https://www.tunkilodge.com/imagenes/habitacionfamiliar3personas.png', 2, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (10, 3, N'110', 1, N'https://www.tunkilodge.com/imagenes/habitacionfamiliar3personas.png', 2, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (11, 3, N'111', 1, N'https://www.tunkilodge.com/imagenes/habitacionfamiliar3personas.png', 2, N'LIMPIEZA', 1);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (12, 3, N'112', 1, N'https://www.tunkilodge.com/imagenes/habitacionfamiliar3personas.png', 2, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (13, 3, N'113', 1, N'https://www.tunkilodge.com/imagenes/habitacionfamiliar3personas.png', 2, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (14, 3, N'114', 1, N'https://www.tunkilodge.com/imagenes/habitacionfamiliar3personas.png', 2, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (15, 3, N'115', 1, N'https://www.tunkilodge.com/imagenes/habitacionfamiliar3personas.png', 2, N'LIMPIEZA', 1);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (16, 6, N'D1', 1, N'https://www.tunkilodge.com/imagenes/domo.jpeg', 5, N'LIMPIEZA', 2);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (17, 6, N'D2', 1, N'https://www.tunkilodge.com/imagenes/domo.jpeg', 5, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (18, 6, N'D3', 1, N'https://www.tunkilodge.com/imagenes/domo.jpeg', 5, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (19, 6, N'D4', 1, N'https://www.tunkilodge.com/imagenes/domo.jpeg', 5, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (20, 6, N'D5', 1, N'https://www.tunkilodge.com/imagenes/domo.jpeg', 5, N'DISPONIBLE', 1);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (21, 10, N'C1', 1, N'/carrusel-login/foto-4.jpg', 6, N'LIMPIEZA', 1);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (22, 4, N'201', 2, N'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (23, 4, N'202', 2, N'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (24, 4, N'203', 2, N'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, N'LIMPIEZA', 1);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (25, 4, N'204', 2, N'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (26, 4, N'205', 2, N'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (27, 4, N'206', 2, N'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (28, 4, N'207', 2, N'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (29, 4, N'208', 2, N'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (30, 4, N'209', 2, N'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (31, 4, N'210', 2, N'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, N'LIMPIEZA', 1);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (32, 4, N'211', 2, N'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (33, 4, N'212', 2, N'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (34, 6, N'301', 3, N'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (35, 6, N'302', 3, N'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, N'LIMPIEZA', 1);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (36, 6, N'303', 3, N'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (37, 6, N'304', 3, N'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (38, 6, N'305', 3, N'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (39, 6, N'306', 3, N'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (40, 6, N'307', 3, N'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, N'LIMPIEZA', 1);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (41, 6, N'308', 3, N'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (42, 6, N'309', 3, N'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (43, 6, N'310', 3, N'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (44, 6, N'311', 3, N'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, N'DISPONIBLE', 0);
INSERT INTO [dbo].[habitacion] ([id], [aforo], [numero], [piso], [url_imagen], [categoria_id], [estado], [version]) VALUES (45, 6, N'312', 3, N'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, N'DISPONIBLE', 0);
SET IDENTITY_INSERT [dbo].[habitacion] OFF;

-- registro (60 filas)
SET IDENTITY_INSERT [dbo].[registro] ON;
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (1, N'2026-10-05 15:00:00.000000', 3, 1, NULL, 660, 138, 11, 17, N'2026-10-08 16:23:00.000000', N'FINALIZADA', N'EFECTIVO', 660, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (2, N'2026-10-24 12:00:00.000000', 5, 3, NULL, 2250, 162, 21, 11, NULL, N'ACTIVA', N'TARJETA', 1125, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (3, N'2026-10-18 10:00:00.000000', 3, 3, N'', 780, 36, 31, 16, N'2026-10-23 03:23:09.153000', N'FINALIZADA', N'EFECTIVO', 864, 3, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (4, N'2026-09-05 12:00:00.000000', 5, 3, NULL, 1750, 123, 20, 7, N'2026-09-10 12:44:00.000000', N'FINALIZADA', N'TRANSFERENCIA', 1750, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (5, N'2026-09-15 10:00:00.000000', 3, 3, NULL, 960, 99, 45, 15, N'2026-09-18 09:01:00.000000', N'FINALIZADA', N'TRANSFERENCIA', 960, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (6, N'2026-10-02 10:00:00.000000', 2, 1, NULL, 700, 150, 20, 11, N'2026-10-04 09:35:00.000000', N'FINALIZADA', N'EFECTIVO', 700, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (7, N'2026-10-22 18:00:00.000000', 5, 4, N'', 1600, 104, 40, 17, N'2026-10-23 09:25:31.744000', N'FINALIZADA', NULL, 1600, 2, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (8, N'2026-11-05 12:00:00.000000', 5, 2, N'', 900, 128, 7, 18, NULL, N'ACTIVA', N'EFECTIVO', 450, 1, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (9, N'2026-10-04 08:00:00.000000', 4, 4, NULL, 1280, 88, 36, 14, NULL, N'NO_SHOW', NULL, 0, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (10, N'2026-09-13 16:00:00.000000', 5, 4, NULL, 1100, 114, 9, 17, N'2026-09-18 16:18:00.000000', N'FINALIZADA', N'TRANSFERENCIA', 1159.5, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (11, N'2026-10-02 17:00:00.000000', 4, 3, NULL, 1280, 132, 45, 13, N'2026-10-06 17:00:00.000000', N'FINALIZADA', N'EFECTIVO', 1315, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (12, N'2026-08-22 13:00:00.000000', 4, 2, NULL, 720, 5, 5, 13, N'2026-08-26 14:15:00.000000', N'FINALIZADA', N'EFECTIVO', 720, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (13, N'2026-11-05 14:00:00.000000', 3, 4, NULL, 780, 98, 29, 13, NULL, N'ACTIVA', NULL, 0, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (14, N'2026-10-27 14:00:00.000000', 5, 2, NULL, 1300, 30, 24, 16, N'2026-10-23 09:25:59.108000', N'FINALIZADA', N'EFECTIVO', 1300, 1, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (15, N'2026-10-19 16:00:00.000000', 4, 4, N'', 1800, 50, 21, 16, N'2026-10-23 09:18:06.249000', N'FINALIZADA', N'EFECTIVO', 1800, 3, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (16, N'2026-09-27 13:00:00.000000', 4, 4, NULL, 1280, 151, 41, 16, N'2026-10-01 13:18:00.000000', N'FINALIZADA', N'TRANSFERENCIA', 1304, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (17, N'2026-10-21 11:00:00.000000', 2, 2, N'', 440, 53, 11, 7, N'2026-10-23 09:20:29.605000', N'FINALIZADA', N'TARJETA', 522, 2, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (18, N'2026-10-05 17:00:00.000000', 1, 1, NULL, 350, 128, 19, 7, N'2026-10-06 16:38:00.000000', N'FINALIZADA', N'TRANSFERENCIA', 350, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (19, N'2026-10-04 08:00:00.000000', 2, 4, NULL, 640, 88, 42, 11, N'2026-10-06 07:40:00.000000', N'FINALIZADA', N'EFECTIVO', 640, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (20, N'2026-09-16 14:00:00.000000', 5, 2, NULL, 1600, 15, 43, 16, N'2026-09-21 15:11:00.000000', N'FINALIZADA', N'TRANSFERENCIA', 1600, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (21, N'2026-11-03 11:00:00.000000', 5, 2, NULL, 1600, 101, 44, 18, NULL, N'ACTIVA', NULL, 0, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (22, N'2026-09-12 14:00:00.000000', 2, 4, NULL, 640, 13, 34, 11, N'2026-09-14 13:43:00.000000', N'FINALIZADA', N'TARJETA', 640, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (23, N'2026-10-20 11:00:00.000000', 1, 3, NULL, 350, 95, 19, 16, NULL, N'CANCELADA', NULL, 0, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (24, N'2026-09-02 13:00:00.000000', 3, 2, NULL, 540, 25, 3, 14, N'2026-09-05 12:18:00.000000', N'FINALIZADA', N'EFECTIVO', 554, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (25, N'2026-08-28 14:00:00.000000', 2, 2, NULL, 700, 90, 16, 17, N'2026-08-30 13:10:00.000000', N'FINALIZADA', N'TRANSFERENCIA', 700, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (26, N'2026-09-06 17:00:00.000000', 2, 1, NULL, 640, 108, 44, 14, N'2026-09-08 16:53:00.000000', N'FINALIZADA', N'TARJETA', 640, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (27, N'2026-09-20 10:00:00.000000', 2, 2, NULL, 360, 31, 6, 15, N'2026-09-22 10:57:00.000000', N'FINALIZADA', N'EFECTIVO', 360, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (28, N'2026-10-05 17:00:00.000000', 5, 1, NULL, 1300, 81, 26, 16, N'2026-10-10 15:57:00.000000', N'FINALIZADA', N'TRANSFERENCIA', 1356, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (29, N'2026-10-19 09:00:00.000000', 5, 4, N'', 1100, 24, 15, 16, N'2026-10-23 09:21:27.632000', N'FINALIZADA', N'EFECTIVO', 1120, 2, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (30, N'2026-09-06 10:00:00.000000', 5, 2, NULL, 1600, 65, 40, 11, NULL, N'CANCELADA', NULL, 0, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (31, N'2026-10-15 20:00:00.000000', 1, 4, NULL, 320, 158, 43, 14, N'2026-10-16 19:51:00.000000', N'FINALIZADA', N'EFECTIVO', 320, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (32, N'2026-10-11 13:00:00.000000', 4, 4, NULL, 1280, 51, 34, 11, N'2026-10-15 12:26:00.000000', N'FINALIZADA', N'TARJETA', 1280, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (33, N'2026-08-24 09:00:00.000000', 5, 3, NULL, 1300, 122, 31, 18, N'2026-08-29 09:47:00.000000', N'FINALIZADA', N'TRANSFERENCIA', 1395, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (34, N'2026-10-04 11:00:00.000000', 5, 4, NULL, 900, 16, 2, 12, N'2026-10-09 12:15:00.000000', N'FINALIZADA', N'EFECTIVO', 916, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (35, N'2026-10-16 18:00:00.000000', 3, 2, NULL, 780, 69, 30, 14, N'2026-10-19 16:45:00.000000', N'FINALIZADA', N'EFECTIVO', 780, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (36, N'2026-09-03 20:00:00.000000', 4, 3, NULL, 720, 146, 6, 17, N'2026-09-07 20:06:00.000000', N'FINALIZADA', N'TARJETA', 762, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (37, N'2026-09-12 16:00:00.000000', 1, 3, NULL, 320, 116, 40, 13, N'2026-09-13 16:18:00.000000', N'FINALIZADA', N'TRANSFERENCIA', 320, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (38, N'2026-10-07 19:00:00.000000', 2, 1, NULL, 640, 62, 39, 13, NULL, N'NO_SHOW', NULL, 0, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (39, N'2026-08-31 17:00:00.000000', 1, 3, NULL, 180, 100, 2, 15, N'2026-09-01 18:14:00.000000', N'FINALIZADA', N'EFECTIVO', 180, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (40, N'2026-10-16 18:00:00.000000', 1, 3, NULL, 260, 157, 25, 16, N'2026-10-17 17:13:00.000000', N'FINALIZADA', N'TARJETA', 260, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (41, N'2026-11-10 18:00:00.000000', 2, 3, NULL, 360, 111, 7, 7, NULL, N'ACTIVA', N'TRANSFERENCIA', 360, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (42, N'2026-09-17 09:00:00.000000', 2, 1, NULL, 360, 93, 7, 14, N'2026-09-19 10:17:00.000000', N'FINALIZADA', N'EFECTIVO', 360, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (43, N'2026-09-14 15:00:00.000000', 3, 2, NULL, 960, 100, 34, 16, N'2026-09-16 12:30:00.000000', N'FINALIZADA', N'TARJETA', 1018, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (44, N'2026-11-05 08:00:00.000000', 4, 1, NULL, 1400, 63, 19, 17, NULL, N'ACTIVA', NULL, 0, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (45, N'2026-10-29 08:00:00.000000', 3, 2, NULL, 1050, 60, 17, 16, NULL, N'ACTIVA', N'TRANSFERENCIA', 1050, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (46, N'2026-10-02 20:00:00.000000', 2, 1, NULL, 520, 1, 31, 16, N'2026-10-04 19:26:00.000000', N'FINALIZADA', N'EFECTIVO', 520, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (47, N'2026-09-21 10:00:00.000000', 5, 2, NULL, 900, 31, 4, 15, N'2026-09-26 11:09:00.000000', N'FINALIZADA', N'TARJETA', 900, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (48, N'2026-08-22 20:00:00.000000', 3, 1, NULL, 780, 89, 30, 14, NULL, N'CANCELADA', NULL, 0, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (49, N'2026-10-26 12:00:00.000000', 4, 4, NULL, 1280, 130, 42, 13, NULL, N'ACTIVA', N'TRANSFERENCIA', 640, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (50, N'2026-09-26 11:00:00.000000', 4, 3, NULL, 720, 19, 4, 7, N'2026-09-30 10:52:00.000000', N'FINALIZADA', N'TRANSFERENCIA', 737, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (51, N'2026-10-25 18:00:00.000000', 1, 4, N'', 220, 67, 15, 12, N'2026-10-23 09:23:54.961000', N'FINALIZADA', N'EFECTIVO', 220, 2, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (52, N'2026-11-04 11:00:00.000000', 1, 3, NULL, 320, 138, 34, 14, NULL, N'ACTIVA', N'EFECTIVO', 160, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (53, N'2026-10-16 14:00:00.000000', 3, 4, NULL, 960, 73, 34, 18, N'2026-10-19 15:23:00.000000', N'FINALIZADA', N'TRANSFERENCIA', 960, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (54, N'2026-10-10 15:00:00.000000', 2, 4, NULL, 640, 90, 40, 14, N'2026-10-12 13:34:00.000000', N'FINALIZADA', N'TRANSFERENCIA', 640, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (55, N'2026-10-27 14:00:00.000000', 5, 3, NULL, 1600, 91, 35, 7, N'2026-10-23 09:26:14.480000', N'FINALIZADA', N'EFECTIVO', 1600, 1, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (56, N'2026-10-28 16:00:00.000000', 4, 3, N'', 1400, 77, 16, 17, N'2026-10-23 09:27:08.061000', N'FINALIZADA', NULL, 1400, 2, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (57, N'2026-10-09 20:00:00.000000', 2, 4, NULL, 640, 79, 39, 7, N'2026-10-11 21:30:00.000000', N'FINALIZADA', N'EFECTIVO', 640, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (58, N'2026-10-22 16:00:00.000000', 4, 4, N'', 720, 77, 5, 17, N'2026-10-23 09:24:36.315000', N'FINALIZADA', N'TARJETA', 720, 3, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (59, N'2026-09-25 12:00:00.000000', 2, 2, NULL, 640, 144, 45, 13, N'2026-09-27 11:31:00.000000', N'FINALIZADA', N'EFECTIVO', 640, 0, NULL);
INSERT INTO [dbo].[registro] ([id], [check_in], [noches], [num_huespedes], [observaciones], [tarifa], [cliente_id], [habitacion_id], [usuario_id], [check_out_real], [estado], [metodo_pago], [monto_pagado], [version], [reserva_id]) VALUES (60, N'2026-09-05 09:00:00.000000', 1, 4, NULL, 450, 87, 21, 12, N'2026-09-06 10:12:00.000000', N'FINALIZADA', N'EFECTIVO', 450, 0, NULL);
SET IDENTITY_INSERT [dbo].[registro] OFF;

-- comprobante (4 filas)
SET IDENTITY_INSERT [dbo].[comprobante] ON;
INSERT INTO [dbo].[comprobante] ([id], [correlativo], [datos_json], [fecha_emision], [igv], [serie], [total], [valor_venta], [registro_id]) VALUES (1, 1, N'{
  "serie" : "C001",
  "numero" : "00000001",
  "fecha_de_emision" : "2026-10-21",
  "moneda" : "PEN",
  "cliente" : {
    "tipo_de_documento" : "DNI",
    "numero_de_documento" : "64321531",
    "denominacion" : "Katherine Reyes Díaz"
  },
  "items" : [ {
    "descripcion" : "Estadía - Habitación 111 (Habitación Familiar (3 personas)) - 3 noche(s)",
    "cantidad" : 1,
    "total" : 660.0
  } ],
  "valor_venta" : 559.32,
  "total_igv" : 100.68,
  "total" : 660.0
}', N'2026-10-21 01:06:18.105169', 100.68, N'C001', 660, 559.32, 1);
INSERT INTO [dbo].[comprobante] ([id], [correlativo], [datos_json], [fecha_emision], [igv], [serie], [total], [valor_venta], [registro_id]) VALUES (2, 2, N'{
  "serie" : "C001",
  "numero" : "00000002",
  "fecha_de_emision" : "2026-10-21",
  "moneda" : "PEN",
  "cliente" : {
    "tipo_de_documento" : "PASAPORTE",
    "numero_de_documento" : "19FR45678",
    "denominacion" : "Sophie Martin"
  },
  "items" : [ {
    "descripcion" : "Estadía - Habitación 301 (Habitación 5-6 Personas) - 2 noche(s)",
    "cantidad" : 1,
    "total" : 640.0
  } ],
  "valor_venta" : 542.37,
  "total_igv" : 97.63,
  "total" : 640.0
}', N'2026-10-21 01:08:31.193459', 97.63, N'C001', 640, 542.37, 22);
INSERT INTO [dbo].[comprobante] ([id], [correlativo], [datos_json], [fecha_emision], [igv], [serie], [total], [valor_venta], [registro_id]) VALUES (3, 3, N'{
  "serie" : "C001",
  "numero" : "00000003",
  "fecha_de_emision" : "2026-10-23",
  "moneda" : "PEN",
  "cliente" : {
    "tipo_de_documento" : "DNI",
    "numero_de_documento" : "70141304",
    "denominacion" : "Milagros Martínez Gutiérrez"
  },
  "items" : [ {
    "descripcion" : "Estadía - Habitación 210 (Habitación Familiar (4 personas)) - 3 noche(s)",
    "cantidad" : 1,
    "total" : 780.0
  }, {
    "descripcion" : "Minibar",
    "cantidad" : 1,
    "total" : 18.0
  }, {
    "descripcion" : "Room service - Desayuno a la habitación",
    "cantidad" : 1,
    "total" : 26.0
  }, {
    "descripcion" : "Room service - Almuerzo o cena",
    "cantidad" : 1,
    "total" : 40.0
  } ],
  "valor_venta" : 732.2,
  "total_igv" : 131.8,
  "total" : 864.0
}', N'2026-10-23 03:23:09.211324', 131.8, N'C001', 864, 732.2, 3);
INSERT INTO [dbo].[comprobante] ([id], [correlativo], [datos_json], [fecha_emision], [igv], [serie], [total], [valor_venta], [registro_id]) VALUES (4, 4, N'{
  "serie" : "C001",
  "numero" : "00000004",
  "fecha_de_emision" : "2026-10-23",
  "moneda" : "PEN",
  "cliente" : {
    "tipo_de_documento" : "DNI",
    "numero_de_documento" : "78764631",
    "denominacion" : "Patricia Flores Gonzáles"
  },
  "items" : [ {
    "descripcion" : "Estadía - Habitación 111 (Habitación Familiar (3 personas)) - 2 noche(s)",
    "cantidad" : 1,
    "total" : 440.0
  }, {
    "descripcion" : "Lavandería",
    "cantidad" : 1,
    "total" : 22.0
  }, {
    "descripcion" : "Minibar",
    "cantidad" : 1,
    "total" : 20.0
  }, {
    "descripcion" : "Room service - Almuerzo o cena",
    "cantidad" : 1,
    "total" : 40.0
  } ],
  "valor_venta" : 442.37,
  "total_igv" : 79.63,
  "total" : 522.0
}', N'2026-10-23 09:20:50.970323', 79.63, N'C001', 522, 442.37, 17);
SET IDENTITY_INSERT [dbo].[comprobante] OFF;

-- producto_consumo (5 filas)
SET IDENTITY_INSERT [dbo].[producto_consumo] ON;
INSERT INTO [dbo].[producto_consumo] ([id], [activo], [nombre], [precio_sugerido]) VALUES (1, 1, N'Minibar', 20);
INSERT INTO [dbo].[producto_consumo] ([id], [activo], [nombre], [precio_sugerido]) VALUES (2, 1, N'Room service - Desayuno a la habitación', 28);
INSERT INTO [dbo].[producto_consumo] ([id], [activo], [nombre], [precio_sugerido]) VALUES (3, 1, N'Room service - Almuerzo o cena', 40);
INSERT INTO [dbo].[producto_consumo] ([id], [activo], [nombre], [precio_sugerido]) VALUES (4, 1, N'Lavandería', 28);
INSERT INTO [dbo].[producto_consumo] ([id], [activo], [nombre], [precio_sugerido]) VALUES (7, 1, N'Toalla dañada - reposición', 45);
SET IDENTITY_INSERT [dbo].[producto_consumo] OFF;

-- consumo (32 filas)
SET IDENTITY_INSERT [dbo].[consumo] ON;
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (1, N'Room service - Desayuno a la habitación', N'2026-08-25 08:30:00.000000', 28, 33, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (2, N'Room service - Cena a la habitación', N'2026-08-27 20:15:00.000000', 45, 33, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (3, N'Minibar', N'2026-08-28 23:10:00.000000', 22, 33, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (4, N'Lavandería', N'2026-09-07 10:00:00.000000', 32, 4, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (5, N'Room service - Almuerzo', N'2026-09-08 13:20:00.000000', 38, 4, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (6, N'Minibar', N'2026-09-15 21:40:00.000000', 19.5, 10, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (7, N'Late check-out (2 horas extra)', N'2026-09-18 15:50:00.000000', 40, 10, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (8, N'Room service - Cena', N'2026-09-18 21:00:00.000000', 42, 20, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (9, N'Toalla dañada - reposición', N'2026-09-20 11:30:00.000000', 45, 20, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (10, N'Minibar', N'2026-09-29 22:15:00.000000', 24, 16, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (11, N'Room service - Desayuno a la habitación', N'2026-10-07 08:45:00.000000', 26, 28, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (12, N'Lavandería', N'2026-10-08 11:00:00.000000', 30, 28, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (13, N'Minibar', N'2026-10-12 23:00:00.000000', 21, 32, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (14, N'Late check-out (1 hora extra)', N'2026-10-15 12:20:00.000000', 25, 32, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (15, N'Room service - Almuerzo', N'2026-10-04 13:30:00.000000', 35, 11, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (16, N'Minibar', N'2026-10-06 20:00:00.000000', 16, 34, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (17, N'Lavandería', N'2026-10-18 09:30:00.000000', 28, 53, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (18, N'Minibar', N'2026-09-15 22:40:00.000000', 18, 43, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (19, N'Room service - Cena', N'2026-09-15 20:10:00.000000', 40, 43, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (20, N'Minibar', N'2026-09-03 21:30:00.000000', 14, 24, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (21, N'Room service - Desayuno a la habitación', N'2026-10-18 08:20:00.000000', 24, 35, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (22, N'Minibar', N'2026-09-05 22:50:00.000000', 20, 36, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (23, N'Lavandería', N'2026-09-06 10:15:00.000000', 22, 36, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (24, N'Minibar', N'2026-09-28 22:00:00.000000', 17, 50, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (25, N'Minibar', N'2026-08-24 21:45:00.000000', 19, 12, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (26, N'Minibar', N'2026-10-20 22:30:00.000000', 18, 3, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (27, N'Room service - Desayuno a la habitación', N'2026-10-21 08:15:00.000000', 26, 3, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (28, N'Minibar', N'2026-10-20 23:00:00.000000', 20, 29, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (29, N'Lavandería', N'2026-10-22 10:00:00.000000', 22, 17, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (32, N'Room service - Almuerzo o cena', N'2026-10-23 03:09:38.895121', 40, 3, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (33, N'Minibar', N'2026-10-23 03:15:25.293805', 20, 17, NULL);
INSERT INTO [dbo].[consumo] ([id], [descripcion], [fecha], [monto], [registro_id], [producto_consumo_id]) VALUES (34, N'Room service - Almuerzo o cena', N'2026-10-23 03:15:27.435657', 40, 17, NULL);
SET IDENTITY_INSERT [dbo].[consumo] OFF;

-- login_attempts (46 filas)
SET IDENTITY_INSERT [dbo].[login_attempts] ON;
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (1, N'2026-10-21 00:13:11.064963', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (2, N'2026-10-21 00:18:32.132995', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (3, N'2026-10-21 00:21:17.089907', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (4, N'2026-10-21 00:27:00.068545', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (5, N'2026-10-21 00:31:11.962863', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (6, N'2026-10-21 00:37:12.096243', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (7, N'2026-10-21 00:38:18.714710', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (8, N'2026-10-21 00:39:15.104976', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (9, N'2026-10-21 00:42:24.739990', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (10, N'2026-10-21 00:43:44.495850', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (11, N'2026-10-21 00:45:16.027786', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (12, N'2026-10-21 00:46:42.103485', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (13, N'2026-10-21 00:50:18.549191', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (14, N'2026-10-21 00:58:44.229702', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (15, N'2026-10-21 01:03:52.876731', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (16, N'2026-10-21 01:08:10.090440', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (17, N'2026-10-21 01:10:01.961566', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (18, N'2026-10-21 01:14:20.930592', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (19, N'2026-10-21 01:14:55.761219', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (20, N'2026-10-21 01:20:43.330785', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (21, N'2026-10-21 01:23:31.757256', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (22, N'2026-10-21 09:53:26.382105', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (23, N'2026-10-21 10:30:23.496741', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (24, N'2026-10-21 10:31:32.270005', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (25, N'2026-10-21 10:39:38.607965', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (26, N'2026-10-21 10:41:05.903247', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (27, N'2026-10-21 10:42:50.790380', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (28, N'2026-10-21 10:51:08.709925', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (29, N'2026-10-21 10:57:54.469556', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (30, N'2026-10-21 10:59:16.945344', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (31, N'2026-10-21 11:08:33.441438', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (32, N'2026-10-21 11:13:00.904498', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (33, N'2026-10-21 11:15:45.673546', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (34, N'2026-10-21 11:28:19.927529', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (35, N'2026-10-21 11:35:23.717862', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (36, N'2026-10-21 11:50:31.972818', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (37, N'2026-10-21 11:55:12.095200', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (38, N'2026-10-21 12:29:04.993698', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (39, N'2026-10-21 15:33:23.291783', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (40, N'2026-10-21 18:26:59.895149', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (41, N'2026-10-21 18:38:58.612592', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (42, N'2026-10-21 19:39:10.715276', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (43, N'2026-10-23 01:40:42.292346', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (44, N'2026-10-23 09:14:05.188823', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (45, N'2026-10-23 10:17:49.037114', N'0:0:0:0:0:0:0:1', 1, N'elon');
INSERT INTO [dbo].[login_attempts] ([id], [attempt_time], [ip_address], [successful], [username]) VALUES (46, N'2026-10-23 12:23:15.367715', N'0:0:0:0:0:0:0:1', 1, N'elon');
SET IDENTITY_INSERT [dbo].[login_attempts] OFF;

COMMIT TRANSACTION;
GO

/* ---------- 4. Llaves foráneas (se crean después de la carga) ---------- */
ALTER TABLE [dbo].[comprobante] ADD CONSTRAINT [FKhl00i8fyu1avokxflxsv3aygq] FOREIGN KEY ([registro_id]) REFERENCES [dbo].[registro] ([id]);
ALTER TABLE [dbo].[consumo] ADD CONSTRAINT [FKc0b9ttddssx7idxnrv2gek9vo] FOREIGN KEY ([producto_consumo_id]) REFERENCES [dbo].[producto_consumo] ([id]);
ALTER TABLE [dbo].[consumo] ADD CONSTRAINT [FKgp6py4ydstf8voa6if4b9r1ha] FOREIGN KEY ([registro_id]) REFERENCES [dbo].[registro] ([id]);
ALTER TABLE [dbo].[habitacion] ADD CONSTRAINT [FKmlrva0wqqhpr6xg0fkx7muy4u] FOREIGN KEY ([categoria_id]) REFERENCES [dbo].[categoria] ([id]);
ALTER TABLE [dbo].[password_reset_token] ADD CONSTRAINT [FKaehv7qqwsde87cy79hxhy4lke] FOREIGN KEY ([usuario_id]) REFERENCES [dbo].[usuario] ([id]);
ALTER TABLE [dbo].[registro] ADD CONSTRAINT [FK101aahenl319n647ge5763uyc] FOREIGN KEY ([reserva_id]) REFERENCES [dbo].[reserva] ([id]);
ALTER TABLE [dbo].[registro] ADD CONSTRAINT [FK8jlgra1srn0uxvlxba7swgtlw] FOREIGN KEY ([habitacion_id]) REFERENCES [dbo].[habitacion] ([id]);
ALTER TABLE [dbo].[registro] ADD CONSTRAINT [FKhhvhc05dls8gcil8hfr4yvw18] FOREIGN KEY ([cliente_id]) REFERENCES [dbo].[cliente] ([id]);
ALTER TABLE [dbo].[registro] ADD CONSTRAINT [FKqfbdwuu2isbwwnx1uky39930w] FOREIGN KEY ([usuario_id]) REFERENCES [dbo].[usuario] ([id]);
ALTER TABLE [dbo].[reserva] ADD CONSTRAINT [FK7cg2jiyn5cf6f6elccvb6963k] FOREIGN KEY ([cliente_id]) REFERENCES [dbo].[cliente] ([id]);
ALTER TABLE [dbo].[reserva] ADD CONSTRAINT [FKiad9w96t12u3ms2ul93l97mel] FOREIGN KEY ([usuario_id]) REFERENCES [dbo].[usuario] ([id]);
ALTER TABLE [dbo].[usuarios_roles] ADD CONSTRAINT [FK6yxg1lhuv5nievqea7rvn6afm] FOREIGN KEY ([rol_id]) REFERENCES [dbo].[rol] ([id]);
ALTER TABLE [dbo].[usuarios_roles] ADD CONSTRAINT [FKebiaxjbamgu326glxo1fbysuh] FOREIGN KEY ([usuario_id]) REFERENCES [dbo].[usuario] ([id]);
GO

/* ---------- 5. Continuar los IDs donde los dejó MySQL ---------- */
DBCC CHECKIDENT ('dbo.categoria', RESEED, 6) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.cliente', RESEED, 165) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.comprobante', RESEED, 4) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.consumo', RESEED, 36) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.habitacion', RESEED, 999) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.login_attempts', RESEED, 46) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.producto_consumo', RESEED, 7) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.registro', RESEED, 70) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.usuario', RESEED, 19) WITH NO_INFOMSGS;
GO

/* ---------- 6. Verificación ---------- */
SELECT t.tabla, t.esperadas, ISNULL(r.filas, 0) AS cargadas,
       CASE WHEN t.esperadas = ISNULL(r.filas, 0) THEN 'OK' ELSE 'REVISAR' END AS estado
FROM (VALUES
    (N'categoria', 6),
    (N'cliente', 162),
    (N'comprobante', 4),
    (N'consumo', 32),
    (N'habitacion', 45),
    (N'login_attempts', 46),
    (N'password_reset_token', 0),
    (N'producto_consumo', 5),
    (N'registro', 60),
    (N'reserva', 0),
    (N'rol', 0),
    (N'usuario', 9),
    (N'usuarios_roles', 0)
) AS t(tabla, esperadas)
LEFT JOIN (
    SELECT o.name AS tabla, SUM(p.rows) AS filas
    FROM sys.objects o JOIN sys.partitions p ON p.object_id = o.object_id AND p.index_id IN (0, 1)
    WHERE o.type = 'U' GROUP BY o.name
) AS r ON r.tabla = t.tabla
ORDER BY t.tabla;
GO
