-- =============================================================
-- DATOS DE PRUEBA COMPLETOS Y RELACIONADOS: Salud_y_vida
-- Ejecutar después de Salud_y_vida_nueva_completa.sql y de
-- datos_ejemplo_salud_vida.sql.
-- =============================================================
USE Salud_y_vida;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

-- 1. ASEGURADORAS: 6 registros (incluye la reservada particular)
INSERT IGNORE INTO aseguradoras (nombre, nit, telefono, email, es_reservada) VALUES
('SEGURO NACIONAL DE SALUD', 'ASEG-0001', '22110001', 'contacto@sns.local', FALSE),
('PROTECCIÓN MÉDICA S.A.', 'ASEG-0002', '22110002', 'contacto@proteccion.local', FALSE),
('VIDA SEGURA LTDA.', 'ASEG-0003', '22110003', 'contacto@vidasegura.local', FALSE),
('SALUD TOTAL S.A.', 'ASEG-0004', '22110004', 'contacto@saludtotal.local', FALSE),
('BIENESTAR FAMILIAR', 'ASEG-0005', '22110005', 'contacto@bienestar.local', FALSE),
('CORPORACIÓN MÉDICA', 'ASEG-0006', '22110006', 'contacto@corporacionmedica.local', FALSE);

-- 2. PACIENTES: 12 personas y pacientes
INSERT IGNORE INTO personas (ci, nombre, fecha_nacimiento, telefono, direccion, correo) VALUES
('PAC-0001', 'María Elena Flores Quispe', '1992-01-18', '71000001', 'Av. Central 101', 'maria.flores@paciente.local'),
('PAC-0002', 'José Antonio Pérez Lima', '1985-04-22', '71000002', 'Calle Los Pinos 202', 'jose.perez@paciente.local'),
('PAC-0003', 'Lucía Gabriela Mendoza Ruiz', '2014-08-11', '71000003', 'Barrio Norte 303', 'lucia.mendoza@paciente.local'),
('PAC-0004', 'Roberto Carlos Gutiérrez Soto', '1971-12-05', '71000004', 'Av. Libertad 404', 'roberto.gutierrez@paciente.local'),
('PAC-0005', 'Carmen Teresa Aguilar Paz', '1968-06-27', '71000005', 'Calle Sucre 505', 'carmen.aguilar@paciente.local'),
('PAC-0006', 'Daniel Mauricio Rojas Céspedes', '2001-02-14', '71000006', 'Zona Este 606', 'daniel.rojas@paciente.local'),
('PAC-0007', 'Andrea Sofía Villarroel Arias', '1995-09-30', '71000007', 'Zona Sur 707', 'andrea.villarroel@paciente.local'),
('PAC-0008', 'Pedro Martín Salinas León', '1959-03-09', '71000008', 'Zona Oeste 808', 'pedro.salinas@paciente.local'),
('PAC-0009', 'Natalia Isabel Romero Vargas', '1989-11-16', '71000009', 'Av. América 909', 'natalia.romero@paciente.local'),
('PAC-0010', 'Fernando David Ortiz Molina', '2010-05-03', '71000010', 'Calle Bolívar 100', 'fernando.ortiz@paciente.local'),
('PAC-0011', 'Rosa Beatriz Chávez Flores', '1977-07-25', '71000011', 'Calle Aroma 111', 'rosa.chavez@paciente.local'),
('PAC-0012', 'Iván Alejandro Ponce Rivera', '1998-10-12', '71000012', 'Av. Circunvalación 121', 'ivan.ponce@paciente.local');

INSERT IGNORE INTO pacientes (id_persona, tipo_sangre, activo)
SELECT id_persona,
       CASE ci
           WHEN 'PAC-0001' THEN 'O+'
           WHEN 'PAC-0002' THEN 'A+'
           WHEN 'PAC-0003' THEN 'B+'
           WHEN 'PAC-0004' THEN 'AB+'
           WHEN 'PAC-0005' THEN 'O-'
           WHEN 'PAC-0006' THEN 'A-'
           WHEN 'PAC-0007' THEN 'B-'
           WHEN 'PAC-0008' THEN 'O+'
           WHEN 'PAC-0009' THEN 'A+'
           WHEN 'PAC-0010' THEN 'O+'
           WHEN 'PAC-0011' THEN 'AB-'
           WHEN 'PAC-0012' THEN 'B+'
       END, TRUE
FROM personas WHERE ci LIKE 'PAC-%';

-- 3. HISTORIAS CLÍNICAS: una por paciente de prueba
INSERT INTO historias_clinicas (id_persona, antecedentes, alergias, observaciones)
SELECT p.id_persona,
       'Historia inicial de paciente de prueba.',
       CASE p.ci WHEN 'PAC-0002' THEN 'Penicilina' WHEN 'PAC-0008' THEN 'Ninguna conocida' ELSE 'Ninguna registrada' END,
       'Registro creado para pruebas del sistema.'
FROM personas p
WHERE p.ci LIKE 'PAC-%'
  AND NOT EXISTS (SELECT 1 FROM historias_clinicas h WHERE h.id_persona = p.id_persona);

-- 4. PÓLIZAS DE PACIENTES: 12 registros
INSERT IGNORE INTO paciente_seguro (id_persona, id_aseguradora, numero_poliza, fecha_inicio, fecha_fin, activo)
SELECT p.id_persona, a.id_aseguradora, CONCAT('POL-', SUBSTRING(p.ci, 5)), '2026-01-01', '2026-12-31', TRUE
FROM personas p
JOIN aseguradoras a ON a.nit = CASE
    WHEN p.ci IN ('PAC-0001','PAC-0007') THEN 'ASEG-0001'
    WHEN p.ci IN ('PAC-0002','PAC-0008') THEN 'ASEG-0002'
    WHEN p.ci IN ('PAC-0003','PAC-0009') THEN 'ASEG-0003'
    WHEN p.ci IN ('PAC-0004','PAC-0010') THEN 'ASEG-0004'
    WHEN p.ci IN ('PAC-0005','PAC-0011') THEN 'ASEG-0005'
    ELSE 'ASEG-0006'
END
WHERE p.ci LIKE 'PAC-%';

-- 5. MEDICAMENTOS: 15 registros
INSERT IGNORE INTO medicamentos (nombre, presentacion, activo) VALUES
('Paracetamol', 'Tableta 500 mg', TRUE),
('Ibuprofeno', 'Tableta 400 mg', TRUE),
('Amoxicilina', 'Cápsula 500 mg', TRUE),
('Azitromicina', 'Tableta 500 mg', TRUE),
('Losartán', 'Tableta 50 mg', TRUE),
('Enalapril', 'Tableta 10 mg', TRUE),
('Omeprazol', 'Cápsula 20 mg', TRUE),
('Metformina', 'Tableta 850 mg', TRUE),
('Salbutamol', 'Inhalador 100 mcg', TRUE),
('Loratadina', 'Tableta 10 mg', TRUE),
('Diclofenaco', 'Gel tópico 1%', TRUE),
('Ácido fólico', 'Tableta 5 mg', TRUE),
('Clotrimazol', 'Crema 1%', TRUE),
('Suero fisiológico', 'Solución 0.9% 500 ml', TRUE),
('Tramadol', 'Cápsula 50 mg', TRUE);

-- 6. EXÁMENES DE LABORATORIO: 12 registros
INSERT IGNORE INTO examenes_laboratorio (nombre, precio, activo) VALUES
('Hemograma completo', 80.00, TRUE),
('Glucosa en sangre', 35.00, TRUE),
('Perfil lipídico', 120.00, TRUE),
('Examen general de orina', 45.00, TRUE),
('Creatinina', 40.00, TRUE),
('Urea', 40.00, TRUE),
('Prueba de embarazo', 60.00, TRUE),
('Pruebas hepáticas', 150.00, TRUE),
('Ácido úrico', 45.00, TRUE),
('Electrolitos séricos', 130.00, TRUE),
('Tiempo de protrombina', 75.00, TRUE),
('Cultivo bacteriológico', 180.00, TRUE);

-- 7. INSUMOS: 12 registros
INSERT IGNORE INTO insumos (nombre, stock_actual, unidad_medida, activo) VALUES
('Guantes quirúrgicos', 500.00, 'PAR', TRUE),
('Mascarillas quirúrgicas', 800.00, 'UNIDAD', TRUE),
('Jeringas 5 ml', 300.00, 'UNIDAD', TRUE),
('Gasas estériles', 400.00, 'PAQUETE', TRUE),
('Suturas nylon 3-0', 120.00, 'UNIDAD', TRUE),
('Suturas absorbibles 2-0', 100.00, 'UNIDAD', TRUE),
('Bisturí desechable', 80.00, 'UNIDAD', TRUE),
('Campos quirúrgicos', 90.00, 'UNIDAD', TRUE),
('Catéter intravenoso', 200.00, 'UNIDAD', TRUE),
('Solución salina 1000 ml', 150.00, 'UNIDAD', TRUE),
('Antiséptico quirúrgico', 60.00, 'FRASCO', TRUE),
(' vendas elásticas', 100.00, 'UNIDAD', TRUE);

-- 8. CONVENIOS: cobertura por especialidad
INSERT IGNORE INTO convenios_aseguradora (id_aseguradora, id_especialidad, porcentaje_cobertura, fecha_inicio, activo)
SELECT a.id_aseguradora, e.id_especialidad,
       CASE a.nit WHEN 'ASEG-0001' THEN 80 WHEN 'ASEG-0002' THEN 70 WHEN 'ASEG-0003' THEN 85 WHEN 'ASEG-0004' THEN 60 WHEN 'ASEG-0005' THEN 75 ELSE 65 END,
       '2026-01-01', TRUE
FROM aseguradoras a
CROSS JOIN especialidades e
WHERE a.es_reservada = FALSE
  AND e.nombre IN ('MEDICINA GENERAL','CARDIOLOGÍA','PEDIATRÍA','CIRUGÍA GENERAL','GINECOLOGÍA');

-- 9. CONSULTAS: 12 registros para probar agenda y orígenes de factura
INSERT INTO consultas
    (id_persona, id_medico, id_especialidad, id_historia, id_consultorio, fecha_hora, duracion_estimada_minutos, motivo, estado, tipo_consulta)
SELECT p.id_persona, m.id_persona, e.id_especialidad,
       (SELECT h.id_historia FROM historias_clinicas h WHERE h.id_persona=p.id_persona ORDER BY h.fecha_apertura DESC LIMIT 1),
       c.id_consultorio, DATE_ADD(NOW(), INTERVAL n DAY), 30,
       'Consulta de control y evaluación general.', 'ATENDIDA',
       CASE WHEN n IN (1,4,7,10) THEN 'CONTROL' ELSE 'PRIMERA_VEZ' END
FROM (
    SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
    UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
) x
JOIN personas p ON p.ci = CONCAT('PAC-', LPAD(n,4,'0'))
JOIN personas m ON m.ci = CONCAT('DOC-', LPAD(((n-1) MOD 15)+1,4,'0'))
JOIN medicos md ON md.id_persona=m.id_persona
JOIN especialidades e ON e.nombre = CASE WHEN n IN (2,5,8,11) THEN 'CARDIOLOGÍA' WHEN n IN (3,6,9,12) THEN 'PEDIATRÍA' ELSE 'MEDICINA GENERAL' END
JOIN consultorios c ON c.numero = CONCAT('CONS-', 100 + n);

-- 10. RECETAS y detalles para las primeras consultas
INSERT IGNORE INTO recetas (id_consulta, observaciones)
SELECT id_consulta, 'Receta de ejemplo para validación del módulo clínico.'
FROM consultas ORDER BY id_consulta LIMIT 4;

INSERT INTO receta_detalle (id_receta, id_medicamento, dosis, frecuencia, duracion_dias, indicaciones)
SELECT r.id_receta, m.id_medicamento, '1 tableta', 'Cada 8 horas', 5, 'Tomar después de los alimentos.'
FROM recetas r
JOIN medicamentos m ON m.nombre='Paracetamol'
WHERE NOT EXISTS (SELECT 1 FROM receta_detalle rd WHERE rd.id_receta=r.id_receta);

-- 11. SOLICITUDES DE LABORATORIO y detalles
INSERT IGNORE INTO solicitudes_laboratorio (id_consulta, estado)
SELECT id_consulta, 'COMPLETADA' FROM consultas ORDER BY id_consulta LIMIT 4;

INSERT INTO solicitud_laboratorio_detalle (id_solicitud, id_examen, resultado, fecha_resultado)
SELECT sl.id_solicitud, e.id_examen, 'Resultado de ejemplo: dentro de parámetros normales.', NOW()
FROM solicitudes_laboratorio sl
JOIN examenes_laboratorio e ON e.nombre='Hemograma completo'
WHERE NOT EXISTS (SELECT 1 FROM solicitud_laboratorio_detalle d WHERE d.id_solicitud=sl.id_solicitud);

-- 12. CIRUGÍAS: 5 registros
INSERT INTO cirugias
    (id_persona, id_quirofano, id_especialidad, id_cirujano_principal, fecha_programada, duracion_estimada_minutos, diagnostico_prequirurgico, estado)
SELECT p.id_persona, q.id_quirofano, e.id_especialidad, m.id_persona,
       DATE_ADD(NOW(), INTERVAL n DAY), 120,
       'Diagnóstico prequirúrgico de ejemplo.',
       CASE WHEN n=1 THEN 'REALIZADA' ELSE 'PROGRAMADA' END
FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) x
JOIN personas p ON p.ci=CONCAT('PAC-',LPAD(n+1,4,'0'))
JOIN quirofanos q ON q.nombre=CONCAT('QUIRÓFANO ',n,' - ', CASE n WHEN 1 THEN 'CIRUGÍA GENERAL' WHEN 2 THEN 'TRAUMA' WHEN 3 THEN 'GINECOLOGÍA' WHEN 4 THEN 'OFTALMOLOGÍA' ELSE 'PROCEDIMIENTOS' END)
JOIN especialidades e ON e.nombre=CASE n WHEN 1 THEN 'CIRUGÍA GENERAL' WHEN 2 THEN 'TRAUMATOLOGÍA' WHEN 3 THEN 'GINECOLOGÍA' WHEN 4 THEN 'OFTALMOLOGÍA' ELSE 'CIRUGÍA GENERAL' END
JOIN personas m ON m.ci=CONCAT('DOC-',LPAD(n+6,4,'0'));

-- 13. PERSONAL E INSUMOS DE CIRUGÍA
INSERT IGNORE INTO cirugia_personal (id_cirugia, id_persona, rol)
SELECT c.id_cirugia, p.id_persona, 'ENFERMERO'
FROM cirugias c JOIN personas p ON p.ci='DOC-0012';

INSERT IGNORE INTO cirugia_insumo (id_cirugia, id_insumo, cantidad_utilizada)
SELECT c.id_cirugia, i.id_insumo, 2.00
FROM cirugias c JOIN insumos i ON i.nombre='Guantes quirúrgicos';

-- 14. INTERNACIONES: 3 registros con habitaciones y cargos
INSERT INTO ordenes_internacion (id_consulta, motivo)
SELECT id_consulta, 'Internación de prueba para validación del sistema.'
FROM consultas ORDER BY id_consulta LIMIT 3;

INSERT INTO internaciones (id_orden, id_persona, id_habitacion, fecha_ingreso, estado)
SELECT o.id_orden, c.id_persona, h.id_habitacion, NOW(), CASE WHEN o.id_orden=(SELECT MIN(id_orden) FROM ordenes_internacion) THEN 'ACTIVA' ELSE 'FINALIZADA' END
FROM ordenes_internacion o
JOIN consultas c ON c.id_consulta=o.id_consulta
JOIN habitaciones h ON h.numero=CONCAT('H-10', o.id_orden)
WHERE NOT EXISTS (SELECT 1 FROM internaciones i WHERE i.id_orden=o.id_orden)
LIMIT 3;

UPDATE habitaciones h JOIN internaciones i ON i.id_habitacion=h.id_habitacion
SET h.estado='OCUPADA' WHERE i.estado='ACTIVA';

INSERT INTO cargos_internacion (id_internacion, fecha, concepto, monto)
SELECT id_internacion, CURDATE(), 'Habitación y atención hospitalaria', 250.00
FROM internaciones
WHERE NOT EXISTS (SELECT 1 FROM cargos_internacion c WHERE c.id_internacion=internaciones.id_internacion);

-- 15. USUARIOS DE PRUEBA PARA VALIDAR PERMISOS
INSERT IGNORE INTO personas (ci, nombre, fecha_nacimiento, telefono, correo) VALUES
('USR-FACT-01', 'Facturador de Prueba', '1988-02-10', '72000001', 'facturador@saludvida.local'),
('USR-MED-01', 'Médico de Prueba', '1984-05-20', '72000002', 'medico@saludvida.local'),
('USR-ENF-01', 'Enfermero de Prueba', '1990-07-15', '72000003', 'enfermero@saludvida.local');

INSERT IGNORE INTO usuarios (id_persona, id_rol, nombre_usuario, contrasena_hash, estado)
SELECT p.id_persona, r.id_rol,
       CASE p.ci WHEN 'USR-FACT-01' THEN 'facturador' WHEN 'USR-MED-01' THEN 'medico' ELSE 'enfermero' END,
       '$2b$12$YWn7Hvv1JA1DkZBMRj45Z.5krvpS7xiV0A.StAhJMz.5j/FVyIjnu', TRUE
FROM personas p
JOIN roles r ON r.nombre = CASE p.ci WHEN 'USR-FACT-01' THEN 'FACTURADOR' WHEN 'USR-MED-01' THEN 'MEDICO' ELSE 'ENFERMERO' END
WHERE p.ci IN ('USR-FACT-01','USR-MED-01','USR-ENF-01');

-- 16. FACTURAS DE PRUEBA: 3 registros y sus detalles
INSERT INTO datos_facturacion (nit_ci, razon_social, tipo_documento_fiscal) VALUES
('102030401', 'María Elena Flores Quispe', 'RECIBO'),
('203040502', 'José Antonio Pérez Lima', 'FACTURA_CREDITO_FISCAL'),
('304050603', 'Lucía Gabriela Mendoza Ruiz', 'FACTURA_SIN_CREDITO_FISCAL');

INSERT INTO facturas (id_paciente_seguro, id_usuario_factura, id_datos_facturacion, tipo_pago, subtotal, monto_cobertura_seguro, estado)
SELECT ps.id_paciente_seguro, u.id_usuario, d.id_datos_facturacion, 'SEGURO', 80.00, 56.00, 'PENDIENTE'
FROM paciente_seguro ps
JOIN personas p ON p.id_persona=ps.id_persona AND p.ci='PAC-0001'
JOIN usuarios u ON u.nombre_usuario='admin'
JOIN datos_facturacion d ON d.nit_ci='102030401'
WHERE NOT EXISTS (SELECT 1 FROM facturas f JOIN datos_facturacion x ON x.id_datos_facturacion=f.id_datos_facturacion WHERE x.nit_ci='102030401');

INSERT INTO factura_detalle (id_factura, id_servicio, id_consulta, cantidad, precio_unitario)
SELECT f.id_factura, s.id_servicio, c.id_consulta, 1, 80.00
FROM facturas f JOIN datos_facturacion d ON d.id_datos_facturacion=f.id_datos_facturacion AND d.nit_ci='102030401'
JOIN servicios_medicos s ON s.nombre='Consulta de medicina general'
JOIN consultas c ON c.id_persona=(SELECT id_persona FROM personas WHERE ci='PAC-0001')
WHERE NOT EXISTS (SELECT 1 FROM factura_detalle fd WHERE fd.id_factura=f.id_factura);

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;

-- 16. VISTA PARA CONSULTAR SOLO LA OPERACIÓN DE FACTURACIÓN
CREATE OR REPLACE VIEW vw_facturacion_operativa AS
SELECT f.id_factura, f.fecha_emision, f.estado, f.tipo_pago,
       p.ci, p.nombre AS paciente,
       a.nombre AS aseguradora, ps.numero_poliza,
       d.nit_ci, d.razon_social, d.tipo_documento_fiscal,
       f.subtotal, f.monto_cobertura_seguro, f.total,
       u.nombre_usuario AS usuario_emisor,
       GROUP_CONCAT(DISTINCT s.nombre ORDER BY s.nombre SEPARATOR ', ') AS servicios
FROM facturas f
JOIN paciente_seguro ps ON ps.id_paciente_seguro=f.id_paciente_seguro
JOIN personas p ON p.id_persona=ps.id_persona
JOIN aseguradoras a ON a.id_aseguradora=ps.id_aseguradora
JOIN datos_facturacion d ON d.id_datos_facturacion=f.id_datos_facturacion
JOIN usuarios u ON u.id_usuario=f.id_usuario_factura
LEFT JOIN factura_detalle fd ON fd.id_factura=f.id_factura
LEFT JOIN servicios_medicos s ON s.id_servicio=fd.id_servicio
GROUP BY f.id_factura, f.fecha_emision, f.estado, f.tipo_pago,
         p.ci, p.nombre, a.nombre, ps.numero_poliza,
         d.nit_ci, d.razon_social, d.tipo_documento_fiscal,
         f.subtotal, f.monto_cobertura_seguro, f.total, u.nombre_usuario;

-- VERIFICACIÓN
SELECT 'Aseguradoras' AS tabla, COUNT(*) cantidad FROM aseguradoras
UNION ALL SELECT 'Pacientes', COUNT(*) FROM pacientes
UNION ALL SELECT 'Pólizas activas', COUNT(*) FROM paciente_seguro WHERE activo=1
UNION ALL SELECT 'Medicamentos', COUNT(*) FROM medicamentos
UNION ALL SELECT 'Exámenes', COUNT(*) FROM examenes_laboratorio
UNION ALL SELECT 'Consultas', COUNT(*) FROM consultas
UNION ALL SELECT 'Cirugías', COUNT(*) FROM cirugias
UNION ALL SELECT 'Internaciones', COUNT(*) FROM internaciones
UNION ALL SELECT 'Facturas', COUNT(*) FROM facturas;
