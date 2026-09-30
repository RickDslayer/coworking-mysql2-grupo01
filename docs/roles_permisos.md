# Roles y permisos: Gestión de Coworking

## Roles del sistema

| Rol | Responsabilidad (según el documento) |
|-----|--------------------------------------|
| **Administrador** | Acceso total a la base de datos. |
| **Recepcionista** | Registro de usuarios, asignación de membresías, gestión de reservas y control de acceso. |
| **Usuario** | Reservar espacios, consultar su historial y descargar sus facturas. |
| **Gerente Corporativo** | Administrar los empleados de su empresa y ver su facturación consolidada. |
| **Contador** | Gestión de ingresos, pagos y reportes financieros. |

## Matriz de permisos

`x` = sin acceso

| Objeto | Administrador | Recepcionista | Usuario | Gerente Corporativo | Contador |
|--------|---------------|---------------|---------|---------------------|----------|
| EMPRESA | SELECT, INSERT, UPDATE, DELETE | SELECT, INSERT, UPDATE | x | SELECT | SELECT |
| USUARIO | SELECT, INSERT, UPDATE, DELETE | SELECT, INSERT, UPDATE | SELECT, UPDATE | SELECT, INSERT, UPDATE | SELECT |
| CUENTA | SELECT, INSERT, UPDATE, DELETE | SELECT, INSERT, UPDATE | SELECT, UPDATE | SELECT, INSERT, UPDATE | x |
| TIPO_MEMBRESIA | SELECT, INSERT, UPDATE, DELETE | SELECT | SELECT | SELECT | SELECT |
| MEMBRESIA | SELECT, INSERT, UPDATE, DELETE | SELECT, INSERT, UPDATE | SELECT | SELECT, INSERT | SELECT |
| LOG_MEMBRESIA | SELECT, INSERT, UPDATE, DELETE | SELECT | x | x | SELECT |
| TIPO_ESPACIO | SELECT, INSERT, UPDATE, DELETE | SELECT | SELECT | SELECT | SELECT |
| ESPACIO | SELECT, INSERT, UPDATE, DELETE | SELECT, UPDATE | SELECT | SELECT | SELECT |
| HORARIO_ESPACIO | SELECT, INSERT, UPDATE, DELETE | SELECT | SELECT | SELECT | x |
| RESERVA | SELECT, INSERT, UPDATE, DELETE | SELECT, INSERT, UPDATE | SELECT, INSERT, UPDATE | SELECT | SELECT |
| LOG_RESERVA | SELECT, INSERT, UPDATE, DELETE | SELECT | x | x | SELECT |
| SERVICIO | SELECT, INSERT, UPDATE, DELETE | SELECT | SELECT | SELECT | SELECT |
| SERVICIO_CONTRATADO | SELECT, INSERT, UPDATE, DELETE | SELECT, INSERT, UPDATE | SELECT, INSERT | SELECT | SELECT |
| METODO_PAGO | SELECT, INSERT, UPDATE, DELETE | SELECT | SELECT | SELECT | SELECT |
| FACTURA | SELECT, INSERT, UPDATE, DELETE | SELECT, INSERT | SELECT | SELECT | SELECT, INSERT, UPDATE |
| DETALLE_FACTURA | SELECT, INSERT, UPDATE, DELETE | SELECT, INSERT | SELECT | SELECT | SELECT, INSERT, UPDATE |
| PAGO | SELECT, INSERT, UPDATE, DELETE | SELECT, INSERT | SELECT | SELECT | SELECT, INSERT, UPDATE |
| LOG_PAGO_ANULADO | SELECT, INSERT, UPDATE, DELETE | x | x | x | SELECT |
| REEMBOLSO | SELECT, INSERT, UPDATE, DELETE | SELECT | SELECT | x | SELECT, INSERT, UPDATE |
| PENALIZACION | SELECT, INSERT, UPDATE, DELETE | SELECT, INSERT | SELECT | SELECT | SELECT, INSERT, UPDATE |
| CREDENCIAL | SELECT, INSERT, UPDATE, DELETE | SELECT, INSERT, UPDATE | SELECT | x | x |
| ACCESO | SELECT, INSERT, UPDATE, DELETE | SELECT, INSERT, UPDATE | SELECT | SELECT | x |
| LOG_ACCESO_RECHAZADO | SELECT, INSERT, UPDATE, DELETE | SELECT | x | x | x |
| NOTIFICACION | SELECT, INSERT, UPDATE, DELETE | SELECT, INSERT | SELECT | SELECT | SELECT |

## Por qué se asignó así

**Recepcionista**
- Registra clientes (`USUARIO`, `CUENTA`, `EMPRESA`), asigna membresías y entrega credenciales.
- Gestiona reservas y servicios contratados. Puede cambiar el `estado` de un `ESPACIO`, por ejemplo a Mantenimiento.
- Registra entradas y salidas en `ACCESO`.
- Puede crear facturas y registrar pagos en caja, pero no modificarlos. Las anulaciones y los ajustes son del Contador.
- No ve `LOG_PAGO_ANULADO`, que es información financiera.

**Usuario**
- Solo ve y modifica **sus propios** datos. Puede actualizar su teléfono o email y cambiar su contraseña.
- Puede crear reservas y cancelarlas (`UPDATE` del estado), y contratar servicios.
- Consulta su historial de accesos, reservas, membresías y facturas.

**Gerente Corporativo**
- Solo ve y modifica los datos de **su empresa** (`CUENTA.id_empresa`).
- Puede registrar empleados nuevos (`USUARIO` + `CUENTA`) y solicitarles membresía corporativa (`INSERT` en `MEMBRESIA`).
- Consulta la facturación consolidada, los pagos y la asistencia de sus empleados.
- No ve credenciales ni logs.

**Contador**
- Administra todo el módulo financiero: facturas, detalles, pagos, reembolsos y penalizaciones. Hace ajustes, recargos y anulaciones.
- Tiene lectura sobre membresías, reservas y servicios para cruzar ingresos por tipo de membresía, espacio o servicio.
- No tiene acceso a `CUENTA` (contraseñas) ni a los datos de acceso físico.

**Tablas de log**
- Nadie, salvo el Administrador, tiene `INSERT` o `UPDATE` sobre las tablas `LOG_*`. Las llenan los triggers, que se ejecutan con los permisos de quien los creó (`DEFINER`), así que los roles no necesitan esos permisos. Así nadie puede alterar la auditoría.
- Por la misma razón, el Recepcionista no necesita `UPDATE` sobre `FACTURA` para que el trigger actualice `saldo_pendiente` al registrar un pago.

## Consideraciones de implementación

1. **Restricción por fila (Usuario y Gerente).** `GRANT` en MySQL da permisos sobre tablas completas, no sobre filas. Para que un Usuario vea solo lo suyo y un Gerente solo lo de su empresa, se les da acceso a **vistas** en lugar de a las tablas. Las vistas filtran con `CURRENT_USER()` contra `CUENTA.username`. Por ejemplo, `v_mis_reservas` o `v_facturas_empresa`, con `SQL SECURITY DEFINER`.
2. **Procedimientos almacenados.** Cada rol debe tener además `EXECUTE` sobre los procedimientos de su área:

| Rol | Procedimientos |
|-----|----------------|
| Administrador | Todos |
| Recepcionista | Registrar / renovar membresía, verificar disponibilidad, crear / confirmar / cancelar reserva, registrar entrada y salida |
| Usuario | Verificar disponibilidad, crear reserva, cancelar reserva |
| Gerente Corporativo | Registrar lote de empleados corporativos |
| Contador | Generar factura (membresía y consolidada), aplicar recargos, bloquear servicios por falta de pago, reporte de ingresos mensuales |

3. **Eventos.** Los eventos los crea y administra solo el Administrador. Necesitan el privilegio `EVENT` y `event_scheduler = ON`.