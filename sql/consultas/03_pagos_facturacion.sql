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

-- Fecha de corte de los datos de prueba (las consultas de "hoy" la usan).
-- En producción: SET @hoy = CURDATE();
SET @hoy = DATE('2026-09-30');

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
  AND fecha_pago >= DATE_SUB(@hoy, INTERVAL 3 MONTH);


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

SELECT ROUND(COALESCE(SUM(p.monto * dm.monto_membresias / f.total), 0), 2) AS ingresos_membresias_ultimo_mes
FROM pago p
JOIN factura f ON f.id_factura = p.id_factura
JOIN (SELECT id_factura, SUM(monto) AS monto_membresias
      FROM detalle_factura
      WHERE id_membresia IS NOT NULL
      GROUP BY id_factura) dm ON dm.id_factura = f.id_factura
WHERE p.estado = 'Pagado'
  AND f.total > 0
  AND p.fecha_pago BETWEEN @hoy - INTERVAL 1 MONTH AND @hoy + INTERVAL 1 DAY;

-- =========================================
-- CONSULTA 47
-- Mostrar el total de ingresos por reservas en el último mes.
-- =========================================

SELECT ROUND(COALESCE(SUM(p.monto * dr.monto_reservas / f.total), 0), 2) AS ingresos_reservas_ultimo_mes
FROM pago p
JOIN factura f ON f.id_factura = p.id_factura
JOIN (SELECT id_factura, SUM(monto) AS monto_reservas
      FROM detalle_factura
      WHERE id_reserva IS NOT NULL
      GROUP BY id_factura) dr ON dr.id_factura = f.id_factura
WHERE p.estado = 'Pagado'
  AND f.total > 0
  AND p.fecha_pago BETWEEN @hoy - INTERVAL 1 MONTH AND @hoy + INTERVAL 1 DAY;

-- =========================================
-- CONSULTA 48
-- Mostrar el total de ingresos por servicios adicionales.
-- =========================================

SELECT s.nombre AS servicio,
       ROUND(SUM(d.monto * LEAST(pf.pagado, f.total) / f.total), 2) AS ingresos
FROM detalle_factura d
JOIN factura f ON f.id_factura = d.id_factura
JOIN servicio_contratado sc ON sc.id_contratado = d.id_contratado
JOIN servicio s ON s.id_servicio = sc.id_servicio
JOIN (SELECT id_factura, SUM(monto) AS pagado
      FROM pago WHERE estado = 'Pagado'
      GROUP BY id_factura) pf ON pf.id_factura = f.id_factura
WHERE f.total > 0
GROUP BY s.nombre WITH ROLLUP;

-- =========================================
-- CONSULTA 49
-- Identificar usuarios que nunca han pagado con PayPal.
-- =========================================

SELECT u.id_usuario,
       CONCAT(u.nombre, ' ', u.apellidos) AS nombre_completo
FROM usuario u
WHERE NOT EXISTS (SELECT 1
                  FROM pago p
                  JOIN factura f ON f.id_factura = p.id_factura
                  JOIN metodo_pago mp ON mp.id_metodo = p.id_metodo
                  WHERE f.id_usuario = u.id_usuario
                    AND mp.nombre = 'PayPal'
                    AND p.estado = 'Pagado')
ORDER BY u.id_usuario;

-- =========================================
-- CONSULTA 50
-- Calcular el promedio de gasto por usuario.
-- =========================================

SELECT ROUND(AVG(total_pagado), 2) AS gasto_promedio_por_usuario
FROM (SELECT f.id_usuario, SUM(p.monto) AS total_pagado
      FROM pago p
      JOIN factura f ON f.id_factura = p.id_factura
      WHERE p.estado = 'Pagado' AND f.id_usuario IS NOT NULL
      GROUP BY f.id_usuario) t;

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

SELECT YEAR(@hoy) AS AÑO, SUM(fac.total) AS total_recaudado
FROM factura AS fac
WHERE YEAR(fac.fecha_emision) = YEAR(@hoy) AND estado = 'Pagada';

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