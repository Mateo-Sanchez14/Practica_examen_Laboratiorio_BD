DROP SCHEMA IF EXISTS Parcial2023;

CREATE SCHEMA IF NOT EXISTS Parcial2023;

USE Parcial2023;

CREATE TABLE Clientes
(
    idCliente INTEGER      NOT NULL AUTO_INCREMENT,
    apellidos VARCHAR(50)  NOT NULL,
    nombres   VARCHAR(50)  NOT NULL,
    dni       VARCHAR(10)  NOT NULL,
    domicilio VARCHAR(100) NOT NULL,
    PRIMARY KEY (idCliente),
    UNIQUE (dni)
);

CREATE TABLE Sucursales
(
    idSucursal INTEGER      NOT NULL AUTO_INCREMENT,
    nombre     VARCHAR(100) NOT NULL,
    domicilio  VARCHAR(100) NOT NULL,
    PRIMARY KEY (idSucursal),
    UNIQUE (nombre, domicilio)
);

CREATE TABLE BandasHorarias
(
    idBandaHoraria INTEGER  NOT NULL AUTO_INCREMENT,
    nombre         CHAR(13) NOT NULL,
    PRIMARY KEY (idBandaHoraria),
    UNIQUE (nombre)
);

CREATE TABLE Productos
(
    idProducto INTEGER      NOT NULL AUTO_INCREMENT,
    nombre     VARCHAR(150) NOT NULL,
    precio     FLOAT        NOT NULL CHECK (precio > 0),
    PRIMARY KEY (idProducto),
    UNIQUE (nombre)
);

CREATE TABLE Pedidos
(
    idPedido  INTEGER  NOT NULL AUTO_INCREMENT,
    idCliente INTEGER  NOT NULL,
    fecha     DATETIME NOT NULL,
    PRIMARY KEY (idPedido),
    FOREIGN KEY (idCliente) REFERENCES Clientes (idCliente)
);

CREATE TABLE ProductoDelPedido
(
    idPedido   INTEGER NOT NULL,
    idProducto INTEGER NOT NULL,
    cantidad   FLOAT   NOT NULL,
    precio     FLOAT   NOT NULL CHECK (precio > 0),
    PRIMARY KEY (idPedido, idProducto),
    FOREIGN KEY (idPedido) REFERENCES Pedidos (idPedido),
    FOREIGN KEY (idProducto) REFERENCES Productos (idProducto)
);

CREATE TABLE Entregas
(
    idEntrega      INTEGER  NOT NULL AUTO_INCREMENT,
    idSucursal     INTEGER  NOT NULL,
    idPedido       INTEGER  NOT NULL,
    fecha          DATETIME NOT NULL,
    idBandaHoraria INTEGER  NOT NULL,
    PRIMARY KEY (idEntrega),
    FOREIGN KEY (idSucursal) REFERENCES Sucursales (idSucursal),
    FOREIGN KEY (idPedido) REFERENCES Pedidos (idPedido),
    FOREIGN KEY (idBandaHoraria) REFERENCES BandasHorarias (idBandaHoraria)
);

# Crear una vista llamada VEntregas que muestre por cada sucursal su nombre, el
# identificador del pedido que entregó, la fecha en la que se hizo el pedido, la fecha en la que
# fue entregado junto con la banda horaria, y el cliente que hizo el pedido. La salida, mostrada
# en la siguiente tabla, deberá estar ordenada ascendentemente según el nombre de la
# sucursal, fecha del pedido y fecha de entrega (tener en cuenta las sucursales que pudieran
# no tener entregas). Incluir el código con la consulta a la vista. [15 puntos]

DROP VIEW IF EXISTS VEntregas;

CREATE VIEW VEntregas AS
SELECT S.nombre                                               AS Sucursal,
       E.idPedido                                             AS 'Pedido',
       P.fecha                                                AS 'F. pedido',
       E.fecha                                                AS 'F. entrega',
       BH.nombre                                              AS 'Banda',
       CONCAT(C.apellidos, ', ', C.nombres, ' (', C.dni, ')') AS Cliente
FROM Entregas E
         RIGHT JOIN Sucursales S
                    ON E.idSucursal = S.idSucursal
         LEFT JOIN Pedidos P
                   ON E.idPedido = P.idPedido
         LEFT JOIN BandasHorarias BH
                   ON E.idBandaHoraria = BH.idBandaHoraria
         LEFT JOIN Clientes C
                   ON P.idCliente = C.idCliente
ORDER BY S.nombre, P.fecha, E.fecha;

SELECT *
FROM VEntregas;

# Realizar un procedimiento almacenado llamado NuevoProducto para dar de alta un
# producto, incluyendo el control de errores lógicos y mensajes de error necesarios
# (implementar la lógica del manejo de errores empleando parámetros de salida). Incluir el
# código con la llamada al procedimiento probando todos los casos con datos incorrectos y
# uno con datos correctos. [20 puntos]

DROP PROCEDURE IF EXISTS NuevoProducto;

DELIMITER $$

CREATE PROCEDURE NuevoProducto(
    IN p_nombre VARCHAR(150),
    IN p_precio FLOAT,
    OUT mensaje VARCHAR(100)
)
SALIR:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET mensaje = 'Error: El producto no pudo ser dado de alta.';
        END;

    IF p_nombre IS NULL OR p_nombre = '' THEN
        SET mensaje = 'Error: El nombre del producto no puede ser nulo o vacío.';
        LEAVE SALIR;
    END IF;

    IF p_precio IS NULL OR p_precio <= 0 THEN
        SET mensaje = 'Error: El precio del producto no puede ser nulo o menor o igual a 0.';
        LEAVE SALIR;
    END IF;

   -- Chequeo un producto con el mismo nombre
    IF EXISTS (SELECT 1 FROM Productos WHERE nombre = p_nombre) THEN
        SET mensaje = 'Error: Ya existe un producto con el nombre ingresado.';
        LEAVE SALIR;
    END IF;


    INSERT INTO Productos (nombre, precio)
    VALUES (p_nombre, p_precio);
    SET mensaje = 'Producto dado de alta correctamente.';
END$$

DELIMITER ;

-- Pruebo con todos los errores posibles:

-- Nombre nulo

CALL NuevoProducto(NULL, 100, @mensaje);
SELECT @mensaje;

-- Nombre vacío

CALL NuevoProducto('', 100, @mensaje);
SELECT @mensaje;

-- Precio nulo
CALL NuevoProducto('Producto 1', NULL, @mensaje);
SELECT @mensaje;

-- Precio menor o igual a 0
CALL NuevoProducto('Producto 1', 0, @mensaje);
SELECT @mensaje;

-- Producto ya existente
-- SELECT * FROM Productos;

CALL NuevoProducto('iPhone 12', 100, @mensaje);
SELECT @mensaje;

-- Pruebo con un caso correcto
CALL NuevoProducto('iPhone 15', 100, @mensaje);
SELECT @mensaje;

# Realizar un procedimiento almacenado llamado BuscarPedidos que reciba el
# identificador de un pedido y muestre los datos del mismo. Por cada pedido mostrará el
# identificador del producto, nombre, precio de lista, cantidad, precio de venta y total. Además
# en la última fila mostrará los datos del pedido (fecha, cliente y total del pedido). La salida,
# mostrada en la siguiente tabla, deberá estar ordenada alfabéticamente según el nombre del
# producto. Incluir en el código la llamada al procedimiento. [25 puntos]

DROP PROCEDURE IF EXISTS BuscarPedidos;

DELIMITER $$
CREATE PROCEDURE BuscarPedidos(
    IN p_idPedido INTEGER
)
BEGIN
#     SELECT PDP.idProducto,
#            PR.nombre,
#            PR.precio,
#            PDP.cantidad,
#            PDP.precio,
#            PDP.cantidad * PDP.precio AS Total
#     FROM ProductoDelPedido PDP
#              JOIN Productos PR
#                   ON PDP.idProducto = PR.idProducto
#     WHERE PDP.idPedido = p_idPedido
#     UNION
#     SELECT 'Fecha: ',
#            NULL,
#            'Cliente: ',
#            NULL,
#            'Total: ',
#            SUM(PDP.cantidad * PDP.precio) AS Total
#     FROM ProductoDelPedido PDP
#     WHERE PDP.idPedido = p_idPedido;

    CREATE TEMPORARY TABLE IF NOT EXISTS TemporalPedido AS
    SELECT PDP.idProducto AS idProducto,
           PR.nombre AS nombre,
           PR.precio AS 'precio lista',
           PDP.cantidad AS cantidad,
           PDP.precio AS 'Precio venta',
           PDP.cantidad * PDP.precio AS total
    FROM ProductoDelPedido PDP
             JOIN Productos PR
                  ON PDP.idProducto = PR.idProducto
    WHERE PDP.idPedido = p_idPedido;

    CREATE TEMPORARY TABLE IF NOT EXISTS TotalPedido AS
    SELECT 'Fecha:',
           P.fecha,
           'Cliente:',
           CONCAT(C.apellidos, ', ', C.nombres, ' (', C.dni, ')'),
           'Total:',
           SUM(PDP.cantidad * PDP.precio)
    FROM ProductoDelPedido PDP
    INNER JOIN Pedidos P
    ON PDP.idPedido = P.idPedido
    INNER JOIN Clientes C
    ON P.idCliente = C.idCliente
    WHERE PDP.idPedido = p_idPedido;

    SELECT * FROM TemporalPedido
    UNION
    SELECT * FROM TotalPedido;
END$$

DELIMITER ;

CALL BuscarPedidos(1);

# Utilizando triggers, implementar la lógica para que en caso que se quiera borrar un
# producto incluido en un pedido se informe mediante un mensaje de error que no se puede.
# Incluir el código con los borrados de un producto no incluido en ningún pedido, y otro de uno
# que sí. [15 puntos

DROP TRIGGER IF EXISTS Producto_Borrado;

DELIMITER $$
CREATE TRIGGER Producto_Borrado
BEFORE DELETE
ON Productos
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM ProductoDelPedido WHERE idProducto = OLD.idProducto) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede borrar un producto incluido en un pedido.';
    END IF;
END$$

DELIMITER ;

-- Borro un producto incluido en ningún pedido
SELECT * FROM Productos LEFT JOIN ProductoDelPedido PDP on Productos.idProducto = PDP.idProducto;
DELETE FROM Productos WHERE nombre = 'iPhone 12';

SELECT * FROM Productos;

-- Borro un producto incluido en un pedido
DELETE FROM Productos WHERE nombre = 'iPhone 15';

SELECT * FROM Productos;


