/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Procedimientos Almacenados y Control de Acceso / Roles
Archivo: 01_roles.sql
Descripción:
Creación de los 5 roles de Control de Acceso del sistema.
Los permisos de cada rol se asignan en 02_permisos.sql y los
usuarios que reciben cada rol se crean en 03_usuarios.sql.
Requisitos:
Ejecutar previamente DDL, DML, funciones, triggers, procedimientos
y eventos. Ejecutar como root (o un usuario con CREATE ROLE).
Si se vuelve a ejecutar, ejecutar después 02_permisos.sql y
03_usuarios.sql (al borrar un rol, los usuarios lo pierden).
*/
USE coworking_db;

-- ============================================================================
-- SECCIÓN: LIMPIEZA (permite volver a ejecutar el script)
-- ============================================================================
DROP ROLE IF EXISTS 'rol_administrador', 'rol_recepcionista', 'rol_usuario',
                    'rol_gerente', 'rol_contador';

-- ============================================================================
-- SECCIÓN: CONTROL DE ACCESO Y ROLES (Roles 01 a 05)
-- ============================================================================
-- =========================================
-- ROL 01
-- Administrador del Coworking -> Acceso total.
-- =========================================
CREATE ROLE 'rol_administrador';

-- =========================================
-- ROL 02
-- Recepcionista -> Registro de usuarios, asignación de membresías, gestión de reservas.
-- =========================================
CREATE ROLE 'rol_recepcionista';

-- =========================================
-- ROL 03
-- Usuario -> Reservar espacios, consultar historial, descargar facturas.
-- =========================================
CREATE ROLE 'rol_usuario';

-- =========================================
-- ROL 04
-- Gerente Corporativo -> Administrar empleados de su empresa, ver facturación consolidada.
-- =========================================
CREATE ROLE 'rol_gerente';

-- =========================================
-- ROL 05
-- Contador -> Gestión de ingresos y reportes financieros.
-- =========================================
CREATE ROLE 'rol_contador';