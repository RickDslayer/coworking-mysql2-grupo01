/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Triggers - Accesos
Archivo: 04_triggers_accesos.sql
Descripción:
Triggers 16 a 20 del módulo de Accesos.

Requisitos:
Ejecutar previamente DDL, DML y funciones.
*/


-- =========================================
-- TRIGGER 16
-- Registrar asistencia automáticamente al validar acceso con QR o tarjeta.
-- =========================================


-- =========================================
-- TRIGGER 17
-- Bloquear acceso si el usuario no tiene membresía activa.
-- =========================================

DROP TRIGGER IF EXISTS trg_acceso_bi_validar;

DELIMITER $$

CREATE TRIGGER trg_acceso_bi_validar
BEFORE INSERT ON acceso
FOR EACH ROW
BEGIN
    DECLARE v_cred         INT;
    DECLARE v_usuario      INT;
    DECLARE v_cred_estado  VARCHAR(10);
    DECLARE v_tipo         INT;
    DECLARE v_reserva      INT;
    DECLARE v_hora_ini     TIME;
    DECLARE v_hora_fin     TIME;
    DECLARE v_ult_estado   VARCHAR(20);

    SET NEW.resultado = 'Permitido', NEW.motivo_rechazo = NULL;

    -- Credencial leída
    SET v_cred        = (SELECT id_credencial FROM credencial WHERE codigo = NEW.codigo_leido);
    SET v_usuario     = (SELECT id_usuario    FROM credencial WHERE codigo = NEW.codigo_leido);
    SET v_cred_estado = (SELECT estado        FROM credencial WHERE codigo = NEW.codigo_leido);

    IF v_cred IS NULL THEN
        SET NEW.id_credencial  = NULL,
            NEW.id_usuario     = NULL,
            NEW.resultado      = 'Rechazado',
            NEW.motivo_rechazo = IF(NEW.metodo = 'QR', 'QR invalido', 'Tarjeta invalida');
    ELSE
        SET NEW.id_credencial = v_cred,
            NEW.id_usuario    = v_usuario;

        IF v_cred_estado <> 'Activa' THEN
            SET NEW.resultado      = 'Rechazado',
                NEW.motivo_rechazo = CONCAT('Credencial ', LOWER(v_cred_estado));
        ELSE
            -- Membresía activa y vigente en la fecha del ingreso
            SET v_tipo = (SELECT m.id_tipo FROM membresia m
                          WHERE m.id_usuario = v_usuario
                            AND m.estado = 'Activa'
                            AND DATE(NEW.fecha_hora_entrada) BETWEEN m.fecha_inicio AND m.fecha_fin
                          ORDER BY m.fecha_fin DESC
                          LIMIT 1);
            -- Reserva confirmada en curso (se puede entrar 30 min antes)
            SET v_reserva = (SELECT r.id_reserva FROM reserva r
                             WHERE r.id_usuario = v_usuario
                               AND r.estado = 'Confirmada'
                               AND NEW.fecha_hora_entrada BETWEEN r.fecha_inicio - INTERVAL 30 MINUTE
                                                              AND r.fecha_fin
                             ORDER BY r.fecha_inicio
                             LIMIT 1);

            IF v_tipo IS NULL AND v_reserva IS NULL THEN
                SET v_ult_estado = (SELECT estado FROM membresia
                                    WHERE id_usuario = v_usuario
                                    ORDER BY fecha_inicio DESC, id_membresia DESC
                                    LIMIT 1);
                SET NEW.resultado      = 'Rechazado',
                    NEW.motivo_rechazo = CASE
                                             WHEN v_ult_estado = 'Suspendida'           THEN 'Membresia suspendida'
                                             WHEN v_ult_estado IN ('Vencida', 'Activa') THEN 'Membresia vencida'
                                             ELSE 'Membresia inactiva'
                                         END;
            ELSEIF v_reserva IS NULL THEN
                -- Entra por membresía: se valida el horario de su tipo
                SET v_hora_ini = (SELECT hora_acceso_inicio FROM tipo_membresia WHERE id_tipo = v_tipo);
                SET v_hora_fin = (SELECT hora_acceso_fin    FROM tipo_membresia WHERE id_tipo = v_tipo);
                IF TIME(NEW.fecha_hora_entrada) NOT BETWEEN v_hora_ini AND v_hora_fin THEN
                    SET NEW.resultado      = 'Rechazado',
                        NEW.motivo_rechazo = 'Fuera de horario';
                END IF;
            END IF;
        END IF;
    END IF;
END $$

DELIMITER ;

-- =========================================
-- TRIGGER 18
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
-- TRIGGER 19
-- Registrar salida automáticamente si el usuario vuelve a entrar sin salida previa.
-- =========================================


-- =========================================
-- TRIGGER 20
-- Registrar en un log cada intento de acceso rechazado.
-- =========================================