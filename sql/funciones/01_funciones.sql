/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Funciones SQL
Archivo: 01_funciones.sql
Descripción:
Implementación de las 20 Funciones SQL del proyecto, organizadas por
submódulo (Membresías, Reservas, Pagos y Facturación, Accesos).
Requisitos:
Ejecutar previamente 01_estructura.sql y 01_datos_iniciales.sql.
*/

USE coworking_db;

-- ============================================================================
-- SECCIÓN: FUNCIONES SQL (Funciones 01 a 20)
-- ============================================================================
-- Submódulo: Membresías (Funciones 01 a 05)
-- =========================================
-- FUNCIÓN 01
-- fn_membresia_activa(usuario_id) -> Devuelve TRUE si el usuario tiene membresía activa.
-- =========================================
-- =========================================
-- FUNCIÓN 02
-- fn_dias_restantes_membresia(usuario_id) -> Días restantes de vigencia.
-- =========================================

DROP FUNCTION IF EXISTS fn_dias_restantes_membresia;

DELIMITER $$

CREATE FUNCTION fn_dias_restantes_membresia(p_usuario_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_fecha_fin DATE;

    SELECT MAX(fecha_fin) INTO v_fecha_fin
    FROM MEMBRESIA
    WHERE id_usuario = p_usuario_id
      AND estado = 'Activa';

    IF v_fecha_fin IS NULL THEN
        RETURN 0;
    END IF;
    RETURN GREATEST(DATEDIFF(v_fecha_fin, CURDATE()), 0);
END $$

DELIMITER ;

-- =========================================
-- FUNCIÓN 03
-- fn_tipo_membresia(usuario_id) -> Retorna el tipo actual de membresía.
-- =========================================

DROP FUNCTION IF EXISTS fn_tipo_membresia;

DELIMITER $$

CREATE FUNCTION fn_tipo_membresia(usuario_id INT)
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    DECLARE v_tipo VARCHAR(20);

    SELECT tip.nombre
      INTO v_tipo
      FROM membresia AS mem
     INNER JOIN tipo_membresia AS tip ON tip.id_tipo = mem.id_tipo
     WHERE mem.id_usuario = usuario_id
       AND mem.estado = 'Activa'
     ORDER BY mem.fecha_inicio DESC
     LIMIT 1;

    -- Si no encontró ninguna, v_tipo queda vacío
    RETURN IFNULL(v_tipo, 'Sin membresia');
END$$

DELIMITER ;

-- =========================================
-- FUNCIÓN 04
-- fn_renovaciones_membresia(usuario_id) -> Número de veces que renovó.
-- =========================================
-- =========================================
-- FUNCIÓN 05
-- fn_estado_membresia(usuario_id) -> Devuelve estado (Activa, Suspendida, Vencida).
-- =========================================
-- Submódulo: Reservas (Funciones 06 a 10)
-- =========================================
-- FUNCIÓN 06
-- fn_total_reservas(usuario_id) -> Cantidad total de reservas del usuario.
-- =========================================
-- =========================================
-- FUNCIÓN 07
-- fn_horas_reservadas(usuario_id, mes, año) -> Total de horas reservadas en un período.
-- =========================================

DROP FUNCTION IF EXISTS fn_horas_reservadas;

DELIMITER $$

CREATE FUNCTION fn_horas_reservadas(p_usuario_id INT, p_mes INT, p_anio INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_horas DECIMAL(10,2);

    SELECT COALESCE(SUM(TIMESTAMPDIFF(MINUTE, fecha_inicio, fecha_fin)) / 60, 0)
      INTO v_horas
    FROM RESERVA
    WHERE id_usuario = p_usuario_id
      AND MONTH(fecha_inicio) = p_mes
      AND YEAR(fecha_inicio)  = p_anio
      AND estado <> 'Cancelada';

    RETURN v_horas;
END $$

DELIMITER ;

-- =========================================
-- FUNCIÓN 08
-- fn_espacio_mas_reservado() -> Retorna el ID del espacio más usado.
-- =========================================

DROP FUNCTION IF EXISTS fn_espacio_mas_reservado;

DELIMITER $$

CREATE FUNCTION fn_espacio_mas_reservado()
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_id_espacio INT;


    SELECT res.id_espacio
      INTO v_id_espacio
      FROM reserva AS res
     WHERE res.estado NOT IN ('Cancelada', 'Liberada')
     GROUP BY res.id_espacio
     ORDER BY COUNT(*) DESC, res.id_espacio ASC
     LIMIT 1;

    RETURN v_id_espacio;
END$$

DELIMITER ;


-- =========================================
-- FUNCIÓN 09
-- fn_reservas_activas(usuario_id) -> Cantidad de reservas activas.
-- =========================================
-- =========================================
-- FUNCIÓN 10
-- fn_duracion_promedio_reservas(espacio_id) -> Promedio de duración de reservas en un espacio.
-- =========================================

DROP FUNCTION IF EXISTS fn_duracion_promedio_reservas;

DELIMITER $$

CREATE FUNCTION fn_duracion_promedio_reservas(espacio_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_promedio_horas DECIMAL(10,2);

    SELECT AVG(TIMESTAMPDIFF(MINUTE, res.fecha_inicio, res.fecha_fin)) / 60
      INTO v_promedio_horas
      FROM reserva AS res
     WHERE res.id_espacio = espacio_id
       AND res.estado NOT IN ('Cancelada', 'Liberada');

    RETURN IFNULL(v_promedio_horas, 0);
END$$

DELIMITER ;

-- Submódulo: Pagos y Facturación (Funciones 11 a 15)
-- =========================================
-- FUNCIÓN 11
-- fn_total_pagado(usuario_id) -> Total pagado por un usuario.
-- =========================================
-- =========================================
-- FUNCIÓN 12
-- fn_ingresos_por_mes(mes, año) -> Ingresos totales en un mes.
-- =========================================

DROP FUNCTION IF EXISTS fn_ingresos_por_mes;

DELIMITER $$

CREATE FUNCTION fn_ingresos_por_mes(p_mes INT, p_anio INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2);

    SELECT COALESCE(SUM(monto), 0) INTO v_total
    FROM PAGO
    WHERE estado = 'Pagado'
      AND MONTH(fecha_pago) = p_mes
      AND YEAR(fecha_pago)  = p_anio;

    RETURN v_total;
END $$

DELIMITER ;

-- =========================================
-- FUNCIÓN 13
-- fn_ingresos_por_membresias() -> Total de ingresos por membresías.
-- =========================================


DROP FUNCTION IF EXISTS fn_ingresos_por_membresias;

DELIMITER $$

CREATE FUNCTION fn_ingresos_por_membresias()
RETURNS DECIMAL(14,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(14,2);

    SELECT COALESCE(SUM(df.monto), 0)
      INTO v_total
      FROM detalle_factura AS df
      JOIN factura AS fac ON fac.id_factura = df.id_factura
     WHERE df.id_membresia IS NOT NULL
       AND fac.estado = 'Pagada';

    RETURN v_total;
END$$

DELIMITER ;

-- =========================================
-- FUNCIÓN 14
-- fn_ingresos_por_reservas() -> Total de ingresos por reservas.
-- =========================================
-- =========================================
-- FUNCIÓN 15
-- fn_ingresos_por_empresa(empresa_id) -> Ingresos totales por una empresa.
-- =========================================

DROP FUNCTION IF EXISTS fn_ingresos_por_empresa;

DELIMITER $$

CREATE FUNCTION fn_ingresos_por_empresa(p_empresa_id INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2);

    SELECT COALESCE(SUM(p.monto), 0) INTO v_total
    FROM PAGO p
    JOIN FACTURA f      ON f.id_factura = p.id_factura
    LEFT JOIN USUARIO u ON u.id_usuario = f.id_usuario
    WHERE p.estado = 'Pagado'
      AND (f.id_empresa = p_empresa_id OR u.id_empresa = p_empresa_id);

    RETURN v_total;
END $$

DELIMITER ;

-- Submódulo: Accesos y Asistencias (Funciones 16 a 20)
-- =========================================
-- FUNCIÓN 16
-- fn_total_asistencias(usuario_id) -> Cantidad total de asistencias del usuario.
-- =========================================
-- =========================================
-- FUNCIÓN 17
-- fn_asistencias_mes(usuario_id, mes, año) -> Total de asistencias en un mes.
-- =========================================

DROP FUNCTION IF EXISTS fn_asistencias_mes;

DELIMITER $$

CREATE FUNCTION fn_asistencias_mes(p_usuario_id INT, p_mes INT, p_anio INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_total INT;

    SELECT COUNT(*) INTO v_total
    FROM ACCESO
    WHERE id_usuario = p_usuario_id
      AND resultado = 'Permitido'
      AND MONTH(fecha_hora_entrada) = p_mes
      AND YEAR(fecha_hora_entrada)  = p_anio;

    RETURN v_total;
END $$

DELIMITER ;

-- =========================================
-- FUNCIÓN 18
-- fn_top_usuario_asistencias() -> Usuario con más accesos.
-- =========================================

DROP FUNCTION IF EXISTS fn_top_usuario_asistencias;

DELIMITER $$

CREATE FUNCTION fn_top_usuario_asistencias()
RETURNS VARCHAR(150)
READS SQL DATA
BEGIN
    DECLARE v_usuario VARCHAR(150);

    SELECT CONCAT(usu.nombre, ' ', usu.apellidos)
      INTO v_usuario
      FROM acceso AS acc
      JOIN usuario AS usu ON usu.id_usuario = acc.id_usuario
     WHERE acc.resultado = 'Permitido'    
     GROUP BY usu.id_usuario, usu.nombre, usu.apellidos
     ORDER BY COUNT(*) DESC, usu.id_usuario ASC 
     LIMIT 1;

    RETURN v_usuario;
END$$

DELIMITER ;


-- =========================================
-- FUNCIÓN 19
-- fn_ultima_asistencia(usuario_id) -> Fecha de última asistencia.
-- =========================================
-- =========================================
-- FUNCIÓN 20
-- fn_promedio_asistencias() -> Promedio de asistencias por usuario.
-- =========================================
