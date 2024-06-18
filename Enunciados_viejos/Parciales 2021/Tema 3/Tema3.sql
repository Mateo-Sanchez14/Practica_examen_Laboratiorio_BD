DROP SCHEMA IF EXISTS TEMA3;

CREATE SCHEMA IF NOT EXISTS TEMA3;

USE TEMA3;

CREATE TABLE Domicilios
(
    idDomicilio  INTEGER     NOT NULL AUTO_INCREMENT,
    calleYNumero VARCHAR(50) NOT NULL UNIQUE,
    municipio    VARCHAR(20) NOT NULL,
    codigoPostal VARCHAR(10) NULL,
    telefono     VARCHAR(20) NOT NULL,
    PRIMARY KEY (idDomicilio)
);

CREATE TABLE Clientes
(
    idCliente   INTEGER     NOT NULL AUTO_INCREMENT,
    nombres     VARCHAR(45) NOT NULL,
    apellidos   VARCHAR(45) NOT NULL,
    idDomicilio INTEGER     NOT NULL,
    correo      VARCHAR(50) NOT NULL UNIQUE,
    estado      CHAR(1)     NOT NULL DEFAULT 'E',
    PRIMARY KEY (idCliente),
    FOREIGN KEY (idDomicilio) REFERENCES Domicilios (idDomicilio)

#     CHECK (estado IN ('E', 'D'))
);

CREATE TABLE Peliculas
(
    idPelicula    INTEGER      NOT NULL AUTO_INCREMENT,
    titulo        VARCHAR(128) NOT NULL UNIQUE,
    estreno       INTEGER      NULL,
    duracion      INTEGER      NULL,
    clasificacion VARCHAR(10)  NOT NULL DEFAULT 'G',
    PRIMARY KEY (idPelicula),
    CHECK (clasificacion IN ('G', 'PG', 'PG-13', 'R', 'NC-17'))
);

-- Create Tiendas table which depends on Domicilios
CREATE TABLE Tiendas
(
    idTienda    INTEGER NOT NULL AUTO_INCREMENT,
    idDomicilio INTEGER NOT NULL,
    PRIMARY KEY (idTienda),
    FOREIGN KEY (idDomicilio) REFERENCES Domicilios (idDomicilio)
);

-- Create Registros table which depends on Peliculas and Tiendas
CREATE TABLE Registros
(
    idRegistro INTEGER NOT NULL AUTO_INCREMENT,
    idPelicula INTEGER NOT NULL,
    idTienda   INTEGER NOT NULL,
    PRIMARY KEY (idRegistro),
    FOREIGN KEY (idPelicula) REFERENCES Peliculas (idPelicula),
    FOREIGN KEY (idTienda) REFERENCES Tiendas (idTienda)
);

CREATE TABLE Alquileres
(
    idAlquiler      INTEGER  NOT NULL AUTO_INCREMENT,
    fechaAlquiler   DATETIME NOT NULL,
    idRegistro      INTEGER  NOT NULL,
    idCliente       INTEGER  NOT NULL,
    fechaDevolucion DATETIME NULL,
    PRIMARY KEY (idAlquiler),
    FOREIGN KEY (idRegistro) REFERENCES Registros (idRegistro),
    FOREIGN KEY (idCliente) REFERENCES Clientes (idCliente)
);

CREATE TABLE Pagos
(
    idPago     INTEGER       NOT NULL AUTO_INCREMENT,
    idCliente  INTEGER       NOT NULL,
    idAlquiler INTEGER       NOT NULL,
    importe    DECIMAL(5, 2) NOT NULL,
    fecha      DATETIME      NOT NULL,
    PRIMARY KEY (idPago),
    FOREIGN KEY (idCliente) REFERENCES Clientes (idCliente),
    FOREIGN KEY (idAlquiler) REFERENCES Alquileres (idAlquiler)
);

# 1) Crear una vista llamada VCantidadAlquileres que muestre por cada cliente su código,
# apellido y nombre (formato: apellido, nombre), y la cantidad de alquileres que realizó. La
# salida deberá estar ordenada alfabéticamente según el apellido y nombre del cliente. Incluir
# el código con la consulta a la vista. [20 puntos]

DROP VIEW IF EXISTS VCantidadAlquileres;

CREATE VIEW VCantidadAlquileres AS
SELECT C.idCliente,
       CONCAT(C.apellidos, ', ', C.nombres) AS 'Apellido, Nombre',
       COUNT(A.idAlquiler)                  AS 'Cantidad de alquileres'
FROM Clientes C
         INNER JOIN Alquileres A
                    ON C.idCliente = A.idCliente
GROUP BY C.idCliente, C.apellidos, C.nombres
ORDER BY C.apellidos, C.nombres;

SELECT *
FROM VCantidadAlquileres;

SELECT *
FROM Clientes
WHERE estado != 'E'
  AND estado != 'D';

# Realizar un procedimiento almacenado llamado BorrarDomicilio para borrar un
# domicilio, incluyendo el control de errores lógicos y mensajes de error necesarios
# (implementar la lógica del manejo de errores empleando parámetros de salida). Incluir el
# código con la llamada al procedimiento probando todos los casos con datos incorrectos y
# uno con datos correctos. [20 puntos]

DROP PROCEDURE IF EXISTS BorrarDomicilio;

DELIMITER $$

CREATE PROCEDURE BorrarDomicilio(
    IN idDomicilioParam INTEGER,
    OUT mensaje VARCHAR(128)
)
SALIR:
BEGIN
    DECLARE v_cantidadDeClientes INTEGER;
    DECLARE v_cantidadDeTiendas INTEGER;

    IF idDomicilioParam IS NULL THEN
        SET mensaje = 'El idDomicilio no puede ser nulo.';
        LEAVE SALIR;
    END IF;

    SELECT COUNT(*)
    INTO v_cantidadDeClientes
    FROM Clientes
    WHERE idDomicilio = idDomicilioParam;

    IF v_cantidadDeClientes > 0 THEN
        SET mensaje = 'No se puede borrar el domicilio porque hay clientes asociados a él.';
        LEAVE SALIR;
    END IF;

    SELECT COUNT(*)
    INTO v_cantidadDeTiendas
    FROM Tiendas
    WHERE idDomicilio = idDomicilioParam;

    IF v_cantidadDeTiendas > 0 THEN
        SET mensaje = 'No se puede borrar el domicilio porque hay tiendas asociadas a él.';
        LEAVE SALIR;
    END IF;

    DELETE
    FROM Domicilios
    WHERE idDomicilio = idDomicilioParam;

    SET mensaje = 'Domicilio borrado correctamente.';
end $$

DELIMITER ;

-- Test the procedure with all cases

CALL BorrarDomicilio(NULL, @mensaje);
SELECT @mensaje;

-- Domicilio con tiendas
SELECT *
FROM Domicilios
         LEFT JOIN Tiendas ON Domicilios.idDomicilio = Tiendas.idDomicilio;

CALL BorrarDomicilio(1, @mensaje);
SELECT @mensaje;

-- Domicilio con clientes
SELECT *
FROM Domicilios
         LEFT JOIN Clientes ON Domicilios.idDomicilio = Clientes.idDomicilio;

CALL BorrarDomicilio(5, @mensaje);
SELECT @mensaje;

-- Domicilio sin tiendas ni clientes
SELECT *
FROM Domicilios
         LEFT JOIN Tiendas ON Domicilios.idDomicilio = Tiendas.idDomicilio
         LEFT JOIN Clientes ON Domicilios.idDomicilio = Clientes.idDomicilio
WHERE Tiendas.idTienda IS NULL AND Clientes.idCliente IS NULL;

CALL BorrarDomicilio(4, @mensaje);
SELECT @mensaje;

# Realizar un procedimiento almacenado llamado TotalAlquileres que reciba el código de
# un cliente y muestre alquiler por alquiler, película por película, la fecha del alquiler, el título
# de la película, la fecha de devolución y la cantidad. La salida deberá estar ordenada en
# orden cronológico inverso según la fecha de alquiler (del alquiler más reciente al más
# antiguo). Incluir en el código la llamada al procedimiento. [15 puntos]

DROP PROCEDURE IF EXISTS TotalAlquileres;

DELIMITER $$
CREATE PROCEDURE TotalAlquileres(
    IN idClienteParam INTEGER
)
BEGIN
    SELECT A.idAlquiler,
            A.fechaAlquiler,
           P.titulo,
           A.fechaDevolucion,
           COUNT(*) AS 'Cantidad'
    FROM Alquileres A
             INNER JOIN Registros R
                        ON A.idRegistro = R.idRegistro
             INNER JOIN Peliculas P
                        ON R.idPelicula = P.idPelicula
    WHERE A.idCliente = idClienteParam
    GROUP BY A.idAlquiler, A.fechaAlquiler, P.titulo, A.fechaDevolucion
    ORDER BY A.fechaAlquiler DESC;
END $$

DELIMITER ;

CALL TotalAlquileres(1);

# 5) Utilizando triggers, implementar la lógica para que en caso que se quiera crear un
# domicilio ya existente según código y/o calle y número se informe mediante un mensaje de
# error que no se puede. Incluir el código con las creaciones de domicilios existentes según
# código y/o calle y número y otro inexistente. [20 puntos]

DROP TRIGGER IF EXISTS TRG_Domicilios_BeforeInsert;

DELIMITER $$
CREATE TRIGGER TRG_Domicilios_BeforeInsert
BEFORE INSERT ON Domicilios
FOR EACH ROW
BEGIN
    DECLARE v_cantidadDeDomicilios INTEGER;

    SELECT COUNT(*)
    INTO v_cantidadDeDomicilios
    FROM Domicilios
    WHERE idDomicilio = NEW.idDomicilio OR calleYNumero = NEW.calleYNumero;

    IF v_cantidadDeDomicilios > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede crear el domicilio porque ya existe un domicilio con el mismo código y/o calle y número.';
    END IF;
END $$

DELIMITER ;

-- Test the trigger with an existing domicilio id
INSERT INTO Domicilios (idDomicilio, calleYNumero, municipio, codigoPostal, telefono)
VALUES (1, 'Calle 123', 'Municipio 1', '1234', '1234-1234');

-- Test the trigger with an existing domicilio calleYNumero
SELECT * FROM Domicilios;

INSERT INTO Domicilios ( calleYNumero, municipio, codigoPostal, telefono)
VALUES ('47 MySakila Drive', 'Municipio 2', '1234', '1234-1234');

-- Correct insert

INSERT INTO Domicilios ( calleYNumero, municipio, codigoPostal, telefono)
VALUES ('7ma de Boca', 'Municipio 2', '1234', '1234-1234');
