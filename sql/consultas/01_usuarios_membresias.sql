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

SELECT u.id_usuario,
       CONCAT(u.nombre, ' ', u.apellidos) AS nombre_completo,
       u.fecha_registro,
       TIMESTAMPDIFF(MONTH, u.fecha_registro, @hoy) AS meses_antiguedad
FROM USUARIO u
ORDER BY u.fecha_registro ASC
LIMIT 10;

-- =========================================
-- CONSULTA 07
-- Listar usuarios que pertenecen a una empresa específica.
-- =========================================

SELECT u.id_usuario,
       CONCAT(u.nombre, ' ', u.apellidos) AS nombre_completo,
       u.email,
       u.telefono
FROM USUARIO u
JOIN EMPRESA e ON e.id_empresa = u.id_empresa
WHERE e.nombre = 'Andes Software SAS'
ORDER BY u.apellidos;

-- =========================================
-- CONSULTA 08
-- Contar cuántos usuarios están asociados a cada empresa.
-- =========================================

SELECT e.id_empresa,
       e.nombre AS empresa,
       COUNT(u.id_usuario) AS total_usuarios
FROM EMPRESA e
LEFT JOIN USUARIO u ON u.id_empresa = e.id_empresa
GROUP BY e.id_empresa, e.nombre
ORDER BY total_usuarios DESC;

-- =========================================
-- CONSULTA 09
-- Mostrar usuarios que nunca han hecho una reserva.
-- =========================================

SELECT u.id_usuario,
       CONCAT(u.nombre, ' ', u.apellidos) AS nombre_completo,
       u.fecha_registro
FROM USUARIO u
WHERE NOT EXISTS (SELECT 1 FROM RESERVA r WHERE r.id_usuario = u.id_usuario);

-- =========================================
-- CONSULTA 10
-- Mostrar usuarios con más de 5 reservas activas en el mes.
-- =========================================

SELECT u.id_usuario,
       CONCAT(u.nombre, ' ', u.apellidos) AS nombre_completo,
       COUNT(*) AS reservas_mes
FROM USUARIO u
JOIN RESERVA r ON r.id_usuario = u.id_usuario
WHERE r.estado IN ('Pendiente de Confirmacion', 'Confirmada', 'Finalizada')
  AND YEAR(r.fecha_inicio)  = YEAR(@hoy)
  AND MONTH(r.fecha_inicio) = MONTH(@hoy)
GROUP BY u.id_usuario, nombre_completo
HAVING COUNT(*) > 5;

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

- =========================================
-- CONSULTA 16
-- Mostrar usuarios con membresía Corporativa y su empresa.
-- =========================================
SELECT u.nombre AS nombre_empleado,
u.apellidos AS apellid_empleado,
e.nombre AS nombre_empresa,
e.nit 
FROM usuario AS u
INNER JOIN empresa AS e
ON e.id_empresa = u.id_empresa
WHERE e.id_empresa;

-- =========================================
-- CONSULTA 17
-- Identificar usuarios con membresía diaria que la han renovado más de 10 veces.
-- =========================================

SELECT
    u.id_usuario,
    u.nombre,
    u.apellidos,
    COUNT(m.id_membresia) AS total_renovaciones
FROM membresia AS m
INNER JOIN  usuario AS u
    ON u.id_usuario = m.id_usuario
INNER JOIN tipo_membresia AS tm
    ON m.id_tipo = tm.id_tipo
WHERE tm.nombre = 'Diaria'
GROUP BY 
    u.id_usuario,
    u.nombre,
    u.apellidos
HAVING COUNT(m.id_membresia) > 10
ORDER BY total_renovaciones DESC;


-- =========================================
-- CONSULTA 18
-- Mostrar usuarios cuya membresía vence en los próximos 7 días.
-- =========================================

SELECT
    u.id_usuario,
    u.nombre,
    m.fecha_fin,
    DATEDIFF(m.fecha_fin, CURDATE()) AS dias_restantes
FROM membresia AS m
INNER JOIN usuario AS u
    ON u.id_usuario = m.id_usuario
WHERE m.estado = 'activa'
  AND m.fecha_fin BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
ORDER BY m.fecha_fin;

-- =========================================
-- CONSULTA 19
-- Listar usuarios que se registraron en el último mes.
-- =========================================

SELECT id_usuario, 
nombre , 
fecha_registro
FROM usuario 
WHERE YEAR(fecha_registro) = YEAR(NOW()) AND MONTH(fecha_registro) = MONTH(NOW()) -1 ;


-- =========================================
-- CONSULTA 20
-- Mostrar usuarios que nunca han asistido al coworking (0 accesos).
-- =========================================
SELECT
    u.id_usuario,
    u.nombre,
    u.apellidos
FROM usuario AS u
LEFT JOIN acceso AS a
    ON a.id_usuario = u.id_usuario
WHERE a.id_acceso IS NULL;