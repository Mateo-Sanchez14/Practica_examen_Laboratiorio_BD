DROP SCHEMA IF EXISTS Parcial2016;

CREATE SCHEMA IF NOT EXISTS Parcial2016;

USE Parcial2016;

-- Crear tabla establecimientos
CREATE TABLE establecimientos (
    IdEstablecimiento INTEGER NOT NULL,
    Codigo VARCHAR(10) NOT NULL,
    Nombre VARCHAR(100) NOT NULL,
    Domicilio VARCHAR(70) NOT NULL,
    Tipo VARCHAR(10) NOT NULL,
    PRIMARY KEY (IdEstablecimiento),
    UNIQUE (Codigo),
    UNIQUE (Nombre),

    constraint chk_tipo check (Tipo in ('Público', 'Privado'))
);

-- Crear tabla niveles
CREATE TABLE niveles (
    IdNivel INTEGER NOT NULL,
    Nombre VARCHAR(15) NOT NULL,
    PRIMARY KEY (IdNivel),
    UNIQUE (Nombre)
);

-- Crear tabla planesestudio
CREATE TABLE planesestudio (
    IdPlan INTEGER NOT NULL,
    Nombre VARCHAR(70) NULL,
    Desde DATE NULL,
    Hasta DATE NULL,
    PRIMARY KEY (IdPlan),
    UNIQUE (Nombre),

    constraint chk_fechas check (Desde <= Hasta)
);

-- Crear tabla materias
CREATE TABLE materias (
    Codigo INTEGER NOT NULL,
    Nombre VARCHAR(30) NOT NULL,
    Tipo VARCHAR(20) NOT NULL,
    PRIMARY KEY (Codigo),
    UNIQUE (Nombre),

    constraint chk_tipo_materia check (Tipo in ('Obligatoria', 'Opcional'))
);

-- Crear tabla ofertaacademica
CREATE TABLE ofertaacademica (
    IdPlan INTEGER NOT NULL,
    IdNivel INTEGER NOT NULL,
    IdEstablecimiento INTEGER NOT NULL,
    PRIMARY KEY (IdPlan, IdNivel, IdEstablecimiento),
    FOREIGN KEY (IdPlan) REFERENCES planesestudio(IdPlan),
    FOREIGN KEY (IdNivel) REFERENCES niveles(IdNivel),
    FOREIGN KEY (IdEstablecimiento) REFERENCES establecimientos(IdEstablecimiento)
);

-- Crear tabla detalleplan
CREATE TABLE detalleplan (
    IdPlan INTEGER NOT NULL,
    Codigo INTEGER NOT NULL,
    CargaHoraria INTEGER NOT NULL,
    PRIMARY KEY (IdPlan, Codigo),
    FOREIGN KEY (IdPlan) REFERENCES planesestudio(IdPlan),
    FOREIGN KEY (Codigo) REFERENCES materias(Codigo)
);

-- Verificar los indices de el schema, cualquier omisión por inferencia discutir con el motor, no conmigo
SELECT TABLE_NAME, INDEX_NAME,
       IF(NON_UNIQUE = 1, 'NO', 'SI') AS UNIQUE_FLAG,
      COLUMN_NAME
FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = 'Parcial2016';

# ii) Realizar una vista, llamada OfertaAcademicaEstablecimientos donde se muestre el Nombre del Establecimiento,
# el nivel, el Nombre de PlanEstudio, la Materia y la CargaHoraria.
# Contemplar aquellos planes que no tengan una oferta académica. [20].

DROP VIEW IF EXISTS OfertaAcademicaEstablecimientos;

CREATE VIEW OfertaAcademicaEstablecimientos AS
    SELECT
        E.Nombre AS NombreEstablecimiento,
        N.Nombre AS Nivel,
        PE.Nombre AS PlanEstudio,
        M.Nombre AS Materia,
        DP.CargaHoraria
    FROM planesestudio PE
    LEFT JOIN ofertaacademica o on PE.IdPlan = o.IdPlan
    LEFT JOIN establecimientos E on o.IdEstablecimiento = E.IdEstablecimiento
    LEFT JOIN niveles N on o.IdNivel = N.IdNivel
    LEFT JOIN detalleplan DP on PE.IdPlan = DP.IdPlan
    LEFT JOIN materias M on DP.Codigo = M.Codigo
    ORDER BY E.Nombre, N.Nombre, PE.Nombre, M.Nombre;

SELECT * FROM OfertaAcademicaEstablecimientos;

-- TEST: Ver planes de estudio sin oferta académica

SELECT * FROM planesestudio PE
WHERE PE.IdPlan NOT IN (
    SELECT IdPlan FROM ofertaacademica
);

INSERT INTO planesestudio VALUES (1, 'Plan sin oferta', '2020-01-01', '2020-12-31');

# iii) Realizar un SP, llamado CargarMateriaEnPlan el cual cargue una determinada materia en el plan de estudios
# , efectuar las comprobaciones necesarias y devolver los mensajes de error correspondiente [15].

DROP PROCEDURE IF EXISTS CargarMateriaEnPlan;

DELIMITER $$

CREATE PROCEDURE CargarMateriaEnPlan (
    IN p_IdPlan INTEGER,
    IN p_CodigoMateria INTEGER,
    IN p_CargaHoraria INTEGER,
    OUT mensaje VARCHAR(100)
)
SALIR: BEGIN
    IF p_IdPlan IS NULL OR p_CodigoMateria IS NULL OR p_CargaHoraria IS NULL THEN
        SET mensaje = 'Los parámetros no pueden ser nulos';
        LEAVE SALIR;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM planesestudio WHERE IdPlan = p_IdPlan) THEN
        SET mensaje = 'El plan de estudio no existe';
        LEAVE SALIR;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM materias WHERE Codigo = p_CodigoMateria) THEN
        SET mensaje = 'La materia no existe';
        LEAVE SALIR;
    END IF;

    IF p_CargaHoraria <= 0 THEN
        SET mensaje = 'La carga horaria debe ser mayor a 0';
        LEAVE SALIR;
    END IF;

    IF EXISTS (SELECT 1 FROM detalleplan WHERE IdPlan = p_IdPlan AND Codigo = p_CodigoMateria) THEN
        SET mensaje = 'La materia ya se encuentra en el plan de estudio';
        LEAVE SALIR;
    END IF;

    INSERT INTO detalleplan VALUES (p_IdPlan, p_CodigoMateria, p_CargaHoraria);
    SET mensaje = 'Materia cargada correctamente';

END$$

DELIMITER ;

-- Llamada al SP con todos los casos posibles.

-- Caso 1: Parámetros nulos
CALL CargarMateriaEnPlan(NULL, 1, 10, @mensaje);
SELECT @mensaje;

-- Caso 2: Plan de estudio no existe
CALL CargarMateriaEnPlan(100, 1, 10, @mensaje);
SELECT @mensaje;

-- Caso 3: Materia no existe
CALL CargarMateriaEnPlan(1, 100, 10, @mensaje);
SELECT @mensaje;

-- Caso 4: Carga horaria menor o igual a 0

CALL CargarMateriaEnPlan(1, 1, 0, @mensaje);
SELECT @mensaje;

-- Caso 5: Materia ya se encuentra en el plan de estudio
-- Test: Ver materias del plan 4
# SELECT * FROM detalleplan WHERE IdPlan = 4;
-- Podemos observar que la materia con codigo uno esta en el plan 4

CALL CargarMateriaEnPlan(4, 1, 10, @mensaje);
SELECT @mensaje;

-- Caso 6: Creacion correcta, añado al plan 4 la materia 13 con 10 horas
-- Test ver materias posibles
# SELECT * FROM materias;
CALL CargarMateriaEnPlan(4, 13, 10, @mensaje);
SELECT @mensaje;

# iv) Realizar un trigger llamado AuditarCargaHoraria el cual se dispare luego de modificar la carga horaria
# por un valor menor o igual a cero, los datos se deben guardar en la tabla auditoria guardando
# el valor original de la carga horaria, la materia y el plan de estudio, el usuario la fecha en que se realizó [25].

DROP TABLE IF EXISTS auditoria_carga_horaria;

CREATE TABLE auditoria_carga_horaria (
    IdAuditoria INTEGER AUTO_INCREMENT PRIMARY KEY,
    IdPlan INTEGER NOT NULL,
    CodigoMateria INTEGER NOT NULL,
    CargaHorariaOriginal INTEGER NOT NULL,
    Usuario VARCHAR(50) NOT NULL,
    Fecha TIMESTAMP NOT NULL
);

DROP TRIGGER IF EXISTS AuditarCargaHoraria;

DELIMITER $$

CREATE TRIGGER AuditarCargaHoraria
AFTER UPDATE ON detalleplan
FOR EACH ROW
BEGIN
    IF NEW.CargaHoraria <= 0 THEN
        INSERT INTO auditoria_carga_horaria (IdPlan, CodigoMateria, CargaHorariaOriginal, Usuario, Fecha)
        VALUES (NEW.IdPlan, NEW.Codigo, OLD.CargaHoraria, USER(), NOW());
    END IF;
END$$

DELIMITER ;

-- Test: Modificar la carga horaria de la materia 13 del plan 4 a 0

UPDATE detalleplan
SET CargaHoraria = 0
WHERE IdPlan = 4 AND Codigo = 13;

SELECT * FROM auditoria_carga_horaria;