/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Procedimientos Almacenados
Archivo: 01_procedimientos.sql
Descripción:
Implementación de los 20 Procedimientos Almacenados del proyecto,
organizados por submódulo.
Requisitos:
Ejecutar previamente DDL, DML, funciones y triggers.
*/
USE coworking_db;
-- ============================================================================
-- SECCIÓN: PROCEDIMIENTOS ALMACENADOS (Procedimientos 01 a 20)
-- ============================================================================
-- Submódulo: Membresías (Procedimientos 01 a 04)
-- =========================================
-- PROCEDIMIENTO 01
-- Registrar nueva membresía y asignarla a un usuario -> Inserta una nueva membresía con 
-- fecha de inicio, fecha de vencimiento y estado inicial.
-- =========================================
DROP PROCEDURE IF EXISTS sp_registrar_membresia;
 
DELIMITER $$
 
CREATE PROCEDURE sp_registrar_membresia(
    IN  p_id_usuario   INT,
    IN  p_id_tipo      INT,
    OUT p_id_membresia INT)
BEGIN
    DECLARE v_duracion   INT;
    DECLARE v_nombre     VARCHAR(20);
    DECLARE v_empresa    INT;
    DECLARE v_id_factura INT;
 

    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario = p_id_usuario) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario no existe';
    END IF;
 
   
    SELECT duracion_dias, nombre
      INTO v_duracion, v_nombre
      FROM tipo_membresia
     WHERE id_tipo = p_id_tipo;
 
    IF v_duracion IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El tipo de membresia no existe';
    END IF;
 
    
    IF EXISTS (SELECT 1 FROM membresia
               WHERE id_usuario = p_id_usuario
                 AND estado IN ('Activa', 'Pendiente')
                 AND fecha_fin >= CURDATE()) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El usuario ya tiene una membresia vigente. Use sp_renovar_membresia.';
    END IF;
 
    
    INSERT INTO membresia (id_usuario, id_tipo, estado, fecha_inicio, fecha_fin)
    VALUES (p_id_usuario, p_id_tipo, 'Pendiente', CURDATE(),
            DATE_ADD(CURDATE(), INTERVAL v_duracion DAY));
    SET p_id_membresia = LAST_INSERT_ID();
 
   
    SET v_empresa = (SELECT id_empresa FROM usuario WHERE id_usuario = p_id_usuario);
    IF NOT (v_empresa IS NOT NULL AND v_nombre = 'Corporativa') THEN
        CALL sp_factura_membresia(p_id_membresia, v_id_factura);
    END IF;
END
END$$
 
DELIMITER ;
-- =========================================
-- PROCEDIMIENTO 02
-- Renovar una membresía existente -> Extiende la vigencia de una membresía según el tipo
-- contratado.
-- =========================================

DROP PROCEDURE IF EXISTS sp_renovar_membresia;

DELIMITER $$

CREATE PROCEDURE sp_renovar_membresia(
    IN  p_id_usuario        INT,
    OUT p_id_membresia_nueva INT)
BEGIN
    DECLARE v_id_actual  INT;
    DECLARE v_tipo       INT;
    DECLARE v_fin        DATE;
    DECLARE v_inicio     DATE;
    DECLARE v_empresa    INT;
    DECLARE v_nombre     VARCHAR(20);
    DECLARE v_id_factura INT;

    SET v_id_actual = (SELECT id_membresia FROM membresia
                       WHERE id_usuario = p_id_usuario
                       ORDER BY fecha_inicio DESC, id_membresia DESC
                       LIMIT 1);
    IF v_id_actual IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El usuario no tiene membresias para renovar. Use sp_registrar_membresia.';
    END IF;

    SET v_tipo   = (SELECT id_tipo   FROM membresia WHERE id_membresia = v_id_actual);
    SET v_fin    = (SELECT fecha_fin FROM membresia WHERE id_membresia = v_id_actual);
    SET v_inicio = GREATEST(v_fin, CURDATE());

    INSERT INTO membresia (id_usuario, id_tipo, estado, fecha_inicio)
    VALUES (p_id_usuario, v_tipo, 'Pendiente', v_inicio);
    SET p_id_membresia_nueva = LAST_INSERT_ID();

    SET v_empresa = (SELECT id_empresa FROM usuario WHERE id_usuario = p_id_usuario);
    SET v_nombre  = (SELECT nombre FROM tipo_membresia WHERE id_tipo = v_tipo);
    IF NOT (v_empresa IS NOT NULL AND v_nombre = 'Corporativa') THEN
        CALL sp_factura_membresia(p_id_membresia_nueva, v_id_factura);
    END IF;
END $$

DELIMITER ;

-- =========================================
-- PROCEDIMIENTO 03
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
-- PROCEDIMIENTO 04
-- Suspender membresías con facturas impagas por más de X días -> Cambia el estado a
-- "Suspendida" para usuarios con deudas.
-- =========================================
DELIMITER $$

CREATE PROCEDURE sp_suspender_membresias_impagas(IN p_dias INT)
BEGIN
    UPDATE membresia AS m
    SET m.estado = 'Suspendida'
    WHERE m.estado = 'Activa'
      AND EXISTS (
            SELECT 1
            FROM factura AS f
            WHERE f.id_usuario = m.id_usuario
              AND f.estado IN ('Pendiente', 'Parcial', 'Vencida')
              AND f.saldo_pendiente > 0
              AND f.fecha_vencimiento < CURDATE() - INTERVAL p_dias DAY
      );

    SELECT ROW_COUNT() AS membresias_suspendidas;
END$$
-- Submódulo: Reservas y Espacios (Procedimientos 05 a 09)
-- =========================================
-- PROCEDIMIENTO 05
-- Verificar disponibilidad de un espacio antes de crear reserva -> Comprueba que no haya
-- solapamiento de horarios en el mismo espacio.
-- =========================================

DROP PROCEDURE IF EXISTS sp_verificar_disponibilidad;
 
DELIMITER $$
 
CREATE PROCEDURE sp_verificar_disponibilidad(
    IN  p_id_espacio INT,
    IN  p_inicio     DATETIME,
    IN  p_fin        DATETIME,
    OUT p_disponible BOOLEAN,
    OUT p_motivo     VARCHAR(100))
BEGIN
    DECLARE v_estado   VARCHAR(20) DEFAULT NULL;
    DECLARE v_apertura TIME        DEFAULT NULL;
    DECLARE v_cierre   TIME        DEFAULT NULL;
    DECLARE v_choques  INT         DEFAULT 0;
 
    
    SELECT estado INTO v_estado
      FROM espacio
     WHERE id_espacio = p_id_espacio;
 
    
    SELECT hora_apertura, hora_cierre
      INTO v_apertura, v_cierre
      FROM horario_espacio
     WHERE id_espacio = p_id_espacio
       AND dia_semana = WEEKDAY(p_inicio) + 1;
 
    
    SELECT COUNT(*) INTO v_choques
      FROM reserva
     WHERE id_espacio = p_id_espacio
       AND estado NOT IN ('Cancelada', 'Liberada')
       AND p_inicio < fecha_fin
       AND p_fin    > fecha_inicio;
 
   
    SET p_disponible = FALSE;
 
    IF v_estado IS NULL THEN
        SET p_motivo = 'El espacio no existe';
    ELSEIF v_estado <> 'Disponible' THEN
        SET p_motivo = CONCAT('El espacio no esta disponible (', v_estado, ')');
    ELSEIF p_inicio >= p_fin THEN
        SET p_motivo = 'La hora de inicio debe ser anterior a la hora de fin';
    ELSEIF DATE(p_inicio) <> DATE(p_fin) THEN
        SET p_motivo = 'La reserva debe empezar y terminar el mismo dia';
    ELSEIF v_apertura IS NULL THEN
        SET p_motivo = 'El espacio no abre ese dia';
    ELSEIF TIME(p_inicio) < v_apertura OR TIME(p_fin) > v_cierre THEN
        SET p_motivo = CONCAT('Fuera del horario del espacio (', v_apertura, ' a ', v_cierre, ')');
    ELSEIF v_choques > 0 THEN
        SET p_motivo = 'El espacio ya esta reservado en ese horario';
    ELSE
        SET p_disponible = TRUE;
        SET p_motivo     = 'Disponible';
    END IF;
END
END$$
 
DELIMITER ;
-- =========================================
-- PROCEDIMIENTO 06
-- Crear una nueva reserva de espacio -> Inserta una reserva en estado "Pendiente" y la vincula
-- a un usuario y espacio.
-- =========================================

DROP PROCEDURE IF EXISTS sp_crear_reserva;

DELIMITER $$

CREATE PROCEDURE sp_crear_reserva(
    IN  p_id_usuario     INT,
    IN  p_id_espacio     INT,
    IN  p_inicio         DATETIME,
    IN  p_fin            DATETIME,
    IN  p_num_asistentes INT,
    OUT p_id_reserva     INT)
BEGIN
    DECLARE v_disponible BOOLEAN;
    DECLARE v_motivo     VARCHAR(100);
    DECLARE v_capacidad  INT;
    DECLARE v_rol        VARCHAR(20);
    DECLARE v_mi_usuario INT;

    -- Un cliente solo puede reservar a su nombre
    SET v_rol        = (SELECT rol        FROM cuenta WHERE username = SUBSTRING_INDEX(USER(), '@', 1));
    SET v_mi_usuario = (SELECT id_usuario FROM cuenta WHERE username = SUBSTRING_INDEX(USER(), '@', 1));
    IF v_rol = 'Usuario' AND NOT (v_mi_usuario <=> p_id_usuario) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo puede crear reservas a su nombre';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM membresia
                   WHERE id_usuario = p_id_usuario
                     AND estado = 'Activa'
                     AND CURDATE() BETWEEN fecha_inicio AND fecha_fin) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario no tiene una membresia activa';
    END IF;

    SET v_capacidad = (SELECT capacidad_maxima FROM espacio WHERE id_espacio = p_id_espacio);
    IF COALESCE(p_num_asistentes, 1) > v_capacidad THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El numero de asistentes supera la capacidad del espacio';
    END IF;

    CALL sp_verificar_disponibilidad(p_id_espacio, p_inicio, p_fin, v_disponible, v_motivo);
    IF NOT v_disponible THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_motivo;
    END IF;

    INSERT INTO reserva (id_usuario, id_espacio, fecha_inicio, fecha_fin, num_asistentes)
    VALUES (p_id_usuario, p_id_espacio, p_inicio, p_fin, COALESCE(p_num_asistentes, 1));
    SET p_id_reserva = LAST_INSERT_ID();
END $$

DELIMITER ;

-- =========================================
-- PROCEDIMIENTO 07
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
-- PROCEDIMIENTO 08
-- Cancelar reserva con opción de reembolso parcial -> Marca reserva como "Cancelada" y
-- genera un registro de reembolso si aplica.
-- =========================================
DELIMITER $$
CREATE PROCEDURE sp_cancelar_reserva(IN p_id_reserva INT, IN p_con_reembolso TINYINT)
BEGIN
    DECLARE v_estado VARCHAR(30) DEFAULT NULL;
    DECLARE v_inicio DATETIME;
    DECLARE v_id_pago INT DEFAULT NULL;
    DECLARE v_monto_linea DECIMAL(10,2) DEFAULT NULL;

    SELECT estado, fecha_inicio INTO v_estado, v_inicio
    FROM reserva
    WHERE id_reserva = p_id_reserva;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La reserva no existe.';
    END IF;

    IF v_estado NOT IN ('Pendiente de Confirmacion', 'Confirmada') OR v_inicio <= NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Solo se pueden cancelar reservas pendientes o confirmadas que aun no han iniciado.';
    END IF;

    UPDATE reserva
    SET estado = 'Cancelada'
    WHERE id_reserva = p_id_reserva;

    IF p_con_reembolso = 1 THEN
        SELECT p.id_pago, df.monto INTO v_id_pago, v_monto_linea
        FROM detalle_factura AS df
        INNER JOIN pago AS p ON p.id_factura = df.id_factura
                            AND p.estado = 'Pagado'
        WHERE df.id_reserva = p_id_reserva
        ORDER BY p.fecha_pago DESC
        LIMIT 1;

        IF v_id_pago IS NOT NULL THEN
            INSERT INTO reembolso (id_reserva, id_pago, monto, motivo, fecha)
            VALUES (p_id_reserva, v_id_pago, ROUND(v_monto_linea * 0.5, 2),
                    'Cancelacion con reembolso parcial (50%)', NOW());
        END IF;
    END IF;
END$$
DELIMITER ;
-- =========================================
-- PROCEDIMIENTO 09
-- Liberar reservas no confirmadas después de X horas -> Automatiza la cancelación de
-- reservas en estado "Pendiente".
-- =========================================
CREATE PROCEDURE sp_liberar_reservas_pendientes(IN p_horas INT)
BEGIN
    UPDATE reserva
    SET estado = 'Cancelada'
    WHERE estado = 'Pendiente de Confirmacion'
      AND fecha_creacion < NOW() - INTERVAL p_horas HOUR;

    SELECT ROW_COUNT() AS reservas_liberadas;
END$$

-- Submódulo: Pagos y Facturación (Procedimientos 10 a 13)
-- =========================================
-- PROCEDIMIENTO 10
-- Generar factura por membresía -> Crea factura al activar o renovar una membresía.
-- =========================================

DROP PROCEDURE IF EXISTS sp_factura_membresia;
 
DELIMITER $$
 
CREATE PROCEDURE sp_factura_membresia(
    IN  p_id_membresia INT,
    OUT p_id_factura   INT)
BEGIN
    DECLARE v_usuario INT           DEFAULT NULL;
    DECLARE v_precio  DECIMAL(10,2);
    DECLARE v_nombre  VARCHAR(20);
    DECLARE v_inicio  DATE;
    DECLARE v_fin     DATE;
 
    
    SELECT m.id_usuario, t.precio, t.nombre, m.fecha_inicio, m.fecha_fin
      INTO v_usuario, v_precio, v_nombre, v_inicio, v_fin
      FROM membresia AS m
      JOIN tipo_membresia AS t ON t.id_tipo = m.id_tipo
     WHERE m.id_membresia = p_id_membresia;
 
    IF v_usuario IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La membresia no existe';
    END IF;
 
    
    IF EXISTS (SELECT 1
                 FROM detalle_factura AS d
                 JOIN factura AS f ON f.id_factura = d.id_factura
                WHERE d.id_membresia = p_id_membresia
                  AND f.estado <> 'Anulada') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La membresia ya tiene una factura';
    END IF;
 
    
    INSERT INTO factura (id_usuario, fecha_emision, fecha_vencimiento, total, saldo_pendiente, estado)
    VALUES (v_usuario, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 5 DAY), v_precio, v_precio, 'Pendiente');
    SET p_id_factura = LAST_INSERT_ID();
 
    
    INSERT INTO detalle_factura (id_factura, id_membresia, descripcion, monto)
    VALUES (p_id_factura, p_id_membresia,
            CONCAT('Membresia ', v_nombre, ' del ', v_inicio, ' al ', v_fin),
            v_precio);
END
END$$
 
DELIMITER ;
-- =========================================
-- PROCEDIMIENTO 11
-- Generar factura consolidada para empresa -> Agrupa cargos de empleados corporativos en
-- una sola factura.
-- =========================================

DROP PROCEDURE IF EXISTS sp_factura_consolidada;

DELIMITER $$

CREATE PROCEDURE sp_factura_consolidada(
    IN  p_id_empresa INT,
    IN  p_mes        INT,
    IN  p_anio       INT,
    OUT p_id_factura INT)
BEGIN
    DECLARE v_total DECIMAL(12,2);

    IF NOT EXISTS (SELECT 1 FROM empresa WHERE id_empresa = p_id_empresa) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La empresa no existe';
    END IF;

    DROP TEMPORARY TABLE IF EXISTS tmp_cargos;
    CREATE TEMPORARY TABLE tmp_cargos (
        id_membresia  INT NULL,
        id_contratado INT NULL,
        descripcion   VARCHAR(255),
        monto         DECIMAL(12,2)
    );

    -- Membresías del mes sin facturar
    INSERT INTO tmp_cargos (id_membresia, descripcion, monto)
    SELECT m.id_membresia,
           CONCAT('Membresia ', t.nombre, ' - ', u.nombre, ' ', SUBSTRING_INDEX(u.apellidos, ' ', 1)),
           t.precio
    FROM membresia m
    JOIN usuario u        ON u.id_usuario = m.id_usuario
    JOIN tipo_membresia t ON t.id_tipo    = m.id_tipo
    WHERE u.id_empresa = p_id_empresa
      AND MONTH(m.fecha_inicio) = p_mes
      AND YEAR(m.fecha_inicio)  = p_anio
      AND NOT EXISTS (SELECT 1 FROM detalle_factura d
                      JOIN factura f ON f.id_factura = d.id_factura
                      WHERE d.id_membresia = m.id_membresia AND f.estado <> 'Anulada');

    -- Servicios mensuales del mes sin facturar
    INSERT INTO tmp_cargos (id_contratado, descripcion, monto)
    SELECT sc.id_contratado,
           CONCAT('Servicio ', s.nombre, ' - ', u.nombre),
           s.precio * sc.cantidad
    FROM servicio_contratado sc
    JOIN usuario u  ON u.id_usuario  = sc.id_usuario
    JOIN servicio s ON s.id_servicio = sc.id_servicio
    WHERE u.id_empresa = p_id_empresa
      AND sc.id_reserva IS NULL
      AND sc.estado = 'Activo'
      AND MONTH(sc.fecha) = p_mes
      AND YEAR(sc.fecha)  = p_anio
      AND NOT EXISTS (SELECT 1 FROM detalle_factura d
                      JOIN factura f ON f.id_factura = d.id_factura
                      WHERE d.id_contratado = sc.id_contratado AND f.estado <> 'Anulada');

    SET v_total = (SELECT COALESCE(SUM(monto), 0) FROM tmp_cargos);
    IF v_total = 0 THEN
        DROP TEMPORARY TABLE IF EXISTS tmp_cargos;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La empresa no tiene cargos pendientes de facturar en ese mes';
    END IF;

    INSERT INTO factura (id_empresa, fecha_emision, fecha_vencimiento, total, saldo_pendiente, estado)
    VALUES (p_id_empresa, CURDATE(), CURDATE() + INTERVAL 10 DAY, v_total, v_total, 'Pendiente');
    SET p_id_factura = LAST_INSERT_ID();

    INSERT INTO detalle_factura (id_factura, id_membresia, id_contratado, descripcion, monto)
    SELECT p_id_factura, id_membresia, id_contratado, descripcion, monto
    FROM tmp_cargos;

    DROP TEMPORARY TABLE IF EXISTS tmp_cargos;
END $$

DELIMITER ;

-- =========================================
-- PROCEDIMIENTO 12
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
-- PROCEDIMIENTO 13
-- Bloquear servicios adicionales por falta de pago -> Restringe acceso a servicios premium si
-- existen facturas pendientes.
-- =========================================
DELIMITER $$

CREATE PROCEDURE sp_bloquear_servicios_por_impago()
BEGIN
    UPDATE servicio_contratado AS sc
    SET sc.estado = 'Bloqueado'
    WHERE sc.estado = 'Activo'
      AND sc.id_reserva IS NULL
      AND EXISTS (
            SELECT 1
            FROM factura AS f
            WHERE f.id_usuario = sc.id_usuario
              AND f.estado IN ('Pendiente', 'Parcial', 'Vencida')
              AND f.saldo_pendiente > 0
              AND f.fecha_vencimiento < CURDATE()
      );

    SELECT ROW_COUNT() AS servicios_bloqueados;
END$$

DELIMITER ;
-- Submódulo: Accesos y Asistencias (Procedimientos 14 a 17)
-- =========================================
-- PROCEDIMIENTO 14
-- Registrar acceso de usuario (entrada) -> Valida membresía o reserva activa y registra
-- entrada en logs.
-- =========================================
DELIMITER $$

CREATE PROCEDURE sp_registrar_entrada(
    IN  p_codigo    VARCHAR(100),
    IN  p_metodo    VARCHAR(4),
    OUT p_resultado VARCHAR(20),
    OUT p_motivo    VARCHAR(100))
BEGIN
    DECLARE v_id_acceso INT;
    DECLARE v_usuario   INT;
    DECLARE v_entrada   DATETIME;

    INSERT INTO ACCESO (metodo, codigo_leido, fecha_hora_entrada, resultado)
    VALUES (p_metodo, p_codigo, NOW(), 'Permitido');
    SET v_id_acceso = LAST_INSERT_ID();

    SET p_resultado = (SELECT resultado      FROM ACCESO WHERE id_acceso = v_id_acceso);
    SET p_motivo    = (SELECT motivo_rechazo FROM ACCESO WHERE id_acceso = v_id_acceso);
    SET v_usuario   = (SELECT id_usuario     FROM ACCESO WHERE id_acceso = v_id_acceso);
    SET v_entrada   = (SELECT fecha_hora_entrada FROM ACCESO WHERE id_acceso = v_id_acceso);

    IF p_resultado = 'Permitido' THEN
        UPDATE ACCESO
        SET fecha_hora_salida = v_entrada,
            salida_automatica = TRUE
        WHERE id_usuario = v_usuario
          AND resultado = 'Permitido'
          AND fecha_hora_salida IS NULL
          AND id_acceso <> v_id_acceso
          AND fecha_hora_entrada < v_entrada;
    END IF;
END //
DELIMITER ;

-- =========================================
-- PROCEDIMIENTO 15
-- Registrar salida de usuario -> Completa la asistencia del usuario y marca hora de salida.
-- =========================================

DROP PROCEDURE IF EXISTS sp_registrar_salida;

DELIMITER $$

CREATE PROCEDURE sp_registrar_salida(IN p_codigo VARCHAR(100))
BEGIN
    DECLARE v_usuario   INT;
    DECLARE v_id_acceso INT;
    DECLARE v_reserva   INT;

    SET v_usuario = (SELECT id_usuario FROM credencial WHERE codigo = p_codigo);
    IF v_usuario IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credencial no encontrada';
    END IF;

    SET v_id_acceso = (SELECT id_acceso FROM acceso
                       WHERE id_usuario = v_usuario
                         AND resultado = 'Permitido'
                         AND fecha_hora_salida IS NULL
                       ORDER BY fecha_hora_entrada DESC
                       LIMIT 1);
    IF v_id_acceso IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario no tiene un ingreso abierto';
    END IF;

    UPDATE acceso
    SET fecha_hora_salida = GREATEST(NOW(), fecha_hora_entrada + INTERVAL 1 MINUTE)
    WHERE id_acceso = v_id_acceso;

    SET v_reserva = (SELECT id_reserva FROM acceso WHERE id_acceso = v_id_acceso);
    IF v_reserva IS NOT NULL THEN
        UPDATE reserva SET estado = 'Finalizada'
        WHERE id_reserva = v_reserva AND estado = 'Confirmada';
    END IF;
END $$

DELIMITER ;

-- =========================================
-- PROCEDIMIENTO 16
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
-- PROCEDIMIENTO 17
-- Marcar reservas como "No Show" y generar penalización -> Detecta reservas confirmadas
-- sin asistencia y aplica cargo automático.
-- =========================================
DELIMITER $$

CREATE PROCEDURE sp_bloquear_servicios_por_impago()
BEGIN
    UPDATE servicio_contratado AS sc
    SET sc.estado = 'Bloqueado'
    WHERE sc.estado = 'Activo'
      AND sc.id_reserva IS NULL
      AND EXISTS (
            SELECT 1
            FROM factura AS f
            WHERE f.id_usuario = sc.id_usuario
              AND f.estado IN ('Pendiente', 'Parcial', 'Vencida')
              AND f.saldo_pendiente > 0
              AND f.fecha_vencimiento < CURDATE()
      );

    SELECT ROW_COUNT() AS servicios_bloqueados;
END$$
DELIMITER ;
-- Submódulo: Corporativos y Administración (Procedimientos 18 a 20)
-- =========================================
-- PROCEDIMIENTO 18
-- Registrar lote de empleados de una empresa con membresía corporativa -> Inserta varios
-- usuarios vinculados a una empresa y les asigna membresía.
-- =========================================

DROP PROCEDURE IF EXISTS sp_registrar_lote_empleados;
 
DELIMITER $$
 
CREATE PROCEDURE sp_registrar_lote_empleados(
    IN  p_id_empresa INT,
    OUT p_total      INT)
BEGIN
    DECLARE v_rol      VARCHAR(20) DEFAULT NULL;
    DECLARE v_emp_cta  INT         DEFAULT NULL;
    DECLARE v_id_tipo  INT;
    DECLARE v_duracion INT;
 
    
    SELECT rol, id_empresa
      INTO v_rol, v_emp_cta
      FROM cuenta
     WHERE username = SUBSTRING_INDEX(USER(), '@', 1);
 
    IF v_rol = 'Gerente' AND NOT (v_emp_cta <=> p_id_empresa) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo puede registrar empleados de su empresa';
    END IF;
 
    
    IF NOT EXISTS (SELECT 1 FROM empresa WHERE id_empresa = p_id_empresa) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La empresa no existe';
    END IF;
 
    s
    IF NOT EXISTS (SELECT 1 FROM lote_empleados) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La tabla lote_empleados esta vacia';
    END IF;
 
    
    SELECT id_tipo, duracion_dias
      INTO v_id_tipo, v_duracion
      FROM tipo_membresia
     WHERE nombre = 'Corporativa';
 
    
    INSERT INTO usuario (documento, nombre, apellidos, fecha_nacimiento, email, telefono, id_empresa)
    SELECT documento, nombre, apellidos, fecha_nacimiento, email, telefono, p_id_empresa
      FROM lote_empleados;
 
    SET p_total = ROW_COUNT();
 
    
    INSERT INTO membresia (id_usuario, id_tipo, estado, fecha_inicio, fecha_fin)
    SELECT u.id_usuario, v_id_tipo, 'Pendiente', CURDATE(),
           DATE_ADD(CURDATE(), INTERVAL v_duracion DAY)
      FROM usuario AS u
      JOIN lote_empleados AS l ON l.documento = u.documento;
 
    
    DELETE FROM lote_empleados;
END
END$$
 
DELIMITER ;
-- =========================================
-- PROCEDIMIENTO 19
-- Cancelar reservas futuras al eliminar membresía de usuario -> Recorre reservas
-- pendientes/confirmadas y las cancela automáticamente.
-- =========================================

DROP PROCEDURE IF EXISTS sp_cancelar_reservas_futuras;

DELIMITER $$

CREATE PROCEDURE sp_cancelar_reservas_futuras(IN p_id_usuario INT, OUT p_total INT)
BEGIN
    DECLARE v_fin     BOOLEAN DEFAULT FALSE;
    DECLARE v_reserva INT;

    DECLARE cur CURSOR FOR
        SELECT id_reserva FROM reserva
        WHERE id_usuario = p_id_usuario
          AND estado IN ('Pendiente de Confirmacion', 'Confirmada')
          AND fecha_inicio > NOW();
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = TRUE;

    SET p_total = 0;
    OPEN cur;
    leer: LOOP
        FETCH cur INTO v_reserva;
        IF v_fin THEN
            LEAVE leer;
        END IF;
        CALL sp_cancelar_reserva(v_reserva, 100, 'Membresia eliminada');
        SET p_total = p_total + 1;
    END LOOP;
    CLOSE cur;
END $$

DELIMITER ;

-- =========================================
-- PROCEDIMIENTO 20
-- Generar reporte de ingresos mensuales acumulados -> Calcula ingresos por mes e ingresos
-- acumulados en el año.
-- =========================================
DELIMITER $$
CREATE PROCEDURE sp_bloquear_servicios_por_impago()
BEGIN
    UPDATE servicio_contratado AS sc
    SET sc.estado = 'Bloqueado'
    WHERE sc.estado = 'Activo'
      AND sc.id_reserva IS NULL
      AND EXISTS (
            SELECT 1
            FROM factura AS f
            WHERE f.id_usuario = sc.id_usuario
              AND f.estado IN ('Pendiente', 'Parcial', 'Vencida')
              AND f.saldo_pendiente > 0
              AND f.fecha_vencimiento < CURDATE()
      );

    SELECT ROW_COUNT() AS servicios_bloqueados;
END$$

DELIMITER ;