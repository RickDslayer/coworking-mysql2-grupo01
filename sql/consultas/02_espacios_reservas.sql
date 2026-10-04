/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Espacios y Reservas
Archivo: 02_espacios_reservas.sql
Descripción:
Consultas 21 a 40 del módulo.

Requisitos:
Ejecutar previamente DDL y DML.
*/

USE coworking_db;

-- Fecha de corte de los datos de prueba (las consultas de "hoy" la usan).
-- En producción: SET @hoy = CURDATE();
SET @hoy = DATE('2026-09-30');


-- CONSULTA 21
-- Listar todos los espacios disponibles con su capacidad.
-- =========================================

SELECT e.id_espacio, e.nombre, te.nombre AS tipo_espacio, e.capacidad_maxima
FROM espacio e
JOIN tipo_espacio te ON e.id_tipo_espacio = te.id_tipo_espacio
WHERE e.estado = 'Disponible';


-- =========================================
-- CONSULTA 22
-- Listar reservas activas en el día actual.
-- =========================================

-- "Activa" = reserva Confirmada que empieza hoy.
SELECT r.id_reserva, u.nombre, u.apellidos, e.nombre AS espacio,
       r.fecha_inicio, r.fecha_fin
FROM reserva r
JOIN usuario u ON r.id_usuario = u.id_usuario
JOIN espacio e ON r.id_espacio = e.id_espacio
WHERE r.estado = 'Confirmada'
  AND DATE(r.fecha_inicio) = @hoy;


-- =========================================
-- CONSULTA 23
-- Mostrar reservas canceladas en el último mes.
-- =========================================

-- La fecha en que se canceló está en log_reserva (estado_nuevo = 'Cancelada').
SELECT r.id_reserva, u.nombre, u.apellidos, e.nombre AS espacio,
       r.fecha_inicio, l.fecha AS fecha_cancelacion, l.motivo
FROM reserva r
JOIN log_reserva l ON r.id_reserva = l.id_reserva
JOIN usuario u ON r.id_usuario = u.id_usuario
JOIN espacio e ON r.id_espacio = e.id_espacio
WHERE l.estado_nuevo = 'Cancelada'
  AND l.fecha >= DATE_SUB(@hoy, INTERVAL 1 MONTH);


-- =========================================
-- CONSULTA 24
-- Listar reservas de salas de reuniones en horario pico (9 am – 11 am).
-- =========================================

-- Se toman las reservas que empiezan desde las 9:00 hasta antes de las 11:00.
SELECT r.id_reserva, u.nombre, u.apellidos, e.nombre AS sala,
       r.fecha_inicio, r.fecha_fin
FROM reserva r
JOIN usuario u ON r.id_usuario = u.id_usuario
JOIN espacio e ON r.id_espacio = e.id_espacio
JOIN tipo_espacio te ON e.id_tipo_espacio = te.id_tipo_espacio
WHERE te.nombre = 'Sala de reuniones'
  AND TIME(r.fecha_inicio) >= '09:00:00'
  AND TIME(r.fecha_inicio) < '11:00:00';


-- =========================================
-- CONSULTA 25
-- Contar cuántas reservas se hacen por cada tipo de espacio.
-- =========================================

SELECT te.nombre AS tipo_espacio, COUNT(r.id_reserva) AS total_reservas
FROM tipo_espacio te
LEFT JOIN espacio e ON te.id_tipo_espacio = e.id_tipo_espacio
LEFT JOIN reserva r ON e.id_espacio = r.id_espacio
GROUP BY te.nombre;


-- =========================================
-- CONSULTA 26
-- Mostrar el espacio más reservado del último mes.
-- =========================================

SELECT e.id_espacio,
       e.nombre AS espacio,
       COUNT(*) AS reservas
FROM reserva r
JOIN espacio e ON e.id_espacio = r.id_espacio
WHERE r.fecha_inicio BETWEEN @hoy - INTERVAL 1 MONTH AND @hoy + INTERVAL 1 DAY
  AND r.estado <> 'Cancelada'
GROUP BY e.id_espacio, e.nombre
HAVING COUNT(*) = (SELECT MAX(total) FROM (
                       SELECT COUNT(*) AS total
                       FROM reserva
                       WHERE fecha_inicio BETWEEN @hoy - INTERVAL 1 MONTH AND @hoy + INTERVAL 1 DAY
                         AND estado <> 'Cancelada'
                       GROUP BY id_espacio) t);

-- =========================================
-- CONSULTA 27
-- Listar usuarios que más han reservado salas privadas.
-- =========================================

SELECT u.id_usuario,
       CONCAT(u.nombre, ' ', u.apellidos) AS nombre_completo,
       COUNT(*) AS reservas_oficina_privada
FROM reserva r
JOIN usuario u ON u.id_usuario = r.id_usuario
JOIN espacio e ON e.id_espacio = r.id_espacio
JOIN tipo_espacio te ON te.id_tipo_espacio = e.id_tipo_espacio
WHERE te.nombre = 'Oficina privada'
  AND r.estado <> 'Cancelada'
GROUP BY u.id_usuario, nombre_completo
ORDER BY reservas_oficina_privada DESC
LIMIT 10;

-- =========================================
-- CONSULTA 28
-- Mostrar reservas que exceden la capacidad máxima del espacio.
-- =========================================

SELECT r.id_reserva,
       e.nombre AS espacio,
       r.fecha_inicio,
       r.num_asistentes,
       e.capacidad_maxima,
       r.num_asistentes - e.capacidad_maxima AS exceso
FROM reserva r
JOIN espacio e ON e.id_espacio = r.id_espacio
WHERE r.num_asistentes > e.capacidad_maxima;

-- =========================================
-- CONSULTA 29
-- Listar espacios que no se han reservado en la última semana.
-- =========================================

SELECT e.id_espacio,
       e.nombre AS espacio,
       e.estado
FROM espacio e
WHERE NOT EXISTS (SELECT 1 FROM reserva r
                  WHERE r.id_espacio = e.id_espacio
                    AND r.estado <> 'Cancelada'
                    AND DATE(r.fecha_inicio) BETWEEN @hoy - INTERVAL 7 DAY AND @hoy);

-- =========================================
-- CONSULTA 30
-- Calcular la tasa de ocupación promedio de cada espacio.
-- =========================================

WITH RECURSIVE dias AS (
    SELECT @hoy - INTERVAL 89 DAY AS dia
    UNION ALL
    SELECT dia + INTERVAL 1 DAY FROM dias WHERE dia < @hoy
),
disponible AS (
    SELECT h.id_espacio,
           SUM(TIMESTAMPDIFF(MINUTE, h.hora_apertura, h.hora_cierre)) / 60 AS horas_disponibles
    FROM dias d
    JOIN horario_espacio h ON h.dia_semana = WEEKDAY(d.dia) + 1
    GROUP BY h.id_espacio
),
ocupado AS (
    SELECT id_espacio,
           SUM(TIMESTAMPDIFF(MINUTE, fecha_inicio, fecha_fin)) / 60 AS horas_reservadas
    FROM reserva
    WHERE estado IN ('Confirmada', 'Finalizada', 'No Show')
      AND DATE(fecha_inicio) BETWEEN @hoy - INTERVAL 89 DAY AND @hoy
    GROUP BY id_espacio
)
SELECT e.id_espacio,
       e.nombre                                                      AS espacio,
       ROUND(COALESCE(o.horas_reservadas, 0), 1)                     AS horas_reservadas,
       ROUND(d.horas_disponibles, 1)                                 AS horas_disponibles,
       ROUND(COALESCE(o.horas_reservadas, 0) * 100 / d.horas_disponibles, 2) AS tasa_ocupacion_pct
FROM espacio e
JOIN disponible d    ON d.id_espacio = e.id_espacio
LEFT JOIN ocupado o  ON o.id_espacio = e.id_espacio
ORDER BY tasa_ocupacion_pct DESC;

-- =========================================
-- CONSULTA 31
-- Mostrar reservas de más de 8 horas.
-- =========================================

SELECT
    res.id_reserva,
    usu.nombre,
    usu.apellidos,
    esp.nombre AS espacio,
    res.fecha_inicio,
    res.fecha_fin,
    TIMESTAMPDIFF(MINUTE, res.fecha_inicio, res.fecha_fin) / 60 AS horas,
    res.estado
FROM reserva AS res
INNER JOIN usuario AS usu ON usu.id_usuario = res.id_usuario
INNER JOIN espacio AS esp ON esp.id_espacio = res.id_espacio
WHERE TIMESTAMPDIFF(MINUTE, res.fecha_inicio, res.fecha_fin) / 60 > 8
ORDER BY horas DESC, res.fecha_inicio;

-- =========================================
-- CONSULTA 32
-- Identificar usuarios con más de 20 reservas en total.
-- =========================================


SELECT
    usu.id_usuario,
    usu.nombre,
    usu.apellidos,
    COUNT(res.id_reserva) AS total_reservas
FROM usuario AS usu
INNER JOIN reserva AS res ON res.id_usuario = usu.id_usuario
GROUP BY usu.id_usuario, usu.nombre, usu.apellidos
HAVING COUNT(res.id_reserva) > 20
ORDER BY total_reservas DESC;


-- =========================================
-- CONSULTA 33
-- Mostrar reservas realizadas por empresas con más de 10 empleados.
-- =========================================

SELECT
    res.id_reserva,
    emp.nombre AS empresa,
    esp.nombre   AS espacio,
    res.fecha_inicio,
    res.fecha_fin,
    res.estado
FROM reserva AS res
INNER JOIN usuario AS usu   ON usu.id_usuario   = res.id_usuario
INNER JOIN empresa AS emp ON emp.id_empresa = usu.id_empresa
INNER JOIN espacio AS esp   ON esp.id_espacio   = res.id_espacio
WHERE usu.id_empresa IN (SELECT id_empresa
                         FROM usuario
                        WHERE id_empresa IS NOT NULL
                        GROUP BY id_empresa
                       HAVING COUNT(*) > 10)
ORDER BY emp.nombre, res.fecha_inicio;

-- =========================================
-- CONSULTA 34
-- Listar reservas que se solapan en horario.
-- =========================================

SELECT
    r1.id_reserva   AS reserva_1,
    r2.id_reserva   AS reserva_2,
    e.nombre        AS espacio,
    r1.fecha_inicio AS inicio_1,
    r1.fecha_fin    AS fin_1,
    r2.fecha_inicio AS inicio_2,
    r2.fecha_fin    AS fin_2,
    r1.estado       AS estado_1,
    r2.estado       AS estado_2
FROM reserva AS r1
INNER JOIN reserva AS r2
        ON r2.id_espacio   = r1.id_espacio
       AND r2.id_reserva   > r1.id_reserva
       AND r1.fecha_inicio < r2.fecha_fin
       AND r2.fecha_inicio < r1.fecha_fin
INNER JOIN espacio AS e ON e.id_espacio = r1.id_espacio
WHERE r1.estado NOT IN ('Cancelada', 'Liberada')
  AND r2.estado NOT IN ('Cancelada', 'Liberada')
ORDER BY e.nombre, r1.fecha_inicio;

-- =========================================
-- CONSULTA 35
-- Listar reservas de fin de semana.
-- =========================================

SELECT
    res.id_reserva,
    usu.nombre,
    usu.apellidos,
    esp.nombre AS espacio,
    res.fecha_inicio,
    res.fecha_fin,
    CASE WEEKDAY(res.fecha_inicio) WHEN 5 THEN 'Sabado'
								   WHEN 6 THEN 'Domingo'
    END AS dia,
    res.estado
FROM reserva AS res
INNER JOIN usuario AS usu ON usu.id_usuario = res.id_usuario
INNER JOIN espacio AS esp ON esp.id_espacio = res.id_espacio
WHERE WEEKDAY(res.fecha_inicio) IN (5, 6)
ORDER BY res.fecha_inicio;

-- =========================================
-- CONSULTA 36
-- Mostrar el porcentaje de ocupación por cada tipo de espacio.
-- =========================================

SELECT
    te.nombre AS tipo_espacio,
    ROUND(100 * COALESCE(r.horas_reservadas, 0)   / h.horas_disponibles, 2) AS porcentaje_ocupacion
FROM tipo_espacio AS te
INNER JOIN (
    SELECT e.id_tipo_espacio,
           SUM(TIME_TO_SEC(TIMEDIFF(he.hora_cierre, he.hora_apertura))) / 3600 * (30 / 7) AS horas_disponibles
    FROM espacio AS e
    INNER JOIN horario_espacio AS he ON he.id_espacio = e.id_espacio
    GROUP BY e.id_tipo_espacio
) AS h ON h.id_tipo_espacio = te.id_tipo_espacio
LEFT JOIN (
    SELECT e.id_tipo_espacio,
           SUM(TIMESTAMPDIFF(MINUTE, r.fecha_inicio, r.fecha_fin)) / 60 AS horas_reservadas
    FROM reserva AS r
    INNER JOIN espacio AS e ON e.id_espacio = r.id_espacio
    WHERE r.estado <> 'cancelada'
      AND r.fecha_inicio >= @hoy - INTERVAL 30 DAY
      AND r.fecha_inicio <  @hoy + INTERVAL 1 DAY
    GROUP BY e.id_tipo_espacio
) AS r ON r.id_tipo_espacio = te.id_tipo_espacio;

-- =========================================
-- CONSULTA 37
-- Mostrar la duración promedio de reservas por tipo de espacio.
-- =========================================

SELECT
    te.nombre AS tipo_espacio,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, r.fecha_inicio, r.fecha_fin)) / 60, 2) AS horas_promedio
FROM reserva AS r
INNER JOIN espacio AS e ON e.id_espacio = r.id_espacio
INNER JOIN tipo_espacio AS te ON te.id_tipo_espacio = e.id_tipo_espacio
GROUP BY te.id_tipo_espacio, te.nombre;


-- =========================================
-- CONSULTA 38
-- Mostrar reservas con servicios adicionales incluidos.
-- =========================================

SELECT
    r.id_reserva,
    r.fecha_inicio,
    r.fecha_fin,
    s.nombre AS servicio,
    sc.cantidad,
    s.precio,
    sc.cantidad * s.precio AS subtotal
FROM reserva AS r
INNER JOIN servicio_contratado AS sc ON sc.id_reserva = r.id_reserva
INNER JOIN servicio AS s ON s.id_servicio = sc.id_servicio
ORDER BY r.id_reserva;

-- =========================================
-- CONSULTA 39
-- Listar usuarios que reservaron sala de eventos en los últimos 6 meses.
-- =========================================

SELECT DISTINCT
    u.id_usuario,
    u.nombre,
    u.apellidos,
    u.email
FROM usuario AS u
INNER JOIN reserva AS r ON r.id_usuario = u.id_usuario
INNER JOIN espacio AS e ON e.id_espacio = r.id_espacio
INNER JOIN tipo_espacio AS te ON te.id_tipo_espacio = e.id_tipo_espacio
WHERE te.nombre = 'Sala de eventos'
  AND r.fecha_inicio >= @hoy - INTERVAL 6 MONTH
  AND r.fecha_inicio <  @hoy + INTERVAL 1 DAY;

-- =========================================
-- CONSULTA 40
-- Identificar reservas realizadas y nunca asistidas.
-- =========================================
SELECT
    r.id_reserva,
    r.id_usuario,
    r.id_espacio,
    r.fecha_inicio,
    r.fecha_fin,
    r.estado
FROM reserva AS r
LEFT JOIN acceso AS a
    ON a.id_reserva = r.id_reserva
   AND a.resultado = 'Permitido'
WHERE a.id_acceso IS NULL
  AND r.estado <> 'Cancelada'
  AND r.fecha_fin < @hoy;
