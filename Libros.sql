-- Creating the schema for the database
DROP SCHEMA IF EXISTS libros;

CREATE SCHEMA libros;

use libros;

-- Creating the tables

DROP TABLE IF EXISTS Autores;

CREATE TABLE Autores
(
    idAutor      VARCHAR(11) PRIMARY KEY,
    apellido     VARCHAR(40) NOT NULL,
    nombre       VARCHAR(20) NOT NULL,
    telefono     CHAR(12)    NOT NULL DEFAULT 'Unknown', -- No tiene sentido la constraint NOT NULL ya que el valor por defecto es 'Unknown'
    domicilio    VARCHAR(40) NULL,
    ciudad       VARCHAR(20) NULL,
    estado       CHAR(2)     NULL,
    codigoPostal CHAR(5)     NULL
);

DROP TABLE IF EXISTS Editoriales;

CREATE TABLE Editoriales
(
    idEditorial CHAR(4) PRIMARY KEY,
    nombre      VARCHAR(40) NOT NULL UNIQUE,
    ciudad      VARCHAR(20) NULL,
    estado      CHAR(2)     NULL,
    pais        VARCHAR(30) NULL DEFAULT 'USA' -- No tiene sentido la constraint NULL ya que el valor por defecto es 'USA'
);

DROP TABLE IF EXISTS Tiendas;

CREATE TABLE Tiendas
(
    idTienda     CHAR(4) PRIMARY KEY,
    nombre       VARCHAR(40) NOT NULL UNIQUE,
    domicilio    VARCHAR(40) NULL,
    ciudad       VARCHAR(20) NULL,
    estado       CHAR(2)     NULL,
    codigoPostal CHAR(5)     NULL
);

DROP TABLE IF EXISTS Ventas;

CREATE TABLE Ventas
(
    codigoVenta VARCHAR(20) PRIMARY KEY,
    idTienda    CHAR(4)     NOT NULL,
    fecha       DATETIME    NOT NULL,
    tipo        VARCHAR(12) NOT NULL,

    FOREIGN KEY (idTienda) REFERENCES Tiendas (idTienda)
);

DROP TABLE IF EXISTS Titulos;

CREATE TABLE Titulos
(
    idTitulo         VARCHAR(6) PRIMARY KEY,
    titulo           VARCHAR(80)   NOT NULL,
    genero           CHAR(12)      NOT NULL DEFAULT 'Undecided',
    idEditorial      CHAR(4)       NOT NULL,
    precio           DECIMAL(8, 2) NULL,
    sinopsis         VARCHAR(200)  NULL,
    fechaPublicacion DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (idEditorial) REFERENCES Editoriales (idEditorial),

    CHECK (precio >= 0)
);

DROP TABLE IF EXISTS TitulosDelAutor;

CREATE TABLE TitulosDelAutor
(
    idAutor  VARCHAR(11) NOT NULL,
    idTitulo VARCHAR(6)  NOT NULL,

    PRIMARY KEY (idTitulo, idAutor),

    FOREIGN KEY (idTitulo) REFERENCES Titulos (idTitulo),
    FOREIGN KEY (idAutor) REFERENCES Autores (idAutor)
);

DROP TABLE IF EXISTS Detalles;

CREATE TABLE Detalles
(
    idDetalle   INT AUTO_INCREMENT PRIMARY KEY,
    codigoVenta VARCHAR(20) NOT NULL,
    idTitulo    VARCHAR(6)  NOT NULL,
    cantidad    SMALLINT    NOT NULL,

    FOREIGN KEY (codigoVenta) REFERENCES Ventas (codigoVenta),
    FOREIGN KEY (idTitulo) REFERENCES Titulos (idTitulo),

    CHECK (cantidad > 0)
);

# Ejercicios

# 2) Crear una vista llamada VCantidadVentas que muestre por cada tienda su código,
# cantidad total de ventas y el importe total de todas esas ventas. La salida, mostrada en la
# siguiente tabla, deberá estar ordenada descendentemente según la cantidad total de ventas
# y el importe de las mismas. Incluir el código con la consulta a la vista. [20 puntos]

DROP VIEW IF EXISTS VCantidadVentas;

CREATE VIEW VCantidadVentas AS
SELECT Tien.idTienda,
       COUNT(V.codigoVenta)       AS cantidadVentas,
       IFNULL(SUM(T.precio * D.cantidad), 0) AS importeTotal
FROM Tiendas Tien
         LEFT JOIN
     Ventas V ON Tien.idTienda = V.idTienda
         LEFT JOIN
     Detalles D ON V.codigoVenta = D.codigoVenta
        LEFT JOIN Titulos T
              ON D.idTitulo = T.idTitulo
GROUP BY Tien.idTienda
ORDER BY cantidadVentas DESC, importeTotal DESC;

SELECT *
FROM VCantidadVentas;

-- Incerto una tienda que no tenga ventas para testeo

INSERT INTO Tiendas (idTienda, nombre, domicilio, ciudad, estado, codigoPostal)
VALUES ('T005', 'Tienda 5', 'Calle 5', 'Ciudad 5', 'C5', '5005');

# 3) Realizar un procedimiento almacenado llamado NuevaEditorial para dar de alta una
# editorial, incluyendo el control de errores lógicos y mensajes de error necesarios
# (implementar la lógica del manejo de errores empleando parámetros de salida). Incluir el
# código con la llamada al procedimiento probando todos los casos con datos incorrectos y
# uno con datos correctos. [20 puntos]

DROP PROCEDURE IF EXISTS NuevaEditorial;

DELIMITER $$

CREATE PROCEDURE NuevaEditorial(
    IN  IN_idEditorial CHAR(4),
    IN  IN_nombre      VARCHAR(40),
    IN  IN_ciudad      VARCHAR(20),
    IN  IN_estado      CHAR(2),
    IN  IN_pais        VARCHAR(30),
    OUT mensaje     VARCHAR(100)
)

SALIR: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET @mensaje = 'Error';
    END;

    START TRANSACTION;

    IF IN_idEditorial IS NULL OR IN_nombre IS NULL OR IN_ciudad IS NULL OR IN_estado IS NULL OR IN_pais IS NULL THEN
        SET mensaje = 'Error: Todos los campos son obligatorios';
        LEAVE SALIR;
    ELSEIF LENGTH(IN_idEditorial) != 4 THEN
        SET mensaje = 'Error: El id de la editorial debe tener 4 caracteres';
        LEAVE SALIR;
    ELSEIF LENGTH(IN_nombre) > 40 THEN
        SET mensaje = 'Error: El nombre de la editorial no puede tener más de 40 caracteres';
        LEAVE SALIR;
    ELSEIF LENGTH(IN_ciudad) > 20 THEN
        SET mensaje = 'Error: La ciudad de la editorial no puede tener más de 20 caracteres';
        LEAVE SALIR;
    ELSEIF LENGTH(IN_estado) != 2 THEN
        SET mensaje = 'Error: El estado de la editorial debe tener 2 caracteres';
        LEAVE SALIR;
    ELSEIF LENGTH(IN_pais) > 30 THEN
        SET mensaje = 'Error: El país de la editorial no puede tener más de 30 caracteres';
        LEAVE SALIR;
    END IF;

    IF (SELECT COUNT(*) FROM Editoriales WHERE idEditorial = IN_idEditorial) > 0 THEN
        SET mensaje = 'Error: La editorial ya existe';
    ELSE
        INSERT INTO Editoriales (idEditorial, nombre, ciudad, estado, pais)
        VALUES (IN_idEditorial, IN_nombre, IN_ciudad, IN_estado, IN_pais);

        SET mensaje = 'Editorial dada de alta correctamente';
    END IF;

    COMMIT;
END $$

DELIMITER ;

SET @mensaje = '';

CALL NuevaEditorial('Boca', 'Editorial 1', 'Ciudad 1', 'C1', 'Pais 1', @mensaje);
SELECT @mensaje;

SELECT * FROM Editoriales;

#4) Realizar un procedimiento almacenado llamado BuscarTitulosPorAutor que reciba el
# código de un autor y muestre los títulos del mismo. Por cada título del autor especificado se
# deberá mostrar su código y título, género, nombre de la editorial, precio, sinopsis y fecha de
# publicación. La salida, mostrada en la siguiente tabla, deberá estar ordenada
# alfabéticamente según el título. Incluir en el código la llamada al procedimiento. [15 puntos]

DROP PROCEDURE IF EXISTS BuscarTitulosPorAutor;

DELIMITER $$

CREATE PROCEDURE BuscarTitulosPorAutor(
    IN  IN_idAutor VARCHAR(11)
)
BEGIN
    SELECT T.idTitulo AS Código,
           T.titulo AS Título,
           T.genero AS Género,
           E.nombre AS Editorial,
           T.precio AS Precio,
           T.sinopsis AS Sinopsis,
           T.fechaPublicacion AS Fecha
    FROM Titulos T
             JOIN
         TitulosDelAutor TDA ON T.idTitulo = TDA.idTitulo
             JOIN
         Editoriales E ON T.idEditorial = E.idEditorial
    WHERE TDA.idAutor = IN_idAutor
    ORDER BY T.titulo;
END $$

DELIMITER ;

CALL BuscarTitulosPorAutor('213-46-8915');

# 5) Utilizando triggers, implementar la lógica para que en caso que se quiera borrar una
# editorial referenciada por un título se informe mediante un mensaje de error que no se
# puede. Incluir el código con los borrados de una editorial que no tiene títulos, y otro de una
# que sí. [20 puntos]

DROP TRIGGER IF EXISTS NoBorrarEditorial;

DELIMITER $$
CREATE TRIGGER NoBorrarEditorial
BEFORE DELETE ON Editoriales
FOR EACH ROW
BEGIN
    DECLARE cantidad INT;

    SELECT COUNT(*)
    INTO cantidad
    FROM Titulos
    WHERE idEditorial = OLD.idEditorial;

    IF cantidad > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede borrar la editorial porque tiene títulos asociados';
    END IF;
END $$

DELIMITER ;

SELECT * FROM Editoriales
LEFT JOIN Titulos T on Editoriales.idEditorial = T.idEditorial;

-- Borrado de una editorial que no tiene títulos asociados
DELETE FROM Editoriales WHERE idEditorial = 'Boca';

-- Borrado de una editorial que tiene títulos asociados
DELETE FROM Editoriales WHERE idEditorial = '0736';

-- See all indexes of the schema
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME
FROM
    INFORMATION_SCHEMA.STATISTICS
WHERE
    TABLE_SCHEMA = 'libros';