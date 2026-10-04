/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Eventos SQL
Archivo: 01_eventos.sql
Descripción:
Implementación de los 20 Eventos SQL del proyecto. Se crean
desactivados (DISABLE) para no modificar los datos de prueba; se
activan con SET GLOBAL event_scheduler = ON y ALTER EVENT ... ENABLE.
Requisitos:
Ejecutar previamente DDL, DML, funciones, triggers y procedimientos.
*/

USE coworking_db;

-- ============================================================================
-- SECCIÓN: EVENTOS SQL (Eventos 01 a 20)
-- ============================================================================
-- Submódulo: Membresías (Eventos 01 a 05)
-- =========================================
-- EVENTO 01
-- Revisar diariamente membresías vencidas y actualizarlas a estado "Vencida".
-- =========================================
-- =========================================
-- EVENTO 02
-- Enviar recordatorio de renovación 5 días antes de vencer la membresía.
-- =========================================
DROP EVENT IF EXISTS ev_recordatorio_renovacion;

DELIMITER $$

CREATE EVENT ev_recordatorio_renovacion
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL '08:00' HOUR_MINUTE
DISABLE  -- se deja desactivado por defecto; activar según necesidad
COMMENT 'Diario 08:00 - aviso a clientes cuya membresia vence en 5 dias'
DO
BEGIN
    INSERT INTO NOTIFICACION (id_usuario, destinatario_rol, tipo, asunto, mensaje, fecha_programada)
    SELECT m.id_usuario,
           'Usuario',
           'Recordatorio',
           'Tu membresia vence pronto',
           CONCAT('Hola ', u.nombre, ', tu membresia ', t.nombre, ' vence el ',
                  DATE_FORMAT(m.fecha_fin, '%d/%m/%Y'),
                  '. Renuevala para no perder el acceso.'),
           NOW()
    FROM MEMBRESIA m
    JOIN USUARIO u        ON u.id_usuario = m.id_usuario
    JOIN TIPO_MEMBRESIA t ON t.id_tipo    = m.id_tipo
    WHERE m.estado = 'Activa'
      AND m.fecha_fin = CURDATE() + INTERVAL 5 DAY
      -- no avisar si ya renovó (tiene otra membresía que empieza después)
      AND NOT EXISTS (SELECT 1 FROM MEMBRESIA m2
                      WHERE m2.id_usuario = m.id_usuario
                        AND m2.fecha_inicio >= m.fecha_fin);
END $$

DELIMITER ;

-- =========================================
-- EVENTO 03
-- Suspender membresías inactivas después de 30 días sin pago.
-- =========================================

DROP EVENT IF EXISTS evt_suspender_membresias_sin_pago;

CREATE EVENT evt_suspender_membresias_sin_pago
ON SCHEDULE EVERY 1 DAY
DISABLE  -- se deja desactivado por defecto; activar según necesidad
DO
    UPDATE membresia AS mem
    SET mem.estado = 'Suspendida'
    WHERE mem.estado = 'Activa'
      AND EXISTS (SELECT 1
                    FROM detalle_factura AS det
                    INNER JOIN factura AS fac ON fac.id_factura = det.id_factura
                   WHERE det.id_membresia = mem.id_membresia
                     AND fac.estado IN ('Pendiente', 'Parcial', 'Vencida')
                     AND DATEDIFF(CURDATE(), fac.fecha_emision) > 30);
                     
-- =========================================
-- EVENTO 04
-- Generar reporte semanal de nuevas membresías al administrador.
-- =========================================
-- =========================================
-- EVENTO 05
-- Notificar membresías suspendidas cada día a recepción.
-- =========================================
-- Submódulo: Reservas (Eventos 06 a 10)
-- =========================================
-- EVENTO 06
-- Cancelar automáticamente reservas no confirmadas después de 2 horas.
-- =========================================
-- =========================================
-- EVENTO 07
-- Enviar recordatorio 1 hora antes de la reserva a cada usuario.
-- =========================================

DROP EVENT IF EXISTS ev_recordatorio_reserva;

DELIMITER $$

CREATE EVENT ev_recordatorio_reserva
ON SCHEDULE EVERY 5 MINUTE
DISABLE -- se deja desactivado por defecto; activar según necesidad
COMMENT 'Cada 5 min - recordatorio de reservas que empiezan en la proxima hora'
DO
BEGIN
    INSERT INTO NOTIFICACION (id_usuario, destinatario_rol, tipo, asunto, mensaje, fecha_programada)
    SELECT r.id_usuario,
           'Usuario',
           'Recordatorio',
           'Recordatorio de reserva',
           CONCAT('Tu reserva en ', e.nombre, ' empieza a las ',
                  DATE_FORMAT(r.fecha_inicio, '%H:%i'), '.'),
           NOW()
    FROM RESERVA r
    JOIN ESPACIO e ON e.id_espacio = r.id_espacio
    WHERE r.estado = 'Confirmada'
      AND r.recordatorio_enviado = FALSE
      AND r.fecha_inicio BETWEEN NOW() AND NOW() + INTERVAL 1 HOUR;

    UPDATE RESERVA
    SET recordatorio_enviado = TRUE
    WHERE estado = 'Confirmada'
      AND recordatorio_enviado = FALSE
      AND fecha_inicio BETWEEN NOW() AND NOW() + INTERVAL 1 HOUR;
END $$

DELIMITER ;

-- =========================================
-- EVENTO 08
-- Eliminar reservas pasadas no asistidas después de 7 días.
-- =========================================

DROP EVENT IF EXISTS evt_eliminar_reservas_no_show;

CREATE EVENT evt_eliminar_reservas_no_show
ON SCHEDULE EVERY 1 DAY
DISABLE  -- se deja desactivado por defecto; activar según necesidad
DO
    DELETE res
    FROM reserva AS res
    WHERE res.estado = 'No Show'
      AND res.fecha_fin < NOW() - INTERVAL 7 DAY
      AND NOT EXISTS (SELECT 1
                        FROM penalizacion AS pen
                       WHERE pen.id_reserva = res.id_reserva);

-- =========================================
-- EVENTO 09
-- Generar reporte semanal de ocupación de espacios.
-- =========================================
-- =========================================
-- EVENTO 10
-- Liberar reservas bloqueadas si no se inicia en los primeros 15 minutos.
-- =========================================
-- Submódulo: Pagos y Facturación (Eventos 11 a 15)
-- =========================================
-- EVENTO 11
-- Enviar recordatorio de pago pendiente cada 3 días.
-- =========================================
-- =========================================
-- EVENTO 12
-- Bloquear servicios adicionales si existen facturas vencidas mayores a 10 días.
-- =========================================

DROP EVENT IF EXISTS ev_bloquear_servicios_por_deuda;

DELIMITER $$

CREATE EVENT ev_bloquear_servicios_por_deuda
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL '00:10' HOUR_MINUTE
DISABLE -- se deja desactivado por defecto; activar según necesidad
COMMENT 'Diario 00:10 - marca facturas vencidas y bloquea servicios con deuda de mas de 10 dias'
DO
BEGIN
    DECLARE v_total INT;

    UPDATE FACTURA
    SET estado = 'Vencida'
    WHERE estado IN ('Pendiente', 'Parcial')
      AND saldo_pendiente > 0
      AND fecha_vencimiento < CURDATE();

    CALL sp_bloquear_servicios(10, v_total);
END $$

DELIMITER ;

-- =========================================
-- EVENTO 13
-- Generar resumen de facturación mensual automáticamente.
-- =========================================

DROP EVENT IF EXISTS evt_resumen_facturacion_mensual;

DELIMITER $$

CREATE EVENT evt_resumen_facturacion_mensual
ON SCHEDULE EVERY 1 MONTH
STARTS '2026-11-01 00:10:00'
DISABLE  -- se deja desactivado por defecto; activar según necesidad
DO
BEGIN
    DECLARE v_inicio_mes  DATE;
    DECLARE v_fin_mes     DATE;
    DECLARE v_num_facturas INT;
    DECLARE v_facturado   DECIMAL(12,2);
    DECLARE v_pendiente   DECIMAL(12,2);
    DECLARE v_cobrado     DECIMAL(12,2);

    -- Paso 1: definir el mes anterior (del día 1 al último día)
    SET v_fin_mes    = DATE_FORMAT(CURDATE(), '%Y-%m-01');   -- día 1 del mes actual
    SET v_inicio_mes = v_fin_mes - INTERVAL 1 MONTH;         -- día 1 del mes anterior

    -- Paso 2: facturas emitidas ese mes (sin contar las anuladas)
    SELECT
        COUNT(*),
        IFNULL(SUM(fac.total), 0),
        IFNULL(SUM(fac.saldo_pendiente), 0)
    INTO v_num_facturas, v_facturado, v_pendiente
    FROM factura AS fac
    WHERE fac.estado <> 'Anulada'
      AND fac.fecha_emision >= v_inicio_mes
      AND fac.fecha_emision <  v_fin_mes;

    SELECT IFNULL(SUM(pag.monto), 0)
    INTO v_cobrado
    FROM pago AS pag
    WHERE pag.estado = 'Pagado'
      AND pag.fecha_pago >= v_inicio_mes
      AND pag.fecha_pago <  v_fin_mes;

    INSERT INTO notificacion (id_usuario, id_cuenta, destinatario_rol, tipo, asunto, mensaje)
    VALUES (
        NULL,
        4,
        'Contador',
        'Reporte',
        CONCAT('Resumen de facturacion ', DATE_FORMAT(v_inicio_mes, '%Y-%m')),
        CONCAT('Facturas emitidas: ', v_num_facturas,
               '. Total facturado: $', v_facturado,
               '. Saldo pendiente: $', v_pendiente,
               '. Total cobrado en el mes: $', v_cobrado, '.')
    );
END$$

DELIMITER ;

-- =========================================
-- EVENTO 14
-- Aplicar recargos automáticos a facturas vencidas después de 15 días.
-- =========================================
-- =========================================
-- EVENTO 15
-- Enviar al contador un reporte de ingresos acumulados cada fin de mes.
-- =========================================

DROP EVENT IF EXISTS evt_reporte_ingresos_fin_de_mes;

DELIMITER $$

CREATE EVENT evt_reporte_ingresos_fin_de_mes
ON SCHEDULE EVERY 1 DAY
STARTS '2026-10-03 23:30:00'
DISABLE  -- se deja desactivado por defecto; activar según necesidad
DO
BEGIN
    DECLARE v_inicio_mes    DATE;
    DECLARE v_fin_mes       DATE;
    DECLARE v_inicio_anio   DATE;
    DECLARE v_ingresos_mes  DECIMAL(12,2);
    DECLARE v_acumulado     DECIMAL(12,2);

    IF DAY(CURDATE() + INTERVAL 1 DAY) = 1 THEN

        SET v_inicio_mes  = DATE_FORMAT(CURDATE(), '%Y-%m-01');
        SET v_fin_mes     = v_inicio_mes + INTERVAL 1 MONTH;
        SET v_inicio_anio = DATE_FORMAT(CURDATE(), '%Y-01-01'); 

        SELECT IFNULL(SUM(pag.monto), 0)
        INTO v_ingresos_mes
        FROM pago AS pag
        WHERE pag.estado = 'Pagado'
          AND pag.fecha_pago >= v_inicio_mes
          AND pag.fecha_pago <  v_fin_mes;

        SELECT IFNULL(SUM(pag.monto), 0)
        INTO v_acumulado
        FROM pago AS pag
        WHERE pag.estado = 'Pagado'
          AND pag.fecha_pago >= v_inicio_anio
          AND pag.fecha_pago <  v_fin_mes;

        INSERT INTO notificacion (id_usuario, id_cuenta, destinatario_rol, tipo, asunto, mensaje)
        VALUES (
            NULL,
            4,
            'Contador',
            'Reporte',
            'Reporte de ingresos acumulados',
            CONCAT('Ingresos de ', DATE_FORMAT(v_inicio_mes, '%Y-%m'), ': $', v_ingresos_mes,
                   '. Acumulado del anio: $', v_acumulado, '.')
        );

    END IF;
END$$

DELIMITER ;

-- Submódulo: Accesos y Asistencias (Eventos 16 a 20)
-- =========================================
-- EVENTO 16
-- Eliminar accesos antiguos (más de 1 año) automáticamente.
-- =========================================
-- =========================================
-- EVENTO 17
-- Enviar reporte diario de asistencias al administrador.
-- =========================================

DROP EVENT IF EXISTS ev_reporte_diario_asistencias;

DELIMITER $$

CREATE EVENT ev_reporte_diario_asistencias
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL '06:30' HOUR_MINUTE
DISABLE  -- se deja desactivado por defecto; activar según necesidad
COMMENT 'Diario 06:30 - ingresos, usuarios unicos y hora pico del dia anterior'
DO
BEGIN
    -- El procedimiento guarda el resumen en NOTIFICACION para el administrador
    CALL sp_reporte_asistencias_diario(CURDATE() - INTERVAL 1 DAY);
END $$

DELIMITER ;

-- =========================================
-- EVENTO 18
-- Generar reporte semanal de usuarios inactivos (sin accesos).
-- =========================================

DROP EVENT IF EXISTS evt_reporte_usuarios_inactivos;

CREATE EVENT evt_reporte_usuarios_inactivos
ON SCHEDULE EVERY 1 WEEK
STARTS '2026-10-01 06:10:00'
DISABLE  -- se deja desactivado por defecto; activar según necesidad
DO
    INSERT INTO notificacion (id_usuario, id_cuenta, destinatario_rol, tipo, asunto, mensaje)
    SELECT
        NULL,
        1,
        'Administrador',
        'Reporte',
        'Reporte semanal de usuarios inactivos',
        CONCAT('Usuarios sin accesos en los ultimos 7 dias: ', COUNT(*), '.')
    FROM usuario AS usu
    WHERE usu.id_usuario NOT IN (SELECT acc.id_usuario
                                   FROM acceso AS acc
                                  WHERE acc.resultado = 'Permitido'
                                    AND acc.id_usuario IS NOT NULL
                                    AND acc.fecha_hora_entrada >= NOW() - INTERVAL 7 DAY);

-- =========================================
-- EVENTO 19
-- Alertar accesos fuera de horario laboral cada día.
-- =========================================
-- =========================================
-- EVENTO 20
-- Enviar reporte de top 10 usuarios más frecuentes cada mes.
-- =========================================

DROP EVENT IF EXISTS ev_reporte_top_usuarios;

DELIMITER $$

CREATE EVENT ev_reporte_top_usuarios
ON SCHEDULE EVERY 1 MONTH
STARTS LAST_DAY(CURRENT_DATE) + INTERVAL 1 DAY + INTERVAL '06:45' HOUR_MINUTE
DISABLE  -- se deja desactivado por defecto; activar según necesidad
COMMENT 'Dia 1 de cada mes 06:45 - top 10 de clientes con mas asistencias del mes anterior'
DO
BEGIN
    DECLARE v_ini     DATE;
    DECLARE v_fin     DATE;
    DECLARE v_detalle TEXT;

    SET SESSION group_concat_max_len = 10000;
    SET v_ini = DATE_FORMAT(CURDATE() - INTERVAL 1 MONTH, '%Y-%m-01');
    SET v_fin = LAST_DAY(v_ini);

    SET v_detalle = (SELECT GROUP_CONCAT(CONCAT(t.posicion, '. ', t.nombre, ' (', t.asistencias, ')')
                                         ORDER BY t.posicion SEPARATOR '; ')
                     FROM (SELECT ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, a.id_usuario) AS posicion,
                                  CONCAT(u.nombre, ' ', u.apellidos)                      AS nombre,
                                  COUNT(*)                                                AS asistencias
                           FROM ACCESO a
                           JOIN USUARIO u ON u.id_usuario = a.id_usuario
                           WHERE a.resultado = 'Permitido'
                             AND DATE(a.fecha_hora_entrada) BETWEEN v_ini AND v_fin
                           GROUP BY a.id_usuario, u.nombre, u.apellidos
                           ORDER BY asistencias DESC, a.id_usuario
                           LIMIT 10) t);

    INSERT INTO NOTIFICACION (id_cuenta, destinatario_rol, tipo, asunto, mensaje, fecha_programada)
    VALUES ((SELECT id_cuenta FROM CUENTA WHERE rol = 'Administrador' ORDER BY id_cuenta LIMIT 1),
            'Administrador', 'Reporte', 'Top 10 usuarios mas frecuentes',
            CONCAT('Asistencias de ', DATE_FORMAT(v_ini, '%m/%Y'), ': ',
                   COALESCE(v_detalle, 'sin asistencias registradas'), '.'),
            NOW());
END $$

DELIMITER ;