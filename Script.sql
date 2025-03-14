-- =============================================
-- PRÁCTICA 2.1: CARGA DE DATOS DESDE CSV
-- =============================================

-- 1. PREPARACIÓN DE LA BASE DE DATOS
-- =============================================

-- Elimina la base de datos si existe para comenzar desde cero
DROP DATABASE IF EXISTS anticipo;

-- Crea la base de datos
CREATE DATABASE anticipo;

-- Se Selecciono la base de datos para trabajar
USE anticipo;


-- 2. CREACIÓN DE TABLA PRINCIPAL (DISPOSICIONES)
-- =============================================
-- Campos iniciales como VARCHAR para fechas
-- Motivo: El formato original del CSV usa fechas en formato dd/mm/aaaa incompatible con DATE
CREATE TABLE Disposicion (
    CO_GRUPO VARCHAR(255) NOT NULL,      -- Código de grupo asociado
    IdPersona BIGINT NOT NULL,           -- Identificador único de persona
    FE_ALTA VARCHAR(11) NOT NULL,        -- Fecha de alta en formato texto (dd/mm/aaaa)
    monto DECIMAL(15, 2) NOT NULL,        -- Cantidad dispuesta
    Fe_castigo VARCHAR(11),               -- Fecha de castigo (puede estar vacía)
    Monto_castigado DECIMAL(15, 2)        -- Es el dinero que ya no se va a cobrar,osea que se da por perdido"
);

-- 3. CONFIGURACIÓN DE MYSQL PARA CARGA DE DATOS
-- =============================================
-- Habilita la carga de archivos locales (requiere privilegios de administrador)
SET GLOBAL local_infile = 1;

-- Muestra la ubicación permitida para cargar archivos (seguridad de MySQL)
SHOW VARIABLES LIKE 'secure_file_priv';

-- Verifica que la carga local esté habilitada
SHOW GLOBAL VARIABLES LIKE 'local_infile';

-- 4. CARGA DE DATOS DESDE ARCHIVO CSV
-- =============================================
-- Importa datos del archivo CAN_2021.csv ubicado en el directorio permitido
-- Delimitadores: Campos con ';', Líneas con '\n', Ignora la primera línea (encabezados)
-- Linux /home/alexisduran/Downloads/SQL_Practica/CAN_2021.csv
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/'
INTO TABLE Disposicion
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SELECT* FROM Disposicion;

-- 5. DEPURACIÓN DE FECHAS
-- =============================================
-- Agrega columnas para almacenar fechas en formato DATE
ALTER TABLE Disposicion
ADD COLUMN FE_ALTA_DEP DATE;    -- Fecha de alta depurada

ALTER TABLE Disposicion
ADD COLUMN Fe_castigo_DEP DATE;          -- Fecha de castigo depurada (puede ser NULL)

-- Habilita actualizaciones sin cláusula WHERE (solo para esta sesión)
SET SQL_SAFE_UPDATES = 0;

-- Convierte texto a fechas usando formato dd/mm/aaaa
-- FE_ALTA_DEP: Conversión directa ya que todos los registros tienen fecha
UPDATE Disposicion
SET FE_ALTA_DEP = STR_TO_DATE(FE_ALTA, '%d/%m/%Y');

-- Actualiza la columna Fe_castigo_DEP en la tabla Disposicion
-- Convierte Fe_castigo (texto) a Fe_castigo_DEP (fecha) y asigna una fecha predeterminada para registros inválidos o vacíos
UPDATE Disposicion
SET Fe_castigo_DEP = CASE
    -- Condición 1: Si Fe_castigo no es NULL, no está vacío y puede convertirse a una fecha válida
    WHEN Fe_castigo IS NOT NULL
         AND Fe_castigo != ''
         AND STR_TO_DATE(Fe_castigo, '%d/%m/%Y') IS NOT NULL THEN
         STR_TO_DATE(Fe_castigo, '%d/%m/%Y')  -- Convierte el texto a fecha usando el formato dd/mm/aaaa

    -- Condición 2: Si Fe_castigo es NULL, está vacío o no es una fecha válida, asigna una fecha predeterminada
    ELSE '2000-01-01'  -- Fecha predeterminada para registros inválidos o vacíos
END;

SELECT *FROM Disposicion;





-- =============================================
-- PRÁCTICA 2.2: CONSULTAS Y TABLAS ADICIONALES
-- =============================================

-- 6. CONSULTAS DE ANÁLISIS
-- =============================================

-- Encuentra el registro con menor pérdida porcentual
SELECT *,
       (Monto_castigado/monto)*100 AS Porcentaje_Perdida
FROM Disposicion
WHERE Monto_castigado > 0
ORDER BY Porcentaje_Perdida
LIMIT 1;

-- 7. CARGA DE TABLA DE CLIENTES
-- =============================================
-- Estructura para datos demográficos de clientes
CREATE TABLE Cliente (
    ID INT,                               -- Identificador único (notar que puede tener duplicados)
    NOMBRE VARCHAR(255) NOT NULL,         -- Primer nombre
    NOMBRE2 VARCHAR(255),                 -- Segundo nombre (opcional)
    APE_PATERNO VARCHAR(255) NOT NULL,    -- Apellido paterno
    APE_MATERNO VARCHAR(255),             -- Apellido materno (opcional)
    CIUDAD VARCHAR(100) NOT NULL          -- Ciudad de residencia
);

-- Importa datos desde CLIENTE.csv (codificación latina para caracteres especiales)
-- Linux /home/alexisduran/Downloads/SQL_Practica/CLIENTE.csv
LOAD DATA LOCAL INFILE '/home/alexisduran/Downloads/SQL_Practica/CLIENTE.csv'
INTO TABLE Cliente
CHARACTER SET latin1
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

SELECT * FROM Cliente;

-- 8. CARGA DE TABLA DE GRUPOS
-- =============================================
-- Estructura para información de grupos empresariales
CREATE TABLE Grupo (
    CO_GRUPO VARCHAR(10),                 -- Código de grupo (clave primaria natural)
    DE_ESTATUS VARCHAR(20) NULL,      -- Estatus actual (Activo/Inactivo)
    DE_NOMBRE VARCHAR(100) NULL,      -- Nombre del grupo
    DE_RFC VARCHAR(20)                    -- RFC con posibles espacios/formatos erróneos
);


-- Importa datos desde GRUPOS.csv
-- Linux /home/alexisduran/Downloads/SQL_Practica/GRUPOS.csv
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/GRUPOS.csv'
INTO TABLE Grupo
CHARACTER SET latin1
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;



-- 9. DEPURACIÓN DE RFC EN GRUPOS
-- =============================================
-- Agrega columna para RFC limpio (sin espacios ni comillas)
ALTER TABLE Grupo
ADD COLUMN DE_RFC_DEP VARCHAR(20);

-- Actualiza RFCs: Elimina comillas y espacios en blanco
UPDATE Grupo
SET DE_RFC_DEP = TRIM(REPLACE(REPLACE(DE_RFC, '"', ''), ' ', ''));

SELECT * FROM Grupo;
SELECT * FROM Cliente;
SELECT *FROM Disposicion;

-- 10. Consultas
-- =============================================

-- Empresa con más disposiciones

SELECT
    D.CO_GRUPO,
    G.DE_NOMBRE AS Empresa,
    COUNT(*) AS TotalDisposiciones
FROM Disposicion D
INNER JOIN anticipo.Grupo G ON D.CO_GRUPO = G.CO_GRUPO
GROUP BY G.CO_GRUPO, G.DE_NOMBRE
ORDER BY TotalDisposiciones DESC
LIMIT 1;

-- Cuantas personas llamadas Martínez existen, cuantos han pedido disposiciones y cuantos han tenido castigos

SELECT
    COUNT(*) AS Total
FROM Cliente
WHERE APE_PATERNO = 'Martinez' OR APE_MATERNO = 'Martinez';

-- Se usa el DISTINCT para poder excluir registros de la misma persona
SELECT
     count(DISTINCT C.ID) AS Martinez_Con_Disposiciones
FROM Cliente C
INNER JOIN Disposicion D ON C.ID = D.IdPersona
WHERE C.APE_PATERNO = 'Martínez' OR C.APE_MATERNO = 'Martínez'
;

SELECT
     count(DISTINCT C.ID) AS Martinez_Con_Castigo
FROM Cliente C
INNER JOIN Disposicion D ON C.ID = D.IdPersona
WHERE (C.APE_PATERNO = 'Martínez' OR C.APE_MATERNO = 'Martínez') AND
      (D.Monto_castigado > 0 OR D.Fe_castigo_DEP !='2000-01-01');

SELECT

    (SELECT COUNT(*) FROM Cliente WHERE APE_PATERNO = 'Martínez' OR APE_MATERNO = 'Martínez') AS Total_Martinez,

    (SELECT COUNT(DISTINCT C.ID)
     FROM Cliente C
     INNER JOIN Disposicion D ON C.ID = D.IdPersona
     WHERE C.APE_PATERNO = 'Martínez' OR C.APE_MATERNO = 'Martínez') AS Con_Disposiciones,

    (SELECT COUNT(DISTINCT C.ID)
     FROM Cliente C
     INNER JOIN Disposicion D ON C.ID = D.IdPersona
     WHERE (C.APE_PATERNO = 'Martínez' OR C.APE_MATERNO = 'Martínez')
       AND (D.Monto_castigado > 0 OR D.Fe_castigo_DEP !='2000-01-01')
    ) AS Con_Castigos;

-- =============================================
-- PRÁCTICA: CONSULTAS Y FUNCIONALIDADES AVANZADAS
-- =============================================

-- 1. CONSULTAS BÁSICAS DE RECUENTO
-- =============================================

-- Total de registros en la tabla Disposicion
SELECT COUNT(CO_GRUPO) FROM Disposicion;

-- Total de grupos únicos en Disposicion - Se usa DISTINCT para solamente tomar un registro una sola vez, ya que existe duplicados
SELECT COUNT(DISTINCT CO_GRUPO) FROM Disposicion;


-- 2. CONSULTAS SOBRE CLIENTES CON APELLIDOS ESPECÍFICOS
-- =============================================

-- Cantidad de clientes con apellido 'Duran' o 'Alberto' que solicitaron crédito
SELECT COUNT(DISTINCT C.ID) AS Credito
FROM Cliente C
INNER JOIN Disposicion D ON C.ID = D.IdPersona
WHERE C.APE_PATERNO = 'Duran' OR C.APE_MATERNO = 'Alberto';

-- Detalle de clientes con apellido 'Duran' o 'Alberto'
SELECT ID, C.APE_MATERNO, C.APE_PATERNO
FROM Cliente C
INNER JOIN Disposicion D ON C.ID = D.IdPersona
WHERE C.APE_PATERNO = 'Duran' OR C.APE_MATERNO = 'Alberto';


-- =============================================

-- Total de clientes incluidos  aquellos sin disposiciones (para apellidos específicos)
-- Se LEFT JOIN para obtener todos los registros aunque no hayan tenido disposiciones
SELECT
    C.APE_PATERNO,
    C.APE_MATERNO,
    COUNT(1) AS Cliente,
    SUM(CASE WHEN COALESCE(D.Monto, 0) = 0 THEN 0 ELSE 1 END) AS Cte_disp
FROM Cliente AS C
LEFT JOIN (
    SELECT
        IdPersona,
        SUM(monto) AS Monto,
        SUM(COALESCE(Monto_castigado, 0)) AS castigo
    FROM Disposicion
    GROUP BY IdPersona
) AS D ON C.ID = D.IdPersona
WHERE C.APE_PATERNO = 'Ruiz' AND C.APE_MATERNO = 'GONZALEZ'
GROUP BY C.APE_PATERNO, C.APE_MATERNO;


-- 4. IDENTIFICAR COMBINACIONES DE APELLIDOS CON MÁXIMAS DISPOSICIONES
-- =============================================

-- Uso de ROW_NUMBER() para obtener el primer registro por apellido paterno
SELECT *
FROM (
    SELECT
        C.APE_PATERNO,
        C.APE_MATERNO,
        SUM(COALESCE(D.Monto, 0)) AS Monto,
        ROW_NUMBER() OVER (
            PARTITION BY C.APE_PATERNO
            ORDER BY SUM(COALESCE(D.Monto, 0)) DESC, C.APE_MATERNO
        ) AS numero
    FROM Cliente C
    LEFT JOIN (
        SELECT
            IdPersona,
            SUM(monto) AS Monto,
            SUM(COALESCE(Monto_castigado, 0)) AS castigo
        FROM Disposicion
        GROUP BY IdPersona
    ) AS D ON C.ID = D.IdPersona
    GROUP BY C.APE_PATERNO, C.APE_MATERNO
) AS subconsulta
WHERE numero = 1;


-- 5. ACTUALIZACIÓN DE COMISIONES (HISTÓRICO)
-- =============================================

-- Agregar columna de comisión
ALTER TABLE Disposicion ADD COLUMN Comision DECIMAL(15,2);

-- Actualizar comisiones según fecha (antes/después del 15-mayo-2021)
-- Actualizar comisiones según fecha (antes/después del 15-mayo-2021)
UPDATE Disposicion
SET Comision = CASE
    WHEN FE_ALTA_DEP >= '2021-05-15' THEN 75  -- Comisión para fechas >= 15-mayo-2021
    ELSE 50  -- Comisión para fechas < 15-mayo-2021
END;

SELECT * FROM Disposicion;

-- =============================================
    /*
    Objetivo: Obtener las dos empresas que más dinero generaron en comisiones por mes,
    utilizando funciones de ventana para rankear los resultados dentro de cada mes.
    */
-- =============================================

SELECT *
FROM (
    -- Subconsulta para calcular el ranking de empresas por mes
    SELECT
        MONTH(FE_ALTA_DEP) AS Numero_Mes,  -- Extrae el número del mes de la fecha de alta
        MONTHNAME(FE_ALTA_DEP) AS Nombre_Mes,  -- Extrae el nombre del mes de la fecha de alta
        G.DE_NOMBRE AS Nombre_Empresa,  -- Nombre de la empresa
        SUM(Disposicion.Comision) AS Suma_Comision,  -- Suma de comisiones por empresa y mes
        ROW_NUMBER() OVER (
            PARTITION BY MONTH(FE_ALTA_DEP)  -- Divide los datos en grupos por mes
            ORDER BY SUM(Disposicion.Comision) DESC  -- Ordena las empresas por comisión total descendente dentro de cada mes
        ) AS Rango  -- Asigna un número de rango a cada empresa dentro de su mes
    FROM Disposicion
    left JOIN Grupo G ON Disposicion.CO_GRUPO = G.CO_GRUPO  -- Une con la tabla Grupo para obtener el nombre de la empresa
    GROUP BY G.DE_NOMBRE, MONTH(FE_ALTA_DEP), MONTHNAME(FE_ALTA_DEP)  -- Agrupa por empresa y mes
) AS consulta  -- Alias para la subconsulta
WHERE Rango = 1 OR Rango = 2
ORDER BY Numero_Mes, Rango,Suma_Comision
;  -- Filtra solo las dos primeras empresas por mes (las que tienen mayor comisión)


/*
Explicación detallada:
1. **MONTH(FE_ALTA_DEP)**: Extrae el número del mes de la fecha de alta.
2. **MONTHNAME(FE_ALTA_DEP)**: Extrae el nombre del mes de la fecha de alta.
3. **SUM(Disposicion.Comision)**: Calcula la suma total de comisiones por empresa y mes.
4. **ROW_NUMBER()**: Asigna un número de rango a cada empresa dentro de su mes, ordenado por la suma de comisiones en orden descendente.
   - **PARTITION BY MONTH(FE_ALTA_DEP)**: Crea grupos separados por mes.
   - **ORDER BY SUM(Disposicion.Comision) DESC**: Ordena las empresas por comisión total dentro de cada mes.
5. **WHERE Rango = 1 OR Rango = 2**: Filtra solo las dos primeras empresas (las que tienen las mayores comisiones) en cada mes.
 */


 -- =============================================
    /*
    Objetivo: Obtener las dos empresas que más dinero generaron en comisiones por mes,
    utilizando funciones de ventana para rankear los resultados dentro de cada mes.
    */
-- =============================================

-- =============================================
/*
    Tabla cliente agregar campo ESTATUS de tipo VARCHAR (15),

    ESTATUS: INACTIVO, Cuando no haya tenido disposiciones aun
    ESTATUS: ACTIVO, Cuando haya tenido disposiciones
    ESTATUS: BLOQUEADO, Cuando haya tenido castigos
*/
-- =============================================
SELECT * FROM Grupo  ;


-- Agrega una nueva columna llamada ESTATUS a la tabla Cliente
ALTER TABLE Cliente
ADD ESTATUS VARCHAR(15);

-- Muestra todos los registros de la tabla Cliente para verificar la nueva columna
SELECT * FROM Cliente;


-- Actualiza el campo ESTATUS en la tabla Cliente basado en las disposiciones y castigos
UPDATE Cliente C
LEFT JOIN (
    SELECT
        IdPersona,
        -- Verifica si el cliente tiene algún castigo (Monto_castigado > 0)
        MAX(CASE WHEN Monto_castigado > 0 THEN 1 ELSE 0 END) AS cargo,
        -- Cuenta el total de disposiciones por cliente
        COUNT(*) AS disposiciones
    FROM Disposicion
    GROUP BY IdPersona
) AS D ON C.ID = D.IdPersona
SET C.ESTATUS =
    CASE
        -- Si el cliente tiene algún castigo, se marca como 'BLOQUEADO'
        WHEN D.cargo = 1 THEN 'BLOQUEADO'
        -- Si el cliente tiene disposiciones pero no castigos, se marca como 'ACTIVO'
        WHEN D.disposiciones > 0 THEN 'ACTIVO'
        -- Si no cumple ninguna de las condiciones anteriores, se marca como 'INACTIVO'
        WHEN (D.disposiciones = 0 AND D.cargo = 0) OR (D.disposiciones IS NULL AND D.cargo IS NULL) THEN 'INACTIVO'
        END;
SELECT
        IdPersona,
        -- Verifica si el cliente tiene algún castigo (Monto_castigado > 0)
        MAX(CASE WHEN Monto_castigado > 0 THEN 1 ELSE 0 END) AS cargo,
        -- Cuenta el total de disposiciones por cliente
        COUNT(*) AS disposiciones
    FROM Disposicion
    GROUP BY IdPersona;

-- =============================================
/*
   Muestra, por estatus, la cantidad de clientes únicos, el número y monto total de disposiciones con montos mayores
   a 0, así como el número y monto total de disposiciones castigada
*/
-- =============================================

SELECT
    c.ESTATUS AS Estatus,
    COUNT(DISTINCT c.ID) AS Cantidad_Cliente,
    SUM(CASE WHEN D.monto > 0 THEN 1 ELSE 0 END) AS Cantidad_Disposiciones,
    SUM(COALESCE(D.monto,0)) AS Suma_Disposiciones,
    SUM(CASE WHEN D.Monto_castigado > 0 THEN 1 ELSE 0 END) AS Cantidad_Castigos,
    SUM(COALESCE(D.Monto_castigado,0)) AS Suma_Castigo
FROM Cliente c
LEFT JOIN Disposicion D ON c.ID = D.IdPersona
GROUP BY c.ESTATUS
ORDER BY Cantidad_Cliente DESC ;

SELECT COUNT(IdPersona) FROM Disposicion;
SELECT COUNT(Id) FROM Cliente;
SELECT COUNT(CO_GRUPO) FROM Grupo;

/* Se creo un indice en la columna IdPersona de la tabla Disposicion, ya que la consulta tardaba 35 segundos en promedio
y ahora tarda menos de un 1 segundo

 Solo para Linux
CREATE INDEX idx_disposicion_idpersona ON Disposicion (IdPersona)  */

CREATE INDEX idx_disposicion_idpersona ON Disposicion (IdPersona);

SELECT * FROM Cliente
WHERE CIUDAD LIKE 'LEON%';

-- =============================================
/*
Indice: Es un mecanismo que organiza los datos de forma logica, osea que no se ve directamente en los registros

corroborar el impacto de la base de datos el uso de los indices, osea como medir el impacto de los indices en la base de datos

Cuales la diferencia entre las llaves primarias o foraneas entre los indices

Cual es la problematica de tener demasiados indices

Eliminar indices que no se le conoce su nombre

Saber para el dashboard realizar ciertas consultas
Cual es la galleta mas vendida
Cual es la que mas conviene mas vender
Cuanto me cuesta una galleta
*/
-- =============================================

-- Apellido mas comun
SELECT * FROM Cliente
WHERE APE_PATERNO = 'Lopez'; -- 22 ms  10 ms

SELECT * FROM Cliente
WHERE APE_PATERNO = 'DE MARIA Y CAMPOS'; -- 37 ms 5 ms

SELECT * FROM Cliente
WHERE NOMBRE LIKE '%JUAN%' ;-- 17 MS 24ms

SELECT * FROM Cliente
WHERE NOMBRE ='JUAN'; -- 18ms 13ms

SELECT * FROM Cliente
WHERE NOMBRE ='MARIBEL' AND APE_PATERNO='PEREZ'; -- 34 ms

SELECT * FROM Cliente
WHERE APE_PATERNO='RAMIREZ' AND APE_MATERNO='GONZALEZ'; -- 32

SELECT * FROM Cliente
WHERE CIUDAD='LEON'; -- 3 ms

SELECT * FROM Cliente
WHERE CIUDAD LIKE '%LEON%'; -- 55 ms

SELECT * FROM Cliente
WHERE APE_PATERNO='JUAREZ'
AND CIUDAD='PUEBLA' ;-- 35 ms

SELECT * FROM Cliente; -- 9 ms

SELECT DISTINCT CIUDAD
FROM  Cliente
ORDER BY CIUDAD;

ALTER TABLE Cliente ADD INDEX (APE_PATERNO);
ALTER TABLE Cliente ADD INDEX (NOMBRE,APE_PATERNO);
SELECT * FROM Cliente;

-- 1) Indice de llave primaria ... ADD Primary Key
-- 2) Indices Ordinarios (Ape_paterno)
-- 3) Indices compuestos (Nombre, Ape_paterno)
-- 4) Indices parciales (Ciudad(5),Ape_paterno(5)) cuando buscamos por los primeros 5 letras
-- 5) indices unicos ADD unique <> ()
-- 6) Indice texto completo ADD FULLTEXT indApp()

ALTER TABLE Cliente ADD INDEX cliente_APE_PATERNO(APE_PATERNO);

SELECT 'Apellido_Paterno', 'Cantidad_personas', 'Pers c/disp'
UNION ALL
SELECT
    c.APE_PATERNO,
    COUNT(*) AS total_clientes,
    IF(COALESCE(d.Dispo, 0) = 0, 0, 1) AS tiene_disposicion
FROM Cliente AS c
LEFT JOIN
    (SELECT IdPersona, COUNT(1) AS Dispo
     FROM Disposicion
     GROUP BY IdPersona
    ) AS d
ON c.ID = d.IdPersona
GROUP BY c.APE_PATERNO
INTO OUTFILE '/var/lib/mysql/prueba.csv'
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\n';

SHOW VARIABLES LIKE 'datadir';

SELECT * FROM disposicion;
SELECT * FROM Grupo;
SELECT * FROM Cliente;


/*
Examen
*/

SELECT c.APE_PATERNO as Apellido_Paterno,
        Monto_castigado,
        monto,
       (d.Monto_castigado/d.monto)*100 AS Porcentaje_Perdida
FROM Disposicion d
INNER JOIN cliente c
on d.IdPersona = c.ID
WHERE Monto_castigado > 0
ORDER BY Porcentaje_Perdida desc
limit 1;

SELECT
     Apellido_Paterno,
     Monto_total,
     Monto_Castigado,
    ((Monto_Castigado/Monto_total))*100 AS Porcentaja_perdida
    FROM (SELECT c.APE_PATERNO as Apellido_Paterno,
        SUM(COALESCE(monto, 0)) as Monto_total,
        SUM(COALESCE(Monto_castigado, 0)) as Monto_Castigado
FROM Disposicion d
INNER JOIN cliente c
on d.IdPersona = c.ID
GROUP BY c.APE_PATERNO) AS consulta
order by Porcentaja_perdida desc
limit 1;



/*
 Genera una consulta donde se determine cual es el apellido (paterno) de las personas con mayor perdia porcentual.
 Donde el porcentaje de perdida = Monto toal castigado / Monto total dispuesto
 */

/*
Considera el estatus de las empresas y de los clientes con disposiciones, genera una consulta que permita el siguiente reporte
*/




SELECT
    g.DE_ESTATUS as Estatus_Empresa,
    row_number() over (partition by c.ESTATUS) as rango,
    c.ESTATUS,
    COUNT(DISTINCT g.CO_GRUPO) AS Numero_Empresa,
    COUNT(DISTINCT c.ID) AS Numero_Cliente,
    count(monto) AS Numero_Disposiciones,
    SUM(COALESCE(D.monto,0)) AS Monto_Total
FROM Cliente c
INNER JOIN Disposicion D ON c.ID = D.IdPersona
INNER JOIN grupo g on D.CO_GRUPO = g.CO_GRUPO
GROUP BY c.ESTATUS, g.DE_ESTATUS
order by Estatus_Empresa
;


CREATE TABLE Emisora (
    Entidad VARCHAR(255),
    RAZON_SOCIAL VARCHAR(255),
    SP_LP_EN VARCHAR(255),
    MD_LP_EN VARCHAR(255) ,
    FT_LP_EN VARCHAR(255),
    HR_LP_EN VARCHAR(255)
);
DROP TABLE Emisora;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Emisoras.csv'
INTO TABLE emisora
CHARACTER SET latin1
FIELDS TERMINATED BY ';'
IGNORE 1 LINES;

SELECT * FROM emisora;

ALTER TABLE Emisora
ADD COLUMN Tipo_Entidad VARCHAR(255) DEFAULT 'Otro';

/**/