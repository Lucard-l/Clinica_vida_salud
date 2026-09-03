USE Salud_y_vida;

-- Los pacientes pueden existir como registros clínicos, pero no como usuarios del sistema.
-- Se deshabilitan sus cuentas sin borrar pacientes ni historiales.
UPDATE usuarios u
JOIN roles r ON r.id_rol=u.id_rol
SET u.estado=0
WHERE r.nombre='PACIENTE';

-- Verificación: esta consulta debe devolver cero cuentas activas con rol PACIENTE.
SELECT u.id_usuario,u.nombre_usuario,p.nombre,r.nombre rol,u.estado
FROM usuarios u
JOIN roles r ON r.id_rol=u.id_rol
JOIN personas p ON p.id_persona=u.id_persona
WHERE r.nombre='PACIENTE';

-- El registro facial del panel solo debe mostrar cuentas operativas.
SELECT DISTINCT p.id_persona,p.ci,p.nombre,r.nombre rol
FROM usuarios u
JOIN roles r ON r.id_rol=u.id_rol
JOIN personas p ON p.id_persona=u.id_persona
WHERE r.nombre<>'PACIENTE' AND u.estado=1
ORDER BY p.nombre;
