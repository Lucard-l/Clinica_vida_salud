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
