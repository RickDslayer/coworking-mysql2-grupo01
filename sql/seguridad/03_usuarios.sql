/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: Control de Acceso / Roles
Archivo: 03_usuarios.sql
Descripción:
Usuarios MySQL de ejemplo para cada uno de los 5 roles.
El nombre de cada usuario es el mismo de su registro en CUENTA (así las
vistas de 02_permisos.sql saben quién está conectado) y la contraseña
es la que tiene en dml.sql.
Requisitos:
Ejecutar previamente DDL, DML, funciones, triggers, procedimientos,
eventos, 01_roles.sql y 02_permisos.sql.
Ejecutar como root (o un usuario con CREATE USER).
*/
USE coworking_db;

-- ============================================================================
-- SECCIÓN: LIMPIEZA (permite volver a ejecutar el script)
-- ============================================================================
DROP USER IF EXISTS 'admin'@'localhost', 'recepcion1'@'localhost', 'recepcion2'@'localhost',
                    'miguel.ramirez1'@'localhost', 'carlos.munoz2'@'localhost', 'contador'@'localhost';

-- ============================================================================
-- SECCIÓN: USUARIOS POR ROL (Roles 01 a 05)
-- ============================================================================
-- =========================================
-- ROL 01
-- Administrador del Coworking -> Acceso total.
-- =========================================
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'Admin2914#';
GRANT 'rol_administrador' TO 'admin'@'localhost';
SET DEFAULT ROLE 'rol_administrador' TO 'admin'@'localhost';   -- rol activo al iniciar sesión

-- =========================================
-- ROL 02
-- Recepcionista -> Registro de usuarios, asignación de membresías, gestión de reservas.
-- =========================================
CREATE USER 'recepcion1'@'localhost' IDENTIFIED BY 'Recepcion16102#';
CREATE USER 'recepcion2'@'localhost' IDENTIFIED BY 'Recepcion24137#';
GRANT 'rol_recepcionista' TO 'recepcion1'@'localhost', 'recepcion2'@'localhost';
SET DEFAULT ROLE 'rol_recepcionista' TO 'recepcion1'@'localhost', 'recepcion2'@'localhost';   -- rol activo al iniciar sesión

-- =========================================
-- ROL 03
-- Usuario -> Reservar espacios, consultar historial, descargar facturas.
-- =========================================
CREATE USER 'miguel.ramirez1'@'localhost' IDENTIFIED BY 'Miguel4805!';  -- Cliente independiente
GRANT 'rol_usuario' TO 'miguel.ramirez1'@'localhost';
SET DEFAULT ROLE 'rol_usuario' TO 'miguel.ramirez1'@'localhost';   -- rol activo al iniciar sesión

-- =========================================
-- ROL 04
-- Gerente Corporativo -> Administrar empleados de su empresa, ver facturación consolidada.
-- =========================================
CREATE USER 'carlos.munoz2'@'localhost' IDENTIFIED BY 'Carlos4292#';  -- Gerente de Andes Software SAS
GRANT 'rol_gerente' TO 'carlos.munoz2'@'localhost';
SET DEFAULT ROLE 'rol_gerente' TO 'carlos.munoz2'@'localhost';   -- rol activo al iniciar sesión

-- =========================================
-- ROL 05
-- Contador -> Gestión de ingresos y reportes financieros.
-- =========================================
CREATE USER 'contador'@'localhost' IDENTIFIED BY 'Contador5620*';
GRANT 'rol_contador' TO 'contador'@'localhost';
SET DEFAULT ROLE 'rol_contador' TO 'contador'@'localhost';   -- rol activo al iniciar sesión

FLUSH PRIVILEGES;

-- ============================================================================
-- SECCIÓN: VERIFICACIÓN
-- ============================================================================
-- Ver los permisos de un rol:
--   SHOW GRANTS FOR 'rol_recepcionista';
-- Ver los permisos efectivos de un usuario (incluyendo su rol):
--   SHOW GRANTS FOR 'recepcion1'@'localhost' USING 'rol_recepcionista';
--
-- Probar como cliente:
--   mysql -u miguel.ramirez1 -p coworking_db
--   SELECT * FROM v_mis_reservas;          -- solo ve sus reservas
--   SELECT * FROM RESERVA;                 -- error: sin permiso sobre la tabla
--
-- Probar como gerente:
--   mysql -u carlos.munoz2 -p coworking_db
--   SELECT * FROM v_empleados;             -- solo empleados de Andes Software SAS
--   SELECT * FROM v_facturas_empresa;      -- facturas consolidadas + individuales
--
-- Crear un usuario nuevo y asignarle un rol:
--   1. Registrar su CUENTA con el mismo username (rol correspondiente).
--   2. CREATE USER 'nuevo.usuario'@'localhost' IDENTIFIED BY 'Clave123*';
--   3. GRANT 'rol_usuario' TO 'nuevo.usuario'@'localhost';
--   4. SET DEFAULT ROLE 'rol_usuario' TO 'nuevo.usuario'@'localhost';