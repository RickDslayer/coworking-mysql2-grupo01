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


-- =========================================
-- CONSULTA 27
-- Listar usuarios que más han reservado salas privadas.
-- =========================================


-- =========================================
-- CONSULTA 28
-- Mostrar reservas que exceden la capacidad máxima del espacio.
-- =========================================


-- =========================================
-- CONSULTA 29
-- Listar espacios que no se han reservado en la última semana.
-- =========================================


-- =========================================
-- CONSULTA 30
-- Calcular la tasa de ocupación promedio de cada espacio.
-- =========================================


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
