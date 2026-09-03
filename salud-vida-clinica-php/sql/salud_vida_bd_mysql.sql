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
