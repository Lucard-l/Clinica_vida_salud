-- =============================================================
-- DATOS DE EJEMPLO PARA Salud_y_vida
-- Ejecutar después de crear la base Salud_y_vida_nueva_completa.sql
-- Compatible con MySQL 8.x / XAMPP
-- =============================================================

USE Salud_y_vida;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

-- -------------------------------------------------------------
-- 1. TIPOS DE HABITACIÓN: 8 registros
-- -------------------------------------------------------------
INSERT IGNORE INTO tipos_habitacion (nombre, descripcion) VALUES
('INDIVIDUAL', 'Habitación privada para un paciente'),
('DOBLE', 'Habitación para dos pacientes'),
('TRIPLE', 'Habitación para tres pacientes'),
('SUITE', 'Habitación privada con comodidades adicionales'),
('UCI', 'Unidad de cuidados intensivos'),
('UCIN', 'Unidad de cuidados intensivos neonatales'),
('AISLAMIENTO', 'Habitación destinada a pacientes en aislamiento'),
('MATERNIDAD', 'Habitación para atención materno-infantil');

-- -------------------------------------------------------------
-- 2. ESPECIALIDADES: 12 registros
-- -------------------------------------------------------------
INSERT IGNORE INTO especialidades (nombre, descripcion) VALUES
('MEDICINA GENERAL', 'Atención médica primaria y preventiva'),
('CARDIOLOGÍA', 'Diagnóstico y tratamiento del sistema cardiovascular'),
('PEDIATRÍA', 'Atención médica para niños y adolescentes'),
('GINECOLOGÍA', 'Salud reproductiva y atención ginecológica'),
('OBSTETRICIA', 'Control del embarazo y atención del parto'),
('TRAUMATOLOGÍA', 'Lesiones y enfermedades del sistema musculoesquelético'),
('CIRUGÍA GENERAL', 'Procedimientos quirúrgicos generales'),
('DERMATOLOGÍA', 'Enfermedades de la piel, cabello y uñas'),
('NEUROLOGÍA', 'Enfermedades del sistema nervioso'),
('OFTALMOLOGÍA', 'Diagnóstico y tratamiento de enfermedades oculares'),
('ODONTOLOGÍA', 'Prevención y tratamiento de enfermedades dentales'),
('ANESTESIOLOGÍA', 'Atención anestésica y control del dolor');

-- -------------------------------------------------------------
-- 3. CONSULTORIOS: 10 registros
-- -------------------------------------------------------------
INSERT IGNORE INTO consultorios (numero, estado) VALUES
('CONS-101', 'DISPONIBLE'),
('CONS-102', 'DISPONIBLE'),
('CONS-103', 'DISPONIBLE'),
('CONS-104', 'DISPONIBLE'),
('CONS-105', 'DISPONIBLE'),
('CONS-106', 'DISPONIBLE'),
('CONS-107', 'DISPONIBLE'),
('CONS-108', 'DISPONIBLE'),
('CONS-109', 'DISPONIBLE'),
('CONS-110', 'DISPONIBLE');

-- -------------------------------------------------------------
-- 4. QUIRÓFANOS: 6 registros
-- -------------------------------------------------------------
INSERT IGNORE INTO quirofanos (nombre, estado) VALUES
('QUIRÓFANO 1 - CIRUGÍA GENERAL', 'DISPONIBLE'),
('QUIRÓFANO 2 - TRAUMA', 'DISPONIBLE'),
('QUIRÓFANO 3 - GINECOLOGÍA', 'DISPONIBLE'),
('QUIRÓFANO 4 - OFTALMOLOGÍA', 'DISPONIBLE'),
('QUIRÓFANO 5 - PROCEDIMIENTOS', 'DISPONIBLE'),
('QUIRÓFANO 6 - EMERGENCIAS', 'DISPONIBLE');

-- -------------------------------------------------------------
-- 5. HABITACIONES: 20 registros
-- -------------------------------------------------------------
INSERT IGNORE INTO habitaciones (numero, id_tipo_habitacion, estado)
SELECT v.numero, t.id_tipo_habitacion, 'DISPONIBLE'
FROM (
    SELECT 'H-101' numero, 'INDIVIDUAL' tipo UNION ALL
    SELECT 'H-102', 'INDIVIDUAL' UNION ALL
    SELECT 'H-103', 'INDIVIDUAL' UNION ALL
    SELECT 'H-104', 'INDIVIDUAL' UNION ALL
    SELECT 'H-201', 'DOBLE' UNION ALL
    SELECT 'H-202', 'DOBLE' UNION ALL
    SELECT 'H-203', 'DOBLE' UNION ALL
    SELECT 'H-204', 'DOBLE' UNION ALL
    SELECT 'H-301', 'TRIPLE' UNION ALL
    SELECT 'H-302', 'TRIPLE' UNION ALL
    SELECT 'H-401', 'SUITE' UNION ALL
    SELECT 'H-402', 'SUITE' UNION ALL
    SELECT 'UCI-01', 'UCI' UNION ALL
    SELECT 'UCI-02', 'UCI' UNION ALL
    SELECT 'UCI-03', 'UCI' UNION ALL
    SELECT 'UCIN-01', 'UCIN' UNION ALL
    SELECT 'UCIN-02', 'UCIN' UNION ALL
    SELECT 'AIS-01', 'AISLAMIENTO' UNION ALL
    SELECT 'AIS-02', 'AISLAMIENTO' UNION ALL
    SELECT 'MAT-01', 'MATERNIDAD'
) v
JOIN tipos_habitacion t ON t.nombre = v.tipo;

-- -------------------------------------------------------------
-- 6. TARIFAS DE HABITACIÓN: 8 registros
-- -------------------------------------------------------------
INSERT IGNORE INTO tipo_habitacion_tarifa_historico
    (id_tipo_habitacion, tarifa_diaria, fecha_desde)
SELECT id_tipo_habitacion,
       CASE nombre
           WHEN 'INDIVIDUAL' THEN 250.00
           WHEN 'DOBLE' THEN 180.00
           WHEN 'TRIPLE' THEN 140.00
           WHEN 'SUITE' THEN 450.00
           WHEN 'UCI' THEN 900.00
           WHEN 'UCIN' THEN 950.00
           WHEN 'AISLAMIENTO' THEN 350.00
           WHEN 'MATERNIDAD' THEN 300.00
       END,
       CURDATE()
FROM tipos_habitacion
WHERE nombre IN ('INDIVIDUAL','DOBLE','TRIPLE','SUITE','UCI','UCIN','AISLAMIENTO','MATERNIDAD');

-- -------------------------------------------------------------
-- 7. SERVICIOS MÉDICOS: 15 registros
-- -------------------------------------------------------------
INSERT IGNORE INTO servicios_medicos (nombre, id_especialidad)
SELECT v.servicio, e.id_especialidad
FROM (
    SELECT 'Consulta de medicina general' servicio, 'MEDICINA GENERAL' especialidad UNION ALL
    SELECT 'Consulta cardiológica', 'CARDIOLOGÍA' UNION ALL
    SELECT 'Electrocardiograma', 'CARDIOLOGÍA' UNION ALL
    SELECT 'Consulta pediátrica', 'PEDIATRÍA' UNION ALL
    SELECT 'Control prenatal', 'OBSTETRICIA' UNION ALL
    SELECT 'Consulta ginecológica', 'GINECOLOGÍA' UNION ALL
    SELECT 'Consulta traumatológica', 'TRAUMATOLOGÍA' UNION ALL
    SELECT 'Radiografía de extremidad', 'TRAUMATOLOGÍA' UNION ALL
    SELECT 'Cirugía general ambulatoria', 'CIRUGÍA GENERAL' UNION ALL
    SELECT 'Consulta dermatológica', 'DERMATOLOGÍA' UNION ALL
    SELECT 'Consulta neurológica', 'NEUROLOGÍA' UNION ALL
    SELECT 'Consulta oftalmológica', 'OFTALMOLOGÍA' UNION ALL
    SELECT 'Limpieza dental', 'ODONTOLOGÍA' UNION ALL
    SELECT 'Extracción dental', 'ODONTOLOGÍA' UNION ALL
    SELECT 'Evaluación preanestésica', 'ANESTESIOLOGÍA'
) v
JOIN especialidades e ON e.nombre = v.especialidad;

-- -------------------------------------------------------------
-- 8. PRECIOS DE SERVICIOS: 15 registros
-- -------------------------------------------------------------
INSERT IGNORE INTO servicio_precio_historico (id_servicio, precio, fecha_desde)
SELECT s.id_servicio,
       CASE s.nombre
           WHEN 'Consulta de medicina general' THEN 80.00
           WHEN 'Consulta cardiológica' THEN 150.00
           WHEN 'Electrocardiograma' THEN 120.00
           WHEN 'Consulta pediátrica' THEN 100.00
           WHEN 'Control prenatal' THEN 110.00
           WHEN 'Consulta ginecológica' THEN 120.00
           WHEN 'Consulta traumatológica' THEN 140.00
           WHEN 'Radiografía de extremidad' THEN 180.00
           WHEN 'Cirugía general ambulatoria' THEN 1200.00
           WHEN 'Consulta dermatológica' THEN 100.00
           WHEN 'Consulta neurológica' THEN 160.00
           WHEN 'Consulta oftalmológica' THEN 130.00
           WHEN 'Limpieza dental' THEN 90.00
           WHEN 'Extracción dental' THEN 180.00
           WHEN 'Evaluación preanestésica' THEN 100.00
       END,
       CURDATE()
FROM servicios_medicos s
WHERE s.nombre IN (
    'Consulta de medicina general','Consulta cardiológica','Electrocardiograma',
    'Consulta pediátrica','Control prenatal','Consulta ginecológica',
    'Consulta traumatológica','Radiografía de extremidad','Cirugía general ambulatoria',
    'Consulta dermatológica','Consulta neurológica','Consulta oftalmológica',
    'Limpieza dental','Extracción dental','Evaluación preanestésica'
);

-- -------------------------------------------------------------
-- 9. MÉDICOS: 15 personas y 15 registros médicos
-- -------------------------------------------------------------
INSERT IGNORE INTO personas (ci, nombre, fecha_nacimiento, telefono, direccion, correo) VALUES
('DOC-0001', 'Ana María Rodríguez Pérez', '1982-03-15', '70000001', 'Zona Centro', 'ana.rodriguez@saludvida.local'),
('DOC-0002', 'Carlos Eduardo Méndez Silva', '1979-07-22', '70000002', 'Zona Norte', 'carlos.mendez@saludvida.local'),
('DOC-0003', 'Beatriz Elena Vargas López', '1985-11-08', '70000003', 'Zona Sur', 'beatriz.vargas@saludvida.local'),
('DOC-0004', 'Diego Andrés Fernández Rojas', '1980-01-30', '70000004', 'Zona Este', 'diego.fernandez@saludvida.local'),
('DOC-0005', 'María Fernanda Castillo Ruiz', '1987-05-17', '70000005', 'Zona Oeste', 'maria.castillo@saludvida.local'),
('DOC-0006', 'Jorge Luis Herrera Gómez', '1976-09-12', '70000006', 'Zona Centro', 'jorge.herrera@saludvida.local'),
('DOC-0007', 'Laura Gabriela Torres Díaz', '1984-12-03', '70000007', 'Zona Norte', 'laura.torres@saludvida.local'),
('DOC-0008', 'Miguel Ángel Sánchez Cruz', '1981-02-25', '70000008', 'Zona Sur', 'miguel.sanchez@saludvida.local'),
('DOC-0009', 'Patricia Isabel Morales Vega', '1988-06-19', '70000009', 'Zona Este', 'patricia.morales@saludvida.local'),
('DOC-0010', 'Ricardo Alberto Navarro León', '1978-10-28', '70000010', 'Zona Oeste', 'ricardo.navarro@saludvida.local'),
('DOC-0011', 'Sofía Alejandra Paredes Ortiz', '1986-04-11', '70000011', 'Zona Centro', 'sofia.paredes@saludvida.local'),
('DOC-0012', 'Fernando Javier Campos Arias', '1983-08-06', '70000012', 'Zona Norte', 'fernando.campos@saludvida.local'),
('DOC-0013', 'Gabriela Susana Molina Reyes', '1989-01-14', '70000013', 'Zona Sur', 'gabriela.molina@saludvida.local'),
('DOC-0014', 'Luis Fernando Cabrera Pinto', '1977-03-29', '70000014', 'Zona Este', 'luis.cabrera@saludvida.local'),
('DOC-0015', 'Valeria Cristina Salazar Núñez', '1990-09-21', '70000015', 'Zona Oeste', 'valeria.salazar@saludvida.local');

INSERT IGNORE INTO medicos
    (id_persona, matricula_profesional, tipo_contrato, monto_fijo, porcentaje_procedimiento, activo)
SELECT p.id_persona, CONCAT('MAT-', LPAD(SUBSTRING(p.ci, 5), 4, '0')),
       CASE WHEN CAST(SUBSTRING(p.ci, 5) AS UNSIGNED) IN (2,5,8,11,14) THEN 'PORCENTAJE' ELSE 'FIJO' END,
       CASE WHEN CAST(SUBSTRING(p.ci, 5) AS UNSIGNED) IN (2,5,8,11,14) THEN NULL ELSE 8500.00 END,
       CASE WHEN CAST(SUBSTRING(p.ci, 5) AS UNSIGNED) IN (2,5,8,11,14) THEN 35.00 ELSE NULL END,
       TRUE
FROM personas p
WHERE p.ci LIKE 'DOC-%';

-- -------------------------------------------------------------
-- 10. RELACIÓN MÉDICO-ESPECIALIDAD
-- -------------------------------------------------------------
INSERT IGNORE INTO medico_especialidad (id_persona, id_especialidad)
SELECT p.id_persona, e.id_especialidad
FROM personas p
JOIN especialidades e ON e.nombre = CASE p.ci
    WHEN 'DOC-0001' THEN 'MEDICINA GENERAL'
    WHEN 'DOC-0002' THEN 'CARDIOLOGÍA'
    WHEN 'DOC-0003' THEN 'PEDIATRÍA'
    WHEN 'DOC-0004' THEN 'GINECOLOGÍA'
    WHEN 'DOC-0005' THEN 'OBSTETRICIA'
    WHEN 'DOC-0006' THEN 'TRAUMATOLOGÍA'
    WHEN 'DOC-0007' THEN 'CIRUGÍA GENERAL'
    WHEN 'DOC-0008' THEN 'DERMATOLOGÍA'
    WHEN 'DOC-0009' THEN 'NEUROLOGÍA'
    WHEN 'DOC-0010' THEN 'OFTALMOLOGÍA'
    WHEN 'DOC-0011' THEN 'ODONTOLOGÍA'
    WHEN 'DOC-0012' THEN 'ANESTESIOLOGÍA'
    WHEN 'DOC-0013' THEN 'MEDICINA GENERAL'
    WHEN 'DOC-0014' THEN 'CIRUGÍA GENERAL'
    WHEN 'DOC-0015' THEN 'CARDIOLOGÍA'
END
WHERE p.ci LIKE 'DOC-%';

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================
-- CONSULTAS DE VERIFICACIÓN
-- =============================================================
SELECT 'Tipos de habitación' AS catalogo, COUNT(*) AS cantidad FROM tipos_habitacion
UNION ALL SELECT 'Especialidades', COUNT(*) FROM especialidades
UNION ALL SELECT 'Consultorios', COUNT(*) FROM consultorios
UNION ALL SELECT 'Quirófanos', COUNT(*) FROM quirofanos
UNION ALL SELECT 'Habitaciones', COUNT(*) FROM habitaciones
UNION ALL SELECT 'Servicios médicos', COUNT(*) FROM servicios_medicos
UNION ALL SELECT 'Médicos', COUNT(*) FROM medicos;

SELECT p.ci, p.nombre, m.matricula_profesional, e.nombre AS especialidad
FROM medicos m
JOIN personas p ON p.id_persona = m.id_persona
LEFT JOIN medico_especialidad me ON me.id_persona = m.id_persona
LEFT JOIN especialidades e ON e.id_especialidad = me.id_especialidad
ORDER BY p.nombre;
