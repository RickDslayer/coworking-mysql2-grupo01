/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Triggers - Reservas
Archivo: 02_triggers_reservas.sql
Descripción:
Triggers 07 a 12 del módulo de Reservas.

Requisitos:
Ejecutar previamente DDL y DML.
*/


-- =========================================
-- TRIGGER 07
-- Validar que no existan reservas duplicadas en el mismo espacio, fecha y hora.
-- =========================================


-- =========================================
-- TRIGGER 08
-- Registrar automáticamente el estado “Pendiente de Confirmación” al crear una reserva.
-- =========================================


-- =========================================
-- TRIGGER 09
-- Cambiar estado a “Confirmada” al registrar el pago de la reserva.
-- =========================================


-- =========================================
-- TRIGGER 10
-- Cancelar reserva automáticamente si el usuario elimina su membresía.
-- =========================================


-- =========================================
-- TRIGGER 11
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

-- =========================================
-- TRIGGER 12
-- Registrar cambios relevantes de estado de las reservas en el sistema de auditoría.
-- =========================================

