/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Pagos y Facturación
Archivo: 03_pagos_facturacion.sql
Descripción:
Consultas 41 a 60 del módulo.

Requisitos:
Ejecutar previamente DDL y DML.
*/

USE coworking_db;

-- CONSULTA 41
-- Listar todos los pagos realizados con método tarjeta.
-- =========================================

SELECT p.id_pago, p.id_factura, mp.nombre AS metodo, p.monto, p.fecha_pago
FROM pago p
JOIN metodo_pago mp ON p.id_metodo = mp.id_metodo
WHERE mp.nombre = 'Tarjeta'
  AND p.estado = 'Pagado';


-- =========================================
-- CONSULTA 42
-- Listar pagos pendientes de usuarios.
-- =========================================

-- LEFT JOIN porque un pago puede no tener factura (o usuario) todavía.
SELECT p.id_pago, p.monto, p.fecha_pago, u.nombre, u.apellidos
FROM pago p
LEFT JOIN factura f ON p.id_factura = f.id_factura
LEFT JOIN usuario u ON f.id_usuario = u.id_usuario
WHERE p.estado = 'Pendiente';


-- =========================================
-- CONSULTA 43
-- Mostrar pagos cancelados en los últimos 3 meses.
-- =========================================

SELECT id_pago, id_factura, monto, fecha_pago, estado
FROM pago
WHERE estado = 'Cancelado'
  AND fecha_pago >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH);


-- =========================================
-- CONSULTA 44
-- Listar facturas generadas por membresías.
-- =========================================

-- DISTINCT para que la factura no salga repetida si tiene varias líneas.
SELECT DISTINCT f.id_factura, f.fecha_emision, f.total, f.estado
FROM factura f
JOIN detalle_factura d ON f.id_factura = d.id_factura
WHERE d.id_membresia IS NOT NULL;


-- =========================================
-- CONSULTA 45
-- Listar facturas generadas por reservas.
-- =========================================

SELECT DISTINCT f.id_factura, f.fecha_emision, f.total, f.estado
FROM factura f
JOIN detalle_factura d ON f.id_factura = d.id_factura
WHERE d.id_reserva IS NOT NULL;


-- =========================================
-- CONSULTA 46
-- Mostrar el total de ingresos por membresías en el último mes.
-- =========================================


-- =========================================
-- CONSULTA 47
-- Mostrar el total de ingresos por reservas en el último mes.
-- =========================================


-- =========================================
-- CONSULTA 48
-- Mostrar el total de ingresos por servicios adicionales.
-- =========================================


-- =========================================
-- CONSULTA 49
-- Identificar usuarios que nunca han pagado con PayPal.
-- =========================================


-- =========================================
-- CONSULTA 50
-- Calcular el promedio de gasto por usuario.
-- =========================================


-- =========================================
-- CONSULTA 51
-- Mostrar el top 5 de usuarios que más han pagado en total.
-- =========================================


-- =========================================
-- CONSULTA 52
-- Mostrar facturas con monto mayor a $1000.
-- =========================================


-- =========================================
-- CONSULTA 53
-- Listar pagos realizados después de la fecha de vencimiento.
-- =========================================


-- =========================================
-- CONSULTA 54
-- Calcular el total recaudado en el año actual.
-- =========================================


-- =========================================
-- CONSULTA 55
-- Mostrar facturas anuladas y su motivo.
-- =========================================


-- =========================================
-- CONSULTA 56
-- Mostrar usuarios con facturas pendientes mayores a $200.
-- =========================================


-- =========================================
-- CONSULTA 57
-- Mostrar usuarios que han pagado más de una vez el mismo servicio.
-- =========================================


-- =========================================
-- CONSULTA 58
-- Listar ingresos por cada método de pago.
-- =========================================


-- =========================================
-- CONSULTA 59
-- Mostrar facturación acumulada por empresa.
-- =========================================


-- =========================================
-- CONSULTA 60
-- Mostrar ingresos netos por mes del último año.
-- =========================================