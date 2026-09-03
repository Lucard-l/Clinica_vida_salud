# Salud Vida — Aplicación PHP/MySQL

Aplicación de gestión clínica integral desarrollada en PHP, PDO y MySQL para ejecutarse localmente con XAMPP.

## Instalación limpia

Primero realiza una copia de seguridad de cualquier base de datos anterior. El archivo `sql/Salud_y_vida_nueva_completa.sql` elimina y vuelve a crear la base `Salud_y_vida`, por lo que no debe ejecutarse si necesitas conservar los datos antiguos.

En phpMyAdmin selecciona **Importar** y carga `sql/Salud_y_vida_nueva_completa.sql`. El script crea todas las tablas del diagrama, relaciones, claves foráneas, restricciones, índices, triggers y catálogos iniciales. También crea el usuario administrador inicial.

El archivo `config.php` está preparado para esta conexión:

```php
'host' => '127.0.0.1',
'port' => '3306',
'database' => 'Salud_y_vida',
'username' => 'root',
'password' => '',
```

Modifica únicamente la contraseña o el puerto si tu instalación de MySQL utiliza valores distintos. Copia la carpeta dentro de `C:\xampp\htdocs\salud-vida` e inicia Apache y MySQL desde XAMPP. Después abre `http://localhost/salud-vida/index.php`.

Las credenciales iniciales son **admin** y **admin123**. Cambia la contraseña después del primer ingreso.

## Compatibilidad con el diagrama

El código utiliza los nombres del diagrama: `personas`, `pacientes`, `medicos`, `usuarios`, `roles`, `historias_clinicas`, `consultas`, `recetas`, `solicitudes_laboratorio`, `internaciones`, `cirugias`, `cirugia_personal`, `cirugia_insumo`, `aseguradoras`, `paciente_seguro`, `servicios_medicos`, `facturas`, `factura_detalle` y `pagos_medicos`, entre otras tablas de apoyo.

Además, se conservaron columnas operativas que la interfaz necesita para trabajar, como `estado`, `motivo`, `fecha_emision`, `subtotal`, `monto_cobertura_seguro`, `duracion_estimada_minutos` y `diagnostico_prequirurgico`. Por esa razón, el esquema es compatible tanto con el diagrama como con las operaciones actuales del programa.

## Funcionalidades incluidas

El sistema cuenta con inicio de sesión por rol, dashboard, pacientes, historias clínicas, agenda de consultas, cirugías, internaciones, facturación, catálogos de médicos y especialidades, medicamentos, exámenes de laboratorio, reportes, bitácora y administración de usuarios.

La interfaz incluye formularios para crear los registros principales. Las relaciones se guardan mediante identificadores y claves foráneas, no mediante texto libre. Las operaciones de inserción usan consultas preparadas y las contraseñas se almacenan como hashes.

El botón de cámara solicita permiso mediante `getUserMedia` desde `localhost` o HTTPS; por sí solo no constituye reconocimiento facial biométrico.

## Nota sobre scripts antiguos

Los archivos SQL anteriores se conservan como referencia, pero no deben mezclarse durante la instalación. Para una base nueva utiliza únicamente `sql/Salud_y_vida_nueva_completa.sql`.

## Datos completos para pruebas

Después del esquema principal y del catálogo inicial, puedes importar `sql/datos_prueba_completos_salud_vida.sql`. Este script agrega aseguradoras, pacientes, historias, pólizas, medicamentos, exámenes, insumos, convenios, consultas, recetas, solicitudes de laboratorio, cirugías, internaciones, cargos y facturas relacionadas.

También crea cuentas de prueba. Todas utilizan la contraseña `admin123`:

| Usuario | Rol | Acceso |
|---|---|---|
| `admin` | ADMINISTRADOR | Acceso completo |
| `facturador` | FACTURADOR | Solo facturación |
| `medico` | MEDICO | Operación clínica autorizada |
| `enfermero` | ENFERMERO | Operación asistencial autorizada |

La vista `vw_facturacion_operativa` permite consultar exclusivamente la información necesaria de facturación, incluyendo paciente, aseguradora, póliza, datos fiscales, servicio, subtotal, cobertura, total, estado y usuario emisor.

## Nueva versión del diagrama y niveles de poder

Para aplicar el nuevo diagrama, importa en este orden: `sql/Salud_y_vida_nueva_completa.sql`, `sql/migracion_diagrama_v2.sql` y después `sql/datos_prueba_completos_salud_vida.sql`.

La migración agrega `SUPERVISOR`, contratos médicos, registro facial único por persona, fotografías de medicamentos, índices de búsqueda, `vw_historial_persona` y `vw_facturacion_operativa`. El esquema mantiene algunas columnas adicionales del proyecto actual, como `id_persona` en `usuarios`, `id_paciente_seguro` en `facturas` y los campos de origen de `factura_detalle`, porque el código PHP los utiliza para conservar compatibilidad con seguros y trazabilidad de facturación.

| Rol | Alcance |
|---|---|
| ADMINISTRADOR | Control total, gestión de usuarios, cambio de roles, eliminación de cuentas y configuración de seguridad. |
| SUPERVISOR | Puede registrar pacientes, personal, médicos, contratos, habitaciones, quirófanos, seguros, medicamentos, historias, consultas, internaciones y facturas. No administra cuentas ni cambia roles. |
| FACTURADOR | Solo consulta y registra facturación, datos fiscales, detalles, cobertura y estados de factura. |
| ENFERMERO | Registra medicamentos con fotografía, insumos, historias, pacientes, consultas e internaciones autorizadas. |
| MEDICO | Registra atención clínica, recetas, exámenes, consultas, cirugías e internaciones autorizadas. |

La pantalla de facturación es independiente y selecciona registros existentes de consultas, cirugías e internaciones. La vista `vw_facturacion_operativa` sirve para consultas y reportes exclusivamente financieros.

El registro facial se modela con una única fila por persona en `registro_facial` y se relaciona con el administrador que lo registró. La captura y verificación biométrica real requieren integrar WebAuthn/passkeys o un proveedor biométrico; abrir la cámara del navegador por sí solo no autentica una identidad y no debe presentarse como reconocimiento facial.

## Instalación recomendada v2 en phpMyAdmin

Si aparece `#1146 - Tabla 'salud_y_vida.roles' no existe` al importar `migracion_diagrama_v2.sql`, significa que se importó la migración sin importar antes el esquema base. La forma más sencilla es importar únicamente `sql/instalacion_completa_salud_vida_v2.sql`, que contiene el esquema base y la migración en el orden correcto. No importes primero la migración sola.

## Usuarios de prueba v3

El script `sql/datos_prueba_10_usuarios_salud_vida.sql` crea o actualiza estas cuentas. Todas usan la contraseña inicial `admin123`.

| Nombre | Usuario | Rol |
|---|---|---|
| Fabiana | `fabiana` | FACTURADOR |
| Maciel | `maciel` | SUPERVISOR |
| Josue | `josue` | ENFERMERO |
| Luis | `luis` | ADMINISTRADOR |

Importa primero `sql/instalacion_completa_salud_vida_v2.sql` y luego `sql/datos_prueba_10_usuarios_salud_vida.sql`. La pantalla `Registro facial` aparece únicamente para ADMINISTRADOR y permite guardar o reemplazar una captura para una persona; la tabla impone una sola inscripción por persona. `Exportar Excel` aparece para ADMINISTRADOR y SUPERVISOR.
