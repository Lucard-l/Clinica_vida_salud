# Guía completa del sistema Salud Vida

## 1. Propósito general

**Salud Vida** es una aplicación web de gestión clínica desarrollada en PHP y MySQL. Su objetivo es centralizar la información de pacientes, médicos, historias clínicas, consultas, cirugías, internaciones, seguros, facturación, medicamentos, exámenes de laboratorio, usuarios y auditoría.

La aplicación trabaja con una conexión PDO definida en `db.php`. El archivo `config.php` indica que la base se llama `Salud_y_vida`, el servidor es `127.0.0.1`, el puerto predeterminado es `3306` y el usuario predeterminado es `root`.

> La aplicación es monolítica: `index.php` recibe las solicitudes, valida la sesión y el rol, ejecuta las consultas SQL y construye las páginas HTML.

## 2. Archivos principales

| Archivo | Responsabilidad |
|---|---|
| `config.php` | Define host, puerto, base de datos, usuario, contraseña y codificación. |
| `db.php` | Crea la conexión PDO, activa excepciones, consultas preparadas y funciones auxiliares. |
| `index.php` | Contiene login, permisos, acciones de inserción/actualización/eliminación, consultas de lectura y las pantallas. |
| `assets/app.css` | Define el diseño visual, tarjetas, formularios, tablas, navegación y pantalla de acceso. |
| `sql/Salud_y_vida_nueva_completa.sql` | Crea desde cero la base completa, relaciones, restricciones, triggers, catálogos iniciales y administrador. |
| `sql/datos_ejemplo_salud_vida.sql` | Inserta especialidades, servicios, habitaciones, consultorios, quirófanos y médicos de prueba. |

## 3. Conexión y seguridad de acceso

La conexión se realiza mediante PDO con estas características:

| Configuración | Comportamiento |
|---|---|
| `PDO::ATTR_ERRMODE` | Usa `PDO::ERRMODE_EXCEPTION`, por lo que los errores SQL generan excepciones. |
| `PDO::ATTR_DEFAULT_FETCH_MODE` | Devuelve los resultados como arreglos asociativos. |
| `PDO::ATTR_EMULATE_PREPARES` | Está desactivado para usar consultas preparadas reales. |
| Codificación | `utf8mb4`, compatible con nombres y textos en español. |

El login recibe `username` y `password`, busca el usuario junto con su rol y persona, verifica que la cuenta esté activa y compara la contraseña con `password_verify()`.

La consulta de autenticación es conceptualmente la siguiente:

```sql
SELECT u.id_usuario,
       u.id_persona,
       u.contrasena_hash,
       u.estado,
       r.nombre AS rol,
       p.nombre
FROM usuarios u
JOIN roles r ON r.id_rol = u.id_rol
JOIN personas p ON p.id_persona = u.id_persona
WHERE u.nombre_usuario = ?
LIMIT 1;
```

Cuando el acceso es correcto, se guarda en la sesión el usuario, la persona, el nombre y el rol. Después se actualiza la fecha del último acceso:

```sql
UPDATE usuarios
SET ultimo_acceso = NOW()
WHERE id_usuario = ?;
```

## 4. Roles del sistema

| Rol | Permisos principales en el código |
|---|---|
| `ADMINISTRADOR` | Acceso general, catálogos, usuarios, pacientes, historias, consultas, cirugías, internaciones y facturación. |
| `MEDICO` | Crear pacientes, historias, medicamentos, exámenes, consultas, cirugías e internaciones; también puede autorizar altas. |
| `ENFERMERO` | Crear pacientes, historias, consultas e internaciones. |
| `FACTURADOR` | Asignar seguros y crear o actualizar facturas. |
| `PACIENTE` | Está definido en la base como rol, pero la interfaz actual no tiene un portal separado para este rol. |

La función `can()` comprueba si el rol de la sesión se encuentra dentro del conjunto autorizado para cada operación. Si no se cumple la condición, la acción no se ejecuta.

## 5. Tablas y responsabilidades

### 5.1 Personas, pacientes y usuarios

| Tabla | Función | Relaciones principales |
|---|---|---|
| `personas` | Guarda los datos generales: CI, nombre, fecha de nacimiento, teléfono, dirección y correo. | Es la tabla base de pacientes, médicos y usuarios. |
| `pacientes` | Identifica cuáles personas reciben atención médica, con tipo de sangre y estado activo. | Su clave primaria también es FK hacia `personas`. |
| `medicos` | Guarda matrícula, tipo de contrato, monto fijo, porcentaje por procedimiento y estado. | Su clave primaria también es FK hacia `personas`. |
| `roles` | Define los perfiles de acceso. | Se relaciona con `usuarios`. |
| `usuarios` | Guarda la cuenta de acceso, rol, hash de contraseña, estado y último acceso. | Se relaciona con `personas` y `roles`. |
| `bitacora` | Guarda acciones de auditoría, tabla afectada, registro, usuario y fecha. | Se relaciona con `usuarios`. |

### 5.2 Catálogos clínicos

| Tabla | Función |
|---|---|
| `especialidades` | Cardiología, pediatría, medicina general y otras especialidades. |
| `medico_especialidad` | Tabla intermedia que permite asignar una o varias especialidades a un médico. |
| `consultorios` | Catálogo de consultorios y su estado: disponible, mantenimiento o inactivo. |
| `medicamentos` | Catálogo de medicamentos y presentación. |
| `examenes_laboratorio` | Catálogo de exámenes, precio y estado. |
| `servicios_medicos` | Catálogo de servicios facturables, asociados opcionalmente a una especialidad. |
| `servicio_precio_historico` | Mantiene el precio de cada servicio a través del tiempo. |

### 5.3 Atención médica

| Tabla | Función |
|---|---|
| `historias_clinicas` | Guarda antecedentes, alergias, observaciones y fecha de apertura de la historia. |
| `consultas` | Registra citas y atenciones con paciente, médico, especialidad, historia, consultorio, fecha, duración, motivo, estado y tipo. |
| `recetas` | Relaciona una consulta con una receta médica. |
| `receta_detalle` | Detalla medicamentos, dosis, frecuencia, duración e indicaciones. |
| `solicitudes_laboratorio` | Registra una solicitud de exámenes originada por una consulta. |
| `solicitud_laboratorio_detalle` | Relaciona la solicitud con cada examen y guarda el resultado. |

### 5.4 Habitaciones e internaciones

| Tabla | Función |
|---|---|
| `tipos_habitacion` | Define categorías como individual, doble, UCI o maternidad. |
| `tipo_habitacion_tarifa_historico` | Guarda las tarifas diarias por tipo de habitación y fecha. |
| `habitaciones` | Guarda número, tipo y estado de cada habitación. |
| `ordenes_internacion` | Representa la orden médica de internación originada por una consulta. |
| `internaciones` | Registra paciente, habitación, ingreso, alta, estado y médico que autoriza el alta. |
| `cargos_internacion` | Guarda cargos económicos asociados a una internación. |

### 5.5 Cirugías e insumos

| Tabla | Función |
|---|---|
| `quirofanos` | Catálogo de quirófanos y disponibilidad. |
| `cirugias` | Programa la cirugía con paciente, quirófano, especialidad, cirujano, fecha, duración, diagnóstico y estado. |
| `cirugia_personal` | Relaciona una cirugía con las personas participantes y su rol. |
| `insumos` | Catálogo y stock de materiales utilizados. |
| `cirugia_insumo` | Detalla los insumos consumidos en cada cirugía. |

### 5.6 Seguros y facturación

| Tabla | Función |
|---|---|
| `aseguradoras` | Catálogo de compañías aseguradoras. Incluye la aseguradora reservada particular. |
| `convenios_aseguradora` | Define cobertura por aseguradora y especialidad. |
| `paciente_seguro` | Relaciona pacientes con aseguradoras, póliza, vigencia y estado activo. |
| `datos_facturacion` | Guarda NIT o CI, razón social y tipo de documento fiscal. |
| `facturas` | Registra paciente asegurado, usuario emisor, datos fiscales, forma de pago, subtotal, cobertura, total, estado y fecha. |
| `factura_detalle` | Detalla servicio, cantidad, precio unitario y origen en consulta, cirugía o internación. |
| `pagos_medicos` | Registra pagos a médicos por periodo, monto y estado. |

## 6. Relaciones importantes

La relación central comienza en `personas`. Una persona puede convertirse en paciente, médico o titular de una cuenta de usuario. Un paciente puede tener historias clínicas, consultas, cirugías, internaciones y seguros.

Una consulta relaciona al paciente con un médico, una especialidad, una historia clínica y un consultorio. Además, puede originar una receta, una solicitud de laboratorio o una orden de internación. La columna `consulta_padre` permite representar reconsultas vinculadas a una consulta anterior.

Una cirugía relaciona al paciente con un quirófano, especialidad y cirujano principal. Su personal adicional se registra en `cirugia_personal` y sus insumos en `cirugia_insumo`.

Una factura se emite para un registro de `paciente_seguro`, es generada por un usuario y utiliza datos fiscales. Sus detalles pueden provenir de servicios asociados a una consulta, cirugía o internación.

## 7. Consultas de lectura que ejecuta `index.php`

Cada vez que un usuario autenticado abre una página, el programa verifica cuáles tablas existen en `information_schema.tables`. Esto permite indicar si faltan tablas necesarias.

```sql
SELECT 1
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name = ?;
```

Después consulta los indicadores del dashboard:

```sql
SELECT COUNT(*) FROM pacientes;
SELECT COUNT(*) FROM consultas;
SELECT COUNT(*) FROM cirugias;
SELECT COUNT(*) FROM internaciones;
SELECT COUNT(*) FROM facturas;
```

Para pacientes, el sistema permite buscar por nombre o CI:

```sql
SELECT p.id_persona,
       p.ci,
       p.nombre,
       p.fecha_nacimiento,
       pa.tipo_sangre,
       pa.activo
FROM personas p
JOIN pacientes pa ON pa.id_persona = p.id_persona
WHERE p.nombre LIKE ? OR p.ci LIKE ?
ORDER BY p.nombre;
```

Para cargar formularios y catálogos, consulta médicos activos, especialidades, consultorios disponibles, habitaciones disponibles, quirófanos disponibles, tipos de habitación, aseguradoras, servicios y precios vigentes.

El precio vigente de un servicio se obtiene seleccionando el último precio cuya fecha ya comenzó:

```sql
SELECT s.id_servicio,
       s.nombre,
       COALESCE(
         (
           SELECT ph.precio
           FROM servicio_precio_historico ph
           WHERE ph.id_servicio = s.id_servicio
             AND ph.fecha_desde <= CURDATE()
           ORDER BY ph.fecha_desde DESC
           LIMIT 1
         ), 0
       ) AS precio
FROM servicios_medicos s
ORDER BY s.nombre;
```

Las historias clínicas se consultan uniendo la historia con la persona del paciente. Los médicos se agrupan con `GROUP_CONCAT` para mostrar todas sus especialidades en una sola fila.

Las consultas, cirugías e internaciones se muestran mediante `JOIN` con sus pacientes, médicos, especialidades, consultorios, quirófanos y habitaciones. Las facturas se consultan relacionando factura, póliza, paciente y datos fiscales.

La bitácora obtiene las últimas 200 operaciones:

```sql
SELECT *
FROM bitacora
ORDER BY fecha_hora DESC
LIMIT 200;
```

El reporte agrupa facturas por fecha y estado:

```sql
SELECT DATE(fecha_emision) AS fecha,
       estado,
       COUNT(*) AS cantidad,
       SUM(total) AS total
FROM facturas
GROUP BY DATE(fecha_emision), estado
ORDER BY fecha DESC
LIMIT 60;
```

## 8. Operaciones de escritura que ejecuta el código

### Registrar paciente

El código usa una transacción. Primero inserta la persona, obtiene `lastInsertId()`, crea el paciente y luego abre su historia clínica inicial.

```sql
INSERT INTO personas
    (ci, nombre, fecha_nacimiento, telefono, direccion, correo)
VALUES (?, ?, ?, ?, ?, ?);

INSERT INTO pacientes (id_persona, tipo_sangre)
VALUES (?, ?);

INSERT INTO historias_clinicas (id_persona)
VALUES (?);
```

### Crear catálogos

El administrador puede crear tipos de habitación, aseguradoras, especialidades, consultorios, quirófanos, habitaciones, servicios y médicos. Al crear un servicio se insertan dos registros: el servicio y su primer precio histórico.

```sql
INSERT INTO servicios_medicos (nombre, id_especialidad)
VALUES (?, ?);

INSERT INTO servicio_precio_historico
    (id_servicio, precio, fecha_desde)
VALUES (?, ?, CURDATE());
```

Para médicos, primero se crea la persona y después el registro profesional. Si se selecciona especialidad, se crea también la relación en `medico_especialidad`.

### Registrar historia clínica

```sql
INSERT INTO historias_clinicas
    (id_persona, antecedentes, alergias, observaciones)
VALUES (?, ?, ?, ?);
```

### Crear medicamentos y exámenes

```sql
INSERT INTO medicamentos (nombre, presentacion)
VALUES (?, ?);

INSERT INTO examenes_laboratorio (nombre, precio)
VALUES (?, ?);
```

### Crear usuario

El código crea una persona, busca el ID del rol por nombre y guarda la contraseña como hash bcrypt.

```sql
INSERT INTO personas
    (ci, nombre, fecha_nacimiento, telefono, correo)
VALUES (?, ?, ?, ?, ?);

SELECT id_rol
FROM roles
WHERE nombre = ?;

INSERT INTO usuarios
    (id_persona, id_rol, nombre_usuario, contrasena_hash, estado)
VALUES (?, ?, ?, ?, 1);
```

### Habilitar, deshabilitar y eliminar usuarios

```sql
UPDATE usuarios
SET estado = NOT estado
WHERE id_usuario = ?;

DELETE FROM usuarios
WHERE id_usuario = ?;
```

El código impide eliminar la propia cuenta del usuario que está conectado.

### Crear consulta

Antes de crear la consulta, el programa busca la historia más reciente del paciente. Si no existe, crea una nueva.

```sql
SELECT id_historia
FROM historias_clinicas
WHERE id_persona = ?
ORDER BY fecha_apertura DESC
LIMIT 1;
```

Después registra la cita:

```sql
INSERT INTO consultas
    (consulta_padre, id_persona, id_medico, id_especialidad,
     id_historia, id_consultorio, fecha_hora,
     duracion_estimada_minutos, motivo, tipo_consulta)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
```

El estado de una consulta se actualiza con:

```sql
UPDATE consultas
SET estado = ?
WHERE id_consulta = ?;
```

### Crear cirugía

```sql
INSERT INTO cirugias
    (id_persona, id_quirofano, id_especialidad,
     id_cirujano_principal, fecha_programada,
     duracion_estimada_minutos, diagnostico_prequirurgico, estado)
VALUES (?, ?, ?, ?, ?, ?, ?, ?);
```

El estado se modifica con:

```sql
UPDATE cirugias
SET estado = ?
WHERE id_cirugia = ?;
```

### Crear internación y liberar habitación

La internación se crea dentro de una transacción. Primero se crea la orden, luego la internación y finalmente se cambia la habitación a `OCUPADA`.

```sql
INSERT INTO ordenes_internacion (id_consulta, motivo)
VALUES (?, ?);

INSERT INTO internaciones
    (id_orden, id_persona, id_habitacion, fecha_ingreso, estado)
VALUES (?, ?, ?, ?, 'ACTIVA');

UPDATE habitaciones
SET estado = 'OCUPADA'
WHERE id_habitacion = ?;
```

Para registrar el alta se actualiza la internación y se libera la habitación:

```sql
UPDATE internaciones
SET estado = 'FINALIZADA',
    fecha_alta = NOW(),
    id_medico_autoriza_alta = ?
WHERE id_internacion = ?;

UPDATE habitaciones
SET estado = 'DISPONIBLE'
WHERE id_habitacion = ?;
```

### Crear factura

La factura se registra en una transacción. Primero guarda los datos fiscales, calcula subtotal y cobertura, crea la factura y finalmente inserta el detalle vinculado al origen seleccionado.

```sql
INSERT INTO datos_facturacion
    (nit_ci, razon_social, tipo_documento_fiscal)
VALUES (?, ?, ?);

INSERT INTO facturas
    (id_paciente_seguro, id_usuario_factura,
     id_datos_facturacion, tipo_pago, subtotal,
     monto_cobertura_seguro, estado)
VALUES (?, ?, ?, ?, ?, ?, ?);

INSERT INTO factura_detalle
    (id_factura, id_servicio, id_consulta,
     id_cirugia, id_internacion, cantidad, precio_unitario)
VALUES (?, ?, ?, ?, ?, ?, ?);
```

La tabla `facturas` calcula `total` como:

```text
total = subtotal - monto_cobertura_seguro
```

El estado de una factura se modifica con:

```sql
UPDATE facturas
SET estado = ?
WHERE id_factura = ?;
```

## 9. Triggers y reglas de la base

La base incluye restricciones `CHECK` para impedir valores negativos en precios, tarifas, cantidades, stock, montos y porcentajes. También utiliza claves foráneas para evitar referencias a pacientes, médicos, habitaciones o servicios inexistentes.

Los triggers incluidos realizan estas tareas:

| Trigger | Función |
|---|---|
| `trg_consultas_no_reconsulta_circular` | Evita que una consulta se establezca como padre de sí misma. |
| `trg_internacion_habitacion_ocupada` | Impide internar a otro paciente en una habitación que ya tiene una internación activa. |
| `trg_internacion_alta_valida` | Completa automáticamente la fecha de alta cuando una internación pasa a estado finalizado. |
| `trg_factura_detalle_recalcula_subtotal` | Recalcula el subtotal de la factura después de insertar un detalle. |
| `trg_factura_detalle_recalcula_subtotal_update` | Recalcula el subtotal después de modificar un detalle. |
| `trg_factura_detalle_recalcula_subtotal_delete` | Recalcula el subtotal después de eliminar un detalle. |

## 10. Flujo funcional completo

El flujo normal de uso comienza con la importación del esquema y la creación del administrador. Luego el administrador carga catálogos: especialidades, consultorios, quirófanos, habitaciones, servicios y médicos.

Después se registra al paciente. Al crearlo se guarda su información personal, se crea el registro de paciente y se abre su historia clínica. Con los catálogos disponibles se programa una consulta, asignando médico, especialidad, consultorio, fecha, duración, tipo y motivo.

A partir de la consulta pueden generarse recetas, solicitudes de laboratorio u órdenes de internación. En el módulo actual, la interfaz ya permite programar consultas e internaciones; las tablas de recetas y laboratorio están preparadas en la base para ampliar la interfaz.

Si el paciente necesita cirugía, se registra el procedimiento con quirófano, especialidad, cirujano, fecha, duración, diagnóstico y estado. Para una internación se asigna una habitación disponible, que pasa a estado ocupada; al registrar el alta vuelve a estar disponible.

Para facturar, el paciente debe tener una póliza registrada en `paciente_seguro`. Se selecciona el servicio, origen, cantidad, precio, cobertura, forma de pago y datos fiscales. El sistema registra la factura y calcula el total.

## 11. Funcionalidades visuales actuales

| Pantalla | Funcionalidad disponible |
|---|---|
| Login | Inicio de sesión, validación de contraseña, estado de cuenta y cierre de sesión. |
| Dashboard | Indicadores, agenda del día y estado de conexión. |
| Pacientes | Búsqueda y registro de pacientes. |
| Historias clínicas | Registro y listado de antecedentes, alergias y observaciones. |
| Consultas y citas | Programación y cambio de estado. |
| Cirugías | Registro y cambio de estado. |
| Internaciones | Registro, asignación de habitación, alta y liberación de habitación. |
| Facturación | Emisión y cambio de estado de facturas. |
| Laboratorio | Registro y listado del catálogo de exámenes. |
| Medicamentos | Registro y listado del catálogo de medicamentos. |
| Catálogos maestros | Especialidades, médicos, servicios, aseguradoras, consultorios, quirófanos, habitaciones y tipos de habitación. |
| Reportes | Resumen de facturación por fecha y estado. |
| Bitácora | Últimas operaciones registradas. |
| Usuarios y roles | Crear usuarios, cambiar estado y eliminar cuentas, solo para administradores. |

## 12. Tablas preparadas, pero sin pantalla completa en la interfaz actual

La base ya contiene las estructuras para `recetas`, `receta_detalle`, `solicitudes_laboratorio`, `solicitud_laboratorio_detalle`, `cirugia_personal`, `insumos`, `cirugia_insumo`, `convenios_aseguradora`, `cargos_internacion` y `pagos_medicos`. Sin embargo, la versión actual de `index.php` no ofrece formularios completos para operar todos esos módulos.

Esto significa que la base está preparada para esas funciones, pero agregar el 100 % de la operación visual requiere incorporar nuevas acciones PHP, formularios, listados y consultas específicas en `index.php`.

## 13. Instalación recomendada

Primero respalda cualquier base anterior. Luego importa únicamente `sql/Salud_y_vida_nueva_completa.sql`. Después, si deseas registros de prueba, importa `sql/datos_ejemplo_salud_vida.sql`.

Finalmente revisa `config.php`, coloca la contraseña correcta de MySQL, copia el proyecto en `C:\xampp\htdocs\salud-vida`, inicia Apache y MySQL y abre `http://localhost/salud-vida/index.php`.

Las credenciales iniciales son:

| Campo | Valor |
|---|---|
| Usuario | `admin` |
| Contraseña | `admin123` |

Cambia la contraseña inicial después del primer ingreso y no publiques `config.php` con credenciales reales.

## 14. Consultas útiles de verificación

```sql
USE Salud_y_vida;

SHOW TABLES;

SELECT COUNT(*) AS pacientes FROM pacientes;
SELECT COUNT(*) AS medicos FROM medicos;
SELECT COUNT(*) AS consultas FROM consultas;
SELECT COUNT(*) AS cirugias FROM cirugias;
SELECT COUNT(*) AS internaciones FROM internaciones;
SELECT COUNT(*) AS facturas FROM facturas;

SELECT u.nombre_usuario, r.nombre AS rol, u.estado, p.nombre
FROM usuarios u
JOIN roles r ON r.id_rol = u.id_rol
JOIN personas p ON p.id_persona = u.id_persona;

SELECT h.numero, t.nombre AS tipo, h.estado
FROM habitaciones h
JOIN tipos_habitacion t ON t.id_tipo_habitacion = h.id_tipo_habitacion
ORDER BY h.numero;

SELECT p.nombre, m.matricula_profesional, e.nombre AS especialidad
FROM medicos m
JOIN personas p ON p.id_persona = m.id_persona
LEFT JOIN medico_especialidad me ON me.id_persona = m.id_persona
LEFT JOIN especialidades e ON e.id_especialidad = me.id_especialidad
ORDER BY p.nombre;
```

> Esta guía describe el comportamiento del código y del esquema entregados. La prueba definitiva de ejecución debe realizarse en el MySQL de XAMPP, porque las operaciones dependen de que Apache, MySQL, PDO_MySQL y la configuración local estén activos.
