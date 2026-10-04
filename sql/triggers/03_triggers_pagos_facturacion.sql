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
-- TRIGGER 11
-- Crear automáticamente una factura al registrar un pago.
-- =========================================


-- =========================================
-- TRIGGER 12
-- Actualizar factura a “Pagada” cuando se confirma el pago.
-- =========================================


-- =========================================
-- TRIGGER 13
-- Bloquear eliminación de un pago si ya existe factura asociada.
-- =========================================


-- =========================================
-- TRIGGER 14
-- Actualizar saldo pendiente en facturas con pagos parciales.
-- =========================================

DROP TRIGGER IF EXISTS trg_actualizar_saldo_factura;

DELIMITER $$

CREATE TRIGGER trg_actualizar_saldo_factura
AFTER INSERT ON pago
FOR EACH ROW
BEGIN
    DECLARE v_total_pagado DECIMAL(12,2);
    DECLARE v_saldo        DECIMAL(12,2);


    IF NEW.id_factura IS NOT NULL AND NEW.estado = 'Pagado' THEN

        -- Paso 1: sumar todos los pagos hechos de esa factura
        SELECT SUM(pag.monto)
          INTO v_total_pagado
          FROM pago AS pag
         WHERE pag.id_factura = NEW.id_factura
           AND pag.estado = 'Pagado';

        -- Paso 2: calcular lo que todavía se debe
        SELECT fac.total + fac.recargo_aplicado - v_total_pagado
          INTO v_saldo
          FROM factura AS fac
         WHERE fac.id_factura = NEW.id_factura;

        -- Paso 3: guardar el saldo y el estado según lo que falte
        UPDATE factura AS fac
           SET fac.saldo_pendiente = GREATEST(v_saldo, 0),
               fac.estado = CASE
                                WHEN v_saldo <= 0 THEN 'Pagada'
                                ELSE 'Parcial'
                            END
         WHERE fac.id_factura = NEW.id_factura
           AND fac.estado IN ('Pendiente', 'Parcial', 'Vencida');

    END IF;
END$$

DELIMITER ;

-- =========================================
-- TRIGGER 15
-- Registrar en un log todos los pagos anulados.
-- =========================================

