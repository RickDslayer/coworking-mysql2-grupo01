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
  AND DATE(r.fecha_inicio) = CURDATE();


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
  AND l.fecha >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH);


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


-- =========================================
-- CONSULTA 32
-- Identificar usuarios con más de 20 reservas en total.
-- =========================================


-- =========================================
-- CONSULTA 33
-- Mostrar reservas realizadas por empresas con más de 10 empleados.
-- =========================================


-- =========================================
-- CONSULTA 34
-- Listar reservas que se solapan en horario.
-- =========================================


-- =========================================
-- CONSULTA 35
-- Listar reservas de fin de semana.
-- =========================================


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