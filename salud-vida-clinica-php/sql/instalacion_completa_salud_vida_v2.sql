-- INSTALADOR COMPLETO Salud_y_vida v2
-- Importar este archivo como una sola operación desde phpMyAdmin.
-- =============================================================
-- BASE DE DATOS COMPLETA: Salud_y_vida
-- Compatible con MySQL 8.x / XAMPP
-- Basada en el diagrama ER adjunto y compatible con la aplicación PHP.
-- =============================================================

DROP DATABASE IF EXISTS Salud_y_vida;
CREATE DATABASE Salud_y_vida
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE Salud_y_vida;

SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET FOREIGN_KEY_CHECKS = 0;

-- =========================
-- PERSONAS, ROLES Y ACCESO
-- =========================
CREATE TABLE personas (
    id_persona BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ci VARCHAR(30) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    telefono VARCHAR(30) NULL,
    direccion VARCHAR(255) NULL,
    correo VARCHAR(150) NULL UNIQUE,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE roles (
    id_rol SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre ENUM('ADMINISTRADOR','SUPERVISOR','PACIENTE','ENFERMERO','MEDICO','FACTURADOR') NOT NULL UNIQUE,
    descripcion VARCHAR(255) NULL
) ENGINE=InnoDB;

CREATE TABLE pacientes (
    id_persona BIGINT UNSIGNED PRIMARY KEY,
    tipo_sangre VARCHAR(5) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_pacientes_persona FOREIGN KEY (id_persona)
        REFERENCES personas(id_persona) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE medicos (
    id_persona BIGINT UNSIGNED PRIMARY KEY,
    matricula_profesional VARCHAR(50) NOT NULL UNIQUE,
    tipo_contrato ENUM('FIJO','PORCENTAJE') NOT NULL DEFAULT 'FIJO',
    monto_fijo DECIMAL(12,2) NULL,
    porcentaje_procedimiento DECIMAL(5,2) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_medicos_persona FOREIGN KEY (id_persona)
        REFERENCES personas(id_persona) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_medico_porcentaje CHECK (porcentaje_procedimiento IS NULL OR porcentaje_procedimiento BETWEEN 0 AND 100),
    CONSTRAINT chk_medico_monto CHECK (monto_fijo IS NULL OR monto_fijo >= 0)
) ENGINE=InnoDB;

CREATE TABLE usuarios (
    id_usuario BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_persona BIGINT UNSIGNED NOT NULL,
    id_rol SMALLINT UNSIGNED NOT NULL,
    nombre_usuario VARCHAR(60) NOT NULL UNIQUE,
    contrasena_hash VARCHAR(255) NOT NULL,
    plantilla_facial LONGBLOB NULL,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
    ultimo_acceso DATETIME NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuarios_persona FOREIGN KEY (id_persona)
        REFERENCES personas(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_usuarios_rol FOREIGN KEY (id_rol)
        REFERENCES roles(id_rol) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE bitacora (
    id_bitacora BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_usuario BIGINT UNSIGNED NULL,
    tabla_afectada VARCHAR(100) NOT NULL,
    id_registro BIGINT NULL,
    accion VARCHAR(30) NOT NULL,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    detalle JSON NULL,
    CONSTRAINT fk_bitacora_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- =========================
-- CATÁLOGOS CLÍNICOS
-- =========================
CREATE TABLE especialidades (
    id_especialidad SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NULL
) ENGINE=InnoDB;

CREATE TABLE medico_especialidad (
    id_persona BIGINT UNSIGNED NOT NULL,
    id_especialidad SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (id_persona, id_especialidad),
    CONSTRAINT fk_me_medico FOREIGN KEY (id_persona)
        REFERENCES medicos(id_persona) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_me_especialidad FOREIGN KEY (id_especialidad)
        REFERENCES especialidades(id_especialidad) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE consultorios (
    id_consultorio SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    numero VARCHAR(30) NOT NULL UNIQUE,
    estado ENUM('DISPONIBLE','MANTENIMIENTO','INACTIVO') NOT NULL DEFAULT 'DISPONIBLE'
) ENGINE=InnoDB;

CREATE TABLE medicamentos (
    id_medicamento BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    presentacion VARCHAR(100) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE KEY uq_medicamento (nombre, presentacion)
) ENGINE=InnoDB;

CREATE TABLE examenes_laboratorio (
    id_examen SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    precio DECIMAL(12,2) NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_examen_precio CHECK (precio >= 0)
) ENGINE=InnoDB;

-- =========================
-- HISTORIAS Y CONSULTAS
-- =========================
CREATE TABLE historias_clinicas (
    id_historia BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_persona BIGINT UNSIGNED NOT NULL,
    antecedentes TEXT NULL,
    alergias TEXT NULL,
    observaciones TEXT NULL,
    fecha_apertura DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_historias_persona FOREIGN KEY (id_persona)
        REFERENCES pacientes(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_historias_persona (id_persona)
) ENGINE=InnoDB;

CREATE TABLE consultas (
    id_consulta BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    consulta_padre BIGINT UNSIGNED NULL,
    id_persona BIGINT UNSIGNED NOT NULL,
    id_medico BIGINT UNSIGNED NOT NULL,
    id_especialidad SMALLINT UNSIGNED NOT NULL,
    id_historia BIGINT UNSIGNED NOT NULL,
    id_consultorio SMALLINT UNSIGNED NOT NULL,
    fecha_hora DATETIME NOT NULL,
    duracion_estimada_minutos SMALLINT UNSIGNED NOT NULL DEFAULT 30,
    motivo TEXT NULL,
    estado ENUM('PROGRAMADA','CONFIRMADA','EN_CURSO','ATENDIDA','CANCELADA','NO_ASISTIO') NOT NULL DEFAULT 'PROGRAMADA',
    tipo_consulta ENUM('PRIMERA_VEZ','RECONSULTA','CONTROL','CONTROL_POSTOPERATORIO','URGENCIA') NOT NULL DEFAULT 'PRIMERA_VEZ',
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_consulta_padre FOREIGN KEY (consulta_padre)
        REFERENCES consultas(id_consulta) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_consulta_paciente FOREIGN KEY (id_persona)
        REFERENCES pacientes(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_consulta_medico FOREIGN KEY (id_medico)
        REFERENCES medicos(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_consulta_especialidad FOREIGN KEY (id_especialidad)
        REFERENCES especialidades(id_especialidad) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_consulta_historia FOREIGN KEY (id_historia)
        REFERENCES historias_clinicas(id_historia) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_consulta_consultorio FOREIGN KEY (id_consultorio)
        REFERENCES consultorios(id_consultorio) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_consulta_duracion CHECK (duracion_estimada_minutos >= 5),
    INDEX idx_consulta_paciente_fecha (id_persona, fecha_hora),
    INDEX idx_consulta_medico_fecha (id_medico, fecha_hora)
) ENGINE=InnoDB;

CREATE TABLE recetas (
    id_receta BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_consulta BIGINT UNSIGNED NOT NULL UNIQUE,
    fecha_emision DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT NULL,
    CONSTRAINT fk_receta_consulta FOREIGN KEY (id_consulta)
        REFERENCES consultas(id_consulta) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE receta_detalle (
    id_receta_detalle BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_receta BIGINT UNSIGNED NOT NULL,
    id_medicamento BIGINT UNSIGNED NOT NULL,
    dosis VARCHAR(100) NOT NULL,
    frecuencia VARCHAR(100) NOT NULL,
    duracion_dias SMALLINT UNSIGNED NULL,
    indicaciones TEXT NULL,
    CONSTRAINT fk_rd_receta FOREIGN KEY (id_receta)
        REFERENCES recetas(id_receta) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_rd_medicamento FOREIGN KEY (id_medicamento)
        REFERENCES medicamentos(id_medicamento) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE solicitudes_laboratorio (
    id_solicitud BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_consulta BIGINT UNSIGNED NOT NULL UNIQUE,
    estado ENUM('SOLICITADA','EN_PROCESO','COMPLETADA','CANCELADA') NOT NULL DEFAULT 'SOLICITADA',
    fecha_solicitud DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sl_consulta FOREIGN KEY (id_consulta)
        REFERENCES consultas(id_consulta) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE solicitud_laboratorio_detalle (
    id_detalle BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_solicitud BIGINT UNSIGNED NOT NULL,
    id_examen SMALLINT UNSIGNED NOT NULL,
    resultado TEXT NULL,
    fecha_resultado DATETIME NULL,
    CONSTRAINT fk_sld_solicitud FOREIGN KEY (id_solicitud)
        REFERENCES solicitudes_laboratorio(id_solicitud) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_sld_examen FOREIGN KEY (id_examen)
        REFERENCES examenes_laboratorio(id_examen) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =========================
-- HABITACIONES E INTERNACIONES
-- =========================
CREATE TABLE tipos_habitacion (
    id_tipo_habitacion SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NULL
) ENGINE=InnoDB;

CREATE TABLE tipo_habitacion_tarifa_historico (
    id_tarifa BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_tipo_habitacion SMALLINT UNSIGNED NOT NULL,
    tarifa_diaria DECIMAL(12,2) NOT NULL,
    fecha_desde DATE NOT NULL,
    CONSTRAINT fk_tarifa_tipo FOREIGN KEY (id_tipo_habitacion)
        REFERENCES tipos_habitacion(id_tipo_habitacion) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_tarifa_monto CHECK (tarifa_diaria >= 0),
    UNIQUE KEY uq_tarifa_tipo_fecha (id_tipo_habitacion, fecha_desde)
) ENGINE=InnoDB;

CREATE TABLE habitaciones (
    id_habitacion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    numero VARCHAR(30) NOT NULL UNIQUE,
    id_tipo_habitacion SMALLINT UNSIGNED NOT NULL,
    estado ENUM('DISPONIBLE','OCUPADA','MANTENIMIENTO','INACTIVA') NOT NULL DEFAULT 'DISPONIBLE',
    CONSTRAINT fk_habitacion_tipo FOREIGN KEY (id_tipo_habitacion)
        REFERENCES tipos_habitacion(id_tipo_habitacion) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE ordenes_internacion (
    id_orden BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_consulta BIGINT UNSIGNED NOT NULL UNIQUE,
    motivo TEXT NOT NULL,
    fecha_orden DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_orden_consulta FOREIGN KEY (id_consulta)
        REFERENCES consultas(id_consulta) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE internaciones (
    id_internacion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_orden BIGINT UNSIGNED NOT NULL UNIQUE,
    id_persona BIGINT UNSIGNED NOT NULL,
    id_habitacion BIGINT UNSIGNED NOT NULL,
    fecha_ingreso DATETIME NOT NULL,
    fecha_alta DATETIME NULL,
    id_medico_autoriza_alta BIGINT UNSIGNED NULL,
    estado ENUM('ACTIVA','FINALIZADA','CANCELADA') NOT NULL DEFAULT 'ACTIVA',
    CONSTRAINT fk_internacion_orden FOREIGN KEY (id_orden)
        REFERENCES ordenes_internacion(id_orden) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_internacion_paciente FOREIGN KEY (id_persona)
        REFERENCES pacientes(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_internacion_habitacion FOREIGN KEY (id_habitacion)
        REFERENCES habitaciones(id_habitacion) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_internacion_medico FOREIGN KEY (id_medico_autoriza_alta)
        REFERENCES medicos(id_persona) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_internacion_fechas CHECK (fecha_alta IS NULL OR fecha_alta >= fecha_ingreso),
    INDEX idx_internacion_estado (estado)
) ENGINE=InnoDB;

CREATE TABLE cargos_internacion (
    id_cargo BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_internacion BIGINT UNSIGNED NOT NULL,
    fecha DATE NOT NULL,
    concepto VARCHAR(150) NOT NULL DEFAULT 'Cargo de internación',
    monto DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_cargo_internacion FOREIGN KEY (id_internacion)
        REFERENCES internaciones(id_internacion) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_cargo_monto CHECK (monto >= 0)
) ENGINE=InnoDB;

-- =========================
-- CIRUGÍAS
-- =========================
CREATE TABLE quirofanos (
    id_quirofano SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    estado ENUM('DISPONIBLE','MANTENIMIENTO','INACTIVO') NOT NULL DEFAULT 'DISPONIBLE'
) ENGINE=InnoDB;

CREATE TABLE cirugias (
    id_cirugia BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_persona BIGINT UNSIGNED NOT NULL,
    id_quirofano SMALLINT UNSIGNED NOT NULL,
    id_especialidad SMALLINT UNSIGNED NOT NULL,
    id_cirujano_principal BIGINT UNSIGNED NOT NULL,
    fecha_programada DATETIME NOT NULL,
    duracion_estimada_minutos SMALLINT UNSIGNED NOT NULL DEFAULT 120,
    diagnostico_prequirurgico TEXT NULL,
    estado ENUM('PROGRAMADA','CONFIRMADA','EN_CURSO','REALIZADA','CANCELADA') NOT NULL DEFAULT 'PROGRAMADA',
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cirugia_paciente FOREIGN KEY (id_persona)
        REFERENCES pacientes(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_cirugia_quirofano FOREIGN KEY (id_quirofano)
        REFERENCES quirofanos(id_quirofano) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_cirugia_especialidad FOREIGN KEY (id_especialidad)
        REFERENCES especialidades(id_especialidad) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_cirugia_cirujano FOREIGN KEY (id_cirujano_principal)
        REFERENCES medicos(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_cirugia_duracion CHECK (duracion_estimada_minutos >= 10),
    INDEX idx_cirugia_quirofano_fecha (id_quirofano, fecha_programada)
) ENGINE=InnoDB;

CREATE TABLE cirugia_personal (
    id_cirugia BIGINT UNSIGNED NOT NULL,
    id_persona BIGINT UNSIGNED NOT NULL,
    rol ENUM('CIRUJANO','ANESTESIOLOGO','ENFERMERO','ASISTENTE','OTRO') NOT NULL,
    PRIMARY KEY (id_cirugia, id_persona),
    CONSTRAINT fk_cp_cirugia FOREIGN KEY (id_cirugia)
        REFERENCES cirugias(id_cirugia) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_cp_persona FOREIGN KEY (id_persona)
        REFERENCES personas(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE insumos (
    id_insumo BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    stock_actual DECIMAL(12,2) NOT NULL DEFAULT 0,
    unidad_medida VARCHAR(30) NOT NULL DEFAULT 'UNIDAD',
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_insumo_stock CHECK (stock_actual >= 0)
) ENGINE=InnoDB;

CREATE TABLE cirugia_insumo (
    id_cirugia BIGINT UNSIGNED NOT NULL,
    id_insumo BIGINT UNSIGNED NOT NULL,
    cantidad_utilizada DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (id_cirugia, id_insumo),
    CONSTRAINT fk_ci_cirugia FOREIGN KEY (id_cirugia)
        REFERENCES cirugias(id_cirugia) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_ci_insumo FOREIGN KEY (id_insumo)
        REFERENCES insumos(id_insumo) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_cirugia_insumo_cantidad CHECK (cantidad_utilizada > 0)
) ENGINE=InnoDB;

-- =========================
-- SEGUROS Y FACTURACIÓN
-- =========================
CREATE TABLE aseguradoras (
    id_aseguradora SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    nit VARCHAR(40) NOT NULL UNIQUE,
    telefono VARCHAR(30) NULL,
    email VARCHAR(150) NULL,
    es_reservada BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB;

CREATE TABLE convenios_aseguradora (
    id_convenio BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_aseguradora SMALLINT UNSIGNED NOT NULL,
    id_especialidad SMALLINT UNSIGNED NOT NULL,
    porcentaje_cobertura DECIMAL(5,2) NOT NULL,
    fecha_inicio DATE NOT NULL DEFAULT (CURRENT_DATE),
    fecha_fin DATE NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_convenio_aseguradora FOREIGN KEY (id_aseguradora)
        REFERENCES aseguradoras(id_aseguradora) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_convenio_especialidad FOREIGN KEY (id_especialidad)
        REFERENCES especialidades(id_especialidad) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_convenio_porcentaje CHECK (porcentaje_cobertura BETWEEN 0 AND 100),
    CONSTRAINT chk_convenio_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
) ENGINE=InnoDB;

CREATE TABLE paciente_seguro (
    id_paciente_seguro BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_persona BIGINT UNSIGNED NOT NULL,
    id_aseguradora SMALLINT UNSIGNED NOT NULL,
    numero_poliza VARCHAR(100) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_ps_paciente FOREIGN KEY (id_persona)
        REFERENCES pacientes(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ps_aseguradora FOREIGN KEY (id_aseguradora)
        REFERENCES aseguradoras(id_aseguradora) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_ps_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    UNIQUE KEY uq_poliza_aseguradora (id_aseguradora, numero_poliza),
    INDEX idx_ps_persona_activo (id_persona, activo)
) ENGINE=InnoDB;

CREATE TABLE servicios_medicos (
    id_servicio BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    id_especialidad SMALLINT UNSIGNED NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_servicio_especialidad FOREIGN KEY (id_especialidad)
        REFERENCES especialidades(id_especialidad) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE servicio_precio_historico (
    id_precio BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_servicio BIGINT UNSIGNED NOT NULL,
    precio DECIMAL(12,2) NOT NULL,
    fecha_desde DATE NOT NULL,
    CONSTRAINT fk_precio_servicio FOREIGN KEY (id_servicio)
        REFERENCES servicios_medicos(id_servicio) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_precio_servicio CHECK (precio >= 0),
    UNIQUE KEY uq_precio_servicio_fecha (id_servicio, fecha_desde)
) ENGINE=InnoDB;

CREATE TABLE datos_facturacion (
    id_datos_facturacion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nit_ci VARCHAR(40) NOT NULL,
    razon_social VARCHAR(180) NOT NULL,
    tipo_documento_fiscal ENUM('FACTURA_CREDITO_FISCAL','FACTURA_SIN_CREDITO_FISCAL','RECIBO') NOT NULL
) ENGINE=InnoDB;

CREATE TABLE facturas (
    id_factura BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_paciente_seguro BIGINT UNSIGNED NOT NULL,
    id_usuario_factura BIGINT UNSIGNED NOT NULL,
    id_datos_facturacion BIGINT UNSIGNED NOT NULL,
    tipo_pago ENUM('PARTICULAR','SEGURO','MIXTO') NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    monto_cobertura_seguro DECIMAL(12,2) NOT NULL DEFAULT 0,
    total DECIMAL(12,2) GENERATED ALWAYS AS (subtotal - monto_cobertura_seguro) STORED,
    estado ENUM('PENDIENTE','PAGADA','ANULADA') NOT NULL DEFAULT 'PENDIENTE',
    fecha_emision DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_factura_seguro FOREIGN KEY (id_paciente_seguro)
        REFERENCES paciente_seguro(id_paciente_seguro) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_factura_usuario FOREIGN KEY (id_usuario_factura)
        REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_factura_datos FOREIGN KEY (id_datos_facturacion)
        REFERENCES datos_facturacion(id_datos_facturacion) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_factura_subtotal CHECK (subtotal >= 0),
    CONSTRAINT chk_factura_cobertura CHECK (monto_cobertura_seguro BETWEEN 0 AND subtotal),
    INDEX idx_factura_fecha_estado (fecha_emision, estado)
) ENGINE=InnoDB;

CREATE TABLE factura_detalle (
    id_detalle BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_factura BIGINT UNSIGNED NOT NULL,
    id_servicio BIGINT UNSIGNED NOT NULL,
    id_consulta BIGINT UNSIGNED NULL,
    id_cirugia BIGINT UNSIGNED NULL,
    id_internacion BIGINT UNSIGNED NULL,
    cantidad DECIMAL(10,2) NOT NULL DEFAULT 1,
    precio_unitario DECIMAL(12,2) NOT NULL DEFAULT 0,
    subtotal DECIMAL(12,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    CONSTRAINT fk_fd_factura FOREIGN KEY (id_factura)
        REFERENCES facturas(id_factura) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_fd_servicio FOREIGN KEY (id_servicio)
        REFERENCES servicios_medicos(id_servicio) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_fd_consulta FOREIGN KEY (id_consulta)
        REFERENCES consultas(id_consulta) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_fd_cirugia FOREIGN KEY (id_cirugia)
        REFERENCES cirugias(id_cirugia) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_fd_internacion FOREIGN KEY (id_internacion)
        REFERENCES internaciones(id_internacion) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_fd_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_fd_precio CHECK (precio_unitario >= 0),
    INDEX idx_fd_servicio (id_servicio)
) ENGINE=InnoDB;

CREATE TABLE pagos_medicos (
    id_pago BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_medico BIGINT UNSIGNED NOT NULL,
    periodo DATE NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    fecha_pago DATETIME NULL,
    estado ENUM('PENDIENTE','PAGADO','ANULADO') NOT NULL DEFAULT 'PENDIENTE',
    CONSTRAINT fk_pago_medico FOREIGN KEY (id_medico)
        REFERENCES medicos(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_pago_monto CHECK (monto >= 0)
) ENGINE=InnoDB;

-- =========================
-- TRIGGERS DE AUDITORÍA Y REGLAS BÁSICAS
-- =========================
DELIMITER $$

CREATE TRIGGER trg_consultas_no_reconsulta_circular
BEFORE INSERT ON consultas
FOR EACH ROW
BEGIN
    IF NEW.consulta_padre IS NOT NULL AND NEW.consulta_padre = NEW.id_consulta THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Una consulta no puede ser padre de sí misma';
    END IF;
END$$

CREATE TRIGGER trg_internacion_habitacion_ocupada
BEFORE INSERT ON internaciones
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM internaciones WHERE id_habitacion = NEW.id_habitacion AND estado = 'ACTIVA') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La habitación seleccionada ya está ocupada';
    END IF;
END$$

CREATE TRIGGER trg_internacion_alta_valida
BEFORE UPDATE ON internaciones
FOR EACH ROW
BEGIN
    IF NEW.estado = 'FINALIZADA' AND NEW.fecha_alta IS NULL THEN
        SET NEW.fecha_alta = CURRENT_TIMESTAMP;
    END IF;
END$$

CREATE TRIGGER trg_factura_detalle_recalcula_subtotal
AFTER INSERT ON factura_detalle
FOR EACH ROW
BEGIN
    UPDATE facturas f
    SET f.subtotal = (SELECT COALESCE(SUM(fd.subtotal),0) FROM factura_detalle fd WHERE fd.id_factura = NEW.id_factura)
    WHERE f.id_factura = NEW.id_factura;
END$$

CREATE TRIGGER trg_factura_detalle_recalcula_subtotal_update
AFTER UPDATE ON factura_detalle
FOR EACH ROW
BEGIN
    UPDATE facturas f
    SET f.subtotal = (SELECT COALESCE(SUM(fd.subtotal),0) FROM factura_detalle fd WHERE fd.id_factura = NEW.id_factura)
    WHERE f.id_factura = NEW.id_factura;
END$$

CREATE TRIGGER trg_factura_detalle_recalcula_subtotal_delete
AFTER DELETE ON factura_detalle
FOR EACH ROW
BEGIN
    UPDATE facturas f
    SET f.subtotal = (SELECT COALESCE(SUM(fd.subtotal),0) FROM factura_detalle fd WHERE fd.id_factura = OLD.id_factura)
    WHERE f.id_factura = OLD.id_factura;
END$$

DELIMITER ;

-- =========================
-- DATOS INICIALES DE CATÁLOGO
-- =========================
INSERT INTO roles (nombre, descripcion) VALUES
('ADMINISTRADOR','Acceso completo al sistema'),
('PACIENTE','Acceso limitado como paciente'),
('ENFERMERO','Gestión operativa de pacientes y consultas'),
('MEDICO','Atención médica y gestión clínica'),
('FACTURADOR','Gestión de seguros y facturación'),
('SUPERVISOR','Operación integral sin administración de usuarios');

INSERT INTO aseguradoras (nombre, nit, es_reservada)
VALUES ('PARTICULAR / SIN ASEGURADORA', '0', TRUE);

INSERT INTO tipos_habitacion (nombre, descripcion) VALUES
('SIMPLE','Habitación individual'),
('DOBLE','Habitación para dos pacientes'),
('UTI','Unidad de terapia intensiva');

INSERT INTO especialidades (nombre, descripcion) VALUES
('MEDICINA GENERAL','Atención médica general');

INSERT INTO consultorios (numero, estado) VALUES ('CONS-01','DISPONIBLE');
INSERT INTO quirofanos (nombre, estado) VALUES ('QUIRÓFANO 1','DISPONIBLE');

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================
-- CREACIÓN OPCIONAL DEL USUARIO ADMINISTRADOR
-- =============================================================
-- Ejecuta este bloque después de crear la base. La contraseña inicial es admin123.
-- El hash corresponde a password_hash('admin123', PASSWORD_BCRYPT).
-- =============================================================

INSERT INTO personas (ci, nombre, fecha_nacimiento, telefono, correo)
VALUES ('0000000', 'Administrador del sistema', '1990-01-01', NULL, 'admin@saludvida.local');

INSERT INTO usuarios (id_persona, id_rol, nombre_usuario, contrasena_hash, estado)
SELECT p.id_persona, r.id_rol,
       'admin',
       '$2b$12$YWn7Hvv1JA1DkZBMRj45Z.5krvpS7xiV0A.StAhJMz.5j/FVyIjnu',
       TRUE
FROM personas p CROSS JOIN roles r
WHERE p.ci = '0000000' AND r.nombre = 'ADMINISTRADOR';

-- Verificación rápida:
-- SHOW TABLES;
-- SELECT id_rol, nombre FROM roles;
-- SELECT id_usuario, nombre_usuario, estado FROM usuarios;

-- =============================================================
-- MIGRACIÓN Salud_y_vida v2: diagrama y requisitos operativos
-- Ejecutar después de Salud_y_vida_nueva_completa.sql
-- MySQL 8.x / XAMPP
-- =============================================================
USE Salud_y_vida;

-- Nuevo nivel de poder solicitado.
ALTER TABLE roles MODIFY nombre ENUM('ADMINISTRADOR','SUPERVISOR','PACIENTE','ENFERMERO','MEDICO','FACTURADOR') NOT NULL UNIQUE;
INSERT INTO roles (nombre, descripcion) VALUES
('SUPERVISOR','Puede registrar operaciones clínicas y administrativas y facturar')
ON DUPLICATE KEY UPDATE descripcion=VALUES(descripcion);

-- Contratos históricos de médicos.
CREATE TABLE IF NOT EXISTS contratos_medico (
    id_contrato BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_medico BIGINT UNSIGNED NOT NULL,
    tipo_contrato ENUM('FIJO','PORCENTAJE') NOT NULL,
    monto_fijo DECIMAL(12,2) NULL,
    porcentaje_procedimiento DECIMAL(5,2) NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    observaciones VARCHAR(255) NULL,
    CONSTRAINT fk_contrato_medico FOREIGN KEY (id_medico) REFERENCES medicos(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_contrato_monto CHECK (monto_fijo IS NULL OR monto_fijo >= 0),
    CONSTRAINT chk_contrato_porcentaje CHECK (porcentaje_procedimiento IS NULL OR porcentaje_procedimiento BETWEEN 0 AND 100),
    CONSTRAINT chk_contrato_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    INDEX idx_contrato_medico_activo (id_medico, activo)
) ENGINE=InnoDB;

-- Una sola inscripción facial por persona. La inscripción la realiza el administrador.
CREATE TABLE IF NOT EXISTS registro_facial (
    id_registro_facial BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_persona BIGINT UNSIGNED NOT NULL UNIQUE,
    plantilla_facial LONGBLOB NOT NULL,
    algoritmo VARCHAR(40) NOT NULL DEFAULT 'WEBAUTHN_O_SERVICIO_BIOMETRICO',
    registrado_por BIGINT UNSIGNED NOT NULL,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_facial_persona FOREIGN KEY (id_persona) REFERENCES personas(id_persona) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_facial_admin FOREIGN KEY (registrado_por) REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Fotografía opcional del medicamento. Se guarda la ruta, no el archivo binario, para facilitar XAMPP.
ALTER TABLE medicamentos ADD COLUMN IF NOT EXISTS foto_path VARCHAR(255) NULL;

-- Índices para búsquedas globales.
CREATE INDEX idx_personas_nombre ON personas(nombre);
CREATE INDEX idx_personas_ci ON personas(ci);
CREATE INDEX idx_medicamentos_nombre ON medicamentos(nombre);
CREATE INDEX idx_examenes_nombre ON examenes_laboratorio(nombre);

-- Vista para consultar rápidamente la ficha de una persona y sus registros clínicos.
CREATE OR REPLACE VIEW vw_historial_persona AS
SELECT p.id_persona, p.ci, p.nombre, p.fecha_nacimiento, p.telefono, p.correo,
       pa.tipo_sangre, pa.activo AS paciente_activo,
       h.id_historia, h.antecedentes, h.alergias, h.observaciones,
       c.id_consulta, c.fecha_hora AS fecha_consulta, c.estado AS estado_consulta,
       c.tipo_consulta, esp.nombre AS especialidad,
       m.nombre AS medico,
       i.id_internacion, i.fecha_ingreso, i.fecha_alta, i.estado AS estado_internacion
FROM personas p
LEFT JOIN pacientes pa ON pa.id_persona=p.id_persona
LEFT JOIN historias_clinicas h ON h.id_persona=p.id_persona
LEFT JOIN consultas c ON c.id_persona=p.id_persona AND (h.id_historia IS NULL OR c.id_historia=h.id_historia)
LEFT JOIN especialidades esp ON esp.id_especialidad=c.id_especialidad
LEFT JOIN personas m ON m.id_persona=c.id_medico
LEFT JOIN internaciones i ON i.id_persona=p.id_persona;

-- Vista exclusiva para facturación.
CREATE OR REPLACE VIEW vw_facturacion_operativa AS
SELECT f.id_factura, f.fecha_emision, f.estado, f.tipo_pago,
       p.id_persona, p.ci, p.nombre AS paciente,
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
         p.id_persona, p.ci, p.nombre, a.nombre, ps.numero_poliza,
         d.nit_ci, d.razon_social, d.tipo_documento_fiscal,
         f.subtotal, f.monto_cobertura_seguro, f.total, u.nombre_usuario;

SELECT 'Migración v2 completada' AS resultado;
