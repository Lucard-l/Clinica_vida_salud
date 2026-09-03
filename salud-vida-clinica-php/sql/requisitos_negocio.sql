-- =============================================================
-- SALUD VIDA: requisitos de negocio y diseño relacional
-- Migración incremental para MariaDB 10.4+
-- Ejecutar DESPUÉS de salud_y_vida.sql y migracion_salud_vida_completa.sql.
-- No elimina datos ni tablas existentes.
-- =============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=1;

-- Una cirugía puede involucrar varios médicos; el cirujano principal
ALTER TABLE cirugias ADD COLUMN IF NOT EXISTS id_anestesiologo BIGINT NULL;
ALTER TABLE cirugias ADD INDEX IF NOT EXISTS idx_cirugias_anestesiologo (id_anestesiologo);
ALTER TABLE cirugias ADD CONSTRAINT fk_cirugias_anestesiologo FOREIGN KEY (id_anestesiologo) REFERENCES medicos(id_persona);

-- El cirujano principal
-- permanece en cirugias.id_cirujano_principal y el resto se registra aquí.
CREATE TABLE IF NOT EXISTS cirugia_medico (
  id_cirugia BIGINT NOT NULL,
  id_medico BIGINT NOT NULL,
  rol ENUM('CIRUJANO','ANESTESIOLOGO','APOYO') NOT NULL,
  PRIMARY KEY (id_cirugia,id_medico),
  KEY idx_cirugia_medico_medico (id_medico),
  CONSTRAINT fk_cm_cirugia FOREIGN KEY (id_cirugia) REFERENCES cirugias(id_cirugia) ON DELETE CASCADE,
  CONSTRAINT fk_cm_medico FOREIGN KEY (id_medico) REFERENCES medicos(id_persona)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Convenios por servicio, además del convenio general o por especialidad.
CREATE TABLE IF NOT EXISTS convenio_servicio (
  id_convenio BIGINT NOT NULL,
  id_servicio BIGINT NOT NULL,
  porcentaje_cobertura DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (porcentaje_cobertura BETWEEN 0 AND 100),
  PRIMARY KEY (id_convenio,id_servicio),
  CONSTRAINT fk_cs_convenio FOREIGN KEY (id_convenio) REFERENCES convenios_aseguradora(id_convenio) ON DELETE CASCADE,
  CONSTRAINT fk_cs_servicio FOREIGN KEY (id_servicio) REFERENCES servicios_medicos(id_servicio) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Pagos recibidos de facturas; permite pagos parciales y medios mixtos.
CREATE TABLE IF NOT EXISTS pagos_factura (
  id_pago BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_factura BIGINT NOT NULL,
  fecha_pago DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  medio_pago ENUM('EFECTIVO','TARJETA','TRANSFERENCIA','SEGURO','OTRO') NOT NULL,
  monto DECIMAL(12,2) NOT NULL CHECK (monto > 0),
  referencia VARCHAR(100) NULL,
  id_usuario BIGINT NOT NULL,
  CONSTRAINT fk_pf_factura FOREIGN KEY (id_factura) REFERENCES facturas(id_factura) ON DELETE CASCADE,
  CONSTRAINT fk_pf_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Respalda qué convenio y porcentaje se usaron en cada línea facturada.
CREATE TABLE IF NOT EXISTS factura_detalle_cobertura (
  id_detalle BIGINT PRIMARY KEY,
  id_convenio BIGINT NULL,
  porcentaje_aplicado DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (porcentaje_aplicado BETWEEN 0 AND 100),
  monto_cubierto DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (monto_cubierto >= 0),
  CONSTRAINT fk_fdc_detalle FOREIGN KEY (id_detalle) REFERENCES factura_detalle(id_detalle) ON DELETE CASCADE,
  CONSTRAINT fk_fdc_convenio FOREIGN KEY (id_convenio) REFERENCES convenios_aseguradora(id_convenio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Las restricciones más importantes se aplican por triggers porque MariaDB
-- no permite expresar solapamiento temporal con una UNIQUE convencional.
DROP TRIGGER IF EXISTS trg_consultas_validar_relaciones;
DROP TRIGGER IF EXISTS trg_cirugias_validar_equipo;
DROP TRIGGER IF EXISTS trg_cirugias_no_solapadas_ins;
DROP TRIGGER IF EXISTS trg_cirugias_no_solapadas_upd;
DROP TRIGGER IF EXISTS trg_internacion_validar_paciente;
DROP TRIGGER IF EXISTS trg_factura_validar_montos;
DROP TRIGGER IF EXISTS trg_pago_validar_saldo;

DELIMITER $$

CREATE TRIGGER trg_consultas_validar_relaciones
BEFORE INSERT ON consultas
FOR EACH ROW
BEGIN
  DECLARE v_paciente BIGINT DEFAULT NULL;
  DECLARE v_especialidad INT DEFAULT NULL;
  SELECT id_persona INTO v_paciente FROM historias_clinicas WHERE id_historia=NEW.id_historia LIMIT 1;
  IF v_paciente IS NULL OR v_paciente <> NEW.id_persona THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La historia clínica no pertenece al paciente seleccionado.';
  END IF;
  SELECT id_especialidad INTO v_especialidad FROM medico_especialidad WHERE id_persona=NEW.id_medico AND id_especialidad=NEW.id_especialidad LIMIT 1;
  IF v_especialidad IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El médico no tiene asignada la especialidad seleccionada.';
  END IF;
END$$

CREATE TRIGGER trg_cirugias_validar_equipo
BEFORE INSERT ON cirugias
FOR EACH ROW
BEGIN
  DECLARE v_asignado INT DEFAULT 0;
  IF NEW.id_cirujano_principal IS NULL OR NEW.id_anestesiologo IS NULL OR NEW.id_cirujano_principal=NEW.id_anestesiologo THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La cirugía requiere cirujano principal y anestesiólogo distintos.';
  END IF;
  IF NEW.id_cirujano_principal IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La cirugía requiere un cirujano principal.';
  END IF;
  SELECT COUNT(*) INTO v_asignado FROM medico_especialidad WHERE id_persona=NEW.id_cirujano_principal AND id_especialidad=NEW.id_especialidad;
  IF v_asignado=0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El cirujano principal no tiene la especialidad de la cirugía.';
  END IF;
END$$

CREATE TRIGGER trg_cirugias_no_solapadas_ins
BEFORE INSERT ON cirugias
FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM cirugias c WHERE c.id_quirofano=NEW.id_quirofano AND c.estado<>'CANCELADA' AND NEW.fecha_programada < c.fecha_fin_estimada AND c.fecha_programada < DATE_ADD(NEW.fecha_programada,INTERVAL NEW.duracion_estimada_minutos MINUTE)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El quirófano ya está ocupado en ese horario.';
  END IF;
END$$

CREATE TRIGGER trg_cirugias_no_solapadas_upd
BEFORE UPDATE ON cirugias
FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM cirugias c WHERE c.id_cirugia<>NEW.id_cirugia AND c.id_quirofano=NEW.id_quirofano AND c.estado<>'CANCELADA' AND NEW.fecha_programada < c.fecha_fin_estimada AND c.fecha_programada < DATE_ADD(NEW.fecha_programada,INTERVAL NEW.duracion_estimada_minutos MINUTE)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El quirófano ya está ocupado en ese horario.';
  END IF;
END$$

CREATE TRIGGER trg_internacion_validar_paciente
BEFORE INSERT ON internaciones
FOR EACH ROW
BEGIN
  DECLARE v_paciente BIGINT DEFAULT NULL;
  SELECT c.id_persona INTO v_paciente FROM ordenes_internacion o JOIN consultas c ON c.id_consulta=o.id_consulta WHERE o.id_orden=NEW.id_orden LIMIT 1;
  IF v_paciente IS NULL OR v_paciente<>NEW.id_persona THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La internación debe pertenecer al paciente de la orden.';
  END IF;
END$$

CREATE TRIGGER trg_factura_validar_montos
BEFORE INSERT ON facturas
FOR EACH ROW
BEGIN
  IF NEW.monto_cobertura_seguro < 0 OR NEW.monto_cobertura_seguro > NEW.subtotal THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La cobertura del seguro no puede superar el subtotal.';
  END IF;
END$$

CREATE TRIGGER trg_pago_validar_saldo
BEFORE INSERT ON pagos_factura
FOR EACH ROW
BEGIN
  DECLARE v_total DECIMAL(12,2) DEFAULT 0;
  DECLARE v_pagado DECIMAL(12,2) DEFAULT 0;
  SELECT total INTO v_total FROM facturas WHERE id_factura=NEW.id_factura;
  SELECT COALESCE(SUM(monto),0) INTO v_pagado FROM pagos_factura WHERE id_factura=NEW.id_factura;
  IF v_total IS NULL OR v_pagado + NEW.monto > v_total THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El pago supera el saldo pendiente de la factura.';
  END IF;
END$$

DELIMITER ;

-- Restricción explícita de factura: la cobertura no puede ser mayor al subtotal.
ALTER TABLE facturas ADD CONSTRAINT chk_factura_cobertura CHECK (monto_cobertura_seguro BETWEEN 0 AND subtotal);

-- Índices de consulta para búsquedas por identificadores y fechas.
ALTER TABLE cirugias ADD INDEX idx_cirugias_quirofano_horario (id_quirofano,fecha_programada,estado);
ALTER TABLE consultas ADD INDEX idx_consultas_paciente_fecha (id_persona,fecha_hora);
ALTER TABLE consultas ADD INDEX idx_consultas_medico_fecha (id_medico,fecha_hora);
ALTER TABLE factura_detalle ADD INDEX idx_factura_detalle_servicio (id_servicio);
ALTER TABLE pagos_factura ADD INDEX idx_pagos_factura_fecha (id_factura,fecha_pago);

-- Genera automáticamente un cargo por cada día de internación activo.
DROP PROCEDURE IF EXISTS sp_generar_cargos_internacion;
DELIMITER $$
CREATE PROCEDURE sp_generar_cargos_internacion(IN p_fecha DATE)
BEGIN
  INSERT IGNORE INTO cargos_internacion(id_internacion,fecha,concepto,monto)
  SELECT i.id_internacion,p_fecha,'Estadía diaria',COALESCE(fn_tarifa_vigente(h.id_tipo_habitacion,p_fecha),0)
  FROM internaciones i JOIN habitaciones h ON h.id_habitacion=i.id_habitacion
  WHERE i.estado='ACTIVA' AND i.fecha_ingreso < DATE_ADD(p_fecha,INTERVAL 1 DAY)
    AND (i.fecha_alta IS NULL OR i.fecha_alta >= p_fecha);
END$$
DELIMITER ;

-- El evento funciona cuando event_scheduler está habilitado en MariaDB.
DROP EVENT IF EXISTS ev_cargos_internacion_diarios;
DELIMITER $$
CREATE EVENT ev_cargos_internacion_diarios
ON SCHEDULE EVERY 1 DAY STARTS (CURRENT_DATE + INTERVAL 1 DAY)
DO CALL sp_generar_cargos_internacion(CURRENT_DATE)$$
DELIMITER ;

-- Consultas de verificación para la entrega académica.
CREATE OR REPLACE VIEW vw_historial_atencion AS
SELECT c.id_consulta,c.fecha_hora,c.id_persona paciente,c.id_medico medico,c.id_especialidad,c.estado
FROM consultas c;

CREATE OR REPLACE VIEW vw_facturacion_detallada AS
SELECT f.id_factura,f.fecha_emision,f.tipo_pago,f.subtotal,f.monto_cobertura_seguro,f.total,f.estado,
       fd.id_detalle,fd.id_servicio,fd.cantidad,fd.precio_unitario,fd.subtotal subtotal_detalle
FROM facturas f JOIN factura_detalle fd ON fd.id_factura=f.id_factura;

-- Fin de la migración.


-- Registro recomendado de cirugía: crea la cirugía y su equipo en una sola transacción.
DROP PROCEDURE IF EXISTS sp_registrar_cirugia_completa;
DELIMITER $$
CREATE PROCEDURE sp_registrar_cirugia_completa(
  IN p_id_persona BIGINT,
  IN p_id_quirofano SMALLINT,
  IN p_id_especialidad SMALLINT,
  IN p_id_cirujano_principal BIGINT,
  IN p_id_anestesiologo BIGINT,
  IN p_fecha_programada DATETIME,
  IN p_duracion INT,
  IN p_diagnostico TEXT
)
BEGIN
  DECLARE v_cirugia BIGINT;
  IF p_id_anestesiologo IS NULL OR p_id_cirujano_principal IS NULL OR p_id_anestesiologo=p_id_cirujano_principal THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La cirugía requiere cirujano principal y anestesiólogo distintos.';
  END IF;
  START TRANSACTION;
  INSERT INTO cirugias(id_persona,id_quirofano,id_especialidad,id_cirujano_principal,id_anestesiologo,fecha_programada,duracion_estimada_minutos,diagnostico_prequirurgico)
  VALUES(p_id_persona,p_id_quirofano,p_id_especialidad,p_id_cirujano_principal,p_id_anestesiologo,p_fecha_programada,COALESCE(p_duracion,120),p_diagnostico);
  SET v_cirugia=LAST_INSERT_ID();
  INSERT INTO cirugia_medico(id_cirugia,id_medico,rol) VALUES(v_cirugia,p_id_cirujano_principal,'CIRUJANO'),(v_cirugia,p_id_anestesiologo,'ANESTESIOLOGO');
  COMMIT;
END$$
DELIMITER ;

-- Regla de equipo: una persona no puede ocupar simultáneamente dos roles en la misma cirugía.
DROP TRIGGER IF EXISTS trg_cirugia_medico_unico_rol;
DELIMITER $$
CREATE TRIGGER trg_cirugia_medico_unico_rol
BEFORE INSERT ON cirugia_medico
FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM cirugia_medico WHERE id_cirugia=NEW.id_cirugia AND id_medico=NEW.id_medico) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El médico ya está asignado a esta cirugía.';
  END IF;
END$$
DELIMITER ;

-- Fin de reglas adicionales.

