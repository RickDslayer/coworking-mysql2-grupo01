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

-- CONSULTA 41
-- Listar todos los pagos realizados con método tarjeta.
-- =========================================


-- =========================================
-- CONSULTA 42
-- Listar pagos pendientes de usuarios.
-- =========================================


-- =========================================
-- CONSULTA 43
-- Mostrar pagos cancelados en los últimos 3 meses.
-- =========================================


-- =========================================
-- CONSULTA 44
-- Listar facturas generadas por membresías.
-- =========================================


-- =========================================
-- CONSULTA 45
-- Listar facturas generadas por reservas.
-- =========================================


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

SELECT fac.id_usuario, usu.nombre, SUM(fac.total) AS total_pagado 
FROM factura AS fac
JOIN usuario AS usu ON fac.id_usuario = usu.id_usuario
WHERE fac.estado = 'Pagada'
GROUP BY fac.id_usuario, usu.nombre
ORDER BY total_pagado DESC
LIMIT 5;

-- =========================================
-- CONSULTA 52
-- Mostrar facturas con monto mayor a $1000.
-- =========================================

SELECT * FROM factura
WHERE total > 1000
ORDER BY total DESC;

-- =========================================
-- CONSULTA 53
-- Listar pagos realizados después de la fecha de vencimiento.
-- =========================================

SELECT
    pag.id_pago,
    pag.id_factura,
    fac.fecha_vencimiento,
    pag.fecha_pago,
    DATEDIFF(DATE(pag.fecha_pago), fac.fecha_vencimiento) AS dias_de_retraso,
    pag.monto,
    pag.estado
FROM pago AS pag
JOIN factura AS fac ON fac.id_factura = pag.id_factura
WHERE DATE(pag.fecha_pago) > fac.fecha_vencimiento
  AND pag.estado = 'Pagado'
ORDER BY dias_de_retraso DESC;

-- =========================================
-- CONSULTA 54
-- Calcular el total recaudado en el año actual.
-- =========================================

SELECT YEAR(NOW()) AS AÑO, SUM(fac.total) AS total_recaudado
FROM factura AS fac
WHERE YEAR(fac.fecha_emision) = YEAR(NOW()) AND estado = 'Pagada';

-- =========================================
-- CONSULTA 55
-- Mostrar facturas anuladas y su motivo.
-- =========================================

SELECT fac.id_factura, estado, motivo_anulacion 
FROM factura AS fac
WHERE estado = 'Anulada';

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