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

-- =========================================
-- CONSULTA 61
-- Listar todos los accesos registrados hoy.
-- =========================================


-- =========================================
-- CONSULTA 62
-- Mostrar usuarios con más de 20 asistencias en el mes.
-- =========================================


-- =========================================
-- CONSULTA 63
-- Mostrar usuarios que no asistieron en la última semana.
-- =========================================


-- =========================================
-- CONSULTA 64
-- Calcular la asistencia promedio por día de la semana.
-- =========================================


-- =========================================
-- CONSULTA 65
-- Mostrar los 10 usuarios más constantes (más asistencias).
-- =========================================


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
FROM ACCESO a
JOIN USUARIO u ON u.id_usuario = a.id_usuario
JOIN MEMBRESIA m ON m.id_usuario = a.id_usuario
                     AND DATE(a.fecha_hora_entrada) BETWEEN m.fecha_inicio AND m.fecha_fin
JOIN TIPO_MEMBRESIA t ON t.id_tipo = m.id_tipo
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
FROM ACCESO a
JOIN USUARIO u ON u.id_usuario = a.id_usuario
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
FROM ACCESO a
JOIN USUARIO u ON u.id_usuario = a.id_usuario
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
FROM ACCESO a
JOIN USUARIO u ON u.id_usuario = a.id_usuario
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
FROM ACCESO
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


-- =========================================
-- CONSULTA 77
-- Mostrar accesos rechazados por intentos con QR inválido.
-- =========================================


-- =========================================
-- CONSULTA 78
-- Mostrar accesos promedio por usuario.
-- =========================================


-- =========================================
-- CONSULTA 79
-- Identificar usuarios que asisten más en la mañana.
-- =========================================


-- =========================================
-- CONSULTA 80
-- Identificar usuarios que asisten más en la noche.
-- =========================================