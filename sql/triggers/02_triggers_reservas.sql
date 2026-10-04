/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Triggers - Reservas
Archivo: 02_triggers_reservas.sql
Descripción:
Triggers 06 a 10 del módulo de Reservas.

Requisitos:
Ejecutar previamente DDL, DML y funciones.
*/


-- =========================================
-- TRIGGER 06
-- Validar que no existan reservas duplicadas en el mismo espacio, fecha y hora.
-- =========================================


-- =========================================
-- TRIGGER 07
-- Registrar automáticamente el estado “Pendiente de Confirmación” al crear una reserva.
-- =========================================

DROP TRIGGER IF EXISTS trg_reserva_bi_estado_inicial;

DELIMITER $$

CREATE TRIGGER trg_reserva_bi_estado_inicial
BEFORE INSERT ON RESERVA
FOR EACH ROW
BEGIN
    SET NEW.estado               = 'Pendiente de Confirmacion',
        NEW.fecha_creacion       = NOW(),
        NEW.recordatorio_enviado = FALSE;
END $$

DELIMITER ;

-- =========================================
-- TRIGGER 08
-- Cambiar estado a “Confirmada” al registrar el pago de la reserva.
-- =========================================


-- =========================================
-- TRIGGER 09
-- Cancelar reserva automáticamente si el usuario elimina su membresía.
-- =========================================


-- =========================================
-- TRIGGER 10
-- Registrar en un log cada vez que una reserva es cancelada.
-- =========================================

DROP TRIGGER IF EXISTS trg_log_reserva_cancelada;

DELIMITER $$

CREATE TRIGGER trg_log_reserva_cancelada
AFTER UPDATE ON reserva
FOR EACH ROW
BEGIN

    IF NEW.estado = 'Cancelada' AND OLD.estado <> 'Cancelada' THEN

        INSERT INTO log_reserva (id_reserva, estado_anterior, estado_nuevo, motivo, fecha)
        VALUES (NEW.id_reserva, OLD.estado, NEW.estado, 'Reserva cancelada', NOW());

    END IF;
END$$

DELIMITER ;


