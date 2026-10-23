-- =====================================================================
-- BASE DE DATOS ALQUILER - Sistema Estadía (SQL Server)
-- Crea la base, sus tablas y carga todos los datos en una sola ejecución (F5).
-- =====================================================================
SET NOCOUNT ON
GO

USE master
GO

if exists (select * from sysdatabases where name='alquiler')
		drop database alquiler
go

create database alquiler
go
USE alquiler
go
set dateformat ymd
go


-- Categorías de habitación
CREATE TABLE categoria (
    id                    INT IDENTITY(1,1) NOT NULL,
    descripcion           VARCHAR(255),
    nombre                VARCHAR(255),
    precio                FLOAT NOT NULL,
    slug                  VARCHAR(255),
    url_imagen            VARCHAR(255),
    precio_temporada_alta FLOAT,
    temporada_alta_fin    DATETIME2(6),
    temporada_alta_inicio DATETIME2(6),
    CONSTRAINT PK_categoria PRIMARY KEY (id)
)
go

SET IDENTITY_INSERT categoria ON
INSERT INTO categoria (id, descripcion, nombre, precio, slug, url_imagen, precio_temporada_alta, temporada_alta_fin, temporada_alta_inicio) VALUES(1, 'Cama queen, baño propio, agua caliente 24h, TV cable, wifi y parlante Alexa. Vista a la piscina y áreas verdes.', 'Habitación Matrimonial', 180, 'habitacion-matrimonial', 'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', NULL, NULL, NULL)
INSERT INTO categoria (id, descripcion, nombre, precio, slug, url_imagen, precio_temporada_alta, temporada_alta_fin, temporada_alta_inicio) VALUES(2, 'Acabados en madera de la zona, baño privado, agua caliente 24h, wifi y parlante Alexa. Vista panorámica a la Plaza de Armas de Oxapampa.', 'Habitación Familiar (3 personas)', 220, 'habitacion-familiar-3-personas', 'https://www.tunkilodge.com/imagenes/habitacionfamiliar3personas.png', NULL, NULL, NULL)
INSERT INTO categoria (id, descripcion, nombre, precio, slug, url_imagen, precio_temporada_alta, temporada_alta_fin, temporada_alta_inicio) VALUES(3, 'Bungalow 100% en madera, 1 cama matrimonial y 2 de plaza y media, baño propio, agua caliente 24h.', 'Habitación Familiar (4 personas)', 260, 'habitacion-familiar-4-personas', 'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', NULL, NULL, NULL)
INSERT INTO categoria (id, descripcion, nombre, precio, slug, url_imagen, precio_temporada_alta, temporada_alta_fin, temporada_alta_inicio) VALUES(4, '1 cama matrimonial y 4 camas individuales, baño propio, agua caliente, wifi y TV cable. Vista a la plaza y la campiña oxapampina.', 'Habitación 5-6 Personas', 320, 'habitacion-5-6-personas', 'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', NULL, NULL, NULL)
INSERT INTO categoria (id, descripcion, nombre, precio, slug, url_imagen, precio_temporada_alta, temporada_alta_fin, temporada_alta_inicio) VALUES(5, '1 cama matrimonial y 2 camarotes, baño con ducha española, agua caliente 24h, smart TV y wifi en amplias áreas verdes.', 'Domo Colibrí', 350, 'domo-colibri', 'https://www.tunkilodge.com/imagenes/domo.jpeg', NULL, NULL, NULL)
INSERT INTO categoria (id, descripcion, nombre, precio, slug, url_imagen, precio_temporada_alta, temporada_alta_fin, temporada_alta_inicio) VALUES(6, 'Cabaña histórica de colonos austro-alemanes con más de 90 años, 4 habitaciones y 2 baños completos. Acceso a piscina y áreas de juegos.', 'Cabaña Bungalow (8-10 personas)', 450, 'cabana-bungalow-8-10-personas', '/carrusel-login/foto-4.jpg', 550, '2027-01-15 00:00:00.000000', '2026-12-15 00:00:00.000000')
SET IDENTITY_INSERT categoria OFF
go


-- Clientes (huéspedes)
CREATE TABLE cliente (
    id               INT IDENTITY(1,1) NOT NULL,
    apellidos        VARCHAR(255),
    ciudad           VARCHAR(255),
    correo           VARCHAR(255),
    fecha_nacimiento DATETIME2(6),
    identificacion   VARCHAR(255),
    nombres          VARCHAR(255),
    ocupacion        VARCHAR(255),
    pais             VARCHAR(255),
    telefono         VARCHAR(255),
    tipo_documento   VARCHAR(255),
    CONSTRAINT PK_cliente PRIMARY KEY (id)
)
go

SET IDENTITY_INSERT cliente ON
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(1, 'Salazar Vega', 'Lima', 'andrea.salazar@gmail.com', '1992-03-11 00:00:00.000000', '41234567', 'Andrea', 'Diseñadora UX', 'Perú', '945112233', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(2, 'Castillo Paredes', 'Arequipa', 'renzo.castillo@gmail.com', '1988-07-22 00:00:00.000000', '42345678', 'Renzo', 'Contador', 'Perú', '956223344', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(3, 'Guzmán Torres', 'Lima', 'fiorella.guzman@gmail.com', '1995-01-30 00:00:00.000000', '43456789', 'Fiorella', 'Abogada', 'Perú', '967334455', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(4, 'Chávez Ríos', 'Huánuco', 'esteban.chavez@gmail.com', '1985-09-14 00:00:00.000000', '44567890', 'Esteban', 'Comerciante', 'Perú', '978445566', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(5, 'Paredes Luna', 'Lima', 'milagros.paredes@gmail.com', '1990-11-02 00:00:00.000000', '45678901', 'Milagros', 'Médica', 'Perú', '989556677', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(6, 'Rivas Medina', 'Cusco', 'gonzalo.rivas@gmail.com', '1993-05-18 00:00:00.000000', '46789012', 'Gonzalo', 'Ingeniero', 'Perú', '912667788', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(7, 'Delgado Soto', 'Lima', 'ximena.delgado@gmail.com', '1991-12-25 00:00:00.000000', '47890123', 'Ximena', 'Profesora', 'Perú', '923778899', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(8, 'Aranda Campos', 'Trujillo', 'bruno.aranda@gmail.com', '1987-04-09 00:00:00.000000', '48901234', 'Bruno', 'Arquitecto', 'Perú', '934889900', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(9, 'Núñez Herrera', 'Lima', 'camila.nunez@gmail.com', '1994-08-07 00:00:00.000000', '49012345', 'Camila', 'Psicóloga', 'Perú', '945990011', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(10, 'Pérez Rondón', 'Lima', 'valentina.perez@gmail.com', '1994-06-20 00:00:00.000000', '001234567', 'Valentina', 'Enfermera', 'Perú', '978112233', 'CARNE_EXTRANJERIA')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(12, 'Fernandes Souza', 'Lima', 'thiago.fernandes@gmail.com', '1991-10-05 00:00:00.000000', '001345678', 'Thiago', 'Chef', 'Perú', '989223344', 'CARNE_EXTRANJERIA')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(13, 'Martin', 'París', 'sophie.martin@gmail.com', '1996-02-14 00:00:00.000000', '19FR45678', 'Sophie', 'Fotógrafa', 'Francia', '998334455', 'PASAPORTE')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(14, 'Mendoza Castillo', 'Cajamarca', 'pedro.mendoza28@gmail.com', '1969-06-13 00:00:00.000000', '13337116', 'Pedro', 'Contador', 'Perú', '961881023', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(15, 'Fernández Ramos', 'Trujillo', 'jorge.fernandez91@gmail.com', '1990-11-12 00:00:00.000000', '48008803', 'Jorge', 'Médico', 'Perú', '972179148', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(16, 'Núñez Herrera', 'Huancayo', 'jose.nuñez23@gmail.com', '1967-06-15 00:00:00.000000', '45807472', 'José', 'Diseñador', 'Perú', '942206376', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(17, 'Ortiz Reyes', 'Cajamarca', 'luis.ortiz93@gmail.com', '1991-12-09 00:00:00.000000', '73190837', 'Luis', 'Programador', 'Perú', '965067214', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(18, 'Mendoza Quispe', 'Cajamarca', 'carmen.mendoza72@gmail.com', '1965-12-20 00:00:00.000000', '36105014', 'Carmen', 'Periodista', 'Perú', '963894841', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(19, 'García Flores', 'Cajamarca', 'maria.garcia11@gmail.com', '1991-04-02 00:00:00.000000', '37685718', 'María', 'Chef', 'Perú', '980435341', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(20, 'Flores Sánchez', 'Ica', 'diana.flores12@gmail.com', '1985-05-09 00:00:00.000000', '11183708', 'Diana', 'Estudiante', 'Perú', '967526955', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(21, 'Salazar Vargas', 'Ica', 'sergio.salazar5@gmail.com', '1973-11-25 00:00:00.000000', '26752287', 'Sergio', 'Estudiante', 'Perú', '921364822', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(22, 'Romero Díaz', 'Huánuco', 'jorge.romero14@gmail.com', '1975-04-03 00:00:00.000000', '50597279', 'Jorge', 'Contador', 'Perú', '945738162', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(23, 'Torres Martínez', 'Oxapampa', 'lourdes.torres53@gmail.com', '1988-06-13 00:00:00.000000', '75026997', 'Lourdes', 'Técnico', 'Perú', '978301425', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(24, 'Quispe Ortiz', 'Puno', 'carlos.quispe21@gmail.com', '1971-06-03 00:00:00.000000', '75510509', 'Carlos', 'Diseñador', 'Perú', '971659953', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(25, 'Sánchez Vargas', 'Puno', 'milagros.sanchez52@gmail.com', '2005-08-21 00:00:00.000000', '15300111', 'Milagros', 'Estudiante', 'Perú', '999125475', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(26, 'Chávez Chávez', 'Cajamarca', 'silvia.chavez72@gmail.com', '1992-04-26 00:00:00.000000', '47656613', 'Silvia', 'Arquitecto', 'Perú', '968698668', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(27, 'Gutiérrez Martínez', 'Oxapampa', 'miguel.gutierrez77@gmail.com', '1987-03-13 00:00:00.000000', '56805206', 'Miguel', 'Chef', 'Perú', '983507605', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(28, 'Castillo Castillo', 'Iquitos', 'pedro.castillo33@gmail.com', '2001-11-09 00:00:00.000000', '36756434', 'Pedro', 'Arquitecto', 'Perú', '950703431', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(29, 'Medina Ortiz', 'Iquitos', 'sandra.medina98@gmail.com', '1985-03-01 00:00:00.000000', '16490038', 'Sandra', 'Técnico', 'Perú', '950306011', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(30, 'Flores Medina', 'Huánuco', 'patricia.flores73@gmail.com', '1985-09-09 00:00:00.000000', '53884514', 'Patricia', 'Chef', 'Perú', '926203466', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(31, 'Sánchez Rojas', 'Piura', 'ricardo.sanchez28@gmail.com', '2001-02-19 00:00:00.000000', '65738102', 'Ricardo', 'Enfermera', 'Perú', '970228157', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(32, 'Mendoza Gómez', 'Chiclayo', 'rosa.mendoza32@gmail.com', '1973-03-21 00:00:00.000000', '37878238', 'Rosa', 'Periodista', 'Perú', '925376594', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(33, 'Castillo Salazar', 'Piura', 'luz.castillo46@gmail.com', '1976-03-24 00:00:00.000000', '44455849', 'Luz', 'Enfermera', 'Perú', '971597495', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(34, 'Aguilar Medina', 'Ica', 'karen.aguilar67@gmail.com', '1985-07-18 00:00:00.000000', '65414213', 'Karen', 'Diseñador', 'Perú', '977266658', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(35, 'Paredes Fernández', 'Cusco', 'jose.paredes81@gmail.com', '1993-11-28 00:00:00.000000', '30502371', 'José', 'Médico', 'Perú', '911426255', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(36, 'Martínez Gutiérrez', 'Chiclayo', 'milagros.martinez4@gmail.com', '1986-12-28 00:00:00.000000', '70141304', 'Milagros', 'Chef', 'Perú', '937787797', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(37, 'Fernández Cruz', 'Arequipa', 'pedro.fernandez38@gmail.com', '1992-10-08 00:00:00.000000', '30979393', 'Pedro', 'Diseñador', 'Perú', '944999145', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(38, 'Romero Ramos', 'Lima', 'alejandro.romero89@gmail.com', '1996-06-01 00:00:00.000000', '62650287', 'Alejandro', 'Docente', 'Perú', '943698072', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(39, 'Mendoza Rojas', 'Tacna', 'karen.mendoza71@gmail.com', '2002-12-02 00:00:00.000000', '10368346', 'Karen', 'Docente', 'Perú', '912671815', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(40, 'Castillo Reyes', 'Lima', 'lourdes.castillo94@gmail.com', '1980-05-12 00:00:00.000000', '23552682', 'Lourdes', 'Vendedor', 'Perú', '914907608', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(41, 'Salazar Gómez', 'Tacna', 'silvia.salazar41@gmail.com', '1988-12-27 00:00:00.000000', '48815126', 'Silvia', 'Arquitecto', 'Perú', '970028702', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(42, 'Reyes Romero', 'Iquitos', 'katherine.reyes40@gmail.com', '1970-08-06 00:00:00.000000', '38532523', 'Katherine', 'Comerciante', 'Perú', '916348373', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(43, 'Martínez Ortiz', 'Puno', 'vanessa.martinez60@gmail.com', '1986-04-16 00:00:00.000000', '18713439', 'Vanessa', 'Administrador', 'Perú', '980872688', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(44, 'Gutiérrez Gutiérrez', 'Arequipa', 'jessica.gutierrez4@gmail.com', '1971-03-12 00:00:00.000000', '57597889', 'Jéssica', 'Programador', 'Perú', '972343189', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(45, 'Herrera Ramos', 'Cajamarca', 'sandra.herrera56@gmail.com', '2002-07-09 00:00:00.000000', '40215069', 'Sandra', 'Administrador', 'Perú', '961211623', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(46, 'Núñez Medina', 'Trujillo', 'sandra.nuñez2@gmail.com', '1978-02-22 00:00:00.000000', '14539791', 'Sandra', 'Docente', 'Perú', '911938972', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(47, 'Gutiérrez Torres', 'Puno', 'fernando.gutierrez78@gmail.com', '2004-03-24 00:00:00.000000', '54489262', 'Fernando', 'Chef', 'Perú', '955140043', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(48, 'Chávez Paredes', 'Huancayo', 'jorge.chavez6@gmail.com', '1988-08-11 00:00:00.000000', '17566278', 'Jorge', 'Diseñador', 'Perú', '991129471', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(49, 'Castillo Ramos', 'Lima', 'diego.castillo42@gmail.com', '2005-04-26 00:00:00.000000', '16085248', 'Diego', 'Comerciante', 'Perú', '964114054', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(50, 'Salazar Gómez', 'Huánuco', 'patricia.salazar44@gmail.com', '1970-01-27 00:00:00.000000', '78589058', 'Patricia', 'Administrador', 'Perú', '918757672', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(51, 'Ortiz Gutiérrez', 'Cusco', 'silvia.ortiz85@gmail.com', '1995-02-05 00:00:00.000000', '23455290', 'Silvia', 'Médico', 'Perú', '994366783', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(52, 'Ortiz Torres', 'Oxapampa', 'alejandro.ortiz61@gmail.com', '1972-04-10 00:00:00.000000', '32074967', 'Alejandro', 'Contador', 'Perú', '959288400', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(53, 'Flores Gonzáles', 'Puno', 'patricia.flores72@gmail.com', '1988-02-09 00:00:00.000000', '78764631', 'Patricia', 'Enfermera', 'Perú', '930838531', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(54, 'López López', 'Cusco', 'jose.lopez29@gmail.com', '1992-10-26 00:00:00.000000', '30737167', 'José', 'Periodista', 'Perú', '990188528', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(55, 'Torres Fernández', 'Arequipa', 'silvia.torres47@gmail.com', '1965-10-17 00:00:00.000000', '65976728', 'Silvia', 'Programador', 'Perú', '912822774', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(56, 'Fernández Gonzáles', 'Pucallpa', 'katherine.fernandez4@gmail.com', '1977-09-21 00:00:00.000000', '76258418', 'Katherine', 'Ingeniero', 'Perú', '989237688', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(57, 'Mendoza Gonzáles', 'Iquitos', 'vanessa.mendoza31@gmail.com', '2002-04-10 00:00:00.000000', '29848090', 'Vanessa', 'Técnico', 'Perú', '976816536', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(58, 'Reyes Gómez', 'Huancayo', 'alberto.reyes42@gmail.com', '1976-09-14 00:00:00.000000', '50434050', 'Alberto', 'Técnico', 'Perú', '958368457', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(59, 'Gutiérrez Fernández', 'Trujillo', 'silvia.gutierrez89@gmail.com', '1968-04-14 00:00:00.000000', '50325919', 'Silvia', 'Docente', 'Perú', '981106552', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(60, 'Cruz Chávez', 'Trujillo', 'silvia.cruz2@gmail.com', '1978-06-04 00:00:00.000000', '47504085', 'Silvia', 'Chef', 'Perú', '912126129', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(61, 'Ortiz Gutiérrez', 'Chiclayo', 'marco.ortiz72@gmail.com', '1993-01-18 00:00:00.000000', '58309640', 'Marco', 'Diseñador', 'Perú', '978451328', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(62, 'Mendoza Herrera', 'Iquitos', 'giuliana.mendoza3@gmail.com', '1985-01-19 00:00:00.000000', '61936371', 'Giuliana', 'Diseñador', 'Perú', '978961517', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(63, 'Aguilar Cruz', 'Trujillo', 'jessica.aguilar52@gmail.com', '1971-09-08 00:00:00.000000', '13373823', 'Jéssica', 'Programador', 'Perú', '923751674', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(64, 'Rojas Romero', 'Trujillo', 'maria.rojas66@gmail.com', '1984-12-08 00:00:00.000000', '79435383', 'María', 'Técnico', 'Perú', '953232917', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(65, 'Mendoza Cruz', 'Huánuco', 'milagros.mendoza81@gmail.com', '1999-09-09 00:00:00.000000', '58832350', 'Milagros', 'Abogado', 'Perú', '921048234', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(66, 'Herrera López', 'Iquitos', 'rosa.herrera46@gmail.com', '2001-10-19 00:00:00.000000', '39860765', 'Rosa', 'Arquitecto', 'Perú', '934800750', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(67, 'Torres Rodríguez', 'Huancayo', 'raul.torres87@gmail.com', '2005-10-01 00:00:00.000000', '39511742', 'Raúl', 'Arquitecto', 'Perú', '961638996', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(68, 'Ramos Flores', 'Iquitos', 'estefania.ramos29@gmail.com', '1976-05-28 00:00:00.000000', '72993790', 'Estefanía', 'Docente', 'Perú', '948069031', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(69, 'Herrera Quispe', 'Oxapampa', 'victor.herrera89@gmail.com', '1975-05-01 00:00:00.000000', '26613178', 'Víctor', 'Docente', 'Perú', '980749609', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(70, 'Medina Reyes', 'Piura', 'ivan.medina46@gmail.com', '1971-04-18 00:00:00.000000', '27182732', 'Iván', 'Comerciante', 'Perú', '925769971', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(71, 'Salazar López', 'Oxapampa', 'ricardo.salazar89@gmail.com', '1992-06-23 00:00:00.000000', '52499677', 'Ricardo', 'Contador', 'Perú', '917197583', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(72, 'Romero Salazar', 'Cusco', 'maria.romero97@gmail.com', '2005-01-28 00:00:00.000000', '75177712', 'María', 'Periodista', 'Perú', '943206133', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(73, 'Núñez Rojas', 'Arequipa', 'alejandro.nuñez91@gmail.com', '1984-08-25 00:00:00.000000', '67261539', 'Alejandro', 'Arquitecto', 'Perú', '980591961', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(74, 'Gonzáles Gómez', 'Iquitos', 'luis.gonzales26@gmail.com', '1969-03-21 00:00:00.000000', '45800177', 'Luis', 'Técnico', 'Perú', '929314844', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(75, 'Chávez Núñez', 'Trujillo', 'veronica.chavez84@gmail.com', '2003-07-05 00:00:00.000000', '60767090', 'Verónica', 'Vendedor', 'Perú', '995095882', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(76, 'Castillo Gómez', 'Cajamarca', 'monica.castillo2@gmail.com', '1977-11-15 00:00:00.000000', '10663326', 'Mónica', 'Programador', 'Perú', '918176893', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(77, 'Torres Medina', 'Iquitos', 'jessica.torres49@gmail.com', '1969-05-26 00:00:00.000000', '65721934', 'Jéssica', 'Ingeniero', 'Perú', '921569436', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(78, 'Romero García', 'Oxapampa', 'jessica.romero99@gmail.com', '1996-02-08 00:00:00.000000', '33928134', 'Jéssica', 'Abogado', 'Perú', '939773679', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(79, 'Herrera Herrera', 'Lima', 'lourdes.herrera91@gmail.com', '1984-11-11 00:00:00.000000', '35117253', 'Lourdes', 'Enfermera', 'Perú', '913839169', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(80, 'Gonzáles Torres', 'Huánuco', 'vanessa.gonzales12@gmail.com', '1998-12-05 00:00:00.000000', '41338586', 'Vanessa', 'Administrador', 'Perú', '935430838', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(81, 'López Rodríguez', 'Ica', 'monica.lopez25@gmail.com', '1981-01-11 00:00:00.000000', '16309823', 'Mónica', 'Abogado', 'Perú', '933553828', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(82, 'Ramos Gómez', 'Tacna', 'martin.ramos90@gmail.com', '1989-11-02 00:00:00.000000', '24623112', 'Martín', 'Vendedor', 'Perú', '995172269', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(83, 'Sánchez Pérez', 'Huánuco', 'giuliana.sanchez5@gmail.com', '1980-05-07 00:00:00.000000', '41381732', 'Giuliana', 'Docente', 'Perú', '997555759', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(84, 'Ortiz Flores', 'Arequipa', 'francisco.ortiz76@gmail.com', '1972-09-11 00:00:00.000000', '53198505', 'Francisco', 'Programador', 'Perú', '980073073', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(85, 'Rodríguez Ramos', 'Tacna', 'sergio.rodriguez44@gmail.com', '1985-05-09 00:00:00.000000', '55312507', 'Sergio', 'Comerciante', 'Perú', '984526238', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(86, 'Aguilar Mendoza', 'Arequipa', 'carmen.aguilar72@gmail.com', '1984-04-12 00:00:00.000000', '64240721', 'Carmen', 'Estudiante', 'Perú', '958021421', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(87, 'Ramos Herrera', 'Iquitos', 'jose.ramos59@gmail.com', '1978-04-18 00:00:00.000000', '28429120', 'José', 'Enfermera', 'Perú', '922312565', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(88, 'Romero Salazar', 'Huánuco', 'milagros.romero1@gmail.com', '1986-08-14 00:00:00.000000', '74277701', 'Milagros', 'Administrador', 'Perú', '931663084', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(89, 'Rodríguez Ramos', 'Piura', 'jose.rodriguez17@gmail.com', '1988-08-15 00:00:00.000000', '21178357', 'José', 'Comerciante', 'Perú', '965189811', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(90, 'Castillo Aguilar', 'Tacna', 'victor.castillo4@gmail.com', '1973-10-02 00:00:00.000000', '22342533', 'Víctor', 'Médico', 'Perú', '935309786', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(91, 'Flores Castillo', 'Tacna', 'rodrigo.flores9@gmail.com', '1974-04-20 00:00:00.000000', '75364582', 'Rodrigo', 'Programador', 'Perú', '930118112', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(92, 'Castillo Medina', 'Oxapampa', 'victor.castillo80@gmail.com', '1974-03-19 00:00:00.000000', '71512698', 'Víctor', 'Ingeniero', 'Perú', '920329781', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(93, 'Díaz Martínez', 'Tacna', 'pedro.diaz74@gmail.com', '1984-12-26 00:00:00.000000', '37008571', 'Pedro', 'Vendedor', 'Perú', '985402935', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(94, 'Quispe Gómez', 'Oxapampa', 'sergio.quispe54@gmail.com', '1977-09-18 00:00:00.000000', '69167925', 'Sergio', 'Comerciante', 'Perú', '943163616', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(95, 'García Rojas', 'Ica', 'yolanda.garcia36@gmail.com', '1988-09-28 00:00:00.000000', '73582441', 'Yolanda', 'Programador', 'Perú', '998017382', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(96, 'Martínez Fernández', 'Cajamarca', 'maria.martinez17@gmail.com', '1977-12-18 00:00:00.000000', '75365084', 'María', 'Comerciante', 'Perú', '915904042', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(97, 'Martínez Herrera', 'Arequipa', 'rosa.martinez57@gmail.com', '1979-02-01 00:00:00.000000', '28339573', 'Rosa', 'Médico', 'Perú', '948574225', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(98, 'Martínez Salazar', 'Oxapampa', 'raul.martinez51@gmail.com', '1983-11-10 00:00:00.000000', '33302636', 'Raúl', 'Enfermera', 'Perú', '948364090', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(99, 'Fernández Gutiérrez', 'Tacna', 'ana.fernandez13@gmail.com', '2004-07-24 00:00:00.000000', '40908977', 'Ana', 'Médico', 'Perú', '980285482', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(100, 'Pérez Quispe', 'Cajamarca', 'marco.perez68@gmail.com', '1993-06-28 00:00:00.000000', '45234557', 'Marco', 'Chef', 'Perú', '957007127', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(101, 'Gonzáles Gómez', 'Huancayo', 'diego.gonzales99@gmail.com', '1974-03-13 00:00:00.000000', '54080003', 'Diego', 'Docente', 'Perú', '957106319', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(102, 'Rodríguez Salazar', 'Trujillo', 'pedro.rodriguez34@gmail.com', '1990-07-01 00:00:00.000000', '58589158', 'Pedro', 'Chef', 'Perú', '942263944', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(103, 'Mendoza García', 'Piura', 'sandra.mendoza92@gmail.com', '1967-01-02 00:00:00.000000', '52402376', 'Sandra', 'Vendedor', 'Perú', '975241418', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(104, 'Martínez Quispe', 'Tacna', 'ana.martinez86@gmail.com', '1992-08-15 00:00:00.000000', '65724211', 'Ana', 'Diseñador', 'Perú', '928557310', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(105, 'Sánchez Reyes', 'Arequipa', 'raul.sanchez56@gmail.com', '1966-10-07 00:00:00.000000', '74619313', 'Raúl', 'Contador', 'Perú', '961313340', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(106, 'Romero Chávez', 'Chiclayo', 'diana.romero48@gmail.com', '1982-01-14 00:00:00.000000', '41977517', 'Diana', 'Chef', 'Perú', '948122882', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(107, 'Ortiz Ortiz', 'Cajamarca', 'eduardo.ortiz41@gmail.com', '1970-05-28 00:00:00.000000', '19030609', 'Eduardo', 'Docente', 'Perú', '952981272', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(108, 'Núñez Torres', 'Cusco', 'diego.nuñez56@gmail.com', '1998-05-03 00:00:00.000000', '37712954', 'Diego', 'Enfermera', 'Perú', '929725493', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(109, 'Rodríguez Rojas', 'Iquitos', 'luz.rodriguez48@gmail.com', '2001-11-16 00:00:00.000000', '33296990', 'Luz', 'Enfermera', 'Perú', '967116103', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(110, 'Quispe Salazar', 'Chiclayo', 'lourdes.quispe88@gmail.com', '1987-12-21 00:00:00.000000', '17592189', 'Lourdes', 'Arquitecto', 'Perú', '952209829', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(111, 'Torres Castillo', 'Lima', 'martin.torres6@gmail.com', '1972-04-11 00:00:00.000000', '63850849', 'Martín', 'Médico', 'Perú', '959281270', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(112, 'Mendoza Ramos', 'Puno', 'maria.mendoza88@gmail.com', '1998-06-13 00:00:00.000000', '31134191', 'María', 'Enfermera', 'Perú', '929889481', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(113, 'Flores Cruz', 'Cajamarca', 'patricia.flores89@gmail.com', '1978-04-02 00:00:00.000000', '21239468', 'Patricia', 'Chef', 'Perú', '926748702', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(114, 'Gómez Torres', 'Cajamarca', 'rosa.gomez64@gmail.com', '1993-10-14 00:00:00.000000', '55142339', 'Rosa', 'Chef', 'Perú', '957002151', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(115, 'López Aguilar', 'Chiclayo', 'alberto.lopez16@gmail.com', '1970-04-16 00:00:00.000000', '18024728', 'Alberto', 'Administrador', 'Perú', '926284327', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(116, 'Chávez Reyes', 'Huancayo', 'silvia.chavez26@gmail.com', '1967-07-08 00:00:00.000000', '69544442', 'Silvia', 'Diseñador', 'Perú', '940034598', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(117, 'Ramos Ramos', 'Cajamarca', 'carlos.ramos28@gmail.com', '1971-12-19 00:00:00.000000', '65515700', 'Carlos', 'Administrador', 'Perú', '947320396', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(118, 'Fernández Paredes', 'Chiclayo', 'miguel.fernandez56@gmail.com', '1971-08-07 00:00:00.000000', '33532571', 'Miguel', 'Enfermera', 'Perú', '931642564', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(119, 'Mendoza Fernández', 'Iquitos', 'alejandro.mendoza79@gmail.com', '2002-09-10 00:00:00.000000', '63455673', 'Alejandro', 'Enfermera', 'Perú', '953210027', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(120, 'García Rojas', 'Lima', 'sandra.garcia71@gmail.com', '1973-10-24 00:00:00.000000', '52542544', 'Sandra', 'Administrador', 'Perú', '935422410', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(121, 'Castillo Sánchez', 'Chiclayo', 'pedro.castillo36@gmail.com', '1997-07-09 00:00:00.000000', '73449253', 'Pedro', 'Docente', 'Perú', '976204972', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(122, 'Martínez Cruz', 'Lima', 'sergio.martinez23@gmail.com', '1978-01-19 00:00:00.000000', '40258675', 'Sergio', 'Ingeniero', 'Perú', '999047278', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(123, 'Gómez Ramos', 'Tacna', 'alberto.gomez21@gmail.com', '2000-03-16 00:00:00.000000', '68684362', 'Alberto', 'Programador', 'Perú', '954351854', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(124, 'Ramos Cruz', 'Piura', 'miguel.ramos57@gmail.com', '1992-05-11 00:00:00.000000', '32411265', 'Miguel', 'Diseñador', 'Perú', '942177634', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(125, 'Chávez Díaz', 'Lima', 'alejandro.chavez45@gmail.com', '1974-11-15 00:00:00.000000', '59103254', 'Alejandro', 'Abogado', 'Perú', '913959211', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(126, 'García Paredes', 'Cajamarca', 'pamela.garcia43@gmail.com', '1983-04-27 00:00:00.000000', '78038431', 'Pamela', 'Arquitecto', 'Perú', '912758699', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(127, 'Díaz Medina', 'Pucallpa', 'monica.diaz99@gmail.com', '1975-07-03 00:00:00.000000', '79833947', 'Mónica', 'Abogado', 'Perú', '999157188', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(128, 'Romero Pérez', 'Iquitos', 'veronica.romero42@gmail.com', '1980-06-10 00:00:00.000000', '67380916', 'Verónica', 'Médico', 'Perú', '930352594', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(129, 'Gómez Vargas', 'Ica', 'rodrigo.gomez34@gmail.com', '1986-11-20 00:00:00.000000', '60375589', 'Rodrigo', 'Contador', 'Perú', '969192773', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(130, 'Rodríguez Díaz', 'Arequipa', 'jessica.rodriguez61@gmail.com', '1996-07-19 00:00:00.000000', '67062358', 'Jéssica', 'Administrador', 'Perú', '930146059', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(131, 'Reyes Chávez', 'Chiclayo', 'marco.reyes16@gmail.com', '1973-02-04 00:00:00.000000', '65465338', 'Marco', 'Periodista', 'Perú', '947502923', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(132, 'Díaz Rojas', 'Lima', 'monica.diaz55@gmail.com', '1986-02-20 00:00:00.000000', '61919684', 'Mónica', 'Médico', 'Perú', '983086211', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(133, 'García Rojas', 'Iquitos', 'pedro.garcia99@gmail.com', '1971-11-20 00:00:00.000000', '34953093', 'Pedro', 'Estudiante', 'Perú', '969354808', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(134, 'Núñez Gutiérrez', 'Trujillo', 'estefania.nuñez66@gmail.com', '1979-11-11 00:00:00.000000', '18980105', 'Estefanía', 'Chef', 'Perú', '919798851', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(135, 'Gutiérrez Torres', 'Huancayo', 'silvia.gutierrez93@gmail.com', '1977-04-12 00:00:00.000000', '59165423', 'Silvia', 'Técnico', 'Perú', '962242662', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(136, 'Quispe Paredes', 'Trujillo', 'luis.quispe56@gmail.com', '2000-05-28 00:00:00.000000', '53955451', 'Luis', 'Vendedor', 'Perú', '967467825', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(137, 'Mendoza García', 'Pucallpa', 'ivan.mendoza4@gmail.com', '1975-04-25 00:00:00.000000', '39517195', 'Iván', 'Periodista', 'Perú', '920483922', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(138, 'Reyes Díaz', 'Puno', 'katherine.reyes24@gmail.com', '1966-11-08 00:00:00.000000', '64321531', 'Katherine', 'Diseñador', 'Perú', '941894586', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(139, 'Vargas Chávez', 'Huancayo', 'jose.vargas1@gmail.com', '1984-02-12 00:00:00.000000', '47831004', 'José', 'Abogado', 'Perú', '921757416', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(140, 'Díaz Romero', 'Huánuco', 'rodrigo.diaz64@gmail.com', '1986-12-14 00:00:00.000000', '49153728', 'Rodrigo', 'Estudiante', 'Perú', '953189688', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(141, 'Aguilar Núñez', 'Lima', 'luz.aguilar5@gmail.com', '1969-12-11 00:00:00.000000', '28245372', 'Luz', 'Abogado', 'Perú', '959176269', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(142, 'García Chávez', 'Cusco', 'fernando.garcia40@gmail.com', '1973-11-05 00:00:00.000000', '75675194', 'Fernando', 'Programador', 'Perú', '940564026', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(143, 'Paredes Flores', 'Piura', 'katherine.paredes65@gmail.com', '1978-07-14 00:00:00.000000', '37457307', 'Katherine', 'Administrador', 'Perú', '959284439', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(144, 'Vargas Sánchez', 'Huancayo', 'maria.vargas57@gmail.com', '1994-03-19 00:00:00.000000', '56953116', 'María', 'Programador', 'Perú', '940153432', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(145, 'Ramos Díaz', 'Cajamarca', 'elena.ramos39@gmail.com', '1999-10-08 00:00:00.000000', '15584467', 'Elena', 'Arquitecto', 'Perú', '921733312', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(146, 'Sánchez Díaz', 'Chiclayo', 'fernando.sanchez52@gmail.com', '1974-02-26 00:00:00.000000', '73621807', 'Fernando', 'Vendedor', 'Perú', '918931748', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(147, 'Castillo Núñez', 'Huánuco', 'pedro.castillo10@gmail.com', '1997-03-06 00:00:00.000000', '50830180', 'Pedro', 'Enfermera', 'Perú', '925978378', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(148, 'Ramos Pérez', 'Arequipa', 'diego.ramos19@gmail.com', '1998-12-28 00:00:00.000000', '69857282', 'Diego', 'Vendedor', 'Perú', '978513131', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(149, 'Gonzáles Ramos', 'Tacna', 'gabriela.gonzales14@gmail.com', '2002-12-28 00:00:00.000000', '54909885', 'Gabriela', 'Contador', 'Perú', '965138990', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(150, 'Gutiérrez Mendoza', 'Tacna', 'francisco.gutierrez36@gmail.com', '1983-05-06 00:00:00.000000', '73243623', 'Francisco', 'Técnico', 'Perú', '955521589', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(151, 'Castillo Gómez', 'Huánuco', 'elena.castillo42@gmail.com', '1999-05-01 00:00:00.000000', '40036307', 'Elena', 'Diseñador', 'Perú', '930869395', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(152, 'Flores Martínez', 'Arequipa', 'patricia.flores68@gmail.com', '1994-01-03 00:00:00.000000', '77607258', 'Patricia', 'Programador', 'Perú', '924440165', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(153, 'Paredes Aguilar', 'Cusco', 'ana.paredes48@gmail.com', '2004-10-07 00:00:00.000000', '11646358', 'Ana', 'Chef', 'Perú', '942354918', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(154, 'Ramos Cruz', 'Puno', 'raul.ramos57@gmail.com', '1970-11-04 00:00:00.000000', '66332562', 'Raúl', 'Abogado', 'Perú', '981982425', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(155, 'Vargas Díaz', 'Chiclayo', 'ivan.vargas57@gmail.com', '1972-02-11 00:00:00.000000', '14694227', 'Iván', 'Diseñador', 'Perú', '977849074', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(156, 'Salazar Gonzáles', 'Huánuco', 'victor.salazar74@gmail.com', '1984-03-07 00:00:00.000000', '11432655', 'Víctor', 'Ingeniero', 'Perú', '924523990', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(157, 'Gómez Aguilar', 'Cajamarca', 'sergio.gomez16@gmail.com', '1979-09-03 00:00:00.000000', '37059023', 'Sergio', 'Diseñador', 'Perú', '918153857', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(158, 'Flores García', 'Trujillo', 'victor.flores54@gmail.com', '1971-08-06 00:00:00.000000', '77268710', 'Víctor', 'Chef', 'Perú', '951436942', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(159, 'Paredes Vargas', 'Ica', 'roberto.paredes97@gmail.com', '1982-01-16 00:00:00.000000', '61807823', 'Roberto', 'Abogado', 'Perú', '939469152', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(160, 'Cruz Cruz', 'Ica', 'patricia.cruz6@gmail.com', '1970-06-05 00:00:00.000000', '13335060', 'Patricia', 'Arquitecto', 'Perú', '997405807', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(161, 'Martínez Castillo', 'Lima', 'roberto.martinez10@gmail.com', '1973-07-23 00:00:00.000000', '48871159', 'Roberto', 'Docente', 'Perú', '984818316', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(162, 'Díaz Pérez', 'Lima', 'karen.diaz66@gmail.com', '1966-09-28 00:00:00.000000', '23928914', 'Karen', 'Médico', 'Perú', '932286375', 'DNI')
INSERT INTO cliente (id, apellidos, ciudad, correo, fecha_nacimiento, identificacion, nombres, ocupacion, pais, telefono, tipo_documento) VALUES(163, 'Herrera Rojas', 'Huánuco', 'carmen.herrera68@gmail.com', '1998-01-16 00:00:00.000000', '79257439', 'Carmen', 'Diseñador', 'Perú', '913774269', 'DNI')
SET IDENTITY_INSERT cliente OFF
go


-- Usuarios del sistema (staff y administradores)
CREATE TABLE usuario (
    id          INT IDENTITY(1,1) NOT NULL,
    apellidos   VARCHAR(255),
    contrasena  VARCHAR(255),
    correo      VARCHAR(255),
    es_admin    BIT NOT NULL,
    logout_time DATETIME2(6),
    nombres     VARCHAR(255),
    username    VARCHAR(255),
    activo      BIT NOT NULL,
    CONSTRAINT PK_usuario PRIMARY KEY (id)
)
go

SET IDENTITY_INSERT usuario ON
INSERT INTO usuario (id, apellidos, contrasena, correo, es_admin, logout_time, nombres, username, activo) VALUES(7, 'Musk', '$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', 'avalencia4902@gmail.com', 1, '2026-10-21 00:18:15.188593', 'Elon', 'elon', 1)
INSERT INTO usuario (id, apellidos, contrasena, correo, es_admin, logout_time, nombres, username, activo) VALUES(11, 'Quispe', '$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', 'mquispe@hoteltunki.com', 0, NULL, 'María', 'mquispe', 1)
INSERT INTO usuario (id, apellidos, contrasena, correo, es_admin, logout_time, nombres, username, activo) VALUES(12, 'Huamán', '$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', 'jhuaman@hoteltunki.com', 0, NULL, 'Jorge', 'jhuaman', 1)
INSERT INTO usuario (id, apellidos, contrasena, correo, es_admin, logout_time, nombres, username, activo) VALUES(13, 'Rojas', '$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', 'lrojas@hoteltunki.com', 0, NULL, 'Lucía', 'lrojas', 1)
INSERT INTO usuario (id, apellidos, contrasena, correo, es_admin, logout_time, nombres, username, activo) VALUES(14, 'Mendoza', '$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', 'cmendoza@hoteltunki.com', 0, NULL, 'Carlos', 'cmendoza', 1)
INSERT INTO usuario (id, apellidos, contrasena, correo, es_admin, logout_time, nombres, username, activo) VALUES(15, 'Flores', '$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', 'rflores@hoteltunki.com', 0, NULL, 'Rosa', 'rflores', 1)
INSERT INTO usuario (id, apellidos, contrasena, correo, es_admin, logout_time, nombres, username, activo) VALUES(16, 'Torres', '$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', 'mtorres@hoteltunki.com', 0, NULL, 'Miguel', 'mtorres', 1)
INSERT INTO usuario (id, apellidos, contrasena, correo, es_admin, logout_time, nombres, username, activo) VALUES(17, 'Ramírez', '$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', 'pramirez@hoteltunki.com', 0, NULL, 'Paola', 'pramirez', 1)
INSERT INTO usuario (id, apellidos, contrasena, correo, es_admin, logout_time, nombres, username, activo) VALUES(18, 'Vásquez', '$2a$12$gx4jBU180qN4ohLJiyokkuRMZpnhtVmlsVJoCQFrKIeHaXTjI5m5G', 'dvasquez@hoteltunki.com', 0, NULL, 'Daniel', 'dvasquez', 1)
SET IDENTITY_INSERT usuario OFF
go


-- Catálogo de productos de consumo
CREATE TABLE producto_consumo (
    id              INT IDENTITY(1,1) NOT NULL,
    activo          BIT NOT NULL,
    nombre          VARCHAR(255),
    precio_sugerido FLOAT NOT NULL,
    CONSTRAINT PK_producto_consumo PRIMARY KEY (id)
)
go

SET IDENTITY_INSERT producto_consumo ON
INSERT INTO producto_consumo (id, activo, nombre, precio_sugerido) VALUES(1, 1, 'Minibar', 20)
INSERT INTO producto_consumo (id, activo, nombre, precio_sugerido) VALUES(2, 1, 'Room service - Desayuno a la habitación', 28)
INSERT INTO producto_consumo (id, activo, nombre, precio_sugerido) VALUES(3, 1, 'Room service - Almuerzo o cena', 40)
INSERT INTO producto_consumo (id, activo, nombre, precio_sugerido) VALUES(4, 1, 'Lavandería', 28)
INSERT INTO producto_consumo (id, activo, nombre, precio_sugerido) VALUES(7, 1, 'Toalla dañada - reposición', 45)
SET IDENTITY_INSERT producto_consumo OFF
go


-- Roles
CREATE TABLE rol (
    id   INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(255),
    CONSTRAINT PK_rol PRIMARY KEY (id)
)
go


-- Habitaciones
CREATE TABLE habitacion (
    id           INT IDENTITY(1,1) NOT NULL,
    aforo        INT NOT NULL,
    numero       VARCHAR(255),
    piso         INT NOT NULL,
    url_imagen   VARCHAR(255),
    categoria_id INT,
    estado       VARCHAR(255),
    version      BIGINT,
    CONSTRAINT PK_habitacion PRIMARY KEY (id),
    CONSTRAINT FK_habitacion_categoria FOREIGN KEY (categoria_id) REFERENCES categoria (id)
)
go

SET IDENTITY_INSERT habitacion ON
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(1, 2, '101', 1, 'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', 1, 'DISPONIBLE', 5)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(2, 2, '102', 1, 'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', 1, 'DISPONIBLE', 1)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(3, 2, '103', 1, 'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', 1, 'DISPONIBLE', 2)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(4, 2, '104', 1, 'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', 1, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(5, 2, '105', 1, 'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', 1, 'LIMPIEZA', 1)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(6, 2, '106', 1, 'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', 1, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(7, 2, '107', 1, 'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', 1, 'DISPONIBLE', 1)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(8, 2, '108', 1, 'https://www.tunkilodge.com/imagenes/habitacion%20matrional.png', 1, 'DISPONIBLE', 1)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(9, 3, '109', 1, 'https://www.tunkilodge.com/imagenes/habitacionfamiliar3personas.png', 2, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(10, 3, '110', 1, 'https://www.tunkilodge.com/imagenes/habitacionfamiliar3personas.png', 2, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(11, 3, '111', 1, 'https://www.tunkilodge.com/imagenes/habitacionfamiliar3personas.png', 2, 'LIMPIEZA', 1)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(12, 3, '112', 1, 'https://www.tunkilodge.com/imagenes/habitacionfamiliar3personas.png', 2, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(13, 3, '113', 1, 'https://www.tunkilodge.com/imagenes/habitacionfamiliar3personas.png', 2, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(14, 3, '114', 1, 'https://www.tunkilodge.com/imagenes/habitacionfamiliar3personas.png', 2, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(15, 3, '115', 1, 'https://www.tunkilodge.com/imagenes/habitacionfamiliar3personas.png', 2, 'LIMPIEZA', 1)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(16, 6, 'D1', 1, 'https://www.tunkilodge.com/imagenes/domo.jpeg', 5, 'LIMPIEZA', 2)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(17, 6, 'D2', 1, 'https://www.tunkilodge.com/imagenes/domo.jpeg', 5, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(18, 6, 'D3', 1, 'https://www.tunkilodge.com/imagenes/domo.jpeg', 5, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(19, 6, 'D4', 1, 'https://www.tunkilodge.com/imagenes/domo.jpeg', 5, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(20, 6, 'D5', 1, 'https://www.tunkilodge.com/imagenes/domo.jpeg', 5, 'DISPONIBLE', 1)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(21, 10, 'C1', 1, '/carrusel-login/foto-4.jpg', 6, 'LIMPIEZA', 1)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(22, 4, '201', 2, 'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(23, 4, '202', 2, 'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(24, 4, '203', 2, 'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, 'LIMPIEZA', 1)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(25, 4, '204', 2, 'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(26, 4, '205', 2, 'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(27, 4, '206', 2, 'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(28, 4, '207', 2, 'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(29, 4, '208', 2, 'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(30, 4, '209', 2, 'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(31, 4, '210', 2, 'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, 'LIMPIEZA', 1)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(32, 4, '211', 2, 'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(33, 4, '212', 2, 'https://www.tunkilodge.com/imagenes/habitacion%20familiar%204%20personas.png', 3, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(34, 6, '301', 3, 'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(35, 6, '302', 3, 'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, 'LIMPIEZA', 1)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(36, 6, '303', 3, 'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(37, 6, '304', 3, 'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(38, 6, '305', 3, 'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(39, 6, '306', 3, 'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(40, 6, '307', 3, 'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, 'LIMPIEZA', 1)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(41, 6, '308', 3, 'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(42, 6, '309', 3, 'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(43, 6, '310', 3, 'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(44, 6, '311', 3, 'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, 'DISPONIBLE', 0)
INSERT INTO habitacion (id, aforo, numero, piso, url_imagen, categoria_id, estado, version) VALUES(45, 6, '312', 3, 'https://www.tunkilodge.com/imagenes/habitacion%20de%205%20a%206%20personas.png', 4, 'DISPONIBLE', 0)
SET IDENTITY_INSERT habitacion OFF
go


-- Reservas múltiples (agrupan varios registros)
CREATE TABLE reserva (
    id             INT IDENTITY(1,1) NOT NULL,
    fecha_creacion DATETIME2(6),
    cliente_id     INT,
    usuario_id     INT,
    CONSTRAINT PK_reserva PRIMARY KEY (id),
    CONSTRAINT FK_reserva_cliente FOREIGN KEY (cliente_id) REFERENCES cliente (id),
    CONSTRAINT FK_reserva_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id)
)
go


-- Registros de estadía (check-in / check-out)
CREATE TABLE registro (
    id             INT IDENTITY(1,1) NOT NULL,
    check_in       DATETIME2(6),
    noches         INT NOT NULL,
    num_huespedes  INT NOT NULL,
    observaciones  VARCHAR(255),
    tarifa         FLOAT,
    cliente_id     INT,
    habitacion_id  INT,
    usuario_id     INT,
    check_out_real DATETIME2(6),
    estado         VARCHAR(255),
    metodo_pago    VARCHAR(255),
    monto_pagado   FLOAT,
    version        BIGINT,
    reserva_id     INT,
    CONSTRAINT PK_registro PRIMARY KEY (id),
    CONSTRAINT FK_registro_cliente    FOREIGN KEY (cliente_id)    REFERENCES cliente (id),
    CONSTRAINT FK_registro_habitacion FOREIGN KEY (habitacion_id) REFERENCES habitacion (id),
    CONSTRAINT FK_registro_usuario    FOREIGN KEY (usuario_id)    REFERENCES usuario (id),
    CONSTRAINT FK_registro_reserva    FOREIGN KEY (reserva_id)    REFERENCES reserva (id)
)
go

SET IDENTITY_INSERT registro ON
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(1, '2026-10-05 15:00:00.000000', 3, 1, NULL, 660, 138, 11, 17, '2026-10-08 16:23:00.000000', 'FINALIZADA', 'EFECTIVO', 660, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(2, '2026-10-24 12:00:00.000000', 5, 3, NULL, 2250, 162, 21, 11, NULL, 'ACTIVA', 'TARJETA', 1125, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(3, '2026-10-18 10:00:00.000000', 3, 3, '', 780, 36, 31, 16, '2026-10-23 03:23:09.153000', 'FINALIZADA', 'EFECTIVO', 864, 3, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(4, '2026-09-05 12:00:00.000000', 5, 3, NULL, 1750, 123, 20, 7, '2026-09-10 12:44:00.000000', 'FINALIZADA', 'TRANSFERENCIA', 1750, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(5, '2026-09-15 10:00:00.000000', 3, 3, NULL, 960, 99, 45, 15, '2026-09-18 09:01:00.000000', 'FINALIZADA', 'TRANSFERENCIA', 960, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(6, '2026-10-02 10:00:00.000000', 2, 1, NULL, 700, 150, 20, 11, '2026-10-04 09:35:00.000000', 'FINALIZADA', 'EFECTIVO', 700, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(7, '2026-10-22 18:00:00.000000', 5, 4, '', 1600, 104, 40, 17, '2026-10-23 09:25:31.744000', 'FINALIZADA', NULL, 1600, 2, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(8, '2026-11-05 12:00:00.000000', 5, 2, '', 900, 128, 7, 18, NULL, 'ACTIVA', 'EFECTIVO', 450, 1, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(9, '2026-10-04 08:00:00.000000', 4, 4, NULL, 1280, 88, 36, 14, NULL, 'NO_SHOW', NULL, 0, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(10, '2026-09-13 16:00:00.000000', 5, 4, NULL, 1100, 114, 9, 17, '2026-09-18 16:18:00.000000', 'FINALIZADA', 'TRANSFERENCIA', 1159.5, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(11, '2026-10-02 17:00:00.000000', 4, 3, NULL, 1280, 132, 45, 13, '2026-10-06 17:00:00.000000', 'FINALIZADA', 'EFECTIVO', 1315, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(12, '2026-08-22 13:00:00.000000', 4, 2, NULL, 720, 5, 5, 13, '2026-08-26 14:15:00.000000', 'FINALIZADA', 'EFECTIVO', 720, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(13, '2026-11-05 14:00:00.000000', 3, 4, NULL, 780, 98, 29, 13, NULL, 'ACTIVA', NULL, 0, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(14, '2026-10-27 14:00:00.000000', 5, 2, NULL, 1300, 30, 24, 16, '2026-10-23 09:25:59.108000', 'FINALIZADA', 'EFECTIVO', 1300, 1, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(15, '2026-10-19 16:00:00.000000', 4, 4, '', 1800, 50, 21, 16, '2026-10-23 09:18:06.249000', 'FINALIZADA', 'EFECTIVO', 1800, 3, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(16, '2026-09-27 13:00:00.000000', 4, 4, NULL, 1280, 151, 41, 16, '2026-10-01 13:18:00.000000', 'FINALIZADA', 'TRANSFERENCIA', 1304, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(17, '2026-10-21 11:00:00.000000', 2, 2, '', 440, 53, 11, 7, '2026-10-23 09:20:29.605000', 'FINALIZADA', 'TARJETA', 522, 2, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(18, '2026-10-05 17:00:00.000000', 1, 1, NULL, 350, 128, 19, 7, '2026-10-06 16:38:00.000000', 'FINALIZADA', 'TRANSFERENCIA', 350, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(19, '2026-10-04 08:00:00.000000', 2, 4, NULL, 640, 88, 42, 11, '2026-10-06 07:40:00.000000', 'FINALIZADA', 'EFECTIVO', 640, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(20, '2026-09-16 14:00:00.000000', 5, 2, NULL, 1600, 15, 43, 16, '2026-09-21 15:11:00.000000', 'FINALIZADA', 'TRANSFERENCIA', 1600, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(21, '2026-11-03 11:00:00.000000', 5, 2, NULL, 1600, 101, 44, 18, NULL, 'ACTIVA', NULL, 0, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(22, '2026-09-12 14:00:00.000000', 2, 4, NULL, 640, 13, 34, 11, '2026-09-14 13:43:00.000000', 'FINALIZADA', 'TARJETA', 640, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(23, '2026-10-20 11:00:00.000000', 1, 3, NULL, 350, 95, 19, 16, NULL, 'CANCELADA', NULL, 0, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(24, '2026-09-02 13:00:00.000000', 3, 2, NULL, 540, 25, 3, 14, '2026-09-05 12:18:00.000000', 'FINALIZADA', 'EFECTIVO', 554, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(25, '2026-08-28 14:00:00.000000', 2, 2, NULL, 700, 90, 16, 17, '2026-08-30 13:10:00.000000', 'FINALIZADA', 'TRANSFERENCIA', 700, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(26, '2026-09-06 17:00:00.000000', 2, 1, NULL, 640, 108, 44, 14, '2026-09-08 16:53:00.000000', 'FINALIZADA', 'TARJETA', 640, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(27, '2026-09-20 10:00:00.000000', 2, 2, NULL, 360, 31, 6, 15, '2026-09-22 10:57:00.000000', 'FINALIZADA', 'EFECTIVO', 360, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(28, '2026-10-05 17:00:00.000000', 5, 1, NULL, 1300, 81, 26, 16, '2026-10-10 15:57:00.000000', 'FINALIZADA', 'TRANSFERENCIA', 1356, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(29, '2026-10-19 09:00:00.000000', 5, 4, '', 1100, 24, 15, 16, '2026-10-23 09:21:27.632000', 'FINALIZADA', 'EFECTIVO', 1120, 2, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(30, '2026-09-06 10:00:00.000000', 5, 2, NULL, 1600, 65, 40, 11, NULL, 'CANCELADA', NULL, 0, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(31, '2026-10-15 20:00:00.000000', 1, 4, NULL, 320, 158, 43, 14, '2026-10-16 19:51:00.000000', 'FINALIZADA', 'EFECTIVO', 320, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(32, '2026-10-11 13:00:00.000000', 4, 4, NULL, 1280, 51, 34, 11, '2026-10-15 12:26:00.000000', 'FINALIZADA', 'TARJETA', 1280, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(33, '2026-08-24 09:00:00.000000', 5, 3, NULL, 1300, 122, 31, 18, '2026-08-29 09:47:00.000000', 'FINALIZADA', 'TRANSFERENCIA', 1395, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(34, '2026-10-04 11:00:00.000000', 5, 4, NULL, 900, 16, 2, 12, '2026-10-09 12:15:00.000000', 'FINALIZADA', 'EFECTIVO', 916, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(35, '2026-10-16 18:00:00.000000', 3, 2, NULL, 780, 69, 30, 14, '2026-10-19 16:45:00.000000', 'FINALIZADA', 'EFECTIVO', 780, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(36, '2026-09-03 20:00:00.000000', 4, 3, NULL, 720, 146, 6, 17, '2026-09-07 20:06:00.000000', 'FINALIZADA', 'TARJETA', 762, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(37, '2026-09-12 16:00:00.000000', 1, 3, NULL, 320, 116, 40, 13, '2026-09-13 16:18:00.000000', 'FINALIZADA', 'TRANSFERENCIA', 320, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(38, '2026-10-07 19:00:00.000000', 2, 1, NULL, 640, 62, 39, 13, NULL, 'NO_SHOW', NULL, 0, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(39, '2026-08-31 17:00:00.000000', 1, 3, NULL, 180, 100, 2, 15, '2026-09-01 18:14:00.000000', 'FINALIZADA', 'EFECTIVO', 180, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(40, '2026-10-16 18:00:00.000000', 1, 3, NULL, 260, 157, 25, 16, '2026-10-17 17:13:00.000000', 'FINALIZADA', 'TARJETA', 260, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(41, '2026-11-10 18:00:00.000000', 2, 3, NULL, 360, 111, 7, 7, NULL, 'ACTIVA', 'TRANSFERENCIA', 360, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(42, '2026-09-17 09:00:00.000000', 2, 1, NULL, 360, 93, 7, 14, '2026-09-19 10:17:00.000000', 'FINALIZADA', 'EFECTIVO', 360, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(43, '2026-09-14 15:00:00.000000', 3, 2, NULL, 960, 100, 34, 16, '2026-09-16 12:30:00.000000', 'FINALIZADA', 'TARJETA', 1018, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(44, '2026-11-05 08:00:00.000000', 4, 1, NULL, 1400, 63, 19, 17, NULL, 'ACTIVA', NULL, 0, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(45, '2026-10-29 08:00:00.000000', 3, 2, NULL, 1050, 60, 17, 16, NULL, 'ACTIVA', 'TRANSFERENCIA', 1050, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(46, '2026-10-02 20:00:00.000000', 2, 1, NULL, 520, 1, 31, 16, '2026-10-04 19:26:00.000000', 'FINALIZADA', 'EFECTIVO', 520, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(47, '2026-09-21 10:00:00.000000', 5, 2, NULL, 900, 31, 4, 15, '2026-09-26 11:09:00.000000', 'FINALIZADA', 'TARJETA', 900, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(48, '2026-08-22 20:00:00.000000', 3, 1, NULL, 780, 89, 30, 14, NULL, 'CANCELADA', NULL, 0, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(49, '2026-10-26 12:00:00.000000', 4, 4, NULL, 1280, 130, 42, 13, NULL, 'ACTIVA', 'TRANSFERENCIA', 640, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(50, '2026-09-26 11:00:00.000000', 4, 3, NULL, 720, 19, 4, 7, '2026-09-30 10:52:00.000000', 'FINALIZADA', 'TRANSFERENCIA', 737, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(51, '2026-10-25 18:00:00.000000', 1, 4, '', 220, 67, 15, 12, '2026-10-23 09:23:54.961000', 'FINALIZADA', 'EFECTIVO', 220, 2, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(52, '2026-11-04 11:00:00.000000', 1, 3, NULL, 320, 138, 34, 14, NULL, 'ACTIVA', 'EFECTIVO', 160, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(53, '2026-10-16 14:00:00.000000', 3, 4, NULL, 960, 73, 34, 18, '2026-10-19 15:23:00.000000', 'FINALIZADA', 'TRANSFERENCIA', 960, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(54, '2026-10-10 15:00:00.000000', 2, 4, NULL, 640, 90, 40, 14, '2026-10-12 13:34:00.000000', 'FINALIZADA', 'TRANSFERENCIA', 640, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(55, '2026-10-27 14:00:00.000000', 5, 3, NULL, 1600, 91, 35, 7, '2026-10-23 09:26:14.480000', 'FINALIZADA', 'EFECTIVO', 1600, 1, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(56, '2026-10-28 16:00:00.000000', 4, 3, '', 1400, 77, 16, 17, '2026-10-23 09:27:08.061000', 'FINALIZADA', NULL, 1400, 2, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(57, '2026-10-09 20:00:00.000000', 2, 4, NULL, 640, 79, 39, 7, '2026-10-11 21:30:00.000000', 'FINALIZADA', 'EFECTIVO', 640, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(58, '2026-10-22 16:00:00.000000', 4, 4, '', 720, 77, 5, 17, '2026-10-23 09:24:36.315000', 'FINALIZADA', 'TARJETA', 720, 3, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(59, '2026-09-25 12:00:00.000000', 2, 2, NULL, 640, 144, 45, 13, '2026-09-27 11:31:00.000000', 'FINALIZADA', 'EFECTIVO', 640, 0, NULL)
INSERT INTO registro (id, check_in, noches, num_huespedes, observaciones, tarifa, cliente_id, habitacion_id, usuario_id, check_out_real, estado, metodo_pago, monto_pagado, version, reserva_id) VALUES(60, '2026-09-05 09:00:00.000000', 1, 4, NULL, 450, 87, 21, 12, '2026-09-06 10:12:00.000000', 'FINALIZADA', 'EFECTIVO', 450, 0, NULL)
SET IDENTITY_INSERT registro OFF
go


-- Consumos durante la estadía
CREATE TABLE consumo (
    id                  INT IDENTITY(1,1) NOT NULL,
    descripcion         VARCHAR(255),
    fecha               DATETIME2(6),
    monto               FLOAT NOT NULL,
    registro_id         INT,
    producto_consumo_id INT,
    CONSTRAINT PK_consumo PRIMARY KEY (id),
    CONSTRAINT FK_consumo_registro FOREIGN KEY (registro_id) REFERENCES registro (id),
    CONSTRAINT FK_consumo_producto FOREIGN KEY (producto_consumo_id) REFERENCES producto_consumo (id)
)
go

SET IDENTITY_INSERT consumo ON
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(1, 'Room service - Desayuno a la habitación', '2026-08-25 08:30:00.000000', 28, 33, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(2, 'Room service - Cena a la habitación', '2026-08-27 20:15:00.000000', 45, 33, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(3, 'Minibar', '2026-08-28 23:10:00.000000', 22, 33, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(4, 'Lavandería', '2026-09-07 10:00:00.000000', 32, 4, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(5, 'Room service - Almuerzo', '2026-09-08 13:20:00.000000', 38, 4, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(6, 'Minibar', '2026-09-15 21:40:00.000000', 19.5, 10, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(7, 'Late check-out (2 horas extra)', '2026-09-18 15:50:00.000000', 40, 10, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(8, 'Room service - Cena', '2026-09-18 21:00:00.000000', 42, 20, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(9, 'Toalla dañada - reposición', '2026-09-20 11:30:00.000000', 45, 20, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(10, 'Minibar', '2026-09-29 22:15:00.000000', 24, 16, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(11, 'Room service - Desayuno a la habitación', '2026-10-07 08:45:00.000000', 26, 28, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(12, 'Lavandería', '2026-10-08 11:00:00.000000', 30, 28, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(13, 'Minibar', '2026-10-12 23:00:00.000000', 21, 32, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(14, 'Late check-out (1 hora extra)', '2026-10-15 12:20:00.000000', 25, 32, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(15, 'Room service - Almuerzo', '2026-10-04 13:30:00.000000', 35, 11, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(16, 'Minibar', '2026-10-06 20:00:00.000000', 16, 34, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(17, 'Lavandería', '2026-10-18 09:30:00.000000', 28, 53, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(18, 'Minibar', '2026-09-15 22:40:00.000000', 18, 43, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(19, 'Room service - Cena', '2026-09-15 20:10:00.000000', 40, 43, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(20, 'Minibar', '2026-09-03 21:30:00.000000', 14, 24, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(21, 'Room service - Desayuno a la habitación', '2026-10-18 08:20:00.000000', 24, 35, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(22, 'Minibar', '2026-09-05 22:50:00.000000', 20, 36, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(23, 'Lavandería', '2026-09-06 10:15:00.000000', 22, 36, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(24, 'Minibar', '2026-09-28 22:00:00.000000', 17, 50, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(25, 'Minibar', '2026-08-24 21:45:00.000000', 19, 12, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(26, 'Minibar', '2026-10-20 22:30:00.000000', 18, 3, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(27, 'Room service - Desayuno a la habitación', '2026-10-21 08:15:00.000000', 26, 3, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(28, 'Minibar', '2026-10-20 23:00:00.000000', 20, 29, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(29, 'Lavandería', '2026-10-22 10:00:00.000000', 22, 17, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(32, 'Room service - Almuerzo o cena', '2026-10-23 03:09:38.895121', 40, 3, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(33, 'Minibar', '2026-10-23 03:15:25.293805', 20, 17, NULL)
INSERT INTO consumo (id, descripcion, fecha, monto, registro_id, producto_consumo_id) VALUES(34, 'Room service - Almuerzo o cena', '2026-10-23 03:15:27.435657', 40, 17, NULL)
SET IDENTITY_INSERT consumo OFF
go


-- Comprobantes emitidos (uno por registro)
CREATE TABLE comprobante (
    id            INT IDENTITY(1,1) NOT NULL,
    correlativo   INT NOT NULL,
    datos_json    VARCHAR(MAX),
    fecha_emision DATETIME2(6),
    igv           FLOAT,
    serie         VARCHAR(255),
    total         FLOAT,
    valor_venta   FLOAT,
    registro_id   INT,
    CONSTRAINT PK_comprobante PRIMARY KEY (id),
    CONSTRAINT UQ_comprobante_registro UNIQUE (registro_id),
    CONSTRAINT FK_comprobante_registro FOREIGN KEY (registro_id) REFERENCES registro (id)
)
go

SET IDENTITY_INSERT comprobante ON
INSERT INTO comprobante (id, correlativo, datos_json, fecha_emision, igv, serie, total, valor_venta, registro_id) VALUES(1, 1, '{
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
}', '2026-10-21 01:06:18.105169', 100.68, 'C001', 660, 559.32, 1)
INSERT INTO comprobante (id, correlativo, datos_json, fecha_emision, igv, serie, total, valor_venta, registro_id) VALUES(2, 2, '{
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
}', '2026-10-21 01:08:31.193459', 97.63, 'C001', 640, 542.37, 22)
INSERT INTO comprobante (id, correlativo, datos_json, fecha_emision, igv, serie, total, valor_venta, registro_id) VALUES(3, 3, '{
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
}', '2026-10-23 03:23:09.211324', 131.8, 'C001', 864, 732.2, 3)
INSERT INTO comprobante (id, correlativo, datos_json, fecha_emision, igv, serie, total, valor_venta, registro_id) VALUES(4, 4, '{
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
}', '2026-10-23 09:20:50.970323', 79.63, 'C001', 522, 442.37, 17)
SET IDENTITY_INSERT comprobante OFF
go


-- Intentos de inicio de sesión
CREATE TABLE login_attempts (
    id           INT IDENTITY(1,1) NOT NULL,
    attempt_time DATETIME2(6) NOT NULL,
    ip_address   VARCHAR(45) NOT NULL,
    successful   BIT NOT NULL,
    username     VARCHAR(255),
    CONSTRAINT PK_login_attempts PRIMARY KEY (id)
)
go

SET IDENTITY_INSERT login_attempts ON
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(1, '2026-10-21 00:13:11.064963', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(2, '2026-10-21 00:18:32.132995', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(3, '2026-10-21 00:21:17.089907', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(4, '2026-10-21 00:27:00.068545', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(5, '2026-10-21 00:31:11.962863', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(6, '2026-10-21 00:37:12.096243', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(7, '2026-10-21 00:38:18.714710', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(8, '2026-10-21 00:39:15.104976', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(9, '2026-10-21 00:42:24.739990', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(10, '2026-10-21 00:43:44.495850', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(11, '2026-10-21 00:45:16.027786', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(12, '2026-10-21 00:46:42.103485', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(13, '2026-10-21 00:50:18.549191', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(14, '2026-10-21 00:58:44.229702', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(15, '2026-10-21 01:03:52.876731', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(16, '2026-10-21 01:08:10.090440', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(17, '2026-10-21 01:10:01.961566', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(18, '2026-10-21 01:14:20.930592', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(19, '2026-10-21 01:14:55.761219', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(20, '2026-10-21 01:20:43.330785', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(21, '2026-10-21 01:23:31.757256', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(22, '2026-10-21 09:53:26.382105', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(23, '2026-10-21 10:30:23.496741', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(24, '2026-10-21 10:31:32.270005', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(25, '2026-10-21 10:39:38.607965', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(26, '2026-10-21 10:41:05.903247', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(27, '2026-10-21 10:42:50.790380', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(28, '2026-10-21 10:51:08.709925', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(29, '2026-10-21 10:57:54.469556', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(30, '2026-10-21 10:59:16.945344', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(31, '2026-10-21 11:08:33.441438', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(32, '2026-10-21 11:13:00.904498', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(33, '2026-10-21 11:15:45.673546', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(34, '2026-10-21 11:28:19.927529', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(35, '2026-10-21 11:35:23.717862', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(36, '2026-10-21 11:50:31.972818', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(37, '2026-10-21 11:55:12.095200', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(38, '2026-10-21 12:29:04.993698', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(39, '2026-10-21 15:33:23.291783', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(40, '2026-10-21 18:26:59.895149', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(41, '2026-10-21 18:38:58.612592', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(42, '2026-10-21 19:39:10.715276', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(43, '2026-10-23 01:40:42.292346', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(44, '2026-10-23 09:14:05.188823', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(45, '2026-10-23 10:17:49.037114', '0:0:0:0:0:0:0:1', 1, 'elon')
INSERT INTO login_attempts (id, attempt_time, ip_address, successful, username) VALUES(46, '2026-10-23 12:23:15.367715', '0:0:0:0:0:0:0:1', 1, 'elon')
SET IDENTITY_INSERT login_attempts OFF
go


-- Tokens para recuperar contraseña
CREATE TABLE password_reset_token (
    id               INT IDENTITY(1,1) NOT NULL,
    fecha_expiracion DATETIME2(6),
    token            VARCHAR(255),
    usado            BIT NOT NULL,
    usuario_id       INT,
    CONSTRAINT PK_password_reset_token PRIMARY KEY (id),
    CONSTRAINT FK_token_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id)
)
go


-- Relación usuario - rol
CREATE TABLE usuarios_roles (
    usuario_id INT NOT NULL,
    rol_id     INT NOT NULL,
    CONSTRAINT PK_usuarios_roles PRIMARY KEY (usuario_id, rol_id),
    CONSTRAINT FK_usuarios_roles_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id),
    CONSTRAINT FK_usuarios_roles_rol FOREIGN KEY (rol_id) REFERENCES rol (id)
)
go


-- Verificación: filas cargadas por tabla
SELECT 'categoria' AS tabla, COUNT(*) AS filas FROM categoria
UNION ALL SELECT 'cliente' AS tabla, COUNT(*) AS filas FROM cliente
UNION ALL SELECT 'usuario' AS tabla, COUNT(*) AS filas FROM usuario
UNION ALL SELECT 'producto_consumo' AS tabla, COUNT(*) AS filas FROM producto_consumo
UNION ALL SELECT 'rol' AS tabla, COUNT(*) AS filas FROM rol
UNION ALL SELECT 'habitacion' AS tabla, COUNT(*) AS filas FROM habitacion
UNION ALL SELECT 'reserva' AS tabla, COUNT(*) AS filas FROM reserva
UNION ALL SELECT 'registro' AS tabla, COUNT(*) AS filas FROM registro
UNION ALL SELECT 'consumo' AS tabla, COUNT(*) AS filas FROM consumo
UNION ALL SELECT 'comprobante' AS tabla, COUNT(*) AS filas FROM comprobante
UNION ALL SELECT 'login_attempts' AS tabla, COUNT(*) AS filas FROM login_attempts
UNION ALL SELECT 'password_reset_token' AS tabla, COUNT(*) AS filas FROM password_reset_token
UNION ALL SELECT 'usuarios_roles' AS tabla, COUNT(*) AS filas FROM usuarios_roles
go
