/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Procedimientos Almacenados y Control de Acceso / Roles
Archivo: 06_procedimientos_
Descripción:
Estructura y comentarios organizativos para los 20 Procedimientos Almacenados 
Requisitos:
Ejecutar previamente DDL y DML.
*/
USE coworking_db;
--============================================================================
-- SECCIÓN: PROCEDIMIENTOS ALMACENADOS (Procedimientos 01 a 20)
--============================================================================
-- Submódulo: Membresías (Procedimientos 01 a 04)
-- =========================================
-- CONSULTA 01
-- Registrar nueva membresía y asignarla a un usuario -> Inserta una nueva membresía con 
-- fecha de inicio, fecha de vencimiento y estado inicial.
-- =========================================
-- =========================================
-- CONSULTA 02
-- Renovar una membresía existente -> Extiende la vigencia de una membresía según el tipo
-- contratado.
-- =========================================
-- =========================================
-- CONSULTA 03
-- Actualizar estado de membresías vencidas -> Recorre las membresías y marca como
-- "Vencida" las que superan la fecha de fin.
-- =========================================

DROP PROCEDURE IF EXISTS sp_actualizar_membresias_vencidas;

DELIMITER $$

CREATE PROCEDURE sp_actualizar_membresias_vencidas(OUT p_actualizadas INT)
BEGIN
    UPDATE membresia
       SET estado = 'Vencida'
     WHERE fecha_fin < CURDATE()                    -- superan la fecha de fin
       AND estado IN ('Activa', 'Suspendida');      -- las ya vencidas no se tocan

    SET p_actualizadas = ROW_COUNT();               -- cuántas se actualizaron
END$$

DELIMITER ;


-- =========================================
-- CONSULTA 04
-- Suspender membresías con facturas impagas por más de X días -> Cambia el estado a
-- "Suspendida" para usuarios con deudas.
-- =========================================
-- Submódulo: Reservas y Espacios (Procedimientos 05 a 09)
-- =========================================
-- CONSULTA 05
-- Verificar disponibilidad de un espacio antes de crear reserva -> Comprueba que no haya
-- solapamiento de horarios en el mismo espacio.
-- =========================================
-- =========================================
-- CONSULTA 06
-- Crear una nueva reserva de espacio -> Inserta una reserva en estado "Pendiente" y la vincula
-- a un usuario y espacio.
-- =========================================
-- =========================================
-- CONSULTA 07
-- Confirmar reserva con pago -> Cambia estado de reserva a "Confirmada" al registrar el
-- pago.
-- =========================================

DROP PROCEDURE IF EXISTS sp_confirmar_reserva_con_pago;

DELIMITER $$

CREATE PROCEDURE sp_confirmar_reserva_con_pago(
    IN  p_id_reserva INT,
    IN  p_id_metodo  INT,
    IN  p_monto      DECIMAL(12,2),
    OUT p_id_pago    INT
)
BEGIN
    DECLARE v_estado     VARCHAR(30);
    DECLARE v_id_usuario INT;
    DECLARE v_id_factura INT;
    DECLARE v_total      DECIMAL(12,2);

    -- Si algo falla, se deshace todo
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- 1. Validar la reserva (se bloquea la fila mientras dura la transacción)
    SELECT estado, id_usuario
      INTO v_estado, v_id_usuario
      FROM reserva
     WHERE id_reserva = p_id_reserva
       FOR UPDATE;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La reserva no existe';
    END IF;

    IF v_estado <> 'Pendiente de Confirmacion' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Solo se pueden confirmar reservas pendientes de confirmacion';
    END IF;

    -- 2. Buscar la factura de la reserva (si ya existe y no está anulada)
    SELECT f.id_factura
      INTO v_id_factura
      FROM detalle_factura AS d
      JOIN factura AS f ON f.id_factura = d.id_factura
     WHERE d.id_reserva = p_id_reserva
       AND f.estado <> 'Anulada'
     LIMIT 1;

    -- 3. Si no existe, se genera: línea de la reserva + servicios activos de la reserva
    IF v_id_factura IS NULL THEN
        INSERT INTO factura (id_usuario, fecha_emision, fecha_vencimiento, total, saldo_pendiente, estado)
        VALUES (v_id_usuario, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 3 DAY), 0, 0, 'Pendiente');

        SET v_id_factura = LAST_INSERT_ID();

        INSERT INTO detalle_factura (id_factura, id_reserva, descripcion, monto)
        SELECT v_id_factura,
               r.id_reserva,
               CONCAT('Reserva ', e.nombre, ' (',
                      ROUND(TIMESTAMPDIFF(MINUTE, r.fecha_inicio, r.fecha_fin) / 60, 0), ' h)'),
               ROUND(TIMESTAMPDIFF(MINUTE, r.fecha_inicio, r.fecha_fin) / 60 * e.precio_hora, 2)
          FROM reserva AS r
          JOIN espacio AS e ON e.id_espacio = r.id_espacio
         WHERE r.id_reserva = p_id_reserva;

        INSERT INTO detalle_factura (id_factura, id_contratado, descripcion, monto)
        SELECT v_id_factura,
               sc.id_contratado,
               CONCAT(s.nombre, ' x', sc.cantidad),
               sc.cantidad * s.precio
          FROM servicio_contratado AS sc
          JOIN servicio AS s ON s.id_servicio = sc.id_servicio
         WHERE sc.id_reserva = p_id_reserva
           AND sc.estado = 'Activo';

        SELECT SUM(monto) INTO v_total
          FROM detalle_factura
         WHERE id_factura = v_id_factura;

        UPDATE factura
           SET total = v_total,
               saldo_pendiente = v_total
         WHERE id_factura = v_id_factura;
    END IF;

    -- 4. Registrar el pago
    INSERT INTO pago (id_factura, id_metodo, monto, fecha_pago, estado)
    VALUES (v_id_factura, p_id_metodo, p_monto, NOW(), 'Pagado');

    SET p_id_pago = LAST_INSERT_ID();

    UPDATE factura
       SET estado = IF(saldo_pendiente - p_monto <= 0, 'Pagada', 'Parcial'),
           saldo_pendiente = GREATEST(saldo_pendiente - p_monto, 0)
     WHERE id_factura = v_id_factura;


    UPDATE reserva
       SET estado = 'Confirmada'
     WHERE id_reserva = p_id_reserva;

    COMMIT;
END$$

DELIMITER ;


-- =========================================
-- CONSULTA 08
-- Cancelar reserva con opción de reembolso parcial -> Marca reserva como "Cancelada" y
-- genera un registro de reembolso si aplica.
-- =========================================
-- =========================================
-- CONSULTA 09
-- Liberar reservas no confirmadas después de X horas -> Automatiza la cancelación de
-- reservas en estado "Pendiente".
-- =========================================
-- Submódulo: Pagos y Facturación (Procedimientos 10 a 13)
-- =========================================
-- CONSULTA 10
-- Generar factura por membresía -> Crea factura al activar o renovar una membresía.
-- =========================================
-- =========================================
-- CONSULTA 11
-- Generar factura consolidada para empresa -> Agrupa cargos de empleados corporativos en
-- una sola factura.
-- =========================================
-- =========================================
-- CONSULTA 12
-- Aplicar recargos a facturas vencidas -> Incrementa el monto de facturas con más de X días
-- de atraso.
-- =========================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_aplicar_recargos_vencidas$$

CREATE PROCEDURE sp_aplicar_recargos_vencidas(
    IN p_dias_atraso INT,            -- X: días de atraso a partir de los cuales se recarga
    IN p_porcentaje  DECIMAL(5,2)    -- % de recargo sobre el total de la factura
)
BEGIN
    IF p_dias_atraso IS NULL OR p_dias_atraso < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'p_dias_atraso debe ser un entero mayor o igual a 0';
    END IF;

    IF p_porcentaje IS NULL OR p_porcentaje <= 0 OR p_porcentaje > 100 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'p_porcentaje debe estar entre 0 (excluido) y 100';
    END IF;

    START TRANSACTION;

    UPDATE factura
    SET recargo_aplicado = ROUND(total * p_porcentaje / 100, 2),
        saldo_pendiente  = saldo_pendiente + ROUND(total * p_porcentaje / 100, 2),
        estado           = 'Vencida'
    WHERE estado IN ('Pendiente', 'Parcial', 'Vencida')
      AND saldo_pendiente > 0
      AND recargo_aplicado = 0
      AND DATEDIFF(CURDATE(), fecha_vencimiento) > p_dias_atraso;

    SELECT ROW_COUNT() AS facturas_con_recargo;

    COMMIT;
END$$

DELIMITER ;

-- =========================================
-- CONSULTA 13
-- Bloquear servicios adicionales por falta de pago -> Restringe acceso a servicios premium si
-- existen facturas pendientes.
-- =========================================
-- Submódulo: Accesos y Asistencias (Procedimientos 14 a 17)
-- =========================================
-- CONSULTA 14
-- Registrar acceso de usuario (entrada) -> Valida membresía o reserva activa y registra
-- entrada en logs.
-- =========================================
-- =========================================
-- CONSULTA 15
-- Registrar salida de usuario -> Completa la asistencia del usuario y marca hora de salida.
-- =========================================
-- =========================================
-- CONSULTA 16
-- Generar reporte diario de asistencias -> Resume cantidad de ingresos, usuarios únicos y
-- horarios pico.
-- =========================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_reporte_asistencias_diario$$

CREATE PROCEDURE sp_reporte_asistencias_diario(IN p_fecha DATE)
BEGIN
    DECLARE v_ini         DATETIME;
    DECLARE v_fin         DATETIME;
    DECLARE v_ingresos    INT DEFAULT 0;
    DECLARE v_unicos      INT DEFAULT 0;
    DECLARE v_rechazados  INT DEFAULT 0;
    DECLARE v_max_hora    INT;
    DECLARE v_horas_pico  VARCHAR(255);

    IF p_fecha IS NULL THEN
        SET p_fecha = CURDATE();
    END IF;

    SET v_ini = p_fecha;
    SET v_fin = DATE_ADD(p_fecha, INTERVAL 1 DAY);

    SELECT COUNT(*), COUNT(DISTINCT id_usuario)
      INTO v_ingresos, v_unicos
      FROM acceso
     WHERE resultado = 'Permitido'
       AND fecha_hora_entrada >= v_ini
       AND fecha_hora_entrada <  v_fin;

    SELECT COUNT(*)
      INTO v_rechazados
      FROM acceso
     WHERE resultado = 'Rechazado'
       AND fecha_hora_entrada >= v_ini
       AND fecha_hora_entrada <  v_fin;

    SELECT MAX(t.ingresos)
      INTO v_max_hora
      FROM (SELECT COUNT(*) AS ingresos
              FROM acceso
             WHERE resultado = 'Permitido'
               AND fecha_hora_entrada >= v_ini
               AND fecha_hora_entrada <  v_fin
             GROUP BY HOUR(fecha_hora_entrada)) AS t;

    SELECT GROUP_CONCAT(
               CONCAT(LPAD(t.hora, 2, '0'), ':00 - ', LPAD(MOD(t.hora + 1, 24), 2, '0'), ':00')
               ORDER BY t.hora SEPARATOR ', ')
      INTO v_horas_pico
      FROM (SELECT HOUR(fecha_hora_entrada) AS hora, COUNT(*) AS ingresos
              FROM acceso
             WHERE resultado = 'Permitido'
               AND fecha_hora_entrada >= v_ini
               AND fecha_hora_entrada <  v_fin
             GROUP BY HOUR(fecha_hora_entrada)) AS t
     WHERE t.ingresos = v_max_hora;

    SELECT p_fecha                                   AS fecha,
           v_ingresos                                AS total_ingresos,
           v_unicos                                  AS usuarios_unicos,
           COALESCE(v_horas_pico, 'Sin ingresos')    AS horario_pico,
           COALESCE(v_max_hora, 0)                   AS ingresos_en_hora_pico,
           v_rechazados                              AS intentos_rechazados;

    SELECT CONCAT(LPAD(HOUR(fecha_hora_entrada), 2, '0'), ':00') AS hora,
           COUNT(*)                                              AS ingresos,
           COUNT(DISTINCT id_usuario)                            AS usuarios_unicos,
           IF(COUNT(*) = v_max_hora, 'PICO', '')                 AS pico
      FROM acceso
     WHERE resultado = 'Permitido'
       AND fecha_hora_entrada >= v_ini
       AND fecha_hora_entrada <  v_fin
     GROUP BY HOUR(fecha_hora_entrada)
     ORDER BY HOUR(fecha_hora_entrada);
END$$

DELIMITER ;


-- =========================================
-- CONSULTA 17
-- Marcar reservas como "No Show" y generar penalización -> Detecta reservas confirmadas
-- sin asistencia y aplica cargo automático.
-- =========================================
-- Submódulo: Corporativos y Administración (Procedimientos 18 a 20)
-- =========================================
-- CONSULTA 18
-- Registrar lote de empleados de una empresa con membresía corporativa -> Inserta varios
-- usuarios vinculados a una empresa y les asigna membresía.
-- =========================================
-- =========================================
-- CONSULTA 19
-- Cancelar reservas futuras al eliminar membresía de usuario -> Recorre reservas
-- pendientes/confirmadas y las cancela automáticamente.
-- =========================================
-- =========================================
-- CONSULTA 20
-- Generar reporte de ingresos mensuales acumulados -> Calcula ingresos por mes e ingresos
-- acumulados en el año.
-- =========================================