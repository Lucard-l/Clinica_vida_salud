-- Operaciones de usuarios y roles para Salud_y_vida
-- Ejecutar desde PHP con PDO y parámetros preparados.

USE Salud_y_vida;

-- Deshabilitar una cuenta sin eliminar su historial.
UPDATE usuarios
SET estado = FALSE
WHERE nombre_usuario = :nombre_usuario;

-- Habilitar una cuenta.
UPDATE usuarios
SET estado = TRUE
WHERE nombre_usuario = :nombre_usuario;

-- Eliminar una cuenta. Se recomienda hacerlo solo después de una confirmación administrativa.
DELETE FROM usuarios
WHERE nombre_usuario = :nombre_usuario;

-- Agregar un rol nuevo al ENUM actual. Reemplaza AUDITOR por el valor que necesites.
-- Haz una copia de seguridad antes de modificar la estructura.
ALTER TABLE roles
MODIFY nombre ENUM('ADMINISTRADOR','PACIENTE','ENFERMERO','MEDICO','FACTURADOR','AUDITOR') NOT NULL UNIQUE;

-- Alternativa recomendada para permitir roles sin modificar la tabla cada vez:
-- ALTER TABLE roles MODIFY nombre VARCHAR(50) NOT NULL UNIQUE;
-- Después podrás ejecutar:
-- INSERT INTO roles (nombre, descripcion) VALUES ('AUDITOR', 'Consulta de reportes y bitácora');
