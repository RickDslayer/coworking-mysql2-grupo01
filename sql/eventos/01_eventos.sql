/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Eventos SQL
Archivo: 04_eventos_sql.sql
Descripción:
Estructura y comentarios organizativos para los 20 Eventos SQL del proyecto.
Requisitos:
Ejecutar previamente DDL y DML.
*/

USE coworking_db;

--============================================================================
-- SECCIÓN: EVENTOS SQL (Eventos 01 a 20)
--============================================================================
-- Submódulo: Membresías (Eventos 01 a 05)
-- =========================================
-- CONSULTA 01
-- Revisar diariamente membresías vencidas y actualizarlas a estado "Vencida".
-- =========================================
-- =========================================
-- CONSULTA 02
-- Enviar recordatorio de renovación 5 días antes de vencer la membresía.
-- =========================================
-- =========================================
-- CONSULTA 03
-- Suspender membresías inactivas después de 30 días sin pago.
-- =========================================

DROP EVENT IF EXISTS evt_suspender_membresias_sin_pago;

CREATE EVENT evt_suspender_membresias_sin_pago
ON SCHEDULE EVERY 1 DAY
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
-- CONSULTA 04
-- Generar reporte semanal de nuevas membresías al administrador.
-- =========================================
-- =========================================
-- CONSULTA 05
-- Notificar membresías suspendidas cada día a recepción.
-- =========================================
-- Submódulo: Reservas (Eventos 06 a 10)
-- =========================================
-- CONSULTA 06
-- Cancelar automáticamente reservas no confirmadas después de 2 horas.
-- =========================================
-- =========================================
-- CONSULTA 07
-- Enviar recordatorio 1 hora antes de la reserva a cada usuario.
-- =========================================
-- =========================================
-- CONSULTA 08
-- Eliminar reservas pasadas no asistidas después de 7 días.
-- =========================================

DROP EVENT IF EXISTS evt_eliminar_reservas_no_show;

CREATE EVENT evt_eliminar_reservas_no_show
ON SCHEDULE EVERY 1 DAY
DO
    DELETE res
    FROM reserva AS res
    WHERE res.estado = 'No Show'
      AND res.fecha_fin < NOW() - INTERVAL 7 DAY
      AND NOT EXISTS (SELECT 1
                        FROM penalizacion AS pen
                       WHERE pen.id_reserva = res.id_reserva);

-- =========================================
-- CONSULTA 09
-- Generar reporte semanal de ocupación de espacios.
-- =========================================
-- =========================================
-- CONSULTA 10
-- Liberar reservas bloqueadas si no se inicia en los primeros 15 minutos.
-- =========================================
-- Submódulo: Pagos y Facturación (Eventos 11 a 15)
-- =========================================
-- CONSULTA 11
-- Enviar recordatorio de pago pendiente cada 3 días.
-- =========================================
-- =========================================
-- CONSULTA 12
-- Bloquear servicios adicionales si existen facturas vencidas mayores a 10 días.
-- =========================================
-- =========================================
-- CONSULTA 13
-- Generar resumen de facturación mensual automáticamente.
-- =========================================

DROP EVENT IF EXISTS evt_resumen_facturacion_mensual;

DELIMITER $$

CREATE EVENT evt_resumen_facturacion_mensual
ON SCHEDULE EVERY 1 MONTH
STARTS '2026-11-01 00:10:00'
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
-- CONSULTA 14
-- Aplicar recargos automáticos a facturas vencidas después de 15 días.
-- =========================================
-- =========================================
-- CONSULTA 15
-- Enviar al contador un reporte de ingresos acumulados cada fin de mes.
-- =========================================

DROP EVENT IF EXISTS evt_reporte_ingresos_fin_de_mes;

DELIMITER $$

CREATE EVENT evt_reporte_ingresos_fin_de_mes
ON SCHEDULE EVERY 1 DAY
STARTS '2026-10-03 23:30:00'
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
-- CONSULTA 16
-- Eliminar accesos antiguos (más de 1 año) automáticamente.
-- =========================================
-- =========================================
-- CONSULTA 17
-- Enviar reporte diario de asistencias al administrador.
-- =========================================
-- =========================================
-- CONSULTA 18
-- Generar reporte semanal de usuarios inactivos (sin accesos).
-- =========================================

DROP EVENT IF EXISTS evt_reporte_usuarios_inactivos;

CREATE EVENT evt_reporte_usuarios_inactivos
ON SCHEDULE EVERY 1 WEEK
STARTS '2026-10-01 06:10:00'
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
-- CONSULTA 19
-- Alertar accesos fuera de horario laboral cada día.
-- =========================================
-- =========================================
-- CONSULTA 20
-- Enviar reporte de top 10 usuarios más frecuentes cada mes.
-- =========================================