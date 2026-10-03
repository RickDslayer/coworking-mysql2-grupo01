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

DROP TRIGGER IF EXISTS trg_actualizar_ultimo_acceso;

DELIMITER $$

CREATE TRIGGER trg_actualizar_ultimo_acceso
AFTER INSERT ON acceso
FOR EACH ROW
BEGIN
    -- Solo actúa si la persona sí entró y se sabe quién es
    IF NEW.resultado = 'Permitido' AND NEW.id_usuario IS NOT NULL THEN

        UPDATE usuario AS usu
           SET usu.ultimo_acceso = NEW.fecha_hora_entrada
         WHERE usu.id_usuario = NEW.id_usuario;

    END IF;
END$$

DELIMITER ;

-- =========================================
-- TRIGGER 21
-- Registrar salida automáticamente si el usuario vuelve a entrar sin salida previa.
-- =========================================


-- =========================================
-- TRIGGER 22
-- Registrar en un log cada intento de acceso rechazado.
-- =========================================