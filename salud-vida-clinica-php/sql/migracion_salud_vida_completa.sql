-- Migración incremental Salud Vida.
-- No elimina tablas ni datos existentes. Ejecutar dentro de la base salud_y_vida.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS recetas (
  id_receta BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_consulta BIGINT NOT NULL,
  fecha_emision DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  indicaciones_generales TEXT NULL,
  CONSTRAINT fk_recetas_consulta FOREIGN KEY (id_consulta) REFERENCES consultas(id_consulta)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS receta_detalle (
  id_receta_detalle BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_receta BIGINT NOT NULL,
  id_medicamento BIGINT NOT NULL,
  dosis VARCHAR(50) NOT NULL,
  frecuencia VARCHAR(50) NOT NULL,
  duracion_dias SMALLINT NULL,
  indicaciones TEXT NULL,
  CONSTRAINT fk_rd_receta FOREIGN KEY (id_receta) REFERENCES recetas(id_receta) ON DELETE CASCADE,
  CONSTRAINT fk_rd_medicamento FOREIGN KEY (id_medicamento) REFERENCES medicamentos(id_medicamento)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS solicitudes_laboratorio (
  id_solicitud BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_consulta BIGINT NOT NULL,
  fecha_solicitud DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
  CONSTRAINT fk_sollab_consulta FOREIGN KEY (id_consulta) REFERENCES consultas(id_consulta)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS solicitud_laboratorio_detalle (
  id_detalle BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_solicitud BIGINT NOT NULL,
  id_examen SMALLINT NOT NULL,
  resultado TEXT NULL,
  fecha_resultado DATETIME NULL,
  UNIQUE KEY uq_solicitud_examen (id_solicitud,id_examen),
  CONSTRAINT fk_sld_solicitud FOREIGN KEY (id_solicitud) REFERENCES solicitudes_laboratorio(id_solicitud) ON DELETE CASCADE,
  CONSTRAINT fk_sld_examen FOREIGN KEY (id_examen) REFERENCES examenes_laboratorio(id_examen)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ordenes_internacion (
  id_orden BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_consulta BIGINT NOT NULL,
  fecha_orden DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  motivo VARCHAR(300) NOT NULL,
  CONSTRAINT fk_ordeni_consulta FOREIGN KEY (id_consulta) REFERENCES consultas(id_consulta)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS internaciones (
  id_internacion BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_orden BIGINT NOT NULL,
  id_persona BIGINT NOT NULL,
  id_habitacion BIGINT NOT NULL,
  fecha_ingreso DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_alta DATETIME NULL,
  id_medico_autoriza_alta BIGINT NULL,
  estado VARCHAR(20) NOT NULL DEFAULT 'ACTIVA',
  CONSTRAINT fk_internaciones_orden FOREIGN KEY (id_orden) REFERENCES ordenes_internacion(id_orden),
  CONSTRAINT fk_internaciones_paciente FOREIGN KEY (id_persona) REFERENCES pacientes(id_persona),
  CONSTRAINT fk_internaciones_habitacion FOREIGN KEY (id_habitacion) REFERENCES habitaciones(id_habitacion),
  CONSTRAINT fk_internaciones_medico_alta FOREIGN KEY (id_medico_autoriza_alta) REFERENCES medicos(id_persona)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS cargos_internacion (
  id_cargo BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_internacion BIGINT NOT NULL,
  fecha DATE NOT NULL,
  concepto VARCHAR(100) NOT NULL DEFAULT 'Estadía diaria',
  monto DECIMAL(10,2) NOT NULL DEFAULT 0,
  UNIQUE KEY uq_cargo_internacion (id_internacion,fecha,concepto),
  CONSTRAINT fk_cargos_internacion FOREIGN KEY (id_internacion) REFERENCES internaciones(id_internacion) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS insumos (
  id_insumo BIGINT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL UNIQUE,
  unidad_medida ENUM('UNIDAD','ML','MG','LITRO','CAJA','PAR','FRASCO') NOT NULL,
  stock_actual DECIMAL(10,2) NOT NULL DEFAULT 0,
  stock_minimo DECIMAL(10,2) NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS cirugia_insumo (
  id_cirugia BIGINT NOT NULL,
  id_insumo BIGINT NOT NULL,
  cantidad_utilizada DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id_cirugia,id_insumo),
  CONSTRAINT fk_ci_cirugia FOREIGN KEY (id_cirugia) REFERENCES cirugias(id_cirugia) ON DELETE CASCADE,
  CONSTRAINT fk_ci_insumo FOREIGN KEY (id_insumo) REFERENCES insumos(id_insumo)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS aseguradoras (
  id_aseguradora SMALLINT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL UNIQUE,
  nit VARCHAR(30) NOT NULL UNIQUE,
  telefono VARCHAR(20) NULL,
  email VARCHAR(150) NULL,
  es_reservada BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB;
INSERT IGNORE INTO aseguradoras(id_aseguradora,nombre,nit,es_reservada) VALUES (1,'PARTICULAR / SIN ASEGURADORA','0',TRUE);

CREATE TABLE IF NOT EXISTS convenios_aseguradora (
  id_convenio BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_aseguradora SMALLINT NOT NULL,
  id_especialidad SMALLINT NULL,
  porcentaje_cobertura DECIMAL(5,2) NOT NULL DEFAULT 0,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NULL,
  CONSTRAINT fk_convenio_aseguradora FOREIGN KEY (id_aseguradora) REFERENCES aseguradoras(id_aseguradora),
  CONSTRAINT fk_convenio_especialidad FOREIGN KEY (id_especialidad) REFERENCES especialidades(id_especialidad)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS paciente_seguro (
  id_paciente_seguro BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_persona BIGINT NOT NULL,
  id_aseguradora SMALLINT NOT NULL,
  numero_poliza VARCHAR(50) NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE KEY uq_poliza (id_aseguradora,numero_poliza),
  CONSTRAINT fk_ps_paciente FOREIGN KEY (id_persona) REFERENCES pacientes(id_persona),
  CONSTRAINT fk_ps_aseguradora FOREIGN KEY (id_aseguradora) REFERENCES aseguradoras(id_aseguradora)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS servicios_medicos (
  id_servicio BIGINT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  id_especialidad SMALLINT NULL,
  CONSTRAINT fk_servicio_especialidad FOREIGN KEY (id_especialidad) REFERENCES especialidades(id_especialidad)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS servicio_precio_historico (
  id_precio BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_servicio BIGINT NOT NULL,
  precio DECIMAL(10,2) NOT NULL DEFAULT 0,
  fecha_desde DATE NOT NULL,
  UNIQUE KEY uq_precio_servicio_fecha (id_servicio,fecha_desde),
  CONSTRAINT fk_precio_servicio FOREIGN KEY (id_servicio) REFERENCES servicios_medicos(id_servicio) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS datos_facturacion (
  id_datos_facturacion BIGINT AUTO_INCREMENT PRIMARY KEY,
  nit_ci VARCHAR(20) NOT NULL,
  razon_social VARCHAR(150) NOT NULL,
  tipo_documento_fiscal ENUM('FACTURA_CREDITO_FISCAL','FACTURA_SIN_CREDITO_FISCAL','RECIBO') NOT NULL DEFAULT 'FACTURA_CREDITO_FISCAL'
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS facturas (
  id_factura BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_paciente_seguro BIGINT NOT NULL,
  id_usuario_factura BIGINT NOT NULL,
  id_datos_facturacion BIGINT NOT NULL,
  fecha_emision DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  tipo_pago ENUM('PARTICULAR','SEGURO','MIXTO') NOT NULL,
  subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
  monto_cobertura_seguro DECIMAL(12,2) NOT NULL DEFAULT 0,
  total DECIMAL(12,2) AS (subtotal - monto_cobertura_seguro) STORED,
  estado ENUM('PENDIENTE','PAGADA','ANULADA') NOT NULL DEFAULT 'PENDIENTE',
  CONSTRAINT fk_factura_ps FOREIGN KEY (id_paciente_seguro) REFERENCES paciente_seguro(id_paciente_seguro),
  CONSTRAINT fk_factura_usuario FOREIGN KEY (id_usuario_factura) REFERENCES usuarios(id_usuario),
  CONSTRAINT fk_factura_datos FOREIGN KEY (id_datos_facturacion) REFERENCES datos_facturacion(id_datos_facturacion)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS factura_detalle (
  id_detalle BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_factura BIGINT NOT NULL,
  id_servicio BIGINT NOT NULL,
  id_consulta BIGINT NULL,
  id_cirugia BIGINT NULL,
  id_internacion BIGINT NULL,
  cantidad SMALLINT NOT NULL DEFAULT 1,
  precio_unitario DECIMAL(10,2) NOT NULL DEFAULT 0,
  subtotal DECIMAL(12,2) AS (cantidad * precio_unitario) STORED,
  CONSTRAINT fk_fd_factura FOREIGN KEY (id_factura) REFERENCES facturas(id_factura) ON DELETE CASCADE,
  CONSTRAINT fk_fd_servicio FOREIGN KEY (id_servicio) REFERENCES servicios_medicos(id_servicio),
  CONSTRAINT fk_fd_consulta FOREIGN KEY (id_consulta) REFERENCES consultas(id_consulta),
  CONSTRAINT fk_fd_cirugia FOREIGN KEY (id_cirugia) REFERENCES cirugias(id_cirugia),
  CONSTRAINT fk_fd_internacion FOREIGN KEY (id_internacion) REFERENCES internaciones(id_internacion)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pagos_medicos (
  id_pago BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_medico BIGINT NOT NULL,
  periodo DATE NOT NULL,
  monto DECIMAL(12,2) NOT NULL DEFAULT 0,
  detalle_calculo JSON NULL,
  fecha_pago DATETIME NULL,
  UNIQUE KEY uq_pago_medico_periodo (id_medico,periodo),
  CONSTRAINT fk_pago_medico FOREIGN KEY (id_medico) REFERENCES medicos(id_persona)
) ENGINE=InnoDB;
