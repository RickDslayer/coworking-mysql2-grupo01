/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Accesos y Asistencias
Archivo: 04_accesos_asistencias.sql
Descripción:
Consultas 61 a 80 del módulo.

Requisitos:
Ejecutar previamente DDL y DML.
*/

USE coworking_db;

-- Fecha de corte de los datos de prueba (las consultas de "hoy" la usan).
-- En producción: SET @hoy = CURDATE();
SET @hoy = DATE('2026-09-30');

-- =========================================
-- CONSULTA 61
-- Listar todos los accesos registrados hoy.
-- =========================================

SELECT a.id_acceso, u.nombre, u.apellidos, a.metodo,
       a.fecha_hora_entrada, a.fecha_hora_salida, a.resultado
FROM acceso a
LEFT JOIN usuario u ON a.id_usuario = u.id_usuario
WHERE DATE(a.fecha_hora_entrada) = @hoy;


-- =========================================
-- CONSULTA 62
-- Mostrar usuarios con más de 20 asistencias en el mes.
-- =========================================

-- Una asistencia = un acceso con resultado 'Permitido'.
SELECT u.id_usuario, u.nombre, u.apellidos, COUNT(*) AS asistencias
FROM acceso a
JOIN usuario u ON a.id_usuario = u.id_usuario
WHERE a.resultado = 'Permitido'
  AND MONTH(a.fecha_hora_entrada) = MONTH(@hoy)
  AND YEAR(a.fecha_hora_entrada) = YEAR(@hoy)
GROUP BY u.id_usuario, u.nombre, u.apellidos
HAVING COUNT(*) > 20;


-- =========================================
-- CONSULTA 63
-- Mostrar usuarios que no asistieron en la última semana.
-- =========================================

SELECT id_usuario, nombre, apellidos
FROM usuario
WHERE id_usuario NOT IN (
    SELECT id_usuario
    FROM acceso
    WHERE resultado = 'Permitido'
      AND id_usuario IS NOT NULL
      AND fecha_hora_entrada >= DATE_SUB(@hoy, INTERVAL 7 DAY)
);


-- =========================================
-- CONSULTA 64
-- Calcular la asistencia promedio por día de la semana.
-- =========================================

SELECT t.num_dia,
       CASE t.num_dia
           WHEN 0 THEN 'Lunes'
           WHEN 1 THEN 'Martes'
           WHEN 2 THEN 'Miercoles'
           WHEN 3 THEN 'Jueves'
           WHEN 4 THEN 'Viernes'
           WHEN 5 THEN 'Sabado'
           WHEN 6 THEN 'Domingo'
       END AS dia_semana,
       AVG(t.total) AS promedio_asistencias
FROM (
    SELECT DATE(fecha_hora_entrada) AS fecha,
           WEEKDAY(fecha_hora_entrada) AS num_dia,
           COUNT(*) AS total
    FROM acceso
    WHERE resultado = 'Permitido'
    GROUP BY DATE(fecha_hora_entrada), WEEKDAY(fecha_hora_entrada)
) t
GROUP BY t.num_dia
ORDER BY t.num_dia;


-- =========================================
-- CONSULTA 65
-- Mostrar los 10 usuarios más constantes (más asistencias).
-- =========================================

SELECT u.id_usuario, u.nombre, u.apellidos, COUNT(*) AS asistencias
FROM acceso a
JOIN usuario u ON a.id_usuario = u.id_usuario
WHERE a.resultado = 'Permitido'
GROUP BY u.id_usuario, u.nombre, u.apellidos
ORDER BY asistencias DESC
LIMIT 10;


-- =========================================
-- CONSULTA 66
-- Mostrar accesos fuera del horario permitido.
-- =========================================

SELECT a.id_acceso,
       CONCAT(u.nombre, ' ', u.apellidos) AS usuario,
       t.nombre AS tipo_membresia,
       a.fecha_hora_entrada,
       t.hora_acceso_inicio,
       t.hora_acceso_fin,
       a.resultado
FROM acceso a
JOIN usuario u ON u.id_usuario = a.id_usuario
JOIN membresia m ON m.id_usuario = a.id_usuario
                     AND DATE(a.fecha_hora_entrada) BETWEEN m.fecha_inicio AND m.fecha_fin
JOIN tipo_membresia t ON t.id_tipo = m.id_tipo
WHERE TIME(a.fecha_hora_entrada) NOT BETWEEN t.hora_acceso_inicio AND t.hora_acceso_fin
ORDER BY a.fecha_hora_entrada;

-- =========================================
-- CONSULTA 67
-- Mostrar usuarios que accedieron sin membresía activa (rechazados).
-- =========================================

SELECT u.id_usuario,
       CONCAT(u.nombre, ' ', u.apellidos) AS nombre_completo,
       a.fecha_hora_entrada AS intento,
       a.motivo_rechazo
FROM acceso a
JOIN usuario u ON u.id_usuario = a.id_usuario
WHERE a.resultado = 'Rechazado'
  AND a.motivo_rechazo IN ('Membresia vencida', 'Membresia suspendida', 'Membresia inactiva')
ORDER BY a.fecha_hora_entrada DESC;

-- =========================================
-- CONSULTA 68
-- Listar usuarios que solo acceden los fines de semana.
-- =========================================

SELECT u.id_usuario,
       CONCAT(u.nombre, ' ', u.apellidos) AS nombre_completo,
       COUNT(*) AS asistencias
FROM acceso a
JOIN usuario u ON u.id_usuario = a.id_usuario
WHERE a.resultado = 'Permitido'
GROUP BY u.id_usuario, nombre_completo
HAVING SUM(WEEKDAY(a.fecha_hora_entrada) < 5) = 0;

-- =========================================
-- CONSULTA 69
-- Mostrar usuarios que accedieron más de 2 veces en el mismo día.
-- =========================================

SELECT u.id_usuario,
       CONCAT(u.nombre, ' ', u.apellidos) AS nombre_completo,
       DATE(a.fecha_hora_entrada) AS fecha,
       COUNT(*) AS ingresos
FROM acceso a
JOIN usuario u ON u.id_usuario = a.id_usuario
WHERE a.resultado = 'Permitido'
GROUP BY u.id_usuario, nombre_completo, fecha
HAVING COUNT(*) > 2;

-- =========================================
-- CONSULTA 70
-- Mostrar el total de accesos diarios en el último mes.
-- =========================================

SELECT DATE(fecha_hora_entrada) AS fecha,
       COUNT(*) AS total_accesos,
       SUM(resultado = 'Permitido') AS permitidos,
       SUM(resultado = 'Rechazado') AS rechazados
FROM acceso
WHERE DATE(fecha_hora_entrada) BETWEEN @hoy - INTERVAL 1 MONTH AND @hoy
GROUP BY fecha
ORDER BY fecha;

-- =========================================
-- CONSULTA 71
-- Mostrar usuarios que han accedido pero no tienen reservas.
-- =========================================

SELECT
    usu.id_usuario,
    usu.nombre,
    usu.apellidos
FROM usuario AS usu
WHERE usu.id_usuario IN (SELECT acc.id_usuario
                           FROM acceso AS acc
                          WHERE acc.resultado = 'Permitido')
  AND usu.id_usuario NOT IN (SELECT res.id_usuario
                               FROM reserva AS res)
ORDER BY usu.id_usuario;

-- =========================================
-- CONSULTA 72
-- Mostrar los días con más concurrencia en el coworking.
-- =========================================

SELECT
    DATE(acc.fecha_hora_entrada) AS dia,
    COUNT(*) AS total_ingresos,
    COUNT(DISTINCT acc.id_usuario) AS usuarios_distintos
FROM acceso AS acc
WHERE acc.resultado = 'Permitido'
GROUP BY DATE(acc.fecha_hora_entrada)
ORDER BY total_ingresos DESC
LIMIT 10;

-- =========================================
-- CONSULTA 73
-- Mostrar usuarios que entraron pero no registraron salida.
-- =========================================

SELECT
    usu.id_usuario,
    usu.nombre,
    usu.apellidos,
    acc.id_acceso,
    acc.fecha_hora_entrada
FROM acceso AS acc
JOIN usuario AS usu ON usu.id_usuario = acc.id_usuario
WHERE acc.fecha_hora_salida IS NULL
  AND acc.resultado = 'Permitido'
ORDER BY acc.fecha_hora_entrada;

-- =========================================
-- CONSULTA 74
-- Mostrar accesos de usuarios con membresía vencida.
-- =========================================

SELECT
    usu.id_usuario,
    usu.nombre,
    usu.apellidos,
    acc.id_acceso,
    acc.fecha_hora_entrada,
    acc.resultado,
    acc.motivo_rechazo
FROM acceso AS acc
JOIN usuario AS usu ON usu.id_usuario = acc.id_usuario
WHERE EXISTS (SELECT 1
                FROM membresia AS mem
               WHERE mem.id_usuario = usu.id_usuario
                 AND mem.estado = 'Vencida')
  AND NOT EXISTS (SELECT 1
                    FROM membresia AS mem
                   WHERE mem.id_usuario = usu.id_usuario
                     AND mem.estado IN ('Activa', 'Suspendida'))
ORDER BY usu.id_usuario, acc.fecha_hora_entrada;

-- =========================================
-- CONSULTA 75
-- Mostrar accesos de usuarios corporativos por empresa.
-- =========================================

SELECT
    emp.id_empresa,
    emp.nombre AS empresa,
    COUNT(acc.id_acceso) AS total_accesos,
    COUNT(DISTINCT usu.id_usuario) AS usuarios_que_accedieron
FROM acceso AS acc
INNER JOIN usuario AS usu ON usu.id_usuario = acc.id_usuario
INNER JOIN empresa AS emp ON emp.id_empresa = usu.id_empresa
WHERE acc.resultado = 'Permitido'
GROUP BY emp.id_empresa, emp.nombre
ORDER BY total_accesos DESC;

-- =========================================
-- CONSULTA 76
-- Mostrar clientes que nunca han usado el coworking a pesar de pagar membresía.
-- =========================================

SELECT DISTINCT
    u.id_usuario,
    CONCAT ( u.nombre, ' ' ,u.apellidos) AS nombre_completo
FROM usuario AS u
INNER JOIN membresia AS m ON m.id_usuario = u.id_usuario
INNER JOIN detalle_factura AS df ON df.id_membresia = m.id_membresia
INNER JOIN factura AS f ON f.id_factura = df.id_factura
INNER JOIN pago AS p ON p.id_factura = f.id_factura
                    AND p.estado = 'Pagado'
WHERE NOT EXISTS (
    SELECT a.id_acceso
    FROM acceso AS a
    WHERE a.id_usuario = u.id_usuario
      AND a.resultado = 'Permitido'
);



-- =========================================
-- CONSULTA 77
-- Mostrar accesos rechazados por intentos con QR inválido.
-- =========================================

SELECT
    a.id_acceso,
    a.id_usuario,
    a.codigo_leido,
    a.fecha_hora_entrada AS fecha_intento,
    a.motivo_rechazo
FROM acceso AS a
WHERE a.resultado = 'Rechazado'
  AND a.metodo = 'QR'
  AND a.motivo_rechazo LIKE 'QR invalido'


-- =========================================
-- CONSULTA 78
-- Mostrar accesos promedio por usuario.
-- =========================================

SELECT
    ROUND(COUNT(a.id_acceso) / COUNT(DISTINCT u.id_usuario), 0) AS accesos_promedio_usuario
FROM usuario AS u
LEFT JOIN acceso AS a
    ON a.id_usuario = u.id_usuario
   AND a.resultado = 'Permitido';


-- =========================================
-- CONSULTA 79
-- Identificar usuarios que asisten más en la mañana.
-- =========================================

SELECT
    u.id_usuario,
    CONCAT ( u.nombre, ' ' ,u.apellidos) AS nombre_completo,
    SUM(HOUR(a.fecha_hora_entrada) < 12) AS visitas_mañana
FROM usuario AS u
INNER JOIN acceso AS a ON a.id_usuario = u.id_usuario
WHERE a.resultado = 'Permitido'
GROUP BY u.id_usuario, nombre_completo
HAVING visitas_mañana > 0
ORDER BY visitas_mañana DESC;


-- =========================================
-- CONSULTA 80
-- Identificar usuarios que asisten más en la noche.
-- =========================================

SELECT
    u.id_usuario,
    CONCAT ( u.nombre, ' ' ,u.apellidos) AS nombre_completo,
    SUM(HOUR(a.fecha_hora_entrada) >= 18) AS visitas_noche
FROM usuario AS u
INNER JOIN acceso AS a ON a.id_usuario = u.id_usuario
WHERE a.resultado = 'Permitido'
GROUP BY u.id_usuario, nombre_completo
HAVING visitas_noche > 0
ORDER BY visitas_noche DESC;
