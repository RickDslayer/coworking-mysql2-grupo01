/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Triggers - Membresías
Archivo: 01_triggers_membresias.sql
Descripción:
Triggers 01 a 05 del módulo de Membresías.

Requisitos:
Ejecutar previamente DDL, DML y funciones.
*/


-- =========================================
-- TRIGGER 01
-- Insertar fecha de vencimiento automáticamente al crear una nueva membresía.
-- =========================================


-- =========================================
-- TRIGGER 02
-- Actualizar estado de membresía a “Activa” cuando se realiza un pago exitoso.
-- =========================================

DROP TRIGGER IF EXISTS trg_factura_au_activar_membresia;

DELIMITER $$

CREATE TRIGGER trg_factura_au_activar_membresia
AFTER UPDATE ON factura
FOR EACH ROW
BEGIN
    IF NEW.estado = 'Pagada' AND OLD.estado <> 'Pagada' THEN
        UPDATE membresia m
        JOIN detalle_factura d ON d.id_membresia = m.id_membresia
        SET m.estado = 'Activa'
        WHERE d.id_factura = NEW.id_factura
          AND m.estado IN ('Pendiente', 'Suspendida')
          AND m.fecha_fin >= CURDATE();
    END IF;
END $$

DELIMITER ;

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

DELIMITER !

CREATE TRIGGER trg_membresia_cambio_tipo
AFTER UPDATE ON membresia
FOR EACH ROW
BEGIN
    IF OLD.id_tipo <> NEW.id_tipo THEN
        INSERT INTO log_membresia
            (id_membresia, id_tipo_anterior, id_tipo_nuevo, fecha_cambio, usuario_bd)
        VALUES
            (NEW.id_membresia, OLD.id_tipo, NEW.id_tipo, NOW(), USER());
    END IF;
END!

DELIMITER ;

-- =========================================
-- TRIGGER 05
-- Bloquear eliminación de membresía si el usuario tiene reservas activas.
-- =========================================




