-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema 40217292
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `40217292` ;

-- -----------------------------------------------------
-- Schema 40217292
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `40217292` DEFAULT CHARACTER SET utf8 ;
USE `40217292` ;

-- -----------------------------------------------------
-- Table `Editoriales`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Editoriales` ;

CREATE TABLE IF NOT EXISTS `Editoriales` (
  `idEditorial` CHAR(4) NOT NULL,
  `nombre` VARCHAR(40) NOT NULL,
  `ciudad` VARCHAR(20) NULL,
  `estado` CHAR(2) NULL,
  `pais` VARCHAR(30) NOT NULL DEFAULT 'USA',
  PRIMARY KEY (`idEditorial`))
ENGINE = InnoDB;

CREATE UNIQUE INDEX `nombre_UNIQUE` ON `Editoriales` (`nombre` ASC) VISIBLE;


-- -----------------------------------------------------
-- Table `Titulos`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Titulos` ;

CREATE TABLE IF NOT EXISTS `Titulos` (
  `idTitulo` VARCHAR(6) NOT NULL,
  `titulo` VARCHAR(80) NOT NULL,
  `genero` CHAR(12) NOT NULL DEFAULT 'UNDECIDED',
  `idEditorial` CHAR(4) NOT NULL,
  `precio` DECIMAL(8,2) NULL,
  `sinopsis` VARCHAR(200) NULL,
  `fechaPublicacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (`idTitulo`),
  CONSTRAINT `fk_Titulos_Editoriales1`
    FOREIGN KEY (`idEditorial`)
    REFERENCES `Editoriales` (`idEditorial`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_Titulos_Editoriales1_idx` ON `Titulos` (`idEditorial` ASC) VISIBLE;

ALTER TABLE `Titulos` ADD CONSTRAINT `PrecioTitulo-CK` CHECK (`Precio` > 0);
-- -----------------------------------------------------
-- Table `Tiendas`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Tiendas` ;

CREATE TABLE IF NOT EXISTS `Tiendas` (
  `idTienda` CHAR(4) NOT NULL,
  `nombre` VARCHAR(40) NOT NULL,
  `domicilio` VARCHAR(40) NULL,
  `ciudad` VARCHAR(20) NULL,
  `estado` CHAR(2) NULL,
  `codigoPostal` CHAR(5) NULL,
  PRIMARY KEY (`idTienda`))
ENGINE = InnoDB;

CREATE UNIQUE INDEX `nombre_UNIQUE` ON `Tiendas` (`nombre` ASC) VISIBLE;


-- -----------------------------------------------------
-- Table `Ventas`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Ventas` ;

CREATE TABLE IF NOT EXISTS `Ventas` (
  `codigoVenta` VARCHAR(20) NOT NULL,
  `idTienda` CHAR(4) NOT NULL,
  `fecha` DATETIME NOT NULL,
  `tipo` VARCHAR(12) NOT NULL,
  PRIMARY KEY (`codigoVenta`),
  CONSTRAINT `fk_Ventas_Tiendas1`
    FOREIGN KEY (`idTienda`)
    REFERENCES `Tiendas` (`idTienda`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_Ventas_Tiendas1_idx` ON `Ventas` (`idTienda` ASC) VISIBLE;


-- -----------------------------------------------------
-- Table `Detalles`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Detalles` ;

CREATE TABLE IF NOT EXISTS `Detalles` (
  `idDetalle` INT NOT NULL AUTO_INCREMENT ,
  `codigoVenta` VARCHAR(20) NOT NULL,
  `idTitulo` VARCHAR(6) NOT NULL,
  `cantidad` SMALLINT NOT NULL,
  PRIMARY KEY (`idDetalle`),
  CONSTRAINT `fk_Detalles_Ventas1`
    FOREIGN KEY (`codigoVenta`)
    REFERENCES `Ventas` (`codigoVenta`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Detalles_Titulos1`
    FOREIGN KEY (`idTitulo`)
    REFERENCES `Titulos` (`idTitulo`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_Detalles_Ventas1_idx` ON `Detalles` (`codigoVenta` ASC) VISIBLE;

CREATE INDEX `fk_Detalles_Titulos1_idx` ON `Detalles` (`idTitulo` ASC) VISIBLE;

ALTER TABLE `Detalles` ADD CONSTRAINT `Cantidad-CK` CHECK (`Cantidad` > 0);
-- -----------------------------------------------------
-- Table `Autores`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Autores` ;

CREATE TABLE IF NOT EXISTS `Autores` (
  `idAutor` VARCHAR(11) NOT NULL,
  `apellido` VARCHAR(40) NOT NULL,
  `nombre` VARCHAR(20) NOT NULL,
  `telefono` CHAR(12) NOT NULL DEFAULT 'UNKNOWN',
  `domicilio` VARCHAR(40) NULL,
  `ciudad` VARCHAR(20) NULL,
  `estado` CHAR(2) NULL,
  `codigoPostal` CHAR(5) NULL,
  PRIMARY KEY (`idAutor`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `TitulosDelAutor`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `TitulosDelAutor` ;

CREATE TABLE IF NOT EXISTS `TitulosDelAutor` (
  `idAutor` VARCHAR(11) NOT NULL,
  `idTitulo` VARCHAR(6) NOT NULL,
  PRIMARY KEY (`idAutor`, `idTitulo`),
  CONSTRAINT `fk_Autores_has_Titulos_Autores`
    FOREIGN KEY (`idAutor`)
    REFERENCES `Autores` (`idAutor`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Autores_has_Titulos_Titulos1`
    FOREIGN KEY (`idTitulo`)
    REFERENCES `Titulos` (`idTitulo`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_Autores_has_Titulos_Titulos1_idx` ON `TitulosDelAutor` (`idTitulo` ASC) VISIBLE;

CREATE INDEX `fk_Autores_has_Titulos_Autores_idx` ON `TitulosDelAutor` (`idAutor` ASC) VISIBLE;



/* Punto 2:
muestre por cada tienda su código,
cantidad total de ventas y el importe total de todas esas ventas. La salida, mostrada en la
siguiente tabla, deberá estar ordenada descendentemente según la cantidad total de ventas
y el importe de las mismas. Incluir el código con la consulta a la vista
*/

DROP VIEW IF EXISTS `VCantidadVentas`;

CREATE VIEW `VCantidadVentas`
AS
	SELECT ti.idTienda AS 'Id Tienda', COUNT(v.codigoVenta) AS 'Cantidad de Ventas', SUM(t.precio * d.cantidad) AS 'Importe Total de Ventas'
	FROM Tiendas ti JOIN Ventas v ON ti.idTienda = v.idTienda
    JOIN Detalles d  ON d.codigoVenta = v.codigoVenta
    JOIN Titulos t ON t.idTitulo = d.idTitulo
    GROUP BY ti.idTienda
    ORDER BY COUNT(v.codigoVenta) DESC;

/*
SELECT * FROM `VCantidadVentas`;
*/  
    
    
    
/* Punto 3: Realizar un procedimiento almacenado llamado NuevaEditorial para dar de alta una
editorial, incluyendo el control de errores lógicos y mensajes de error necesarios
(implementar la lógica del manejo de errores empleando parámetros de salida). Incluir el
código con la llamada al procedimiento probando todos los casos con datos incorrectos y
uno con datos correctos. [20 puntos]
ppais` VARCHAR(30) NOT NULL DEFAULT 'USA',
*/
    
DROP PROCEDURE IF EXISTS `NuevaEditorial`;

DELIMITER //
CREATE PROCEDURE `NuevaEditorial`(pidEditorial CHAR(4), pnombre VARCHAR(40), pciudad VARCHAR(20), pestado CHAR(2),
								ppais VARCHAR(30), OUT Mensaje VARCHAR(120))
SALIR: BEGIN
		IF(pidEditorial IS NULL OR pnombre IS NULL) THEN
			SET Mensaje = 'Error faltan completar datos';
			LEAVE SALIR;
		END IF;

		IF EXISTS (SELECT * FROM Editoriales WHERE idEditorial = pidEditorial) THEN
				SET Mensaje =   'Ya existe una editorial con el Id ingresado';
			LEAVE SALIR;
		END IF;
    
    
		IF EXISTS (SELECT * FROM Editoriales WHERE nombre = pnombre) THEN
				SET Mensaje =   'Ya existe una editorial con el nombre ingresado';
			LEAVE SALIR;
		END IF;
        
  
		IF (ppais IS NULL) THEN INSERT INTO Editoriales VALUES (pidEditorial, pnombre, pciudad, pestado, 'USA');
            SET Mensaje = 'La editorial fue creada con éxito';

		ELSE INSERT INTO Editoriales VALUES (pidEditorial, pnombre, pciudad, pestado, ppais);
            SET Mensaje = 'La editorial fue creada con éxito';
		
    	END IF;
    
 END //
 DELIMITER ;
 
    /*
-- Error: falta ingresar datos
 CALL `NuevaEditorial`(NULL, 'Lucerne', 'Paris', NULL, 'France', @resultado);
 SELECT @resultado;
    
-- Error: existe una editorial con ese id
 CALL `NuevaEditorial`('9999', 'Lucerne', 'Paris', NULL, 'France', @resultado);
 SELECT @resultado;

 -- Error: existe una editorial con ese nombre
 CALL `NuevaEditorial`('1000', 'Lucerne Publishing', 'Paris', NULL, 'France', @resultado);
 SELECT @resultado;   
  
 -- SI FUNCIONA: No se ingresa un pais, se pone por default USA 
  CALL `NuevaEditorial`('1000', 'Adventure Publishing', 'Paris', NULL, NULL, @resultado);
 SELECT @resultado;   
  
 -- SI FUNCIONA: se ingresa todo lo que tenia que ingresar
  CALL `NuevaEditorial`('1001', 'Red White', 'Paris',NULL,'France', @resultado);
 SELECT @resultado;   
  
*/



/* Punto 4: Realizar un procedimiento almacenado llamado BuscarTitulosPorAutor que reciba el
código de un autor y muestre los títulos del mismo. Por cada título del autor especificado se
deberá mostrar su código y título, género, nombre de la editorial, precio, sinopsis y fecha de
publicación. La salida, mostrada en la siguiente tabla, deberá estar ordenada
alfabéticamente según el título. Incluir en el código la llamada al procedimiento.
*/

DROP PROCEDURE IF EXISTS `BuscarTitulosPorAutor`;

DELIMITER //
CREATE PROCEDURE `BuscarTitulosPorAutor`(pidAutor VARCHAR(11), OUT Mensaje VARCHAR(120))
SALIR: BEGIN
		IF(pidAutor IS NULL) THEN
			SET Mensaje = 'Es necesario ingresar un Id autor';
		LEAVE SALIR;
        END IF;
        
         IF NOT EXISTS(SELECT * FROM Autores WHERE idAutor = pidAutor) THEN
			SET Mensaje = 'El autor que busca no existe';
		LEAVE SALIR;
		END IF;
        
        SELECT t.idTitulo AS 'Codigo', t.titulo AS 'Titulo', t.genero AS 'Genero', edi.nombre AS 'Editorial', 
				t.precio AS 'Precio', t.sinopsis AS 'Sinopsis', t.fechaPublicacion AS 'Fecha'
        FROM Editoriales edi JOIN Titulos t ON edi.idEditorial = t.idEditorial
        JOIN TitulosDelAutor ta ON ta.idTitulo = t.idTitulo
        JOIN Autores a ON a.idAutor = ta.idAutor
        WHERE a.idAutor = pidAutor
        ORDER BY t.titulo;

END //
DELIMITER ;

/*
-- anda
CALL `BuscarTitulosPorAutor`('486-29-1786', @resultado);
SELECT @resultado;

-- error: no se ingresa id 
CALL `BuscarTitulosPorAutor`(NULL, @resultado);
SELECT @resultado;

-- error: no existe ese autor
CALL `BuscarTitulosPorAutor`('123', @resultado);
SELECT @resultado;

*/



/*Punto 5:
5) Utilizando triggers, implementar la lógica para que en caso que se quiera borrar una
editorial referenciada por un título se informe mediante un mensaje de error que no se
puede. Incluir el código con los borrados de una editorial que no tiene títulos, y otro de una
que sí. */

DROP TRIGGER IF EXISTS `Trigger_BorrarEditorial`;

DELIMITER //
CREATE TRIGGER `Trigger_BorrarEditorial` 
BEFORE DELETE ON `Editoriales` FOR EACH ROW
BEGIN
 IF EXISTS(SELECT * FROM Titulos WHERE idEditorial = OLD.idEditorial) THEN
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: no se puede borrar la Editorial, ya que existe un titulo asociado', MYSQL_ERRNO = 45000;
 END IF;
END //
DELIMITER ;

/*
-- No se puede ya que tiene titulos asociados
DELETE FROM Editoriales WHERE idEditorial = 0736;

-- Si se puede borrar ya que la editorial no tiene titulos
DELETE FROM Editoriales WHERE idEditorial = 1622;

  */
  
  
  
SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;


