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

USE coworking_db;

-- CONSULTA 81
-- Mostrar los usuarios con el mayor gasto acumulado (subconsulta con SUM).
-- =========================================

SELECT u.id_usuario, u.nombre, u.apellidos,
       (SELECT IFNULL(SUM(p.monto), 0)
        FROM pago p
        JOIN factura f ON p.id_factura = f.id_factura
        WHERE f.id_usuario = u.id_usuario
          AND p.estado = 'Pagado') AS gasto_total
FROM usuario u
ORDER BY gasto_total DESC
LIMIT 10;


-- =========================================
-- CONSULTA 82
-- Mostrar los espacios más ocupados considerando reservas confirmadas y asistencias reales.
-- =========================================

SELECT e.id_espacio, e.nombre,
       (SELECT COUNT(*)
        FROM reserva r
        WHERE r.id_espacio = e.id_espacio
          AND r.estado = 'Confirmada') AS reservas_confirmadas,
       (SELECT COUNT(*)
        FROM acceso a
        JOIN reserva r ON a.id_reserva = r.id_reserva
        WHERE r.id_espacio = e.id_espacio
          AND a.resultado = 'Permitido') AS asistencias_reales
FROM espacio e
ORDER BY (reservas_confirmadas + asistencias_reales) DESC
LIMIT 10;


-- =========================================
-- CONSULTA 83
-- Calcular el promedio de ingresos por usuario usando subconsultas.
-- =========================================

SELECT AVG(t.gasto) AS promedio_ingresos_por_usuario
FROM (
    SELECT u.id_usuario,
           (SELECT IFNULL(SUM(p.monto), 0)
            FROM pago p
            JOIN factura f ON p.id_factura = f.id_factura
            WHERE f.id_usuario = u.id_usuario
              AND p.estado = 'Pagado') AS gasto
    FROM usuario u
) t;


-- =========================================
-- CONSULTA 84
-- Listar usuarios que tienen reservas activas y facturas pendientes.
-- =========================================

SELECT id_usuario, nombre, apellidos
FROM usuario
WHERE id_usuario IN (SELECT id_usuario FROM reserva WHERE estado = 'Confirmada')
  AND id_usuario IN (SELECT id_usuario FROM factura WHERE estado = 'Pendiente');


-- =========================================
-- CONSULTA 85
-- Mostrar empresas cuyos empleados generan más del 20% de los ingresos totales.
-- =========================================

SELECT e.id_empresa, e.nombre, SUM(p.monto) AS ingresos_empresa
FROM pago p
JOIN factura f ON p.id_factura = f.id_factura
LEFT JOIN usuario u ON f.id_usuario = u.id_usuario
JOIN empresa e ON e.id_empresa = IFNULL(f.id_empresa, u.id_empresa)
WHERE p.estado = 'Pagado'
GROUP BY e.id_empresa, e.nombre
HAVING SUM(p.monto) > 0.20 * (SELECT SUM(monto) FROM pago WHERE estado = 'Pagado');


-- =========================================
-- CONSULTA 86
-- Mostrar el top 5 de usuarios que más usan servicios adicionales.
-- =========================================


-- =========================================
-- CONSULTA 87
-- Mostrar reservas que generaron facturas mayores al promedio.
-- =========================================


-- =========================================
-- CONSULTA 88
-- Calcular el porcentaje de ocupación global del coworking por mes.
-- =========================================


-- =========================================
-- CONSULTA 89
-- Mostrar usuarios que tienen más horas de reserva que el promedio del sistema.
-- =========================================


-- =========================================
-- CONSULTA 90
-- Mostrar el top 3 de salas más usadas en el último trimestre.
-- =========================================


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