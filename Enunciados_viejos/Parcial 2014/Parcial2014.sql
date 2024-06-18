DROP SCHEMA IF EXISTS Parcial2014;

CREATE SCHEMA Parcial2014;

USE Parcial2014;

CREATE TABLE Categorias
(
    IdCategoria INTEGER     NOT NULL AUTO_INCREMENT,
    Categoria   VARCHAR(25) NOT NULL,
    PRIMARY KEY (IdCategoria),
    UNIQUE (Categoria)
);

CREATE TABLE Niveles
(
    IdNivel INTEGER     NOT NULL AUTO_INCREMENT,
    Nivel   VARCHAR(25) NOT NULL,
    PRIMARY KEY (IdNivel),
    UNIQUE (Nivel),
    CHECK (Nivel IN ('Nulo', 'Básico', 'Intermedio', 'Avanzado', 'Experto'))
);

CREATE TABLE Puestos
(
    IdPuesto INTEGER     NOT NULL AUTO_INCREMENT,
    Puesto   VARCHAR(25) NOT NULL,
    PRIMARY KEY (IdPuesto),
    UNIQUE (Puesto),
    CHECK (Puesto IN ('Programador', 'Analista', 'Líder'))
);

CREATE TABLE Conocimientos
(
    IdConocimiento INTEGER     NOT NULL AUTO_INCREMENT,
    IdCategoria    INTEGER     NOT NULL,
    Conocimiento   VARCHAR(25) NOT NULL,
    PRIMARY KEY (IdConocimiento, IdCategoria),
    UNIQUE (Conocimiento),
    FOREIGN KEY (IdCategoria) REFERENCES Categorias (IdCategoria)
);

CREATE TABLE Personas
(
    IdPersona    INTEGER     NOT NULL AUTO_INCREMENT,
    IdPuesto     INTEGER     NOT NULL,
    Nombres      VARCHAR(25) NOT NULL,
    Apellidos    VARCHAR(25) NOT NULL,
    FechaIngreso DATE        NOT NULL,
    FechaBaja    DATE        NULL,
    PRIMARY KEY (IdPersona, IdPuesto),
    INDEX (Apellidos, Nombres),
    INDEX (FechaIngreso),
    FOREIGN KEY (IdPuesto) REFERENCES Puestos (IdPuesto)
);

CREATE TABLE Skills
(
    IdSkill                 INTEGER      NOT NULL AUTO_INCREMENT,
    IdPersona               INTEGER      NOT NULL,
    IdConocimiento          INTEGER      NOT NULL,
    IdCategoria             INTEGER      NOT NULL,
    IdNivel                 INTEGER      NOT NULL,
    FechaUltimaModificacion DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Observaciones           VARCHAR(144) NULL,
    PRIMARY KEY (IdSkill, IdPersona, IdConocimiento, IdCategoria, IdNivel),
    INDEX (IdPersona),
    INDEX (IdConocimiento),
    INDEX (IdCategoria),
    INDEX (IdCategoria, IdConocimiento),
    INDEX (IdNivel),
    FOREIGN KEY (IdPersona) REFERENCES Personas (IdPersona),
    FOREIGN KEY (IdConocimiento, IdCategoria) REFERENCES Conocimientos (IdConocimiento, IdCategoria),
    FOREIGN KEY (IdNivel) REFERENCES Niveles (IdNivel)
);

# Show Indexes from the schema
SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'Parcial2014';


# ii) Crear una vista llamada vista_conocimientos_por_empleado, que muestre
# la categoría, conocimiento, empleado (nombres, apellidos) y nivel de los empleados en actividad,
# ordenados por categoría y conocimiento [10].

DROP VIEW IF EXISTS vista_conocimientos_por_empleado;

CREATE VIEW vista_conocimientos_por_empleado AS
SELECT C.Categoria, CO.Conocimiento, P.Nombres, P.Apellidos, N.Nivel
FROM Personas P
         INNER JOIN Skills S
                    ON P.IdPersona = S.IdPersona
         INNER JOIN Conocimientos CO
                    ON S.IdConocimiento = CO.IdConocimiento
         INNER JOIN Categorias C
                    ON CO.IdCategoria = C.IdCategoria
         INNER JOIN Niveles N
                    ON S.IdNivel = N.IdNivel
WHERE P.FechaBaja IS NULL
ORDER BY C.Categoria, CO.Conocimiento;

SELECT *
FROM vista_conocimientos_por_empleado;

# iii) Realizar un SP, llamado rsp_alta_skill, para dar de alta un skill,
# efectuando las comprobaciones mínimas (3 por lo menos). Devolver los mensajes de error correspondientes [20].

DROP PROCEDURE IF EXISTS rsp_alta_skill;

DELIMITER $$

CREATE PROCEDURE rsp_alta_skill(
    IN p_IdPersona INTEGER,
    IN p_IdConocimiento INTEGER,
    IN p_IdCategoria INTEGER,
    IN p_IdNivel INTEGER,
    IN p_Observaciones VARCHAR(144),
    OUT p_Resultado VARCHAR(144)
)
Salir:
BEGIN
    DECLARE v_existePersona INTEGER;
    DECLARE v_CantidadSkills INTEGER;

    IF p_IdPersona IS NULL OR p_IdConocimiento IS NULL OR p_IdCategoria IS NULL OR p_IdNivel IS NULL THEN
        SET p_Resultado = 'Faltan datos';
        LEAVE Salir;
    END IF;

    SELECT 1 FROM Personas WHERE IdPersona = p_IdPersona AND FechaBaja IS NULL INTO v_existePersona;

    IF v_existePersona IS NULL THEN
        SET p_Resultado = 'El empleado no existe o está dado de baja';
        LEAVE Salir;
    END IF;

    SELECT COUNT(*)
    INTO v_CantidadSkills
    FROM Skills
    WHERE IdPersona = p_IdPersona
      AND IdConocimiento = p_IdConocimiento
      AND IdCategoria = p_IdCategoria;

    IF v_CantidadSkills > 0 THEN
        SET p_Resultado = 'El empleado ya posee ese skill';
        LEAVE Salir;
    END IF;

    INSERT INTO Skills (IdPersona, IdConocimiento, IdCategoria, IdNivel, Observaciones)
    VALUES (p_IdPersona, p_IdConocimiento, p_IdCategoria, p_IdNivel, p_Observaciones);

    SET p_Resultado = 'Skill dado de alta';

END$$

DELIMITER ;

-- Llamada al SP con todos los casos de errores.
SELECT *
FROM Personas;

-- Envio un campo null

CALL rsp_alta_skill(1, NULL, 1, 1, 'Observaciones', @resultado);
SELECT @resultado;

-- Envio un empleado que no existe
CALL rsp_alta_skill(21, 1, 1, 1, 'Observaciones', @resultado);
SELECT @resultado;

-- Envio un skill que ya posee el empleado
SELECT *
FROM Skills
WHERE IdPersona = 1;
CALL rsp_alta_skill(1, 1, 1, 1, 'Observaciones', @resultado);
SELECT @resultado;

-- Envio un skill que no posee el empleado, con datos correctos
CALL rsp_alta_skill(1, 10, 1, 1, 'Agregada con el SP', @resultado);
SELECT @resultado;

# iv) Realizar un SP, llamado rsp_cantidad_por_conocimiento que muestre la cantidad empleados
# que hay de cada conocimiento, ordenados por categoría y conocimiento de forma descendente, de la forma:
# Categoría, Conocimiento, Cantidad [15].

DROP PROCEDURE IF EXISTS rsp_cantidad_por_conocimiento;

DELIMITER $$

CREATE PROCEDURE rsp_cantidad_por_conocimiento()
BEGIN
    SELECT C.Categoria, CO.Conocimiento, COUNT(P.IdPersona) AS Cantidad
    FROM Categorias C
             INNER JOIN Conocimientos CO
                        ON C.IdCategoria = CO.IdCategoria
             LEFT JOIN Skills S
                       ON CO.IdConocimiento = S.IdConocimiento AND CO.IdCategoria = S.IdCategoria
             LEFT JOIN Personas P
                       ON S.IdPersona = P.IdPersona
    WHERE P.FechaBaja IS NULL
    GROUP BY C.Categoria, CO.Conocimiento
    ORDER BY C.Categoria DESC, CO.Conocimiento DESC;
END$$

DELIMITER ;

CALL rsp_cantidad_por_conocimiento();

# Creo un conocimiento que no lo tenga nadie
# INSERT INTO Conocimientos (IdCategoria, Conocimiento) VALUES (1, 'ConocimientoNuevo');

# v) Utilizando triggers, implementar la lógica para llevar una auditoría de la tabla Skills para el caso de inserción.
# Se deberá auditar la operación, el usuario que la hizo, la fecha y hora, el host
# y la máquina desde donde se realizó la operación. Llamarlo trigger_audit_skills, y a la tabla: audit_skills [15]


DROP TABLE IF EXISTS audit_skills;

CREATE TABLE audit_skills
(
    IdAudit                 INTEGER      NOT NULL AUTO_INCREMENT,
    IdSkill                 INTEGER      NOT NULL,
    IdPersona               INTEGER      NOT NULL,
    IdConocimiento          INTEGER      NOT NULL,
    IdCategoria             INTEGER      NOT NULL,
    IdNivel                 INTEGER      NOT NULL,
    FechaUltimaModificacion DATETIME     NOT NULL,
    Observaciones           VARCHAR(144) NULL,
    Usuario                 VARCHAR(25)  NOT NULL,
    Host                    VARCHAR(25)  NOT NULL,
    Operacion               VARCHAR(25)  NOT NULL,
    Timestamp               TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (IdAudit),
    INDEX (IdSkill),
    INDEX (IdPersona),
    INDEX (IdConocimiento),
    INDEX (IdCategoria),
    INDEX (IdNivel),

    CHECK ( Operacion IN ('INSERT', 'UPDATE', 'DELETE'))
);

DROP TRIGGER IF EXISTS trigger_audit_skills;

DELIMITER $$

CREATE TRIGGER trigger_audit_skills
    AFTER INSERT
    ON Skills
    FOR EACH ROW
BEGIN
    DECLARE v_Host VARCHAR(25);
    DECLARE v_Usuario VARCHAR(25);

    SET v_Host = SUBSTRING_INDEX(USER(), '@', -1);
    SET v_Usuario = SUBSTRING_INDEX(USER(), '@', 1);

    INSERT INTO audit_skills (IdSkill, IdPersona, IdConocimiento, IdCategoria, IdNivel, FechaUltimaModificacion,
                              Observaciones, Usuario, Host, Operacion)
    VALUES (NEW.IdSkill, NEW.IdPersona, NEW.IdConocimiento, NEW.IdCategoria, NEW.IdNivel, NEW.FechaUltimaModificacion,
            NEW.Observaciones, v_Usuario, v_Host, 'INSERT');
END$$

DELIMITER ;

# Inserto un skill para que se audite
CALL rsp_alta_skill(2, 10, 1, 1, 'Observaciones', @resultado);

# Muestro la tabla audit_skills
SELECT *
FROM audit_skills;
