-- Creación de la base de datos
DROP DATABASE IF EXISTS Parcial2009;

CREATE DATABASE IF NOT EXISTS Parcial2009;
USE Parcial2009;

-- Tabla Obras
DROP TABLE IF EXISTS Obras;

CREATE TABLE Obras
(
    IdObra        INTEGER     NOT NULL PRIMARY KEY,
    NombreObra    VARCHAR(75) NOT NULL UNIQUE,
    DireccionObra VARCHAR(75) NOT NULL,
    TotalHoras    INTEGER     NOT NULL
);


-- Tabla Cargos
DROP TABLE IF EXISTS Cargos;

CREATE TABLE Cargos
(
    IdCargo INTEGER     NOT NULL PRIMARY KEY,
    Cargo   VARCHAR(50) NOT NULL UNIQUE
);

-- Tabla Empleados

DROP TABLE IF EXISTS Empleados;

CREATE TABLE Empleados
(
    IdEmpleado INTEGER     NOT NULL PRIMARY KEY AUTO_INCREMENT,
    IdCargo    INTEGER     NOT NULL,
    IdJefe     INTEGER     NULL,
    Apellidos  VARCHAR(50) NOT NULL,
    Nombres    VARCHAR(50) NOT NULL,
    Direccion  VARCHAR(75) NOT NULL,
    Telefono   CHAR(7)     NOT NULL,
    FOREIGN KEY (IdCargo) REFERENCES Cargos (IdCargo),
    FOREIGN KEY (IdJefe) REFERENCES Empleados (IdEmpleado),
    CONSTRAINT CHK_Telefono CHECK (Telefono REGEXP '^4[0-9]{6}$'),

    INDEX idx_apellidos_nombres (Apellidos, Nombres)
);

-- Tabla Trabajos

DROP TABLE IF EXISTS Trabajos;

CREATE TABLE Trabajos
(
    IdObra      INTEGER      NOT NULL,
    IdTrabajo   INTEGER      NOT NULL,
    Descripcion VARCHAR(100) NOT NULL,
    Horas       INTEGER      NOT NULL,
    Estado      CHAR(1)      NOT NULL,
    PRIMARY KEY (IdObra, IdTrabajo),
    FOREIGN KEY (IdObra) REFERENCES Obras (IdObra),
    CONSTRAINT CHK_Estado CHECK (Estado IN ('A', 'B'))

);


-- Tabla TrabajaEn

DROP TABLE IF EXISTS TrabajaEn;


CREATE TABLE TrabajaEn
(
    IdObra          INTEGER NOT NULL,
    IdTrabajo       INTEGER NOT NULL,
    IdEmpleado      INTEGER NOT NULL,
    HorasTrabajadas INTEGER NOT NULL,
    PRIMARY KEY (IdObra, IdTrabajo, IdEmpleado),
    FOREIGN KEY (IdObra, IdTrabajo) REFERENCES Trabajos (IdObra, IdTrabajo),
    FOREIGN KEY (IdEmpleado) REFERENCES Empleados (IdEmpleado),
    INDEX idx_IdObra_IdTrabajo (IdObra, IdTrabajo)
);

-- See all indexes of the schema
SELECT TABLE_NAME,
       INDEX_NAME,
       COLUMN_NAME
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'Parcial2009';

# ii) Crear un SP que dado IdEmpleado, liste los empleados a su cargo (solo 1 nivel) y la cantidad de horas
# trabajadas por cada uno (IdEmpleado, Apellidos, Nombres, Cargo, TotalHoras) y una fila al final con el
# total de horas de todos los empleados. Llamarlo rsp_empleados_a_cargo.


# DELIMITER //
#
# CREATE PROCEDURE rsp_empleados_a_cargo(IN _IdEmpleado INT, OUT _Mensaje VARCHAR(255))
# BEGIN
#     -- Comprobar si el empleado existe
#     IF NOT EXISTS (SELECT 1 FROM Parcial2009.Empleados WHERE IdEmpleado = _IdEmpleado) THEN
#         SET _Mensaje = 'Error: El empleado no existe.';
#     ELSE
#         -- Crear una tabla temporal para almacenar los resultados
#         CREATE TEMPORARY TABLE IF NOT EXISTS Resultado AS
#         SELECT E.IdEmpleado, E.Apellidos, E.Nombres, C.Cargo, ROUND(SUM(TE.HorasTrabajadas), 0) as TotalHoras
#         FROM Parcial2009.Empleados E
#         JOIN Parcial2009.Cargos C ON E.IdCargo = C.IdCargo
#         JOIN Parcial2009.TrabajaEn TE ON E.IdEmpleado = TE.IdEmpleado
#         WHERE E.IdJefe = _IdEmpleado
#         GROUP BY E.IdEmpleado, E.Apellidos, E.Nombres, C.Cargo;
#
#         -- Comprobar si el empleado tiene empleados a su cargo
#         IF (SELECT COUNT(*) FROM Resultado) = 0 THEN
#             SET _Mensaje = 'Error: El empleado no tiene empleados a su cargo.';
#         ELSE
#             -- Calcular el total de horas trabajadas por todos los empleados
#             SELECT ROUND(SUM(TotalHoras), 0) INTO @totalHoras FROM Resultado;
#
#             -- Seleccionar todos los empleados y sus horas trabajadas
#             SELECT * FROM Resultado
#             UNION ALL
#             -- Seleccionar el total de horas trabajadas por todos los empleados
#             SELECT NULL, NULL, NULL, 'Total', CAST(@totalHoras AS UNSIGNED);
#
#             SET _Mensaje = 'Consulta ejecutada con éxito.';
#         END IF;
#
#         -- Eliminar la tabla temporal
#         DROP TEMPORARY TABLE IF EXISTS Resultado;
#     END IF;
# END //


DROP PROCEDURE IF EXISTS rsp_empleados_a_cargo;

DELIMITER //

CREATE PROCEDURE rsp_empleados_a_cargo(IN _IdEmpleado INT)
BEGIN
    SELECT TE.IdEmpleado, E.Apellidos, E.Nombres, C.Cargo, SUM(TE.HorasTrabajadas) as TotalHoras
    FROM TrabajaEn TE
    INNER JOIN Empleados E on TE.IdEmpleado = E.IdEmpleado
    INNER JOIN Cargos C on E.IdCargo = C.IdCargo
    WHERE E.IdJefe = _IdEmpleado
    GROUP BY TE.IdEmpleado, E.Apellidos, E.Nombres, C.Cargo
#     WITH ROLLUP
    ORDER BY TE.IdEmpleado, E.Apellidos, E.Nombres, C.Cargo, TotalHoras ;

END//

DELIMITER ;

CALL rsp_empleados_a_cargo(2);
SELECT @mensaje;

SELECT * FROM Empleados
JOIN Cargos C on C.IdCargo = Empleados.IdCargo
JOIN TrabajaEn TE on Empleados.IdEmpleado = TE.IdEmpleado;


# iii) Realizar una vista que muestre un listado de trabajos con el total de horas estimado y el real trabajado
# (NombreObra, Descripción, Horas, Total HorasTrabajadas). Llamarla vista_trabajos.

DROP VIEW IF EXISTS vista_trabajos;

CREATE VIEW vista_trabajos AS
SELECT O.NombreObra,
       T.Descripcion,
       T.Horas,
       SUM(TE.HorasTrabajadas) AS TotalHorasTrabajadas
FROM Obras O
         JOIN
     Trabajos T ON O.IdObra = T.IdObra
         JOIN
     TrabajaEn TE ON O.IdObra = TE.IdObra AND T.IdTrabajo = TE.IdTrabajo
GROUP BY O.NombreObra, T.Descripcion, T.Horas;

SELECT *
FROM vista_trabajos;


# iv) Realizar un SP para dar de alta un empleado. Efectuar las comprobaciones y devolver mensajes de
# error. Llamarlo rsp_alta_empleado.

DROP PROCEDURE IF EXISTS rsp_alta_empleado;

DELIMITER $$
CREATE PROCEDURE rsp_alta_empleado(
    IN IN_IdCargo INT,
    IN IN_IdJefe INT,
    IN IN_Apellidos VARCHAR(50),
    IN IN_Nombres VARCHAR(50),
    IN IN_Direccion VARCHAR(75),
    IN IN_Telefono CHAR(7),
    OUT mensaje VARCHAR(100)
)
SALIR: BEGIN
    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM Cargos WHERE IdCargo = IN_IdCargo) THEN
        SET mensaje = 'El cargo no existe';
        LEAVE SALIR;
    END IF;

    IF IN_IdJefe IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Empleados WHERE IdEmpleado = IN_IdJefe) THEN
        SET mensaje = 'El jefe no existe';
        LEAVE SALIR;
    END IF;

    IF LENGTH(IN_Telefono) != 7 THEN
        SET mensaje = 'Error: El teléfono debe tener 7 caracteres';
        LEAVE SALIR;
    END IF;

    INSERT INTO Empleados (IdCargo, IdJefe, Apellidos, Nombres, Direccion, Telefono)
    VALUES ( IN_IdCargo, IN_IdJefe, IN_Apellidos, IN_Nombres, IN_Direccion, IN_Telefono);
    SET mensaje = 'Empleado dado de alta correctamente';
    COMMIT;
END $$

DELIMITER ;

CALL rsp_alta_empleado( 4, 1, 'Sanchez', 'Ignacio', 'Pellegrini 14911', '4670989', @mensaje);
SELECT @mensaje;
