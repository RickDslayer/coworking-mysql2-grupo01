/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Usuarios y Membresías
Archivo: 01_usuarios_membresias.sql
Descripción:
Consultas 01 a 20 del módulo.

Requisitos:
Ejecutar previamente DDL y DML.
*/

USE coworking_db;

-- CONSULTA 01
-- Listar todos los usuarios con su información básica.
-- =========================================
SELECT id_usuario, documento, nombre, apellidos, fecha_nacimiento,
       email, telefono, fecha_registro
FROM usuario;

-- =========================================
-- CONSULTA 02
-- Listar los usuarios con membresía activa.
-- =========================================
SELECT u.id_usuario, u.nombre, u.apellidos, m.fecha_inicio, m.fecha_fin
FROM usuario u
JOIN membresia m ON u.id_usuario = m.id_usuario
WHERE m.estado = 'Activa';

-- =========================================
-- CONSULTA 03
-- Listar los usuarios cuya membresía está vencida.
-- =========================================
SELECT u.id_usuario, u.nombre, u.apellidos, m.fecha_inicio, m.fecha_fin
FROM usuario u
JOIN membresia m ON u.id_usuario = m.id_usuario
WHERE m.estado = 'Vencida';

-- =========================================
-- CONSULTA 04
-- Listar los usuarios con membresía suspendida.
-- =========================================
SELECT u.id_usuario, u.nombre, u.apellidos, m.fecha_inicio, m.fecha_fin
FROM usuario u
JOIN membresia m ON u.id_usuario = m.id_usuario
WHERE m.estado = 'Suspendida';

-- =========================================
-- CONSULTA 05
-- Contar cuántos usuarios tienen cada tipo de membresía.
-- =========================================
SELECT t.nombre AS tipo_membresia,
       COUNT(DISTINCT m.id_usuario) AS cantidad_usuarios
FROM tipo_membresia t
LEFT JOIN membresia m ON t.id_tipo = m.id_tipo
GROUP BY t.nombre;

-- =========================================
-- CONSULTA 06
-- Mostrar el top 10 de usuarios con más antigüedad en el coworking.
-- =========================================


-- =========================================
-- CONSULTA 07
-- Listar usuarios que pertenecen a una empresa específica.
-- =========================================


-- =========================================
-- CONSULTA 08
-- Contar cuántos usuarios están asociados a cada empresa.
-- =========================================


-- =========================================
-- CONSULTA 09
-- Mostrar usuarios que nunca han hecho una reserva.
-- =========================================


-- =========================================
-- CONSULTA 10
-- Mostrar usuarios con más de 5 reservas activas en el mes.
-- =========================================


-- =========================================
-- CONSULTA 11
-- Calcular el promedio de edad de los usuarios.
-- =========================================

    SELECT 
    AVG( YEAR(CURDATE()) - YEAR(fecha_nacimiento) ) AS promedio_edad
FROM 
    usuario;

-- =========================================
-- CONSULTA 12
-- Listar usuarios que han cambiado de membresía más de 2 veces.
-- =========================================


SELECT usu.id_usuario, usu.nombre, usu.apellidos, COUNT(lm.id_membresia) AS total
FROM log_membresia AS lm  
LEFT JOIN membresia AS mem ON lm.id_membresia = mem.id_membresia
LEFT JOIN usuario AS usu ON mem.id_usuario = usu.id_usuario
GROUP BY usu.id_usuario
HAVING COUNT(lm.id_membresia) > 2;

-- =========================================
-- CONSULTA 13
-- Listar usuarios que han gastado más de $500 en reservas.
-- =========================================

SELECT	usu.id_usuario,
		usu.nombre,
		usu.apellidos,
		COUNT(DISTINCT res.id_reserva) AS total_reservas,
		SUM(df.monto)                AS total_gastado
FROM usuario AS usu
INNER JOIN reserva AS res          ON res.id_usuario  = usu.id_usuario
INNER JOIN detalle_factura AS df ON df.id_reserva = res.id_reserva
INNER JOIN factura AS fac          ON fac.id_factura  = df.id_factura
WHERE fac.estado <> 'Anulada'        
GROUP BY usu.id_usuario, usu.nombre, usu.apellidos
HAVING SUM(df.monto) > 500
ORDER BY total_gastado DESC;

-- =========================================
-- CONSULTA 14
-- Mostrar usuarios que tienen tanto membresía como servicios adicionales.
-- =========================================


SELECT
    usu.id_usuario,
    usu.nombre,
    usu.apellidos,
    (SELECT COUNT(*)
       FROM servicio_contratado AS sc
      WHERE sc.id_usuario = usu.id_usuario
        AND sc.estado = 'Activo') AS servicios_activos
FROM usuario AS usu
WHERE EXISTS (SELECT 1
                FROM membresia AS mem
               WHERE mem.id_usuario = usu.id_usuario
                 AND mem.estado = 'Activa')
  AND EXISTS (SELECT 1
                FROM servicio_contratado AS sc
               WHERE sc.id_usuario = usu.id_usuario
                 AND sc.estado = 'Activo')
ORDER BY usu.id_usuario;

-- =========================================
-- CONSULTA 15
-- Listar usuarios con membresía Premium y reservas activas.
-- =========================================

SELECT
    usu.id_usuario,
    usu.nombre,
    usu.apellidos,
    mem.fecha_fin AS vence_membresia,
    COUNT(DISTINCT res.id_reserva) AS reservas_activas
FROM usuario AS usu
INNER JOIN membresia AS mem       ON mem.id_usuario = usu.id_usuario
INNER JOIN tipo_membresia AS tm ON tm.id_tipo   = mem.id_tipo
INNER JOIN reserva AS res         ON res.id_usuario = usu.id_usuario
WHERE tm.nombre = 'Premium'
	AND mem.estado  = 'Activa'
	AND res.estado IN ('Confirmada', 'Pendiente de Confirmacion')
GROUP BY usu.id_usuario, usu.nombre, usu.apellidos, mem.fecha_fin
ORDER BY reservas_activas DESC;

-- =========================================
-- CONSULTA 16
-- Mostrar usuarios con membresía Corporativa y su empresa.
-- =========================================


-- =========================================
-- CONSULTA 17
-- Identificar usuarios con membresía diaria que la han renovado más de 10 veces.
-- =========================================


-- =========================================
-- CONSULTA 18
-- Mostrar usuarios cuya membresía vence en los próximos 7 días.
-- =========================================


-- =========================================
-- CONSULTA 19
-- Listar usuarios que se registraron en el último mes.
-- =========================================


-- =========================================
-- CONSULTA 20
-- Mostrar usuarios que nunca han asistido al coworking (0 accesos).
-- =========================================
