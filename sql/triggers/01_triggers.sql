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


-- =========================================
-- TRIGGER 12
-- Registrar cambios relevantes de estado de las reservas en el sistema de auditoría.
-- =========================================


/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Triggers - Pagos y Facturación
Archivo: 03_triggers_pagos_facturacion.sql
Descripción:
Triggers 13 a 17 del módulo de Pagos y Facturación.

Requisitos:
Ejecutar previamente DDL y DML.
*/


-- =========================================
-- TRIGGER 13
-- Crear automáticamente una factura al registrar un pago.
-- =========================================


-- =========================================
-- TRIGGER 14
-- Actualizar factura a “Pagada” cuando se confirma el pago.
-- =========================================


-- =========================================
-- TRIGGER 15
-- Bloquear eliminación de un pago si ya existe factura asociada.
-- =========================================


-- =========================================
-- TRIGGER 16
-- Actualizar saldo pendiente en facturas con pagos parciales.
-- =========================================


-- =========================================
-- TRIGGER 17
-- Registrar en un log todos los pagos anulados.
-- =========================================


/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Triggers - Accesos
Archivo: 04_triggers_accesos.sql
Descripción:
Triggers 18 a 22 del módulo de Accesos.

Requisitos:
Ejecutar previamente DDL y DML.
*/


-- =========================================
-- TRIGGER 18
-- Registrar asistencia automáticamente al validar acceso con QR o tarjeta.
-- =========================================


-- =========================================
-- TRIGGER 19
-- Bloquear acceso si el usuario no tiene membresía activa.
-- =========================================


-- =========================================
-- TRIGGER 20
-- Actualizar última fecha de acceso del usuario al ingresar.
-- =========================================


-- =========================================
-- TRIGGER 21
-- Registrar salida automáticamente si el usuario vuelve a entrar sin salida previa.
-- =========================================


-- =========================================
-- TRIGGER 22
-- Registrar en un log cada intento de acceso rechazado.
-- =========================================