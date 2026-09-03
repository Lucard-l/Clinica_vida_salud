-- Diagnóstico de la instalación Salud Vida.
-- Ejecutar dentro de la base salud_y_vida desde phpMyAdmin.
SELECT DATABASE() AS base_actual;

SELECT tabla_requerida,
       IF(EXISTS(
           SELECT 1 FROM information_schema.tables t
           WHERE t.table_schema = DATABASE()
             AND t.table_name = tabla_requerida
       ), 'EXISTE', 'FALTA') AS estado
FROM (
    SELECT 'personas' AS tabla_requerida UNION ALL
    SELECT 'pacientes' UNION ALL SELECT 'medicos' UNION ALL SELECT 'roles'
    UNION ALL SELECT 'usuarios' UNION ALL SELECT 'bitacora'
    UNION ALL SELECT 'historias_clinicas' UNION ALL SELECT 'especialidades'
    UNION ALL SELECT 'consultorios' UNION ALL SELECT 'consultas'
    UNION ALL SELECT 'recetas' UNION ALL SELECT 'medicamentos'
    UNION ALL SELECT 'receta_detalle' UNION ALL SELECT 'examenes_laboratorio'
    UNION ALL SELECT 'solicitudes_laboratorio'
    UNION ALL SELECT 'solicitud_laboratorio_detalle'
    UNION ALL SELECT 'tipos_habitacion' UNION ALL SELECT 'habitaciones'
    UNION ALL SELECT 'ordenes_internacion' UNION ALL SELECT 'internaciones'
    UNION ALL SELECT 'cargos_internacion' UNION ALL SELECT 'quirofanos'
    UNION ALL SELECT 'cirugias' UNION ALL SELECT 'cirugia_personal'
    UNION ALL SELECT 'insumos' UNION ALL SELECT 'cirugia_insumo'
    UNION ALL SELECT 'aseguradoras' UNION ALL SELECT 'convenios_aseguradora'
    UNION ALL SELECT 'paciente_seguro' UNION ALL SELECT 'servicios_medicos'
    UNION ALL SELECT 'servicio_precio_historico' UNION ALL SELECT 'datos_facturacion'
    UNION ALL SELECT 'facturas' UNION ALL SELECT 'factura_detalle'
    UNION ALL SELECT 'pagos_medicos'
) tablas
ORDER BY estado DESC, tabla_requerida;

-- La consulta puntual que confirma el error reportado:
SHOW TABLES LIKE 'servicios_medicos';
