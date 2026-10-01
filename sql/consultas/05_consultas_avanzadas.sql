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

-- CONSULTA 81
-- Mostrar los usuarios con el mayor gasto acumulado (subconsulta con SUM).
-- =========================================


-- =========================================
-- CONSULTA 82
-- Mostrar los espacios más ocupados considerando reservas confirmadas y asistencias reales.
-- =========================================


-- =========================================
-- CONSULTA 83
-- Calcular el promedio de ingresos por usuario usando subconsultas.
-- =========================================


-- =========================================
-- CONSULTA 84
-- Listar usuarios que tienen reservas activas y facturas pendientes.
-- =========================================


-- =========================================
-- CONSULTA 85
-- Mostrar empresas cuyos empleados generan más del 20% de los ingresos totales.
-- =========================================


-- =========================================
-- CONSULTA 86
-- Mostrar el top 5 de usuarios que más usan servicios adicionales.
-- =========================================

SELECT u.id_usuario,
       CONCAT(u.nombre, ' ', u.apellidos) AS nombre_completo,
       COUNT(*) AS servicios_contratados,
       COUNT(DISTINCT sc.id_servicio) AS servicios_distintos
FROM SERVICIO_CONTRATADO sc
JOIN USUARIO u ON u.id_usuario = sc.id_usuario
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
FROM RESERVA r
JOIN ESPACIO e ON e.id_espacio = r.id_espacio
JOIN DETALLE_FACTURA d ON d.id_reserva = r.id_reserva
JOIN FACTURA f ON f.id_factura = d.id_factura
WHERE f.estado <> 'Anulada'
  AND f.total > (SELECT AVG(f2.total)
                 FROM FACTURA f2
                 WHERE f2.estado <> 'Anulada'
                   AND EXISTS (SELECT 1 FROM DETALLE_FACTURA d2
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
    JOIN HORARIO_ESPACIO h ON h.dia_semana = WEEKDAY(d.dia) + 1
    JOIN ESPACIO e         ON e.id_espacio = h.id_espacio AND e.estado = 'Disponible'
    GROUP BY mes
),
ocupado AS (
    SELECT DATE_FORMAT(fecha_inicio, '%Y-%m') AS mes,
           SUM(TIMESTAMPDIFF(MINUTE, fecha_inicio, fecha_fin)) / 60 AS horas_reservadas
    FROM RESERVA
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
FROM USUARIO u
JOIN (SELECT id_usuario, SUM(TIMESTAMPDIFF(MINUTE, fecha_inicio, fecha_fin)) / 60 AS horas
      FROM RESERVA
      WHERE estado <> 'Cancelada'
      GROUP BY id_usuario) h ON h.id_usuario = u.id_usuario
WHERE h.horas > (SELECT AVG(horas) FROM (
                     SELECT SUM(TIMESTAMPDIFF(MINUTE, fecha_inicio, fecha_fin)) / 60 AS horas
                     FROM RESERVA
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
FROM RESERVA r
JOIN ESPACIO e ON e.id_espacio = r.id_espacio
JOIN TIPO_ESPACIO te ON te.id_tipo_espacio = e.id_tipo_espacio
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


-- =========================================
-- CONSULTA 92
-- Mostrar usuarios que pagan solo con un método de pago (subconsulta).
-- =========================================


-- =========================================
-- CONSULTA 93
-- Mostrar reservas canceladas por usuarios que nunca asistieron.
-- =========================================


-- =========================================
-- CONSULTA 94
-- Mostrar facturas con pagos parciales y calcular saldo pendiente.
-- =========================================


-- =========================================
-- CONSULTA 95
-- Calcular la facturación total de cada empresa y ordenarla de mayor a menor.
-- =========================================


-- =========================================
-- CONSULTA 96
-- Identificar usuarios que superan en reservas al promedio de su empresa.
-- =========================================


-- =========================================
-- CONSULTA 97
-- Mostrar las 3 empresas con más empleados activos en el coworking.
-- =========================================


-- =========================================
-- CONSULTA 98
-- Calcular el porcentaje de usuarios activos frente al total de registrados.
-- =========================================


-- =========================================
-- CONSULTA 99
-- Mostrar ingresos mensuales acumulados con función de ventana (OVER).
-- =========================================


-- =========================================
-- CONSULTA 100
-- Mostrar usuarios con más de 10 reservas, más de $500 en facturación y membresía activa (con múltiples joins).
-- =========================================