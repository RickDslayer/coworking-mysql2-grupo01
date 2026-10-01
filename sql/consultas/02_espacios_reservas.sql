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


-- CONSULTA 21
-- Listar todos los espacios disponibles con su capacidad.
-- =========================================


-- =========================================
-- CONSULTA 22
-- Listar reservas activas en el día actual.
-- =========================================


-- =========================================
-- CONSULTA 23
-- Mostrar reservas canceladas en el último mes.
-- =========================================


-- =========================================
-- CONSULTA 24
-- Listar reservas de salas de reuniones en horario pico (9 am – 11 am).
-- =========================================


-- =========================================
-- CONSULTA 25
-- Contar cuántas reservas se hacen por cada tipo de espacio.
-- =========================================


-- =========================================
-- CONSULTA 26
-- Mostrar el espacio más reservado del último mes.
-- =========================================

SELECT e.id_espacio,
       e.nombre AS espacio,
       COUNT(*) AS reservas
FROM RESERVA r
JOIN ESPACIO e ON e.id_espacio = r.id_espacio
WHERE r.fecha_inicio BETWEEN @hoy - INTERVAL 1 MONTH AND @hoy + INTERVAL 1 DAY
  AND r.estado <> 'Cancelada'
GROUP BY e.id_espacio, e.nombre
HAVING COUNT(*) = (SELECT MAX(total) FROM (
                       SELECT COUNT(*) AS total
                       FROM RESERVA
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
FROM RESERVA r
JOIN USUARIO u ON u.id_usuario = r.id_usuario
JOIN ESPACIO e ON e.id_espacio = r.id_espacio
JOIN TIPO_ESPACIO te ON te.id_tipo_espacio = e.id_tipo_espacio
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
FROM RESERVA r
JOIN ESPACIO e ON e.id_espacio = r.id_espacio
WHERE r.num_asistentes > e.capacidad_maxima;

-- =========================================
-- CONSULTA 29
-- Listar espacios que no se han reservado en la última semana.
-- =========================================

SELECT e.id_espacio,
       e.nombre AS espacio,
       e.estado
FROM ESPACIO e
WHERE NOT EXISTS (SELECT 1 FROM RESERVA r
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
    JOIN HORARIO_ESPACIO h ON h.dia_semana = WEEKDAY(d.dia) + 1
    GROUP BY h.id_espacio
),
ocupado AS (
    SELECT id_espacio,
           SUM(TIMESTAMPDIFF(MINUTE, fecha_inicio, fecha_fin)) / 60 AS horas_reservadas
    FROM RESERVA
    WHERE estado IN ('Confirmada', 'Finalizada', 'No Show')
      AND DATE(fecha_inicio) BETWEEN @hoy - INTERVAL 89 DAY AND @hoy
    GROUP BY id_espacio
)
SELECT e.id_espacio,
       e.nombre                                                      AS espacio,
       ROUND(COALESCE(o.horas_reservadas, 0), 1)                     AS horas_reservadas,
       ROUND(d.horas_disponibles, 1)                                 AS horas_disponibles,
       ROUND(COALESCE(o.horas_reservadas, 0) * 100 / d.horas_disponibles, 2) AS tasa_ocupacion_pct
FROM ESPACIO e
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


-- =========================================
-- CONSULTA 37
-- Mostrar la duración promedio de reservas por tipo de espacio.
-- =========================================


-- =========================================
-- CONSULTA 38
-- Mostrar reservas con servicios adicionales incluidos.
-- =========================================


-- =========================================
-- CONSULTA 39
-- Listar usuarios que reservaron sala de eventos en los últimos 6 meses.
-- =========================================


-- =========================================
-- CONSULTA 40
-- Identificar reservas realizadas y nunca asistidas.
-- =========================================
