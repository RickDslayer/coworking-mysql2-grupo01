/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Consultas Avanzadas
Archivo: 05_consultas_avanzadas.sql
Descripción:
Consultas 81 a 100 del módulo.
Incluye subconsultas, múltiples JOIN, funciones de agregación
y funciones de ventana.

Requisitos:
Ejecutar previamente DDL y DML.
*/

USE coworking_db;

-- Fecha de corte de los datos de prueba (las consultas de "hoy" la usan).
-- En producción: SET @hoy = CURDATE();
SET @hoy = DATE('2026-09-30');

-- CONSULTA 81
-- Mostrar los usuarios con el mayor gasto acumulado (subconsulta con SUM).
-- =========================================

SELECT u.id_usuario, u.nombre, u.apellidos,
       (SELECT IFNULL(SUM(p.monto), 0)
        FROM pago p
        JOIN factura f ON p.id_factura = f.id_factura
        WHERE f.id_usuario = u.id_usuario
          AND p.estado = 'Pagado') AS gasto_total
FROM usuario u
ORDER BY gasto_total DESC
LIMIT 10;


-- =========================================
-- CONSULTA 82
-- Mostrar los espacios más ocupados considerando reservas confirmadas y asistencias reales.
-- =========================================

SELECT e.id_espacio, e.nombre,
       (SELECT COUNT(*)
        FROM reserva r
        WHERE r.id_espacio = e.id_espacio
          AND r.estado = 'Confirmada') AS reservas_confirmadas,
       (SELECT COUNT(*)
        FROM acceso a
        JOIN reserva r ON a.id_reserva = r.id_reserva
        WHERE r.id_espacio = e.id_espacio
          AND a.resultado = 'Permitido') AS asistencias_reales
FROM espacio e
ORDER BY (reservas_confirmadas + asistencias_reales) DESC
LIMIT 10;


-- =========================================
-- CONSULTA 83
-- Calcular el promedio de ingresos por usuario usando subconsultas.
-- =========================================

SELECT AVG(t.gasto) AS promedio_ingresos_por_usuario
FROM (
    SELECT u.id_usuario,
           (SELECT IFNULL(SUM(p.monto), 0)
            FROM pago p
            JOIN factura f ON p.id_factura = f.id_factura
            WHERE f.id_usuario = u.id_usuario
              AND p.estado = 'Pagado') AS gasto
    FROM usuario u
) t;


-- =========================================
-- CONSULTA 84
-- Listar usuarios que tienen reservas activas y facturas pendientes.
-- =========================================

SELECT id_usuario, nombre, apellidos
FROM usuario
WHERE id_usuario IN (SELECT id_usuario FROM reserva WHERE estado = 'Confirmada')
  AND id_usuario IN (SELECT id_usuario FROM factura WHERE estado = 'Pendiente');


-- =========================================
-- CONSULTA 85
-- Mostrar empresas cuyos empleados generan más del 20% de los ingresos totales.
-- =========================================

SELECT e.id_empresa, e.nombre, SUM(p.monto) AS ingresos_empresa
FROM pago p
JOIN factura f ON p.id_factura = f.id_factura
LEFT JOIN usuario u ON f.id_usuario = u.id_usuario
JOIN empresa e ON e.id_empresa = IFNULL(f.id_empresa, u.id_empresa)
WHERE p.estado = 'Pagado'
GROUP BY e.id_empresa, e.nombre
HAVING SUM(p.monto) > 0.20 * (SELECT SUM(monto) FROM pago WHERE estado = 'Pagado');


-- =========================================
-- CONSULTA 86
-- Mostrar el top 5 de usuarios que más usan servicios adicionales.
-- =========================================

SELECT u.id_usuario,
       CONCAT(u.nombre, ' ', u.apellidos) AS nombre_completo,
       COUNT(*) AS servicios_contratados,
       COUNT(DISTINCT sc.id_servicio) AS servicios_distintos
FROM servicio_contratado sc
JOIN usuario u ON u.id_usuario = sc.id_usuario
GROUP BY u.id_usuario, nombre_completo
ORDER BY servicios_contratados DESC
LIMIT 5;

-- =========================================
-- CONSULTA 87
-- Mostrar reservas que generaron facturas mayores al promedio.
-- =========================================

SELECT r.id_reserva,
       e.nombre AS espacio,
       f.id_factura,
       f.total
FROM reserva r
JOIN espacio e ON e.id_espacio = r.id_espacio
JOIN detalle_factura d ON d.id_reserva = r.id_reserva
JOIN factura f ON f.id_factura = d.id_factura
WHERE f.estado <> 'Anulada'
  AND f.total > (SELECT AVG(f2.total)
                 FROM factura f2
                 WHERE f2.estado <> 'Anulada'
                   AND EXISTS (SELECT 1 FROM detalle_factura d2
                               WHERE d2.id_factura = f2.id_factura AND d2.id_reserva IS NOT NULL))
ORDER BY f.total DESC;

-- =========================================
-- CONSULTA 88
-- Calcular el porcentaje de ocupación global del coworking por mes.
-- =========================================

WITH RECURSIVE dias AS (
    SELECT @hoy - INTERVAL 364 DAY AS dia
    UNION ALL
    SELECT dia + INTERVAL 1 DAY FROM dias WHERE dia < @hoy
),
disponible AS (
    SELECT DATE_FORMAT(d.dia, '%Y-%m') AS mes,
           SUM(TIMESTAMPDIFF(MINUTE, h.hora_apertura, h.hora_cierre)) / 60 AS horas_disponibles
    FROM dias d
    JOIN horario_espacio h ON h.dia_semana = WEEKDAY(d.dia) + 1
    JOIN espacio e         ON e.id_espacio = h.id_espacio AND e.estado = 'Disponible'
    GROUP BY mes
),
ocupado AS (
    SELECT DATE_FORMAT(fecha_inicio, '%Y-%m') AS mes,
           SUM(TIMESTAMPDIFF(MINUTE, fecha_inicio, fecha_fin)) / 60 AS horas_reservadas
    FROM reserva
    WHERE estado IN ('Confirmada', 'Finalizada', 'No Show')
      AND DATE(fecha_inicio) BETWEEN @hoy - INTERVAL 364 DAY AND @hoy
    GROUP BY mes
)
SELECT d.mes,
       ROUND(COALESCE(o.horas_reservadas, 0), 1)                               AS horas_reservadas,
       ROUND(d.horas_disponibles, 1)                                           AS horas_disponibles,
       ROUND(COALESCE(o.horas_reservadas, 0) * 100 / d.horas_disponibles, 2)   AS ocupacion_pct
FROM disponible d
LEFT JOIN ocupado o ON o.mes = d.mes
ORDER BY d.mes;

-- =========================================
-- CONSULTA 89
-- Mostrar usuarios que tienen más horas de reserva que el promedio del sistema.
-- =========================================

SELECT u.id_usuario,
       CONCAT(u.nombre, ' ', u.apellidos) AS nombre_completo,
       ROUND(h.horas, 1) AS horas_reservadas
FROM usuario u
JOIN (SELECT id_usuario, SUM(TIMESTAMPDIFF(MINUTE, fecha_inicio, fecha_fin)) / 60 AS horas
      FROM reserva
      WHERE estado <> 'Cancelada'
      GROUP BY id_usuario) h ON h.id_usuario = u.id_usuario
WHERE h.horas > (SELECT AVG(horas) FROM (
                     SELECT SUM(TIMESTAMPDIFF(MINUTE, fecha_inicio, fecha_fin)) / 60 AS horas
                     FROM reserva
                     WHERE estado <> 'Cancelada'
                     GROUP BY id_usuario) t)
ORDER BY horas_reservadas DESC;

-- =========================================
-- CONSULTA 90
-- Mostrar el top 3 de salas más usadas en el último trimestre.
-- =========================================

SELECT e.id_espacio,
       e.nombre AS sala,
       te.nombre AS tipo_espacio,
       COUNT(*) AS reservas,
       ROUND(SUM(TIMESTAMPDIFF(MINUTE, r.fecha_inicio, r.fecha_fin)) / 60, 1) AS horas_usadas
FROM reserva r
JOIN espacio e ON e.id_espacio = r.id_espacio
JOIN tipo_espacio te ON te.id_tipo_espacio = e.id_tipo_espacio
WHERE te.nombre <> 'Escritorio flexible'
  AND r.estado IN ('Confirmada', 'Finalizada')
  AND r.fecha_inicio BETWEEN @hoy - INTERVAL 3 MONTH AND @hoy + INTERVAL 1 DAY
GROUP BY e.id_espacio, e.nombre, te.nombre
ORDER BY horas_usadas DESC
LIMIT 3;

-- =========================================
-- CONSULTA 91
-- Calcular ingresos promedio por tipo de membresía (agrupado con AVG).
-- =========================================

SELECT
    tip.nombre AS tipo_membresia,
    COUNT(det.id_detalle) AS membresias_cobradas,
    AVG(det.monto) AS ingreso_promedio
FROM detalle_factura AS det
INNER JOIN factura AS fac        ON fac.id_factura   = det.id_factura
INNER JOIN membresia AS mem      ON mem.id_membresia = det.id_membresia
INNER JOIN tipo_membresia AS tip ON tip.id_tipo      = mem.id_tipo
WHERE fac.estado <> 'Anulada'
GROUP BY tip.id_tipo, tip.nombre
ORDER BY ingreso_promedio DESC;

-- =========================================
-- CONSULTA 92
-- Mostrar usuarios que pagan solo con un método de pago (subconsulta).
-- =========================================

SELECT
    usu.id_usuario,
    usu.nombre,
    usu.apellidos,
    met.nombre AS metodo_unico,
    uni.total_pagos AS total_pagos
FROM usuario AS usu
INNER JOIN (
    SELECT
        fac.id_usuario,
        MIN(pag.id_metodo) AS id_metodo,
        COUNT(*) AS total_pagos
    FROM pago AS pag
    INNER JOIN factura AS fac ON fac.id_factura = pag.id_factura
    WHERE pag.estado = 'Pagado'
      AND fac.id_usuario IS NOT NULL
    GROUP BY fac.id_usuario
    HAVING COUNT(DISTINCT pag.id_metodo) = 1
) AS uni ON uni.id_usuario = usu.id_usuario
INNER JOIN metodo_pago AS met ON met.id_metodo = uni.id_metodo
ORDER BY uni.total_pagos DESC, usu.id_usuario;

-- =========================================
-- CONSULTA 93
-- Mostrar reservas canceladas por usuarios que nunca asistieron.
-- =========================================

SELECT
    res.id_reserva,
    usu.id_usuario,
    usu.nombre,
    usu.apellidos,
    esp.nombre AS espacio,
    res.fecha_inicio,
    res.fecha_fin,
    res.estado
FROM reserva AS res
INNER JOIN usuario AS usu ON usu.id_usuario = res.id_usuario
INNER JOIN espacio AS esp ON esp.id_espacio = res.id_espacio
WHERE res.estado = 'No Show'
ORDER BY usu.id_usuario, res.fecha_inicio;

-- =========================================
-- CONSULTA 94
-- Mostrar facturas con pagos parciales y calcular saldo pendiente.
-- =========================================

SELECT
    fac.id_factura,
    fac.total,
    fac.recargo_aplicado,
    SUM(pag.monto) AS total_pagado,
    fac.total + fac.recargo_aplicado - SUM(pag.monto) AS saldo_pendiente_calculado
FROM factura AS fac
INNER JOIN pago AS pag ON pag.id_factura = fac.id_factura
WHERE fac.estado = 'Parcial'
  AND pag.estado = 'Pagado'
GROUP BY fac.id_factura, fac.total, fac.recargo_aplicado
ORDER BY fac.id_factura;

-- =========================================
-- CONSULTA 95
-- Calcular la facturación total de cada empresa y ordenarla de mayor a menor.
-- =========================================


SELECT 
    emp.id_empresa,
    emp.nombre AS nombre_empresa,
    emp.nit,
    COALESCE(SUM(fac.total), 0) AS facturacion_total
FROM empresa AS emp
LEFT JOIN factura AS fac ON emp.id_empresa = fac.id_empresa AND fac.estado <> 'Anulada'
GROUP BY emp.id_empresa, emp.nombre, emp.nit
ORDER BY facturacion_total DESC;

-- =========================================
-- CONSULTA 96
-- Identificar usuarios que superan en reservas al promedio de su empresa.
-- =========================================

WITH reservas_usuario AS (
    SELECT
        u.id_usuario,
        u.nombre,
        u.apellidos,
        u.id_empresa,
        COUNT(r.id_reserva) AS total_reservas
    FROM usuario AS u
    LEFT JOIN reserva AS r
        ON r.id_usuario = u.id_usuario
       AND r.estado <> 'cancelada'
    WHERE u.id_empresa IS NOT NULL
    GROUP BY u.id_usuario, u.nombre, u.apellidos, u.id_empresa
),
con_promedio AS (
    SELECT
        ru.*,
        AVG(ru.total_reservas) OVER (PARTITION BY ru.id_empresa) AS promedio_empresa
    FROM reservas_usuario AS ru
)
SELECT
    e.nombre AS empresa,
    cp.id_usuario,
    cp.nombre,
    cp.apellidos,
    cp.total_reservas,
    ROUND(cp.promedio_empresa, 2) AS promedio_empresa
FROM con_promedio AS cp
INNER JOIN empresa AS e ON e.id_empresa = cp.id_empresa
WHERE cp.total_reservas > cp.promedio_empresa
ORDER BY e.nombre, cp.total_reservas DESC;

-- =========================================
-- CONSULTA 97
-- Mostrar las 3 empresas con más empleados activos en el coworking.
-- =========================================

SELECT
    e.id_empresa,
    e.nombre AS empresa,
    COUNT(DISTINCT u.id_usuario) AS empleados_activos
FROM empresa AS e
INNER JOIN usuario AS u ON u.id_empresa = e.id_empresa
INNER JOIN membresia AS m ON m.id_usuario = u.id_usuario
                         AND m.estado = 'Activa'
GROUP BY e.id_empresa, e.nombre
ORDER BY empleados_activos DESC
LIMIT 3;

-- =========================================
-- CONSULTA 98
-- Calcular el porcentaje de usuarios activos frente al total de registrados.
-- =========================================

SELECT
    COUNT(DISTINCT u.id_usuario) AS total_usuarios,
    COUNT(DISTINCT m.id_usuario) AS usuarios_activos,
    ROUND(100 * COUNT(DISTINCT m.id_usuario) / COUNT(DISTINCT u.id_usuario), 2) AS porcentaje_activos
FROM usuario AS u
LEFT JOIN membresia AS m
    ON m.id_usuario = u.id_usuario
   AND m.estado = 'Activa';

-- =========================================
-- CONSULTA 99
-- Mostrar ingresos mensuales acumulados con función de ventana (OVER).
-- =========================================

WITH mensual AS (
    SELECT
        DATE_FORMAT(fecha_pago, '%Y-%m') AS mes,
        SUM(monto) AS ingresos_mes
    FROM pago
    WHERE estado = 'Pagado'
    GROUP BY DATE_FORMAT(fecha_pago, '%Y-%m')
)
SELECT
    mes,
    ingresos_mes,
    SUM(ingresos_mes) OVER (ORDER BY mes) AS ingresos_acumulados
FROM mensual
ORDER BY mes;

-- =========================================
-- CONSULTA 100
-- Mostrar usuarios con más de 10 reservas, más de $500 en facturación y membresía activa (con múltiples joins).
-- =========================================

WITH reservas_usuario AS (
    SELECT id_usuario, COUNT(*) AS total_reservas
    FROM reserva
    WHERE estado <> 'cancelada'
    GROUP BY id_usuario
    HAVING COUNT(*) > 10
),
facturacion_usuario AS (
    SELECT id_usuario, SUM(total) AS total_facturado
    FROM factura
    WHERE estado <> 'anulada'
      AND id_usuario IS NOT NULL
    GROUP BY id_usuario
    HAVING SUM(total) > 500
)
SELECT
    u.id_usuario,
    u.nombre,
    u.apellidos,
    ru.total_reservas,
    fu.total_facturado,
    tm.nombre AS tipo_membresia,
    m.fecha_fin
FROM usuario AS u
INNER JOIN reservas_usuario AS ru ON ru.id_usuario = u.id_usuario
INNER JOIN facturacion_usuario AS fu ON fu.id_usuario = u.id_usuario
INNER JOIN membresia AS m ON m.id_usuario = u.id_usuario
                         AND m.estado = 'Activa'
INNER JOIN tipo_membresia AS tm ON tm.id_tipo = m.id_tipo
ORDER BY fu.total_facturado DESC;