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

-- CONSULTA 61
-- Listar todos los accesos registrados hoy.
-- =========================================

SELECT a.id_acceso, u.nombre, u.apellidos, a.metodo,
       a.fecha_hora_entrada, a.fecha_hora_salida, a.resultado
FROM acceso a
LEFT JOIN usuario u ON a.id_usuario = u.id_usuario
WHERE DATE(a.fecha_hora_entrada) = CURDATE();


-- =========================================
-- CONSULTA 62
-- Mostrar usuarios con más de 20 asistencias en el mes.
-- =========================================

-- Una asistencia = un acceso con resultado 'Permitido'.
SELECT u.id_usuario, u.nombre, u.apellidos, COUNT(*) AS asistencias
FROM acceso a
JOIN usuario u ON a.id_usuario = u.id_usuario
WHERE a.resultado = 'Permitido'
  AND MONTH(a.fecha_hora_entrada) = MONTH(CURDATE())
  AND YEAR(a.fecha_hora_entrada) = YEAR(CURDATE())
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
      AND fecha_hora_entrada >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
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


-- =========================================
-- CONSULTA 67
-- Mostrar usuarios que accedieron sin membresía activa (rechazados).
-- =========================================


-- =========================================
-- CONSULTA 68
-- Listar usuarios que solo acceden los fines de semana.
-- =========================================


-- =========================================
-- CONSULTA 69
-- Mostrar usuarios que accedieron más de 2 veces en el mismo día.
-- =========================================


-- =========================================
-- CONSULTA 70
-- Mostrar el total de accesos diarios en el último mes.
-- =========================================


-- =========================================
-- CONSULTA 71
-- Mostrar usuarios que han accedido pero no tienen reservas.
-- =========================================


-- =========================================
-- CONSULTA 72
-- Mostrar los días con más concurrencia en el coworking.
-- =========================================



-- =========================================
-- CONSULTA 73
-- Mostrar usuarios que entraron pero no registraron salida.
-- =========================================


-- =========================================
-- CONSULTA 74
-- Mostrar accesos de usuarios con membresía vencida.
-- =========================================


-- =========================================
-- CONSULTA 75
-- Mostrar accesos de usuarios corporativos por empresa.
-- =========================================


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