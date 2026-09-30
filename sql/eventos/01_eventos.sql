/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Eventos SQL
Archivo: 04_eventos_sql.sql
Descripción:
Estructura y comentarios organizativos para los 20 Eventos SQL del proyecto.
Requisitos:
Ejecutar previamente DDL y DML.
*/

USE coworking_db;

--============================================================================
-- SECCIÓN: EVENTOS SQL (Eventos 01 a 20)
--============================================================================
-- Submódulo: Membresías (Eventos 01 a 05)
-- =========================================
-- CONSULTA 01
-- Revisar diariamente membresías vencidas y actualizarlas a estado "Vencida".
-- =========================================
-- =========================================
-- CONSULTA 02
-- Enviar recordatorio de renovación 5 días antes de vencer la membresía.
-- =========================================
-- =========================================
-- CONSULTA 03
-- Suspender membresías inactivas después de 30 días sin pago.
-- =========================================
-- =========================================
-- CONSULTA 04
-- Generar reporte semanal de nuevas membresías al administrador.
-- =========================================
-- =========================================
-- CONSULTA 05
-- Notificar membresías suspendidas cada día a recepción.
-- =========================================
-- Submódulo: Reservas (Eventos 06 a 10)
-- =========================================
-- CONSULTA 06
-- Cancelar automáticamente reservas no confirmadas después de 2 horas.
-- =========================================
-- =========================================
-- CONSULTA 07
-- Enviar recordatorio 1 hora antes de la reserva a cada usuario.
-- =========================================
-- =========================================
-- CONSULTA 08
-- Eliminar reservas pasadas no asistidas después de 7 días.
-- =========================================
-- =========================================
-- CONSULTA 09
-- Generar reporte semanal de ocupación de espacios.
-- =========================================
-- =========================================
-- CONSULTA 10
-- Liberar reservas bloqueadas si no se inicia en los primeros 15 minutos.
-- =========================================
-- Submódulo: Pagos y Facturación (Eventos 11 a 15)
-- =========================================
-- CONSULTA 11
-- Enviar recordatorio de pago pendiente cada 3 días.
-- =========================================
-- =========================================
-- CONSULTA 12
-- Bloquear servicios adicionales si existen facturas vencidas mayores a 10 días.
-- =========================================
-- =========================================
-- CONSULTA 13
-- Generar resumen de facturación mensual automáticamente.
-- =========================================
-- =========================================
-- CONSULTA 14
-- Aplicar recargos automáticos a facturas vencidas después de 15 días.
-- =========================================
-- =========================================
-- CONSULTA 15
-- Enviar al contador un reporte de ingresos acumulados cada fin de mes.
-- =========================================
-- Submódulo: Accesos y Asistencias (Eventos 16 a 20)
-- =========================================
-- CONSULTA 16
-- Eliminar accesos antiguos (más de 1 año) automáticamente.
-- =========================================
-- =========================================
-- CONSULTA 17
-- Enviar reporte diario de asistencias al administrador.
-- =========================================
-- =========================================
-- CONSULTA 18
-- Generar reporte semanal de usuarios inactivos (sin accesos).
-- =========================================
-- =========================================
-- CONSULTA 19
-- Alertar accesos fuera de horario laboral cada día.
-- =========================================
-- =========================================
-- CONSULTA 20
-- Enviar reporte de top 10 usuarios más frecuentes cada mes.
-- =========================================