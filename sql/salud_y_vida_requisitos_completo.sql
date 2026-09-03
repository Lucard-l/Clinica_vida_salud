-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 31-08-2026 a las 18:08:26
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `salud_y_vida`
--

DELIMITER $$
--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_tarifa_vigente` (`p_id_tipo_habitacion` SMALLINT, `p_fecha` DATE) RETURNS DECIMAL(10,2) DETERMINISTIC READS SQL DATA BEGIN
    DECLARE v_tarifa DECIMAL(10,2);
    SELECT tarifa_diaria INTO v_tarifa
    FROM tipo_habitacion_tarifa_historico
    WHERE id_tipo_habitacion = p_id_tipo_habitacion AND fecha_desde <= p_fecha
    ORDER BY fecha_desde DESC
    LIMIT 1;
    RETURN v_tarifa;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `bitacora`
--

CREATE TABLE `bitacora` (
  `id_bitacora` bigint(20) NOT NULL,
  `id_usuario` bigint(20) DEFAULT NULL,
  `tabla_afectada` varchar(64) NOT NULL,
  `id_registro` bigint(20) DEFAULT NULL,
  `accion` varchar(10) NOT NULL CHECK (`accion` in ('INSERT','UPDATE','DELETE')),
  `datos_anteriores` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`datos_anteriores`)),
  `datos_nuevos` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`datos_nuevos`)),
  `fecha_hora` datetime NOT NULL DEFAULT current_timestamp(),
  `ip_origen` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cirugias`
--

CREATE TABLE `cirugias` (
  `id_cirugia` bigint(20) NOT NULL,
  `id_persona` bigint(20) NOT NULL,
  `id_quirofano` smallint(6) NOT NULL,
  `id_especialidad` smallint(6) NOT NULL,
  `id_cirujano_principal` bigint(20) NOT NULL,
  `fecha_programada` datetime NOT NULL,
  `duracion_estimada_minutos` int(11) NOT NULL DEFAULT 120,
  `fecha_fin_estimada` datetime GENERATED ALWAYS AS (`fecha_programada` + interval `duracion_estimada_minutos` minute) STORED,
  `diagnostico_prequirurgico` text DEFAULT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'PROGRAMADA' CHECK (`estado` in ('PROGRAMADA','EN_CURSO','REALIZADA','CANCELADA'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `consultas`
--

CREATE TABLE `consultas` (
  `id_consulta` bigint(20) NOT NULL,
  `consulta_padre` bigint(20) DEFAULT NULL,
  `id_persona` bigint(20) NOT NULL,
  `id_medico` bigint(20) NOT NULL,
  `id_especialidad` smallint(6) NOT NULL,
  `id_historia` bigint(20) NOT NULL,
  `id_consultorio` smallint(6) NOT NULL,
  `fecha_hora` datetime NOT NULL,
  `duracion_estimada_minutos` int(11) NOT NULL DEFAULT 30,
  `fecha_fin_estimada` datetime GENERATED ALWAYS AS (`fecha_hora` + interval `duracion_estimada_minutos` minute) STORED,
  `motivo` varchar(300) DEFAULT NULL,
  `diagnostico` text DEFAULT NULL,
  `estado` enum('PROGRAMADA','ATENDIDA','CANCELADA','NO_ASISTIO') NOT NULL DEFAULT 'PROGRAMADA',
  `tipo_consulta` enum('PRIMERA_VEZ','CONTROL','SEGUIMIENTO','POSTOPERATORIO') NOT NULL DEFAULT 'PRIMERA_VEZ'
) ;

--
-- Disparadores `consultas`
--
DELIMITER $$
CREATE TRIGGER `trg_no_auto_reconsulta_upd` BEFORE UPDATE ON `consultas` FOR EACH ROW BEGIN
    IF NEW.consulta_padre IS NOT NULL AND NEW.consulta_padre = NEW.id_consulta THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Una consulta no puede ser su propia consulta padre.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `consultorios`
--

CREATE TABLE `consultorios` (
  `id_consultorio` smallint(6) NOT NULL,
  `numero` varchar(10) NOT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'DISPONIBLE' CHECK (`estado` in ('DISPONIBLE','MANTENIMIENTO'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `especialidades`
--

CREATE TABLE `especialidades` (
  `id_especialidad` smallint(6) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` varchar(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `examenes_laboratorio`
--

CREATE TABLE `examenes_laboratorio` (
  `id_examen` smallint(6) NOT NULL,
  `nombre` varchar(150) NOT NULL,
  `precio` decimal(10,2) NOT NULL CHECK (`precio` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `habitaciones`
--

CREATE TABLE `habitaciones` (
  `id_habitacion` bigint(20) NOT NULL,
  `numero` varchar(10) NOT NULL,
  `id_tipo_habitacion` smallint(6) NOT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'DISPONIBLE' CHECK (`estado` in ('DISPONIBLE','OCUPADA','MANTENIMIENTO'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `historias_clinicas`
--

CREATE TABLE `historias_clinicas` (
  `id_historia` bigint(20) NOT NULL,
  `id_persona` bigint(20) NOT NULL,
  `fecha_apertura` datetime NOT NULL DEFAULT current_timestamp(),
  `antecedentes` text DEFAULT NULL,
  `alergias` text DEFAULT NULL,
  `observaciones` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `medicamentos`
--

CREATE TABLE `medicamentos` (
  `id_medicamento` bigint(20) NOT NULL,
  `nombre` varchar(150) NOT NULL,
  `presentacion` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `medicos`
--

CREATE TABLE `medicos` (
  `id_persona` bigint(20) NOT NULL,
  `matricula_profesional` varchar(30) NOT NULL,
  `tipo_contrato` enum('FIJO','PORCENTAJE') NOT NULL,
  `monto_fijo` decimal(10,2) DEFAULT NULL CHECK (`monto_fijo` is null or `monto_fijo` >= 0),
  `porcentaje_procedimiento` decimal(5,2) DEFAULT NULL CHECK (`porcentaje_procedimiento` is null or `porcentaje_procedimiento` between 0 and 100),
  `activo` tinyint(1) NOT NULL DEFAULT 1
) ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `medico_especialidad`
--

CREATE TABLE `medico_especialidad` (
  `id_persona` bigint(20) NOT NULL,
  `id_especialidad` smallint(6) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pacientes`
--

CREATE TABLE `pacientes` (
  `id_persona` bigint(20) NOT NULL,
  `tipo_sangre` varchar(5) DEFAULT NULL,
  `fecha_registro` datetime NOT NULL DEFAULT current_timestamp(),
  `activo` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `pacientes`
--

INSERT INTO `pacientes` (`id_persona`, `tipo_sangre`, `fecha_registro`, `activo`) VALUES
(3, 'O+', '2026-08-30 23:34:44', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `personas`
--

CREATE TABLE `personas` (
  `id_persona` bigint(20) NOT NULL,
  `ci` varchar(20) NOT NULL,
  `nombre` varchar(150) NOT NULL,
  `fecha_nacimiento` date NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `direccion` varchar(200) DEFAULT NULL,
  `correo` varchar(150) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `personas`
--

INSERT INTO `personas` (`id_persona`, `ci`, `nombre`, `fecha_nacimiento`, `telefono`, `direccion`, `correo`) VALUES
(1, 'ADMIN-0001', 'Administrador General', '1990-01-01', NULL, NULL, 'admin@saludvida.local'),
(3, '11080484', 'Maciel Ariadna Ralde Coaquira', '2004-06-27', '67316555', 'Doctor Placido Sanchez, 3er Anillo Externo', 'uimachell@gmail.com');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `quirofanos`
--

CREATE TABLE `quirofanos` (
  `id_quirofano` smallint(6) NOT NULL,
  `nombre` varchar(30) NOT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'DISPONIBLE' CHECK (`estado` in ('DISPONIBLE','MANTENIMIENTO'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `roles`
--

CREATE TABLE `roles` (
  `id_rol` smallint(6) NOT NULL,
  `nombre` enum('ADMINISTRADOR','PACIENTE','ENFERMERO','MEDICO','FACTURADOR') NOT NULL,
  `descripcion` varchar(150) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `roles`
--

INSERT INTO `roles` (`id_rol`, `nombre`, `descripcion`) VALUES
(1, 'ADMINISTRADOR', 'Acceso completo al sistema');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipos_habitacion`
--

CREATE TABLE `tipos_habitacion` (
  `id_tipo_habitacion` smallint(6) NOT NULL,
  `nombre` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_habitacion_tarifa_historico`
--

CREATE TABLE `tipo_habitacion_tarifa_historico` (
  `id_tarifa` bigint(20) NOT NULL,
  `id_tipo_habitacion` smallint(6) NOT NULL,
  `tarifa_diaria` decimal(10,2) NOT NULL CHECK (`tarifa_diaria` >= 0),
  `fecha_desde` date NOT NULL DEFAULT curdate()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id_usuario` bigint(20) NOT NULL,
  `id_persona` bigint(20) NOT NULL,
  `id_rol` smallint(6) NOT NULL,
  `nombre_usuario` varchar(50) NOT NULL,
  `contrasena_hash` varchar(255) NOT NULL,
  `plantilla_facial` blob DEFAULT NULL,
  `estado` tinyint(1) NOT NULL DEFAULT 1,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  `ultimo_acceso` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id_usuario`, `id_persona`, `id_rol`, `nombre_usuario`, `contrasena_hash`, `plantilla_facial`, `estado`, `fecha_creacion`, `ultimo_acceso`) VALUES
(1, 1, 1, 'admin', '$2b$12$YWn7Hvv1JA1DkZBMRj45Z.5krvpS7xiV0A.StAhJMz.5j/FVyIjnu', NULL, 1, '2026-08-30 23:29:37', '2026-08-30 23:30:03');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `bitacora`
--
ALTER TABLE `bitacora`
  ADD PRIMARY KEY (`id_bitacora`),
  ADD KEY `idx_bitacora_tabla_fecha` (`tabla_afectada`,`fecha_hora`),
  ADD KEY `idx_bitacora_usuario` (`id_usuario`,`fecha_hora`);

--
-- Indices de la tabla `cirugias`
--
ALTER TABLE `cirugias`
  ADD PRIMARY KEY (`id_cirugia`),
  ADD KEY `fk_cirugias_paciente` (`id_persona`),
  ADD KEY `fk_cirugias_quirofano` (`id_quirofano`),
  ADD KEY `fk_cirugias_especialidad` (`id_especialidad`),
  ADD KEY `fk_cirugias_cirujano` (`id_cirujano_principal`),
  ADD KEY `idx_cirugias_fecha_especialidad` (`fecha_programada`,`id_especialidad`);

--
-- Indices de la tabla `consultas`
--
ALTER TABLE `consultas`
  ADD PRIMARY KEY (`id_consulta`),
  ADD UNIQUE KEY `uq_medico_horario` (`id_medico`,`fecha_hora`),
  ADD KEY `fk_consultas_padre` (`consulta_padre`),
  ADD KEY `fk_consultas_paciente` (`id_persona`),
  ADD KEY `fk_consultas_especialidad` (`id_especialidad`),
  ADD KEY `fk_consultas_historia` (`id_historia`),
  ADD KEY `fk_consultas_consultorio` (`id_consultorio`);

--
-- Indices de la tabla `consultorios`
--
ALTER TABLE `consultorios`
  ADD PRIMARY KEY (`id_consultorio`),
  ADD UNIQUE KEY `numero` (`numero`);

--
-- Indices de la tabla `especialidades`
--
ALTER TABLE `especialidades`
  ADD PRIMARY KEY (`id_especialidad`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `examenes_laboratorio`
--
ALTER TABLE `examenes_laboratorio`
  ADD PRIMARY KEY (`id_examen`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `habitaciones`
--
ALTER TABLE `habitaciones`
  ADD PRIMARY KEY (`id_habitacion`),
  ADD UNIQUE KEY `numero` (`numero`),
  ADD KEY `fk_habitaciones_tipo` (`id_tipo_habitacion`),
  ADD KEY `idx_habitaciones_estado` (`estado`);

--
-- Indices de la tabla `historias_clinicas`
--
ALTER TABLE `historias_clinicas`
  ADD PRIMARY KEY (`id_historia`),
  ADD UNIQUE KEY `id_persona` (`id_persona`,`fecha_apertura`),
  ADD KEY `idx_historias_persona` (`id_persona`);

--
-- Indices de la tabla `medicamentos`
--
ALTER TABLE `medicamentos`
  ADD PRIMARY KEY (`id_medicamento`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `medicos`
--
ALTER TABLE `medicos`
  ADD PRIMARY KEY (`id_persona`),
  ADD UNIQUE KEY `matricula_profesional` (`matricula_profesional`);

--
-- Indices de la tabla `medico_especialidad`
--
ALTER TABLE `medico_especialidad`
  ADD PRIMARY KEY (`id_persona`,`id_especialidad`),
  ADD KEY `idx_medico_especialidad_esp` (`id_especialidad`);

--
-- Indices de la tabla `pacientes`
--
ALTER TABLE `pacientes`
  ADD PRIMARY KEY (`id_persona`);

--
-- Indices de la tabla `personas`
--
ALTER TABLE `personas`
  ADD PRIMARY KEY (`id_persona`),
  ADD UNIQUE KEY `ci` (`ci`),
  ADD KEY `idx_personas_nombre` (`nombre`);

--
-- Indices de la tabla `quirofanos`
--
ALTER TABLE `quirofanos`
  ADD PRIMARY KEY (`id_quirofano`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id_rol`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `tipos_habitacion`
--
ALTER TABLE `tipos_habitacion`
  ADD PRIMARY KEY (`id_tipo_habitacion`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `tipo_habitacion_tarifa_historico`
--
ALTER TABLE `tipo_habitacion_tarifa_historico`
  ADD PRIMARY KEY (`id_tarifa`),
  ADD UNIQUE KEY `id_tipo_habitacion` (`id_tipo_habitacion`,`fecha_desde`),
  ADD KEY `idx_tarifa_habitacion_tipo_fecha` (`id_tipo_habitacion`,`fecha_desde`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id_usuario`),
  ADD UNIQUE KEY `nombre_usuario` (`nombre_usuario`),
  ADD UNIQUE KEY `id_persona` (`id_persona`,`id_rol`),
  ADD KEY `idx_usuarios_persona` (`id_persona`),
  ADD KEY `idx_usuarios_rol` (`id_rol`,`estado`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `bitacora`
--
ALTER TABLE `bitacora`
  MODIFY `id_bitacora` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `cirugias`
--
ALTER TABLE `cirugias`
  MODIFY `id_cirugia` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `consultas`
--
ALTER TABLE `consultas`
  MODIFY `id_consulta` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `consultorios`
--
ALTER TABLE `consultorios`
  MODIFY `id_consultorio` smallint(6) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `especialidades`
--
ALTER TABLE `especialidades`
  MODIFY `id_especialidad` smallint(6) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `examenes_laboratorio`
--
ALTER TABLE `examenes_laboratorio`
  MODIFY `id_examen` smallint(6) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `habitaciones`
--
ALTER TABLE `habitaciones`
  MODIFY `id_habitacion` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `historias_clinicas`
--
ALTER TABLE `historias_clinicas`
  MODIFY `id_historia` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `medicamentos`
--
ALTER TABLE `medicamentos`
  MODIFY `id_medicamento` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `personas`
--
ALTER TABLE `personas`
  MODIFY `id_persona` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `quirofanos`
--
ALTER TABLE `quirofanos`
  MODIFY `id_quirofano` smallint(6) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `roles`
--
ALTER TABLE `roles`
  MODIFY `id_rol` smallint(6) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `tipos_habitacion`
--
ALTER TABLE `tipos_habitacion`
  MODIFY `id_tipo_habitacion` smallint(6) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `tipo_habitacion_tarifa_historico`
--
ALTER TABLE `tipo_habitacion_tarifa_historico`
  MODIFY `id_tarifa` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id_usuario` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `bitacora`
--
ALTER TABLE `bitacora`
  ADD CONSTRAINT `fk_bitacora_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`);

--
-- Filtros para la tabla `cirugias`
--
ALTER TABLE `cirugias`
  ADD CONSTRAINT `fk_cirugias_cirujano` FOREIGN KEY (`id_cirujano_principal`) REFERENCES `medicos` (`id_persona`),
  ADD CONSTRAINT `fk_cirugias_especialidad` FOREIGN KEY (`id_especialidad`) REFERENCES `especialidades` (`id_especialidad`),
  ADD CONSTRAINT `fk_cirugias_paciente` FOREIGN KEY (`id_persona`) REFERENCES `pacientes` (`id_persona`),
  ADD CONSTRAINT `fk_cirugias_quirofano` FOREIGN KEY (`id_quirofano`) REFERENCES `quirofanos` (`id_quirofano`);

--
-- Filtros para la tabla `consultas`
--
ALTER TABLE `consultas`
  ADD CONSTRAINT `fk_consultas_consultorio` FOREIGN KEY (`id_consultorio`) REFERENCES `consultorios` (`id_consultorio`),
  ADD CONSTRAINT `fk_consultas_especialidad` FOREIGN KEY (`id_especialidad`) REFERENCES `especialidades` (`id_especialidad`),
  ADD CONSTRAINT `fk_consultas_historia` FOREIGN KEY (`id_historia`) REFERENCES `historias_clinicas` (`id_historia`),
  ADD CONSTRAINT `fk_consultas_medico` FOREIGN KEY (`id_medico`) REFERENCES `medicos` (`id_persona`),
  ADD CONSTRAINT `fk_consultas_paciente` FOREIGN KEY (`id_persona`) REFERENCES `pacientes` (`id_persona`),
  ADD CONSTRAINT `fk_consultas_padre` FOREIGN KEY (`consulta_padre`) REFERENCES `consultas` (`id_consulta`);

--
-- Filtros para la tabla `habitaciones`
--
ALTER TABLE `habitaciones`
  ADD CONSTRAINT `fk_habitaciones_tipo` FOREIGN KEY (`id_tipo_habitacion`) REFERENCES `tipos_habitacion` (`id_tipo_habitacion`);

--
-- Filtros para la tabla `historias_clinicas`
--
ALTER TABLE `historias_clinicas`
  ADD CONSTRAINT `fk_historias_paciente` FOREIGN KEY (`id_persona`) REFERENCES `pacientes` (`id_persona`);

--
-- Filtros para la tabla `medicos`
--
ALTER TABLE `medicos`
  ADD CONSTRAINT `fk_medicos_persona` FOREIGN KEY (`id_persona`) REFERENCES `personas` (`id_persona`) ON DELETE CASCADE;

--
-- Filtros para la tabla `medico_especialidad`
--
ALTER TABLE `medico_especialidad`
  ADD CONSTRAINT `fk_me_especialidad` FOREIGN KEY (`id_especialidad`) REFERENCES `especialidades` (`id_especialidad`),
  ADD CONSTRAINT `fk_me_medico` FOREIGN KEY (`id_persona`) REFERENCES `medicos` (`id_persona`) ON DELETE CASCADE;

--
-- Filtros para la tabla `pacientes`
--
ALTER TABLE `pacientes`
  ADD CONSTRAINT `fk_pacientes_persona` FOREIGN KEY (`id_persona`) REFERENCES `personas` (`id_persona`) ON DELETE CASCADE;

--
-- Filtros para la tabla `tipo_habitacion_tarifa_historico`
--
ALTER TABLE `tipo_habitacion_tarifa_historico`
  ADD CONSTRAINT `fk_tarifa_tipo` FOREIGN KEY (`id_tipo_habitacion`) REFERENCES `tipos_habitacion` (`id_tipo_habitacion`) ON DELETE CASCADE;

--
-- Filtros para la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD CONSTRAINT `fk_usuarios_persona` FOREIGN KEY (`id_persona`) REFERENCES `personas` (`id_persona`),
  ADD CONSTRAINT `fk_usuarios_rol` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id_rol`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
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

