/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Control de Acceso / Roles
Archivo: 02_permisos.sql
Descripción:
Permisos de cada uno de los 5 roles sobre tablas, vistas, funciones
y procedimientos.
GRANT da permisos sobre tablas completas, no sobre filas. Por eso los
roles Usuario y Gerente NO reciben permisos sobre las tablas con datos
de clientes, sino sobre VISTAS que filtran por la persona conectada:
    cuenta.username = SUBSTRING_INDEX(USER(), '@', 1)
(Se usa USER() y no CURRENT_USER(): dentro de una vista SQL SECURITY
DEFINER, CURRENT_USER() devuelve al creador de la vista.)
Por eso cada usuario MySQL debe tener el mismo nombre que su cuenta.
Objetos de apoyo creados aquí (no son de los 20 del enunciado):
    fn_usuario_actual, fn_empresa_gerente,
    sp_crear_cuenta_empleado, sp_estado_cuenta_empleado.
Requisitos:
Ejecutar previamente DDL, DML, funciones.sql, triggers.sql,
procedimientos.sql, eventos.sql y 01_roles.sql (los GRANT EXECUTE
exigen que las funciones y procedimientos ya existan).
*/
USE coworking_db;

-- ============================================================================
-- SECCIÓN: PERMISOS POR ROL (Roles 01 a 05)
-- ============================================================================
-- =========================================
-- ROL 01
-- Administrador del Coworking -> Acceso total.
-- =========================================
-- Todos los privilegios sobre la base (incluye EVENT, TRIGGER,
-- CREATE ROUTINE, EXECUTE y CREATE VIEW).
GRANT ALL PRIVILEGES ON coworking_db.* TO 'rol_administrador';

-- =========================================
-- ROL 02
-- Recepcionista -> Registro de usuarios, asignación de membresías, gestión de reservas.
-- =========================================
-- ---------- Tablas ----------
-- Usuarios y seguridad
GRANT SELECT, INSERT, UPDATE ON coworking_db.empresa             TO 'rol_recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking_db.usuario             TO 'rol_recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking_db.cuenta              TO 'rol_recepcionista';
-- Membresías
GRANT SELECT                 ON coworking_db.tipo_membresia      TO 'rol_recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking_db.membresia           TO 'rol_recepcionista';
GRANT SELECT                 ON coworking_db.log_membresia       TO 'rol_recepcionista';
-- Espacios y reservas
GRANT SELECT                 ON coworking_db.tipo_espacio        TO 'rol_recepcionista';
GRANT SELECT, UPDATE         ON coworking_db.espacio             TO 'rol_recepcionista';
GRANT SELECT                 ON coworking_db.horario_espacio     TO 'rol_recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking_db.reserva             TO 'rol_recepcionista';
GRANT SELECT                 ON coworking_db.log_reserva         TO 'rol_recepcionista';
-- Servicios
GRANT SELECT                 ON coworking_db.servicio            TO 'rol_recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking_db.servicio_contratado TO 'rol_recepcionista';
-- Pagos y facturación (crea facturas y registra pagos en caja; no los modifica)
GRANT SELECT                 ON coworking_db.metodo_pago         TO 'rol_recepcionista';
GRANT SELECT, INSERT         ON coworking_db.factura             TO 'rol_recepcionista';
GRANT SELECT, INSERT         ON coworking_db.detalle_factura     TO 'rol_recepcionista';
GRANT SELECT, INSERT         ON coworking_db.pago                TO 'rol_recepcionista';
GRANT SELECT                 ON coworking_db.reembolso           TO 'rol_recepcionista';
GRANT SELECT, INSERT         ON coworking_db.penalizacion        TO 'rol_recepcionista';
-- Accesos
GRANT SELECT, INSERT, UPDATE ON coworking_db.credencial          TO 'rol_recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking_db.acceso              TO 'rol_recepcionista';
GRANT SELECT                 ON coworking_db.log_acceso_rechazado TO 'rol_recepcionista';
-- Comunicación
GRANT SELECT, INSERT         ON coworking_db.notificacion        TO 'rol_recepcionista';
-- Sin acceso: log_pago_anulado

-- ---------- Funciones (membresías, reservas y asistencias) ----------
GRANT EXECUTE ON FUNCTION coworking_db.fn_membresia_activa           TO 'rol_recepcionista';
GRANT EXECUTE ON FUNCTION coworking_db.fn_dias_restantes_membresia   TO 'rol_recepcionista';
GRANT EXECUTE ON FUNCTION coworking_db.fn_tipo_membresia             TO 'rol_recepcionista';
GRANT EXECUTE ON FUNCTION coworking_db.fn_renovaciones_membresia     TO 'rol_recepcionista';
GRANT EXECUTE ON FUNCTION coworking_db.fn_estado_membresia           TO 'rol_recepcionista';
GRANT EXECUTE ON FUNCTION coworking_db.fn_total_reservas             TO 'rol_recepcionista';
GRANT EXECUTE ON FUNCTION coworking_db.fn_horas_reservadas           TO 'rol_recepcionista';
GRANT EXECUTE ON FUNCTION coworking_db.fn_espacio_mas_reservado      TO 'rol_recepcionista';
GRANT EXECUTE ON FUNCTION coworking_db.fn_reservas_activas           TO 'rol_recepcionista';
GRANT EXECUTE ON FUNCTION coworking_db.fn_duracion_promedio_reservas TO 'rol_recepcionista';
GRANT EXECUTE ON FUNCTION coworking_db.fn_total_asistencias          TO 'rol_recepcionista';
GRANT EXECUTE ON FUNCTION coworking_db.fn_asistencias_mes            TO 'rol_recepcionista';
GRANT EXECUTE ON FUNCTION coworking_db.fn_top_usuario_asistencias    TO 'rol_recepcionista';
GRANT EXECUTE ON FUNCTION coworking_db.fn_ultima_asistencia          TO 'rol_recepcionista';
GRANT EXECUTE ON FUNCTION coworking_db.fn_promedio_asistencias       TO 'rol_recepcionista';

-- ---------- Procedimientos (membresías, reservas y accesos) ----------
GRANT EXECUTE ON PROCEDURE coworking_db.sp_registrar_membresia        TO 'rol_recepcionista';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_renovar_membresia          TO 'rol_recepcionista';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_verificar_disponibilidad   TO 'rol_recepcionista';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_crear_reserva              TO 'rol_recepcionista';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_confirmar_reserva_con_pago TO 'rol_recepcionista';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_cancelar_reserva           TO 'rol_recepcionista';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_cancelar_reservas_futuras  TO 'rol_recepcionista';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_registrar_entrada          TO 'rol_recepcionista';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_registrar_salida           TO 'rol_recepcionista';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_reporte_asistencias_diario TO 'rol_recepcionista';

-- =========================================
-- ROL 03
-- Usuario -> Reservar espacios, consultar historial, descargar facturas.
-- =========================================
-- Solo ve sus propios datos, a través de vistas. No recibe EXECUTE sobre
-- las funciones del enunciado: reciben cualquier id y le dejarían ver
-- datos de otros clientes.

-- ---------- Función de apoyo: cliente conectado ----------
DROP FUNCTION IF EXISTS fn_usuario_actual;

DELIMITER //
CREATE FUNCTION fn_usuario_actual()
RETURNS INT
READS SQL DATA
SQL SECURITY DEFINER
BEGIN
    DECLARE v_id INT;
    SELECT id_usuario INTO v_id
    FROM cuenta
    WHERE username = SUBSTRING_INDEX(USER(), '@', 1)
    LIMIT 1;
    RETURN v_id;
END //
DELIMITER ;

-- ---------- Vistas (WITH CHECK OPTION impide tocar filas de otro cliente) ----------
-- Su perfil (puede actualizar email y teléfono)
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_mi_perfil AS
SELECT *
FROM usuario
WHERE id_usuario = fn_usuario_actual()
WITH CHECK OPTION;

-- Su cuenta (puede cambiar su contraseña)
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_mi_cuenta AS
SELECT id_cuenta, username, password_hash, rol, activo, id_usuario
FROM cuenta
WHERE username = SUBSTRING_INDEX(USER(), '@', 1)
WITH CHECK OPTION;

-- Historial de membresías
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_mis_membresias AS
SELECT m.id_membresia, t.nombre AS tipo_membresia, m.estado, m.fecha_inicio, m.fecha_fin
FROM membresia m
JOIN tipo_membresia t ON t.id_tipo = m.id_tipo
WHERE m.id_usuario = fn_usuario_actual();

-- Sus reservas (puede crearlas y cancelarlas)
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_mis_reservas AS
SELECT *
FROM reserva
WHERE id_usuario = fn_usuario_actual()
WITH CHECK OPTION;

-- Ocupación de espacios (sin datos de otros clientes) para ver disponibilidad
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_ocupacion_espacios AS
SELECT r.id_espacio, e.nombre AS espacio, r.fecha_inicio, r.fecha_fin
FROM reserva r
JOIN espacio e ON e.id_espacio = r.id_espacio
WHERE r.estado IN ('Pendiente de Confirmacion', 'Confirmada')
  AND r.fecha_fin >= NOW();

-- Servicios contratados (puede contratar nuevos)
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_mis_servicios AS
SELECT *
FROM servicio_contratado
WHERE id_usuario = fn_usuario_actual()
WITH CHECK OPTION;

-- Facturas, su detalle y sus pagos (consulta / descarga)
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_mis_facturas AS
SELECT *
FROM factura
WHERE id_usuario = fn_usuario_actual();

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_mi_detalle_factura AS
SELECT d.*
FROM detalle_factura d
JOIN factura f ON f.id_factura = d.id_factura
WHERE f.id_usuario = fn_usuario_actual();

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_mis_pagos AS
SELECT p.id_pago, p.id_factura, mp.nombre AS metodo_pago, p.monto, p.fecha_pago, p.estado
FROM pago p
JOIN factura f      ON f.id_factura = p.id_factura
JOIN metodo_pago mp ON mp.id_metodo = p.id_metodo
WHERE f.id_usuario = fn_usuario_actual();

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_mis_reembolsos AS
SELECT rb.*
FROM reembolso rb
JOIN reserva r ON r.id_reserva = rb.id_reserva
WHERE r.id_usuario = fn_usuario_actual();

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_mis_penalizaciones AS
SELECT pe.*
FROM penalizacion pe
JOIN reserva r ON r.id_reserva = pe.id_reserva
WHERE r.id_usuario = fn_usuario_actual();

-- Credenciales (sin poder modificarlas) e historial de accesos
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_mis_credenciales AS
SELECT id_credencial, tipo, codigo, estado
FROM credencial
WHERE id_usuario = fn_usuario_actual();

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_mis_accesos AS
SELECT id_acceso, id_reserva, metodo, fecha_hora_entrada, fecha_hora_salida,
       resultado, motivo_rechazo
FROM acceso
WHERE id_usuario = fn_usuario_actual();

-- Sus notificaciones
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_mis_notificaciones AS
SELECT id_notificacion, tipo, asunto, mensaje, fecha_programada, enviada, fecha_envio
FROM notificacion
WHERE id_usuario = fn_usuario_actual();

-- ---------- Permisos ----------
-- Catálogos (información pública del coworking)
GRANT SELECT ON coworking_db.tipo_membresia  TO 'rol_usuario';
GRANT SELECT ON coworking_db.tipo_espacio    TO 'rol_usuario';
GRANT SELECT ON coworking_db.espacio         TO 'rol_usuario';
GRANT SELECT ON coworking_db.horario_espacio TO 'rol_usuario';
GRANT SELECT ON coworking_db.servicio        TO 'rol_usuario';
GRANT SELECT ON coworking_db.metodo_pago     TO 'rol_usuario';
-- Datos propios (a través de vistas)
GRANT SELECT                          ON coworking_db.v_mi_perfil          TO 'rol_usuario';
GRANT UPDATE (email, telefono)        ON coworking_db.v_mi_perfil          TO 'rol_usuario';
GRANT SELECT                          ON coworking_db.v_mi_cuenta          TO 'rol_usuario';
GRANT UPDATE (password_hash)          ON coworking_db.v_mi_cuenta          TO 'rol_usuario';
GRANT SELECT                          ON coworking_db.v_mis_membresias     TO 'rol_usuario';
GRANT SELECT, INSERT                  ON coworking_db.v_mis_reservas       TO 'rol_usuario';
GRANT UPDATE (estado)                 ON coworking_db.v_mis_reservas       TO 'rol_usuario';
GRANT SELECT                          ON coworking_db.v_ocupacion_espacios TO 'rol_usuario';
GRANT SELECT, INSERT                  ON coworking_db.v_mis_servicios      TO 'rol_usuario';
GRANT SELECT                          ON coworking_db.v_mis_facturas       TO 'rol_usuario';
GRANT SELECT                          ON coworking_db.v_mi_detalle_factura TO 'rol_usuario';
GRANT SELECT                          ON coworking_db.v_mis_pagos          TO 'rol_usuario';
GRANT SELECT                          ON coworking_db.v_mis_reembolsos     TO 'rol_usuario';
GRANT SELECT                          ON coworking_db.v_mis_penalizaciones TO 'rol_usuario';
GRANT SELECT                          ON coworking_db.v_mis_credenciales   TO 'rol_usuario';
GRANT SELECT                          ON coworking_db.v_mis_accesos        TO 'rol_usuario';
GRANT SELECT                          ON coworking_db.v_mis_notificaciones TO 'rol_usuario';
-- Procedimientos (validan por dentro que la reserva sea suya)
GRANT EXECUTE ON PROCEDURE coworking_db.sp_verificar_disponibilidad   TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_crear_reserva              TO 'rol_usuario';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_cancelar_reserva           TO 'rol_usuario';

-- =========================================
-- ROL 04
-- Gerente Corporativo -> Administrar empleados de su empresa, ver facturación consolidada.
-- =========================================
-- Solo ve los datos de su empresa (cuenta.id_empresa de su cuenta), a
-- través de vistas. No recibe EXECUTE sobre las funciones del enunciado.

-- ---------- Función de apoyo: empresa del gerente conectado ----------
DROP FUNCTION IF EXISTS fn_empresa_gerente;

DELIMITER //
CREATE FUNCTION fn_empresa_gerente()
RETURNS INT
READS SQL DATA
SQL SECURITY DEFINER
BEGIN
    DECLARE v_id INT;
    SELECT id_empresa INTO v_id
    FROM cuenta
    WHERE username = SUBSTRING_INDEX(USER(), '@', 1)
      AND rol = 'Gerente'
    LIMIT 1;
    RETURN v_id;
END //
DELIMITER ;

-- ---------- Vistas y procedimientos de apoyo ----------
-- Su empresa
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_mi_empresa AS
SELECT *
FROM empresa
WHERE id_empresa = fn_empresa_gerente();

-- Empleados (puede registrar nuevos y actualizar sus datos)
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_empleados AS
SELECT *
FROM usuario
WHERE id_empresa = fn_empresa_gerente()
WITH CHECK OPTION;

-- Cuentas de sus empleados (solo lectura, sin contraseñas).
-- Para crear o activar/desactivar cuentas usa los procedimientos de abajo:
-- una vista sobre cuenta que filtre con una función que también lee cuenta
-- no es actualizable en MySQL.
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_cuentas_empleados AS
SELECT c.id_cuenta, c.username, c.rol, c.activo, c.id_usuario
FROM cuenta c
JOIN usuario u ON u.id_usuario = c.id_usuario
WHERE u.id_empresa = fn_empresa_gerente();

-- Crear la cuenta de un empleado de su empresa (siempre con rol 'Usuario')
DROP PROCEDURE IF EXISTS sp_crear_cuenta_empleado;
DROP PROCEDURE IF EXISTS sp_estado_cuenta_empleado;
DELIMITER //
CREATE PROCEDURE sp_crear_cuenta_empleado(
    IN p_id_usuario INT,
    IN p_username   VARCHAR(50),
    IN p_password   VARCHAR(255))
SQL SECURITY DEFINER
BEGIN
    IF fn_empresa_gerente() IS NULL
       OR NOT EXISTS (SELECT 1 FROM usuario
                      WHERE id_usuario = p_id_usuario
                        AND id_empresa = fn_empresa_gerente()) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El usuario no es empleado de su empresa';
    END IF;
    INSERT INTO cuenta (username, password_hash, rol, activo, id_usuario)
    VALUES (p_username, p_password, 'Usuario', TRUE, p_id_usuario);
END //

-- Activar o desactivar la cuenta de un empleado de su empresa
CREATE PROCEDURE sp_estado_cuenta_empleado(
    IN p_id_cuenta INT,
    IN p_activo    BOOLEAN)
SQL SECURITY DEFINER
BEGIN
    IF fn_empresa_gerente() IS NULL
       OR NOT EXISTS (SELECT 1 FROM cuenta c
                      JOIN usuario u ON u.id_usuario = c.id_usuario
                      WHERE c.id_cuenta = p_id_cuenta
                        AND c.rol = 'Usuario'
                        AND u.id_empresa = fn_empresa_gerente()) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La cuenta no pertenece a un empleado de su empresa';
    END IF;
    UPDATE cuenta SET activo = p_activo WHERE id_cuenta = p_id_cuenta;
END //
DELIMITER ;

-- Membresías de sus empleados (puede solicitar membresías nuevas)
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_membresias_empleados AS
SELECT *
FROM membresia
WHERE id_usuario IN (SELECT id_usuario FROM usuario WHERE id_empresa = fn_empresa_gerente())
WITH CHECK OPTION;

-- Reservas, servicios y accesos de sus empleados (solo lectura)
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_reservas_empleados AS
SELECT r.*
FROM reserva r
JOIN usuario u ON u.id_usuario = r.id_usuario
WHERE u.id_empresa = fn_empresa_gerente();

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_servicios_empleados AS
SELECT sc.*
FROM servicio_contratado sc
JOIN usuario u ON u.id_usuario = sc.id_usuario
WHERE u.id_empresa = fn_empresa_gerente();

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_accesos_empleados AS
SELECT a.id_acceso, a.id_usuario, a.id_reserva, a.metodo, a.fecha_hora_entrada,
       a.fecha_hora_salida, a.resultado, a.motivo_rechazo
FROM acceso a
JOIN usuario u ON u.id_usuario = a.id_usuario
WHERE u.id_empresa = fn_empresa_gerente();

-- Facturación: consolidadas de la empresa + individuales de sus empleados
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_facturas_empresa AS
SELECT f.*
FROM factura f
LEFT JOIN usuario u ON u.id_usuario = f.id_usuario
WHERE COALESCE(f.id_empresa, u.id_empresa) = fn_empresa_gerente();

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_detalle_facturas_empresa AS
SELECT d.*
FROM detalle_factura d
JOIN factura f      ON f.id_factura = d.id_factura
LEFT JOIN usuario u ON u.id_usuario = f.id_usuario
WHERE COALESCE(f.id_empresa, u.id_empresa) = fn_empresa_gerente();

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_pagos_empresa AS
SELECT p.id_pago, p.id_factura, mp.nombre AS metodo_pago, p.monto, p.fecha_pago, p.estado
FROM pago p
JOIN factura f      ON f.id_factura = p.id_factura
JOIN metodo_pago mp ON mp.id_metodo = p.id_metodo
LEFT JOIN usuario u ON u.id_usuario = f.id_usuario
WHERE COALESCE(f.id_empresa, u.id_empresa) = fn_empresa_gerente();

CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_penalizaciones_empresa AS
SELECT pe.*
FROM penalizacion pe
JOIN reserva r ON r.id_reserva = pe.id_reserva
JOIN usuario u ON u.id_usuario = r.id_usuario
WHERE u.id_empresa = fn_empresa_gerente();

-- Notificaciones dirigidas al gerente
CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_notificaciones_gerente AS
SELECT n.id_notificacion, n.tipo, n.asunto, n.mensaje, n.fecha_programada, n.enviada, n.fecha_envio
FROM notificacion n
JOIN cuenta c ON c.username = SUBSTRING_INDEX(USER(), '@', 1) AND c.rol = 'Gerente'
WHERE n.id_cuenta = c.id_cuenta OR n.id_usuario = c.id_usuario;

-- ---------- Permisos ----------
-- Catálogos
GRANT SELECT ON coworking_db.tipo_membresia  TO 'rol_gerente';
GRANT SELECT ON coworking_db.tipo_espacio    TO 'rol_gerente';
GRANT SELECT ON coworking_db.espacio         TO 'rol_gerente';
GRANT SELECT ON coworking_db.horario_espacio TO 'rol_gerente';
GRANT SELECT ON coworking_db.servicio        TO 'rol_gerente';
GRANT SELECT ON coworking_db.metodo_pago     TO 'rol_gerente';
-- Datos de su empresa (a través de vistas)
GRANT SELECT                 ON coworking_db.v_mi_empresa               TO 'rol_gerente';
GRANT SELECT, INSERT, UPDATE ON coworking_db.v_empleados                TO 'rol_gerente';
GRANT SELECT                 ON coworking_db.v_cuentas_empleados        TO 'rol_gerente';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_crear_cuenta_empleado  TO 'rol_gerente';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_estado_cuenta_empleado TO 'rol_gerente';
GRANT SELECT, INSERT         ON coworking_db.v_membresias_empleados     TO 'rol_gerente';
GRANT SELECT                 ON coworking_db.v_reservas_empleados       TO 'rol_gerente';
GRANT SELECT                 ON coworking_db.v_servicios_empleados      TO 'rol_gerente';
GRANT SELECT                 ON coworking_db.v_accesos_empleados        TO 'rol_gerente';
GRANT SELECT                 ON coworking_db.v_facturas_empresa         TO 'rol_gerente';
GRANT SELECT                 ON coworking_db.v_detalle_facturas_empresa TO 'rol_gerente';
GRANT SELECT                 ON coworking_db.v_pagos_empresa            TO 'rol_gerente';
GRANT SELECT                 ON coworking_db.v_penalizaciones_empresa   TO 'rol_gerente';
GRANT SELECT                 ON coworking_db.v_notificaciones_gerente   TO 'rol_gerente';
-- Procedimientos del enunciado (valida que sea su empresa)
GRANT EXECUTE ON PROCEDURE coworking_db.sp_registrar_lote_empleados   TO 'rol_gerente';

-- =========================================
-- ROL 05
-- Contador -> Gestión de ingresos y reportes financieros.
-- =========================================
-- ---------- Tablas ----------
-- Lectura para cruzar ingresos por cliente, empresa, membresía, espacio o servicio
GRANT SELECT ON coworking_db.empresa             TO 'rol_contador';
GRANT SELECT ON coworking_db.usuario             TO 'rol_contador';
GRANT SELECT ON coworking_db.tipo_membresia      TO 'rol_contador';
GRANT SELECT ON coworking_db.membresia           TO 'rol_contador';
GRANT SELECT ON coworking_db.log_membresia       TO 'rol_contador';
GRANT SELECT ON coworking_db.tipo_espacio        TO 'rol_contador';
GRANT SELECT ON coworking_db.espacio             TO 'rol_contador';
GRANT SELECT ON coworking_db.reserva             TO 'rol_contador';
GRANT SELECT ON coworking_db.log_reserva         TO 'rol_contador';
GRANT SELECT ON coworking_db.servicio            TO 'rol_contador';
GRANT SELECT ON coworking_db.servicio_contratado TO 'rol_contador';
GRANT SELECT ON coworking_db.metodo_pago         TO 'rol_contador';
GRANT SELECT ON coworking_db.log_pago_anulado    TO 'rol_contador';
GRANT SELECT ON coworking_db.notificacion        TO 'rol_contador';
-- Gestión del módulo financiero (ajustes, recargos, anulaciones)
GRANT SELECT, INSERT, UPDATE ON coworking_db.factura         TO 'rol_contador';
GRANT SELECT, INSERT, UPDATE ON coworking_db.detalle_factura TO 'rol_contador';
GRANT SELECT, INSERT, UPDATE ON coworking_db.pago            TO 'rol_contador';
GRANT SELECT, INSERT, UPDATE ON coworking_db.reembolso       TO 'rol_contador';
GRANT SELECT, INSERT, UPDATE ON coworking_db.penalizacion    TO 'rol_contador';
-- Sin acceso: cuenta, horario_espacio, credencial, acceso, log_acceso_rechazado

-- ---------- Funciones (pagos y facturación + membresías) ----------
GRANT EXECUTE ON FUNCTION coworking_db.fn_total_pagado               TO 'rol_contador';
GRANT EXECUTE ON FUNCTION coworking_db.fn_ingresos_por_mes           TO 'rol_contador';
GRANT EXECUTE ON FUNCTION coworking_db.fn_ingresos_por_membresias    TO 'rol_contador';
GRANT EXECUTE ON FUNCTION coworking_db.fn_ingresos_por_reservas      TO 'rol_contador';
GRANT EXECUTE ON FUNCTION coworking_db.fn_ingresos_por_empresa       TO 'rol_contador';
GRANT EXECUTE ON FUNCTION coworking_db.fn_membresia_activa           TO 'rol_contador';
GRANT EXECUTE ON FUNCTION coworking_db.fn_tipo_membresia             TO 'rol_contador';
GRANT EXECUTE ON FUNCTION coworking_db.fn_estado_membresia           TO 'rol_contador';
GRANT EXECUTE ON FUNCTION coworking_db.fn_renovaciones_membresia     TO 'rol_contador';

-- ---------- Procedimientos (facturación, recargos, bloqueos y reportes) ----------
GRANT EXECUTE ON PROCEDURE coworking_db.sp_factura_membresia          TO 'rol_contador';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_factura_consolidada        TO 'rol_contador';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_aplicar_recargos_vencidas  TO 'rol_contador';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_bloquear_servicios         TO 'rol_contador';
GRANT EXECUTE ON PROCEDURE coworking_db.sp_reporte_ingresos_mensual   TO 'rol_contador';
-- Solo el Administrador ejecuta los procesos masivos que usan los eventos:
--   sp_actualizar_membresias_vencidas, sp_suspender_membresias_morosas,
--   sp_liberar_reservas_pendientes, sp_marcar_no_show
