----------------------------------------------- CREACIÓN DE TOPOLOGÍA --------------------------------------------------------------------------
create extension pgrouting;

/*
 * En QGIS se modificó la tabla del concesionado.
 * Se seccionó cada 50 metros luego se extrajeron los vertices de cada segmento para que representaran las
 * paradas de la ruta. Posteriormente se va a asociar cada parada al nodo más cercano*/


/*Ahora modificamos la tabla de las calles, para que tenga nodos source y target*/
-- Aplica ST_Node a toda la red
CREATE TABLE streets_noded AS
SELECT (ST_Dump(ST_Node(ST_Union(way)))).geom::geometry(LineString, 3857) AS geom
FROM planet_osm_line;

alter table streets_noded add column id int;

WITH numerados AS (
  SELECT
    ctid,
    ROW_NUMBER() OVER () AS nuevo_id
  FROM streets_noded
)
UPDATE streets_noded
SET id = numerados.nuevo_id
FROM numerados
WHERE streets_noded.ctid = numerados.ctid;

select * from streets_noded;


/*Ahora modificamos la tabla de las calles, para que tenga nodos source y target*/
alter table redes.calles add column source int;
alter table redes.calles add column target int;
--creamos la topología
SELECT pgr_createTopology('redes.calles', 1, 'geom', 'id', 'source', 'target');

select * from redes.calles;
--Agregamos el costo, el cual será el tiempo de caminata, se toma 5km/h ó 1.39m/s la velocidad promedio
alter table redes.calles add column cost double precision;
update redes.calles set cost = ST_Length(geom)/1.25;

--vamos a asociar las paradas con los nodos más cercanos
SELECT array_agg(DISTINCT s.source) AS source_nodes
FROM redes.concesionado_est p
JOIN redes.calle s
  ON ST_DWithin(p.geom, s.geom, 10); -- ej. radios de 20 metros

  
  
  
-------------------------------------------------------------TRANSPORTE---------------------------------------------------------------------------------
-- VAMOS a calcular el área de serivicio para una caminata de 240 s ~ 4 min
SELECT *
FROM pgr_drivingDistance(
  'SELECT id, source, target, cost FROM redes.calle',
  ARRAY[60,213,221,239,241,244,245,258,259,260,261,262,264,265,266,269,270,271,272,273,274,277,284,288,290,294,295,301,310,311,312,323,324,325,326,327,337,338,339,341,351,353,354,355,356,367,371,395,396,400,404,405,413,414,415,416,420,428,429,430,439,443,455,459,466,468,471,474,511,546,589,616,653,673,676,677,678,686,691,695,697,698,701,709,710,711,712,714,718,723,724,727,729,735,740,741,745,748,749,759,760,761,762,765,766,769,771,777,778,779,780,781,785,786,787,790,792,793,804,806,807],  -- IDs de los source nodos
  240,
  directed := false
);

create table redes.a4min as
WITH driving_area AS (
  SELECT *
  FROM pgr_drivingDistance(
    'SELECT id, source, target, cost FROM redes.calle',
    ARRAY[60,213,221,239,241,244,245,258,259,260,261,262,264,265,266,269,270,271,272,273,274,277,284,288,290,294,295,301,310,311,312,323,324,325,326,327,337,338,339,341,351,353,354,355,356,367,371,395,396,400,404,405,413,414,415,416,420,428,429,430,439,443,455,459,466,468,471,474,511,546,589,616,653,673,676,677,678,686,691,695,697,698,701,709,710,711,712,714,718,723,724,727,729,735,740,741,745,748,749,759,760,761,762,765,766,769,771,777,778,779,780,781,785,786,787,790,792,793,804,806,807],  -- arreglo de nodos
    240,
    directed := false
  )
)
SELECT s.*
FROM driving_area d
JOIN redes.calle s ON d.edge = s.id;


-- Ahora el área de servicio para una caminata de 320 s ~ 5 min
create table redes.a5min as
WITH driving_area AS (
  SELECT *
  FROM pgr_drivingDistance(
    'SELECT id, source, target, cost FROM redes.calle',
    ARRAY[60,213,221,239,241,244,245,258,259,260,261,262,264,265,266,269,270,271,272,273,274,277,284,288,290,294,295,301,310,311,312,323,324,325,326,327,337,338,339,341,351,353,354,355,356,367,371,395,396,400,404,405,413,414,415,416,420,428,429,430,439,443,455,459,466,468,471,474,511,546,589,616,653,673,676,677,678,686,691,695,697,698,701,709,710,711,712,714,718,723,724,727,729,735,740,741,745,748,749,759,760,761,762,765,766,769,771,777,778,779,780,781,785,786,787,790,792,793,804,806,807],  -- arreglo de nodos
    320,
    directed := false
  )
)
SELECT s.*
FROM driving_area d
JOIN redes.calle s ON d.edge = s.id;


--Finalmente para la caminata de 640 min ~ 8 min
create table redes.a10min as
WITH driving_area AS (
  SELECT *
  FROM pgr_drivingDistance(
    'SELECT id, source, target, cost FROM redes.calle',
    ARRAY[60,213,221,239,241,244,245,258,259,260,261,262,264,265,266,269,270,271,272,273,274,277,284,288,290,294,295,301,310,311,312,323,324,325,326,327,337,338,339,341,351,353,354,355,356,367,371,395,396,400,404,405,413,414,415,416,420,428,429,430,439,443,455,459,466,468,471,474,511,546,589,616,653,673,676,677,678,686,691,695,697,698,701,709,710,711,712,714,718,723,724,727,729,735,740,741,745,748,749,759,760,761,762,765,766,769,771,777,778,779,780,781,785,786,787,790,792,793,804,806,807],  -- arreglo de nodos
    640,
    directed := false
  )
)
SELECT s.*
FROM driving_area d
JOIN redes.calle s ON d.edge = s.id;


--Ahora vamos a asignar la calificación a los frentes de manzana, se hace un buffer de 8 mentros y se asigna la puntuación
alter table operaciones add column "TRANSPORTE" int;

UPDATE operaciones
SET "TRANSPORTE" = CASE
    WHEN EXISTS (
        SELECT 1 FROM redes.a4min b
        WHERE ST_Intersects(st_buffer(b.geom, 8), operaciones.geom)
    ) THEN 3
    WHEN EXISTS (
        SELECT 1 FROM redes.a5min b
        WHERE ST_Intersects(st_buffer(b.geom, 8), operaciones.geom)
    ) THEN 2
    WHEN EXISTS (
        SELECT 1 FROM redes.a10min b
        WHERE ST_Intersects(st_buffer(b.geom, 8), operaciones.geom)
    ) THEN 1
    ELSE 0
END;

update operaciones set "TRANSPORTE" = 2 where cve_unica in ('03180012', '03180022', '03180024', '03180093', '03180094', '03180103', '03180111', '03180114', '03180122', '03180124', 
'03180132', '03180134', '03180142', '03220044', '03220052', '03220133', '03220134', '03220142', '03220144', '03220152', 
'03220154', '03370032', '03370042', '03370044', '03370052', '03370054', '03370092', '03370104', '03370122', '03370124',
'03370132', '03370154', '03370162', '03370172', '03370173', '03370232', '03370241', '03370242', '03370244', '03410052', 
'03410054', '03410062', '03410064', '03410101', '03410344', '03410362', '03410364', '03410374', '06380211', '06380242',
'06380254', '13690461', '13690462', '03370164', '06380252');

update operaciones set "TRANSPORTE" = 1 where cve_unica in ('03180032', '03180034', '03180042', '03180102', '03180104', '03220033', '03220141', '03220164', '03220172', '03220174', 
'03220174', '03370012', '03370024', '03370043', '03370102', '03370112', '03370113', '03370114', '03370121', '03370251', 
'03410061', '03410072', '03410073', '03410074', '03410082', '03410084', '03410091', '03410092', '03410094', '03410104',
'03410153', '03410155', '03410264', '03410372', '03410411', '03410412', '03410414', '06380074', '06380092', '06380104',
'06380202', '06380212', '06380224', '06380232', '06380244', '06420074', '06420172', '03370222', '03370234', '03180101', '03220171');

update operaciones set "TRANSPORTE" = 3 where cve_unica in ('03180031', '03180041', '03180121', '03180131', '03220131', '03370171', '03410053', '06230224', '06380091', '06380231',
'06380241', '03180021', '03180091', '03220181', '03370011', '03370021');

----------------------------------------------------------------------------------------------------------------------------------------------------

--para cortar la capa de calles
create table redes.calle as
SELECT 
    o.id, o.fid, o.source, o.target, o.cost,
    ST_Intersection(o.geom, ST_Buffer(c.geom, 3)) AS geom
FROM 
    redes.calles o
JOIN 
    datos.lomas_padierna c 
ON 
    ST_Intersects(o.geom, ST_Buffer(c.geom, 3));

create table redes.calle_vertices as
SELECT 
    o.id, o.fid, 
    ST_Intersection(o.geom, ST_Buffer(c.geom, 3)) AS geom
FROM 
    redes.calles_vertices o
JOIN 
    datos.lomas_padierna c 
ON 
    ST_Intersects(o.geom, ST_Buffer(c.geom, 3));    
    
select *
from fm_operaciones fo 
where ;

