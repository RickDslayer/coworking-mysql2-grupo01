/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Triggers - Membresías
Archivo: 01_triggers_membresias.sql
Descripción:
Triggers 01 a 06 del módulo de Membresías.

Requisitos:
Ejecutar previamente DDL y DML.
*/


-- =========================================
-- TRIGGER 01
-- Insertar fecha de vencimiento automáticamente al crear una nueva membresía.
-- =========================================


-- =========================================
-- TRIGGER 02
-- Actualizar estado de membresía a “Activa” cuando se realiza un pago exitoso.
-- =========================================


-- =========================================
-- TRIGGER 03
-- Actualizar estado de membresía a “Suspendida” cuando no se paga antes de la fecha límite.
-- =========================================

DROP TRIGGER IF EXISTS trg_suspender_membresia_factura_vencida;

DELIMITER $$

CREATE TRIGGER trg_suspender_membresia_factura_vencida
AFTER UPDATE ON factura
FOR EACH ROW
BEGIN

    IF NEW.estado = 'Vencida' AND OLD.estado <> 'Vencida' THEN

        UPDATE membresia AS mem
        INNER JOIN detalle_factura AS det ON det.id_membresia = mem.id_membresia
        SET mem.estado = 'Suspendida'
        WHERE det.id_factura = NEW.id_factura
          AND mem.estado = 'Activa';

    END IF;
END$$

DELIMITER ;

-- =========================================
-- TRIGGER 04
-- Registrar en un log cada vez que se actualice el tipo de membresía de un usuario.
-- =========================================


-- =========================================
-- TRIGGER 05
-- Bloquear eliminación de membresía si el usuario tiene reservas activas.
-- =========================================


-- =========================================
-- TRIGGER 06
-- Registrar cambios relevantes relacionados con la membresía en el sistema de auditoría.
-- =========================================

