/*
Proyecto: Gestión de Coworking
Grupo: 01
Módulo: CREACION DE BASE DE DATOS
Archivo: 01_estructura.sql
Descripción: Crear la base de datos y todas sus tablas (23)
Ejecutar previamente DDL y DML.
*/
-- =====================================================================
--  MÓDULO 0: CREACION DE BASE DE DATOS
-- =====================================================================

DROP DATABASE IF EXISTS coworking_db;
CREATE DATABASE coworking_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE coworking_db;

-- =====================================================================
--  MÓDULO 1: USUARIOS Y SEGURIDAD
-- =====================================================================

-- Empresas a las que pertenecen los clientes corporativos
CREATE TABLE empresa (
    id_empresa      INT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    nit             VARCHAR(20)  NOT NULL,
    email_contacto  VARCHAR(100) NOT NULL DEFAULT 'N/A',
    CONSTRAINT uq_empresa_nit UNIQUE (nit)
) ENGINE = InnoDB;

-- Clientes del coworking.
CREATE TABLE usuario (
    id_usuario        INT AUTO_INCREMENT PRIMARY KEY,
    documento         VARCHAR(20)  NOT NULL,
    nombre            VARCHAR(60)  NOT NULL,
    apellidos         VARCHAR(80)  NOT NULL DEFAULT 'N/A',
    fecha_nacimiento  DATE         NOT NULL,
    email             VARCHAR(100) NOT NULL DEFAULT 'N/A',
    telefono          VARCHAR(20)  NOT NULL DEFAULT 'N/A',
    fecha_registro    DATE         NOT NULL DEFAULT (CURRENT_DATE),
    ultimo_acceso     DATETIME     NULL,
    id_empresa        INT          NULL,
    CONSTRAINT uq_usuario_documento UNIQUE (documento),
    CONSTRAINT fk_usuario_empresa FOREIGN KEY (id_empresa)
        REFERENCES empresa (id_empresa)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB;


-- Cuentas de acceso al sistema. El rol se corresponde con los roles de MySQL.
CREATE TABLE cuenta (
    id_cuenta      INT AUTO_INCREMENT PRIMARY KEY,
    username       VARCHAR(50)  NOT NULL,
    password_hash  VARCHAR(255) NOT NULL,
    rol            ENUM('Administrador','Recepcionista','Usuario','Gerente','Contador') NOT NULL,
    activo         BOOLEAN      NOT NULL DEFAULT TRUE,
    id_usuario     INT          NULL,
    id_empresa     INT          NULL,
    CONSTRAINT uq_cuenta_username UNIQUE (username),
    CONSTRAINT uq_cuenta_usuario  UNIQUE (id_usuario),
    CONSTRAINT fk_cuenta_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cuenta_empresa FOREIGN KEY (id_empresa)
        REFERENCES empresa (id_empresa)
        ON DELETE RESTRICT ON UPDATE RESTRICT,  
    CONSTRAINT chk_cuenta_gerente CHECK (rol <> 'Gerente' OR id_empresa IS NOT NULL)
) ENGINE = InnoDB;


-- =====================================================================
--  MÓDULO 2: MEMBRESÍAS
-- =====================================================================

-- Catálogo de tipos de membresía con su duración y horario de acceso permitido
CREATE TABLE tipo_membresia (
    id_tipo             INT AUTO_INCREMENT PRIMARY KEY,
    nombre              ENUM('Diaria','Mensual','Corporativa','Premium') NOT NULL,
    precio              DECIMAL(10,2) NOT NULL,
    duracion_dias       INT           NOT NULL,
    hora_acceso_inicio  TIME          NOT NULL DEFAULT '07:00:00',
    hora_acceso_fin     TIME          NOT NULL DEFAULT '21:00:00',
    CONSTRAINT uq_tipo_membresia_nombre UNIQUE (nombre),
    CONSTRAINT chk_tipo_membresia_precio   CHECK (precio >= 0),
    CONSTRAINT chk_tipo_membresia_duracion CHECK (duracion_dias > 0),
    CONSTRAINT chk_tipo_membresia_horario  CHECK (hora_acceso_fin > hora_acceso_inicio)
) ENGINE = InnoDB;

-- Membresías de cada cliente. 
CREATE TABLE membresia (
    id_membresia  INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario    INT  NOT NULL,
    id_tipo       INT  NOT NULL,
    estado        ENUM('Pendiente','Activa','Suspendida','Vencida') NOT NULL DEFAULT 'Pendiente',
    fecha_inicio  DATE NOT NULL,
    fecha_fin     DATE NOT NULL,
    CONSTRAINT fk_membresia_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_membresia_tipo FOREIGN KEY (id_tipo)
        REFERENCES tipo_membresia (id_tipo)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_membresia_fechas CHECK (fecha_fin > fecha_inicio)
) ENGINE = InnoDB;

-- Historial de cambios de tipo de membresía (lo llena un trigger)
CREATE TABLE log_membresia (
    id_log            INT AUTO_INCREMENT PRIMARY KEY,
    id_membresia      INT          NULL,
    id_tipo_anterior  INT          NOT NULL,
    id_tipo_nuevo     INT          NOT NULL,
    fecha_cambio      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario_bd        VARCHAR(100) NOT NULL DEFAULT 'sistema',
    CONSTRAINT fk_log_membresia_membresia FOREIGN KEY (id_membresia)
        REFERENCES membresia (id_membresia)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_log_membresia_tipo_ant FOREIGN KEY (id_tipo_anterior)
        REFERENCES tipo_membresia (id_tipo)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_log_membresia_tipo_nue FOREIGN KEY (id_tipo_nuevo)
        REFERENCES tipo_membresia (id_tipo)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;


-- =====================================================================
--  MÓDULO 3: ESPACIOS Y RESERVAS
-- =====================================================================

-- Catálogo de tipos de espacio
CREATE TABLE tipo_espacio (
    id_tipo_espacio  INT AUTO_INCREMENT PRIMARY KEY,
    nombre           ENUM('Escritorio flexible','Oficina privada','Sala de reuniones','Sala de eventos') NOT NULL,
    CONSTRAINT uq_tipo_espacio_nombre UNIQUE (nombre)
) ENGINE = InnoDB;

-- Espacios físicos que se pueden reservar
CREATE TABLE espacio (
    id_espacio        INT AUTO_INCREMENT PRIMARY KEY,
    id_tipo_espacio   INT           NOT NULL,
    nombre            VARCHAR(60)   NOT NULL,
    capacidad_maxima  INT           NOT NULL,
    precio_hora       DECIMAL(10,2) NOT NULL,
    estado            ENUM('Disponible','Mantenimiento','Inactivo') NOT NULL DEFAULT 'Disponible',
    CONSTRAINT uq_espacio_nombre UNIQUE (nombre),
    CONSTRAINT fk_espacio_tipo FOREIGN KEY (id_tipo_espacio)
        REFERENCES tipo_espacio (id_tipo_espacio)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_espacio_capacidad CHECK (capacidad_maxima > 0),
    CONSTRAINT chk_espacio_precio    CHECK (precio_hora >= 0)
) ENGINE = InnoDB;

-- Horario de disponibilidad de cada espacio por día (1 = lunes ... 7 = domingo)
CREATE TABLE horario_espacio (
    id_horario     INT AUTO_INCREMENT PRIMARY KEY,
    id_espacio     INT     NOT NULL,
    dia_semana     TINYINT NOT NULL,
    hora_apertura  TIME    NOT NULL,
    hora_cierre    TIME    NOT NULL,
    CONSTRAINT uq_horario_espacio_dia UNIQUE (id_espacio, dia_semana),
    CONSTRAINT fk_horario_espacio FOREIGN KEY (id_espacio)
        REFERENCES espacio (id_espacio)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_horario_dia  CHECK (dia_semana BETWEEN 1 AND 7),
    CONSTRAINT chk_horario_horas CHECK (hora_cierre > hora_apertura)
) ENGINE = InnoDB;

-- Reservas de espacios
CREATE TABLE reserva (
    id_reserva            INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario            INT      NOT NULL,
    id_espacio            INT      NOT NULL,
    fecha_inicio          DATETIME NOT NULL,
    fecha_fin             DATETIME NOT NULL,
    num_asistentes        INT      NOT NULL DEFAULT 1,
    estado                ENUM('Pendiente de Confirmacion','Confirmada','Cancelada','Finalizada','No Show','Liberada')
                          NOT NULL DEFAULT 'Pendiente de Confirmacion',
    fecha_creacion        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    recordatorio_enviado  BOOLEAN  NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_reserva_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reserva_espacio FOREIGN KEY (id_espacio)
        REFERENCES espacio (id_espacio)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_reserva_fechas     CHECK (fecha_fin > fecha_inicio),
    CONSTRAINT chk_reserva_asistentes CHECK (num_asistentes > 0)

) ENGINE = InnoDB;

-- Historial de cambios de estado de las reservas (lo llena un trigger)
CREATE TABLE log_reserva (
    id_log           INT AUTO_INCREMENT PRIMARY KEY,
    id_reserva       INT          NULL,
    estado_anterior  VARCHAR(30)  NOT NULL,
    estado_nuevo     VARCHAR(30)  NOT NULL,
    motivo           VARCHAR(255) NOT NULL DEFAULT 'N/A',
    fecha            DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_log_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB;


-- =====================================================================
--  MÓDULO 4: SERVICIOS ADICIONALES
-- =====================================================================

-- Catálogo de servicios (internet premium, lockers, café, impresiones...)
CREATE TABLE servicio (
    id_servicio  INT AUTO_INCREMENT PRIMARY KEY,
    nombre       VARCHAR(60)   NOT NULL,
    precio       DECIMAL(10,2) NOT NULL,
    CONSTRAINT uq_servicio_nombre UNIQUE (nombre),
    CONSTRAINT chk_servicio_precio CHECK (precio >= 0)
) ENGINE = InnoDB;

-- Servicios contratados por un cliente, sueltos o dentro de una reserva
CREATE TABLE servicio_contratado (
    id_contratado  INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario     INT      NOT NULL,
    id_servicio    INT      NOT NULL,
    id_reserva     INT      NULL,
    cantidad       INT      NOT NULL DEFAULT 1,
    estado         ENUM('Activo','Bloqueado','Cancelado') NOT NULL DEFAULT 'Activo',
    fecha          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_contratado_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_contratado_servicio FOREIGN KEY (id_servicio)
        REFERENCES servicio (id_servicio)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_contratado_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_contratado_cantidad CHECK (cantidad > 0)
) ENGINE = InnoDB;


-- =====================================================================
--  MÓDULO 5: PAGOS Y FACTURACIÓN
-- =====================================================================

-- Catálogo de métodos de pago
CREATE TABLE metodo_pago (
    id_metodo  INT AUTO_INCREMENT PRIMARY KEY,
    nombre     ENUM('Efectivo','Tarjeta','Transferencia','PayPal') NOT NULL,
    CONSTRAINT uq_metodo_pago_nombre UNIQUE (nombre)
) ENGINE = InnoDB;

-- Facturas. Individual (id_usuario) o consolidada para una empresa (id_empresa).
CREATE TABLE factura (
    id_factura         INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario         INT           NULL,
    id_empresa         INT           NULL,
    fecha_emision      DATE          NOT NULL DEFAULT (CURRENT_DATE),
    fecha_vencimiento  DATE          NOT NULL,
    total              DECIMAL(12,2) NOT NULL DEFAULT 0,
    saldo_pendiente    DECIMAL(12,2) NOT NULL DEFAULT 0,
    recargo_aplicado   DECIMAL(12,2) NOT NULL DEFAULT 0,
    estado             ENUM('Pendiente','Parcial','Pagada','Vencida','Anulada') NOT NULL DEFAULT 'Pendiente',
    motivo_anulacion   VARCHAR(255)  NULL,
    -- RESTRICT: MySQL no permite acciones CASCADE en columnas usadas en un CHECK
    CONSTRAINT fk_factura_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_factura_empresa FOREIGN KEY (id_empresa)
        REFERENCES empresa (id_empresa)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT chk_factura_titular  CHECK (id_usuario IS NOT NULL OR id_empresa IS NOT NULL),
    CONSTRAINT chk_factura_fechas   CHECK (fecha_vencimiento >= fecha_emision),
    CONSTRAINT chk_factura_montos   CHECK (total >= 0 AND saldo_pendiente >= 0 AND recargo_aplicado >= 0)
) ENGINE = InnoDB;

-- Penalizaciones (No Show, cancelación tardía). Va antes de detalle_factura
-- porque el detalle la referencia.
CREATE TABLE penalizacion (
    id_penalizacion  INT AUTO_INCREMENT PRIMARY KEY,
    id_reserva       INT           NOT NULL,
    monto            DECIMAL(10,2) NOT NULL,
    motivo           VARCHAR(255)  NOT NULL DEFAULT 'N/A',
    fecha            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_penalizacion_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_penalizacion_monto CHECK (monto > 0)
) ENGINE = InnoDB;

-- Líneas de cada factura. Cada línea cobra UNA cosa:
-- una membresía, una reserva, un servicio contratado o una penalización.
CREATE TABLE detalle_factura (
    id_detalle       INT AUTO_INCREMENT PRIMARY KEY,
    id_factura       INT           NOT NULL,
    id_membresia     INT           NULL,
    id_reserva       INT           NULL,
    id_contratado    INT           NULL,
    id_penalizacion  INT           NULL,
    descripcion      VARCHAR(255)  NOT NULL,
    monto            DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_detalle_factura FOREIGN KEY (id_factura)
        REFERENCES factura (id_factura)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_detalle_membresia FOREIGN KEY (id_membresia)
        REFERENCES membresia (id_membresia)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_detalle_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_detalle_contratado FOREIGN KEY (id_contratado)
        REFERENCES servicio_contratado (id_contratado)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_detalle_penalizacion FOREIGN KEY (id_penalizacion)
        REFERENCES penalizacion (id_penalizacion)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_detalle_monto CHECK (monto >= 0)
) ENGINE = InnoDB;

-- Pagos. id_factura puede llegar NULL: el trigger crea la factura automáticamente.
CREATE TABLE pago (
    id_pago     INT AUTO_INCREMENT PRIMARY KEY,
    id_factura  INT           NULL,
    id_metodo   INT           NOT NULL,
    monto       DECIMAL(12,2) NOT NULL,
    fecha_pago  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado      ENUM('Pagado','Pendiente','Cancelado') NOT NULL DEFAULT 'Pagado',
    CONSTRAINT fk_pago_factura FOREIGN KEY (id_factura)
        REFERENCES factura (id_factura)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pago_metodo FOREIGN KEY (id_metodo)
        REFERENCES metodo_pago (id_metodo)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_pago_monto CHECK (monto > 0)
) ENGINE = InnoDB;

-- Registro de pagos anulados (lo llena un trigger)
CREATE TABLE log_pago_anulado (
    id_log           INT AUTO_INCREMENT PRIMARY KEY,
    id_pago          INT           NULL,
    monto            DECIMAL(12,2) NOT NULL,
    motivo           VARCHAR(255)  NOT NULL DEFAULT 'N/A',
    fecha_anulacion  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_log_pago FOREIGN KEY (id_pago)
        REFERENCES pago (id_pago)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB;

-- Reembolsos por cancelación de reservas pagadas
CREATE TABLE reembolso (
    id_reembolso  INT AUTO_INCREMENT PRIMARY KEY,
    id_reserva    INT           NOT NULL,
    id_pago       INT           NOT NULL,
    monto         DECIMAL(12,2) NOT NULL,
    motivo        VARCHAR(255)  NOT NULL DEFAULT 'N/A',
    fecha         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reembolso_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reembolso_pago FOREIGN KEY (id_pago)
        REFERENCES pago (id_pago)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_reembolso_monto CHECK (monto > 0)
) ENGINE = InnoDB;


-- =====================================================================
--  MÓDULO 6: ACCESOS
-- =====================================================================

-- Tarjetas RFID y códigos QR de cada cliente
CREATE TABLE credencial (
    id_credencial  INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario     INT          NOT NULL,
    tipo           ENUM('RFID','QR') NOT NULL,
    codigo         VARCHAR(100) NOT NULL,
    estado         ENUM('Activa','Inactiva','Revocada') NOT NULL DEFAULT 'Activa',
    CONSTRAINT uq_credencial_codigo UNIQUE (codigo),
    CONSTRAINT fk_credencial_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- Cada fila es un intento de ingreso. Si es permitido, también es la asistencia
-- (entrada + salida). Si el código no existe, id_credencial e id_usuario quedan NULL.
CREATE TABLE acceso (
    id_acceso           INT AUTO_INCREMENT PRIMARY KEY,
    id_credencial       INT          NULL,
    id_usuario          INT          NULL,
    id_reserva          INT          NULL,
    metodo              ENUM('RFID','QR') NOT NULL,
    codigo_leido        VARCHAR(100) NOT NULL,
    fecha_hora_entrada  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_hora_salida   DATETIME     NULL,
    salida_automatica   BOOLEAN      NOT NULL DEFAULT FALSE,
    resultado           ENUM('Permitido','Rechazado') NOT NULL,
    motivo_rechazo      VARCHAR(100) NULL,
    CONSTRAINT fk_acceso_credencial FOREIGN KEY (id_credencial)
        REFERENCES credencial (id_credencial)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_acceso_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_acceso_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_acceso_salida CHECK (fecha_hora_salida IS NULL OR fecha_hora_salida > fecha_hora_entrada)
) ENGINE = InnoDB;

-- Registro de intentos de acceso rechazados (lo llena un trigger)
CREATE TABLE log_acceso_rechazado (
    id_log        INT AUTO_INCREMENT PRIMARY KEY,
    id_acceso     INT          NULL,
    codigo_leido  VARCHAR(100) NOT NULL,
    motivo        VARCHAR(100) NOT NULL DEFAULT 'N/A',
    fecha         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_log_acceso FOREIGN KEY (id_acceso)
        REFERENCES acceso (id_acceso)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB;


-- =====================================================================
--  MÓDULO 7: COMUNICACIÓN
-- =====================================================================

-- Recordatorios, alertas y reportes que generan los eventos.
-- Destinatario: un cliente (id_usuario), una cuenta del personal (id_cuenta)
-- o un rol completo (destinatario_rol).
CREATE TABLE notificacion (
    id_notificacion   INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario        INT          NULL,
    id_cuenta         INT          NULL,
    destinatario_rol  ENUM('Usuario','Administrador','Recepcionista','Gerente','Contador') NOT NULL DEFAULT 'Usuario',
    tipo              ENUM('Recordatorio','Alerta','Reporte') NOT NULL,
    asunto            VARCHAR(150) NOT NULL,
    mensaje           TEXT         NOT NULL,
    fecha_programada  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    enviada           BOOLEAN      NOT NULL DEFAULT FALSE,
    fecha_envio       DATETIME     NULL,
    CONSTRAINT fk_notificacion_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_notificacion_cuenta FOREIGN KEY (id_cuenta)
        REFERENCES cuenta (id_cuenta)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;