-- Mejora de registro facial, bitácora y datos de prueba para Salud Vida
-- Compatible con la base salud_y_vida(1).sql recibida.

SELECT id_registro_facial, id_persona, algoritmo, activo, fecha_registro
FROM registro_facial ORDER BY fecha_registro DESC;

UPDATE registro_facial
SET algoritmo = 'FOTOGRAFIA', activo = 1
WHERE algoritmo = 'CAPTURA_PENDIENTE_DE_BIOMETRIA';

-- Ejemplos visibles en la pantalla Bitácora.
INSERT INTO bitacora (id_usuario,tabla_afectada,id_registro,accion,detalle)
SELECT 1,'personas',24,'INSERT','{"origen":"dato de prueba","modulo":"Pacientes"}'
WHERE EXISTS (SELECT 1 FROM usuarios WHERE id_usuario=1)
  AND NOT EXISTS (SELECT 1 FROM bitacora WHERE tabla_afectada='personas' AND id_registro=24 AND accion='INSERT');
INSERT INTO bitacora (id_usuario,tabla_afectada,id_registro,accion,detalle)
SELECT 1,'usuarios',1,'UPDATE','{"campo":"rol","valor_nuevo":"ADMINISTRADOR","modulo":"Usuarios y roles"}'
WHERE EXISTS (SELECT 1 FROM usuarios WHERE id_usuario=1)
  AND NOT EXISTS (SELECT 1 FROM bitacora WHERE tabla_afectada='usuarios' AND id_registro=1 AND accion='UPDATE');
INSERT INTO bitacora (id_usuario,tabla_afectada,id_registro,accion,detalle)
SELECT 1,'registro_facial',1,'INSERT','{"metodo":"FOTOGRAFIA","resultado":"Registro de prueba"}'
WHERE EXISTS (SELECT 1 FROM usuarios WHERE id_usuario=1)
  AND NOT EXISTS (SELECT 1 FROM bitacora WHERE tabla_afectada='registro_facial' AND id_registro=1);

-- Para los triggers automáticos del proyecto, la bitácora debe ser alimentada
-- desde la aplicación con el usuario de sesión. Estos triggers de demostración
-- dejan registrado el cambio de estado de pacientes usando usuario NULL.
DROP TRIGGER IF EXISTS trg_bitacora_paciente_estado;
DELIMITER $$
CREATE TRIGGER trg_bitacora_paciente_estado
AFTER UPDATE ON pacientes
FOR EACH ROW
BEGIN
  IF OLD.activo <> NEW.activo THEN
    INSERT INTO bitacora(id_usuario,tabla_afectada,id_registro,accion,detalle)
    VALUES(NULL,'pacientes',NEW.id_persona,'UPDATE',JSON_OBJECT('campo','activo','anterior',OLD.activo,'nuevo',NEW.activo));
  END IF;
END$$
DELIMITER ;

-- La tabla registro_facial mantiene una sola fila por persona mediante su índice
-- UNIQUE(id_persona). El PHP usa esa regla para reemplazar foto o descriptor.

-- Clasificación de la persona para evitar duplicidades y distinguir vínculos.
ALTER TABLE personas
  ADD COLUMN IF NOT EXISTS tipo_persona ENUM('PACIENTE','PERSONAL_HOSPITAL','USUARIO_EXTERNO') NOT NULL DEFAULT 'USUARIO_EXTERNO' AFTER correo;

UPDATE personas p SET tipo_persona='PACIENTE'
WHERE EXISTS (SELECT 1 FROM pacientes pa WHERE pa.id_persona=p.id_persona);
UPDATE personas p SET tipo_persona='PERSONAL_HOSPITAL'
WHERE EXISTS (SELECT 1 FROM medicos m WHERE m.id_persona=p.id_persona)
   OR EXISTS (SELECT 1 FROM usuarios u JOIN roles r ON r.id_rol=u.id_rol WHERE u.id_persona=p.id_persona AND r.nombre <> 'PACIENTE');
