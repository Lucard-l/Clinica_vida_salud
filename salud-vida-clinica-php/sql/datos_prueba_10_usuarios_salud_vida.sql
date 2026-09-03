USE Salud_y_vida;
SET FOREIGN_KEY_CHECKS=0;

-- Garantizar el nuevo rol.
ALTER TABLE roles MODIFY nombre ENUM('ADMINISTRADOR','SUPERVISOR','PACIENTE','ENFERMERO','MEDICO','FACTURADOR') NOT NULL UNIQUE;
INSERT INTO roles(nombre,descripcion) VALUES
('ADMINISTRADOR','Control total del sistema'),
('SUPERVISOR','Registra y supervisa todas las operaciones'),
('ENFERMERO','Registra insumos, medicamentos y operaciones de enfermería'),
('FACTURADOR','Gestiona facturas, pagos y datos fiscales')
ON DUPLICATE KEY UPDATE descripcion=VALUES(descripcion);

-- Diez tipos de habitación.
INSERT IGNORE INTO tipos_habitacion(nombre,descripcion) VALUES
('SIMPLE','Habitación individual'),('DOBLE','Habitación para dos pacientes'),('TRIPLE','Habitación para tres pacientes'),('UTI','Unidad de terapia intensiva'),('UCI','Unidad de cuidados intensivos'),('PEDIATRICA','Habitación pediátrica'),('MATERNIDAD','Habitación de maternidad'),('AISLAMIENTO','Habitación de aislamiento'),('SUITE','Habitación privada superior'),('RECUPERACION','Sala de recuperación');

-- Diez especialidades.
INSERT IGNORE INTO especialidades(nombre,descripcion) VALUES
('MEDICINA GENERAL','Atención primaria'),('CARDIOLOGIA','Corazón y sistema circulatorio'),('PEDIATRIA','Atención infantil'),('GINECOLOGIA','Salud femenina'),('TRAUMATOLOGIA','Huesos y articulaciones'),('DERMATOLOGIA','Piel y anexos'),('OFTALMOLOGIA','Salud visual'),('NEUROLOGIA','Sistema nervioso'),('CIRUGIA GENERAL','Procedimientos quirúrgicos'),('ODONTOLOGIA','Salud bucal');

-- Diez consultorios.
INSERT IGNORE INTO consultorios(numero,estado) VALUES
('CONS-01','DISPONIBLE'),('CONS-02','DISPONIBLE'),('CONS-03','DISPONIBLE'),('CONS-04','DISPONIBLE'),('CONS-05','DISPONIBLE'),('CONS-06','DISPONIBLE'),('CONS-07','DISPONIBLE'),('CONS-08','DISPONIBLE'),('CONS-09','DISPONIBLE'),('CONS-10','DISPONIBLE');

-- Diez quirófanos.
INSERT IGNORE INTO quirofanos(nombre,estado) VALUES
('QUIROFANO-01','DISPONIBLE'),('QUIROFANO-02','DISPONIBLE'),('QUIROFANO-03','DISPONIBLE'),('QUIROFANO-04','DISPONIBLE'),('QUIROFANO-05','DISPONIBLE'),('QUIROFANO-06','DISPONIBLE'),('QUIROFANO-07','DISPONIBLE'),('QUIROFANO-08','DISPONIBLE'),('QUIROFANO-09','DISPONIBLE'),('QUIROFANO-10','DISPONIBLE');

-- Diez aseguradoras.
INSERT IGNORE INTO aseguradoras(nombre,nit,telefono,email,es_reservada) VALUES
('SUSALUD','900100001','555-1001','contacto@susalud.local',0),('VIDA SEGURA','900100002','555-1002','contacto@vidasegura.local',0),('SALUD TOTAL','900100003','555-1003','contacto@saludtotal.local',0),('MEDIRED','900100004','555-1004','contacto@medired.local',0),('PROTECCION MEDICA','900100005','555-1005','contacto@proteccion.local',0),('BIENESTAR S.A.','900100006','555-1006','contacto@bienestar.local',0),('FAMILIA SALUD','900100007','555-1007','contacto@familiasalud.local',0),('NUEVA VIDA','900100008','555-1008','contacto@nuevavida.local',0),('SEGURO CLINICO','900100009','555-1009','contacto@seguroclinico.local',0),('COBERTURA PLUS','900100010','555-1010','contacto@coberturaplus.local',0);

-- Diez habitaciones, relacionadas con los tipos.
INSERT IGNORE INTO habitaciones(numero,id_tipo_habitacion,estado)
SELECT x.numero,t.id_tipo_habitacion,'DISPONIBLE' FROM (
SELECT 'H-101' numero,'SIMPLE' tipo UNION ALL SELECT 'H-102','DOBLE' UNION ALL SELECT 'H-103','TRIPLE' UNION ALL SELECT 'H-104','UTI' UNION ALL SELECT 'H-105','UCI' UNION ALL SELECT 'H-106','PEDIATRICA' UNION ALL SELECT 'H-107','MATERNIDAD' UNION ALL SELECT 'H-108','AISLAMIENTO' UNION ALL SELECT 'H-109','SUITE' UNION ALL SELECT 'H-110','RECUPERACION') x JOIN tipos_habitacion t ON t.nombre=x.tipo;

-- Diez servicios y precio inicial para cada uno.
INSERT IGNORE INTO servicios_medicos(nombre,id_especialidad)
SELECT x.nombre,e.id_especialidad FROM (
SELECT 'Consulta medicina general' nombre,'MEDICINA GENERAL' esp UNION ALL SELECT 'Consulta cardiologia','CARDIOLOGIA' UNION ALL SELECT 'Consulta pediatria','PEDIATRIA' UNION ALL SELECT 'Consulta ginecologia','GINECOLOGIA' UNION ALL SELECT 'Consulta traumatologia','TRAUMATOLOGIA' UNION ALL SELECT 'Consulta dermatologia','DERMATOLOGIA' UNION ALL SELECT 'Consulta oftalmologia','OFTALMOLOGIA' UNION ALL SELECT 'Consulta neurologia','NEUROLOGIA' UNION ALL SELECT 'Cirugia general','CIRUGIA GENERAL' UNION ALL SELECT 'Consulta odontologia','ODONTOLOGIA') x JOIN especialidades e ON e.nombre=x.esp;
INSERT IGNORE INTO servicio_precio_historico(id_servicio,precio,fecha_desde)
SELECT id_servicio,CASE WHEN nombre LIKE 'Cirugia%' THEN 1500 ELSE 80 END,CURDATE() FROM servicios_medicos WHERE nombre IN ('Consulta medicina general','Consulta cardiologia','Consulta pediatria','Consulta ginecologia','Consulta traumatologia','Consulta dermatologia','Consulta oftalmologia','Consulta neurologia','Cirugia general','Consulta odontologia');

-- Diez medicamentos.
INSERT IGNORE INTO medicamentos(nombre,presentacion,foto_path) VALUES
('Paracetamol','Tableta 500 mg',NULL),('Ibuprofeno','Tableta 400 mg',NULL),('Amoxicilina','Capsula 500 mg',NULL),('Omeprazol','Capsula 20 mg',NULL),('Loratadina','Tableta 10 mg',NULL),('Metformina','Tableta 850 mg',NULL),('Salbutamol','Inhalador 100 mcg',NULL),('Diclofenaco','Gel 1%',NULL),('Ceftriaxona','Ampolla 1 g',NULL),('Suero fisiologico','Bolsa 500 ml',NULL);

-- Diez exámenes.
INSERT IGNORE INTO examenes_laboratorio(nombre,precio) VALUES
('Hemograma completo',25),('Glucosa en sangre',15),('Perfil lipidico',40),('Examen general de orina',18),('Creatinina',20),('Prueba de embarazo',22),('Grupo sanguineo',18),('Pruebas hepaticas',55),('Electrolitos',45),('Tiempo de coagulacion',35);

-- Diez pacientes y sus historias clínicas.
INSERT IGNORE INTO personas(ci,nombre,fecha_nacimiento,telefono,direccion,correo) VALUES
('PAC-0001','Ana Lopez','1988-02-15','555-2001','Av. Central 101','ana.lopez@demo.local'),('PAC-0002','Bruno Perez','1979-06-21','555-2002','Calle Norte 202','bruno.perez@demo.local'),('PAC-0003','Carla Mendoza','1995-09-03','555-2003','Av. Salud 303','carla.mendoza@demo.local'),('PAC-0004','Diego Torres','1968-11-12','555-2004','Calle Sur 404','diego.torres@demo.local'),('PAC-0005','Elena Vargas','2001-01-28','555-2005','Av. Vida 505','elena.vargas@demo.local'),('PAC-0006','Fabio Rojas','1985-03-19','555-2006','Calle Paz 606','fabio.rojas@demo.local'),('PAC-0007','Gabriela Silva','1992-07-07','555-2007','Av. Norte 707','gabriela.silva@demo.local'),('PAC-0008','Hugo Castro','1974-12-30','555-2008','Calle Uno 808','hugo.castro@demo.local'),('PAC-0009','Irene Flores','1981-04-10','555-2009','Av. Dos 909','irene.flores@demo.local'),('PAC-0010','Jorge Molina','1998-10-25','555-2010','Calle Tres 100','jorge.molina@demo.local');
INSERT IGNORE INTO pacientes(id_persona,tipo_sangre) SELECT id_persona,CASE RIGHT(ci,1) WHEN '1' THEN 'O+' WHEN '2' THEN 'A+' WHEN '3' THEN 'B+' WHEN '4' THEN 'AB+' WHEN '5' THEN 'O-' WHEN '6' THEN 'A-' WHEN '7' THEN 'B-' WHEN '8' THEN 'AB-' WHEN '9' THEN 'O+' ELSE 'A+' END FROM personas WHERE ci LIKE 'PAC-%';
INSERT IGNORE INTO historias_clinicas(id_persona,antecedentes,alergias,observaciones) SELECT id_persona,'Registro de prueba para validar el historial clínico.','Ninguna conocida','Paciente de demostración.' FROM personas WHERE ci LIKE 'PAC-%';

-- Diez médicos y sus especialidades.
INSERT IGNORE INTO personas(ci,nombre,fecha_nacimiento,telefono,correo) VALUES
('DOC-0001','Dr. Alberto Ruiz','1975-01-10','555-3001','alberto.ruiz@saludvida.local'),('DOC-0002','Dra. Beatriz Leon','1980-02-11','555-3002','beatriz.leon@saludvida.local'),('DOC-0003','Dr. Carlos Diaz','1978-03-12','555-3003','carlos.diaz@saludvida.local'),('DOC-0004','Dra. Diana Paz','1983-04-13','555-3004','diana.paz@saludvida.local'),('DOC-0005','Dr. Eduardo Gil','1972-05-14','555-3005','eduardo.gil@saludvida.local'),('DOC-0006','Dra. Fernanda Cruz','1986-06-15','555-3006','fernanda.cruz@saludvida.local'),('DOC-0007','Dr. Gustavo Rey','1977-07-16','555-3007','gustavo.rey@saludvida.local'),('DOC-0008','Dra. Helena Mora','1984-08-17','555-3008','helena.mora@saludvida.local'),('DOC-0009','Dr. Ivan Soto','1976-09-18','555-3009','ivan.soto@saludvida.local'),('DOC-0010','Dra. Julia Vera','1982-10-19','555-3010','julia.vera@saludvida.local');
INSERT IGNORE INTO medicos(id_persona,matricula_profesional,tipo_contrato,monto_fijo,activo) SELECT id_persona,CONCAT('MAT-',LPAD(RIGHT(ci,4),4,'0')),'FIJO',2500,1 FROM personas WHERE ci LIKE 'DOC-%';
INSERT IGNORE INTO medico_especialidad(id_persona,id_especialidad) SELECT m.id_persona,e.id_especialidad FROM medicos m JOIN personas p ON p.id_persona=m.id_persona JOIN especialidades e ON e.nombre=CASE RIGHT(p.ci,1) WHEN '1' THEN 'MEDICINA GENERAL' WHEN '2' THEN 'CARDIOLOGIA' WHEN '3' THEN 'PEDIATRIA' WHEN '4' THEN 'GINECOLOGIA' WHEN '5' THEN 'TRAUMATOLOGIA' WHEN '6' THEN 'DERMATOLOGIA' WHEN '7' THEN 'OFTALMOLOGIA' WHEN '8' THEN 'NEUROLOGIA' WHEN '9' THEN 'CIRUGIA GENERAL' ELSE 'ODONTOLOGIA' END;

-- Cuatro usuarios solicitados. Contraseña inicial: admin123.
INSERT INTO personas(ci,nombre,correo) VALUES
('USR-FABIANA','Fabiana','fabiana@saludvida.local'),('USR-MACIEL','Maciel','maciel@saludvida.local'),('USR-JOSUE','Josue','josue@saludvida.local'),('USR-LUIS','Luis','luis@saludvida.local')
ON DUPLICATE KEY UPDATE nombre=VALUES(nombre),correo=VALUES(correo);
INSERT INTO usuarios(id_persona,id_rol,nombre_usuario,contrasena_hash,estado)
SELECT p.id_persona,r.id_rol,'fabiana','$2b$12$YWn7Hvv1JA1DkZBMRj45Z.5krvpS7xiV0A.StAhJMz.5j/FVyIjnu',1 FROM personas p JOIN roles r ON r.nombre='FACTURADOR' WHERE p.ci='USR-FABIANA' ON DUPLICATE KEY UPDATE id_rol=VALUES(id_rol),estado=1;
INSERT INTO usuarios(id_persona,id_rol,nombre_usuario,contrasena_hash,estado)
SELECT p.id_persona,r.id_rol,'maciel','$2b$12$YWn7Hvv1JA1DkZBMRj45Z.5krvpS7xiV0A.StAhJMz.5j/FVyIjnu',1 FROM personas p JOIN roles r ON r.nombre='SUPERVISOR' WHERE p.ci='USR-MACIEL' ON DUPLICATE KEY UPDATE id_rol=VALUES(id_rol),estado=1;
INSERT INTO usuarios(id_persona,id_rol,nombre_usuario,contrasena_hash,estado)
SELECT p.id_persona,r.id_rol,'josue','$2b$12$YWn7Hvv1JA1DkZBMRj45Z.5krvpS7xiV0A.StAhJMz.5j/FVyIjnu',1 FROM personas p JOIN roles r ON r.nombre='ENFERMERO' WHERE p.ci='USR-JOSUE' ON DUPLICATE KEY UPDATE id_rol=VALUES(id_rol),estado=1;
INSERT INTO usuarios(id_persona,id_rol,nombre_usuario,contrasena_hash,estado)
SELECT p.id_persona,r.id_rol,'luis','$2b$12$YWn7Hvv1JA1DkZBMRj45Z.5krvpS7xiV0A.StAhJMz.5j/FVyIjnu',1 FROM personas p JOIN roles r ON r.nombre='ADMINISTRADOR' WHERE p.ci='USR-LUIS' ON DUPLICATE KEY UPDATE id_rol=VALUES(id_rol),estado=1;

-- Diez contratos para los médicos.
INSERT IGNORE INTO contratos_medico(id_medico,tipo_contrato,monto_fijo,fecha_inicio,activo,observaciones)
SELECT id_persona,'FIJO',2500,CURDATE(),1,'Contrato de prueba' FROM medicos;

SET FOREIGN_KEY_CHECKS=1;

SELECT u.nombre_usuario,r.nombre rol,p.nombre FROM usuarios u JOIN roles r ON r.id_rol=u.id_rol JOIN personas p ON p.id_persona=u.id_persona WHERE u.nombre_usuario IN ('fabiana','maciel','josue','luis');
SELECT 'Datos de prueba cargados correctamente' AS resultado;
