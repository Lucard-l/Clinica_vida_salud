-- Salud Vida — creación del usuario administrador
-- Base de datos: Salud_y_vida
-- Contraseña inicial: admin123
-- La aplicación PHP debe validar con password_verify(), nunca comparar texto plano.

USE Salud_y_vida;

START TRANSACTION;

INSERT INTO roles (nombre, descripcion)
VALUES ('ADMINISTRADOR', 'Acceso completo a la gestión clínica y administrativa')
ON DUPLICATE KEY UPDATE id_rol = LAST_INSERT_ID(id_rol);
SET @id_rol_admin = LAST_INSERT_ID();

INSERT INTO personas (ci, nombre, fecha_nacimiento, telefono, direccion, correo)
VALUES ('ADMIN-0001', 'Administrador General', '1990-01-01', NULL, NULL, 'admin@saludvida.local')
ON DUPLICATE KEY UPDATE id_persona = LAST_INSERT_ID(id_persona);
SET @id_persona_admin = LAST_INSERT_ID();

INSERT INTO usuarios (
  id_persona,
  id_rol,
  nombre_usuario,
  contrasena_hash,
  estado
)
VALUES (
  @id_persona_admin,
  @id_rol_admin,
  'admin',
  '$2b$12$YWn7Hvv1JA1DkZBMRj45Z.5krvpS7xiV0A.StAhJMz.5j/FVyIjnu',
  TRUE
)
ON DUPLICATE KEY UPDATE
  contrasena_hash = VALUES(contrasena_hash),
  id_rol = VALUES(id_rol),
  estado = TRUE;

COMMIT;

-- Verificación del registro creado.
SELECT
  u.id_usuario,
  u.nombre_usuario,
  r.nombre AS rol,
  u.estado,
  p.nombre,
  p.correo
FROM usuarios u
INNER JOIN roles r ON r.id_rol = u.id_rol
INNER JOIN personas p ON p.id_persona = u.id_persona
WHERE u.nombre_usuario = 'admin';

-- Credenciales iniciales:
-- Usuario: admin
-- Contraseña: admin123
