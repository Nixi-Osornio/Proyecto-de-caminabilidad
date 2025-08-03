---------------------------------------------------------------- USO MIXTO ------------------------------------------------------------------
select * from redes."DENUE" d ;

--CREAMOS NUEVAS CATEGORÍAS
select distinct nombre_act, codigo_act, uso_suelo from redes."DENUE";

alter table redes."DENUE" add column uso_suelo varchar;

update redes."DENUE"
set uso_suelo = 'comercio'
where nombre_act ilike '%llanta%';

update redes."DENUE"
set uso_suelo = 'servicio'
where nombre_act ilike '%cerrajer_a%';

update redes."DENUE"
set uso_suelo = 'escuelas'
where nombre_act ilike '%guarder_a%';

update redes."DENUE"
set uso_suelo = 'salud'
where nombre_act ilike '%adicciones%';

update redes."DENUE"
set uso_suelo = 'otros'
where uso_suelo is NULL;

select distinct nombre_act, uso_suelo from redes."DENUE" d;

select distinct nombre_act, uso_suelo from redes."DENUE" d where d.uso_suelo is null order by d.nombre_act asc;

select nombre_act, uso_suelo from redes."DENUE" d where nombre_act ilike '%laboratorios%';

select count(*) from redes."DENUE" d where d.uso_suelo is null;

select distinct uso_suelo from redes."DENUE" d ;

alter table operaciones add column "USO MIXTO" int;

--Vamos a ver cuantos usos hay por frente de manzana
select l.cve_unica AS linea_id, COUNT(DISTINCT p.uso_suelo) AS num_clasificaciones
FROM operaciones l
JOIN redes."DENUE" p
ON ST_intersects(st_buffer(l.geom,8), p.geom)  
GROUP BY l.cve_unica
order by num_clasificaciones desc;

-- UPDATE a la tabla
WITH clasificaciones_por_linea AS (
   select l.cve_unica AS linea_id, COUNT(DISTINCT p.uso_suelo) AS num_clasificaciones
   from operaciones l
   join redes."DENUE" p
   on ST_intersects(st_buffer(l.geom,8), p.geom)
   GROUP by l.cve_unica
)
UPDATE operaciones l
SET "USO MIXTO" = CASE
   WHEN c.num_clasificaciones >= 3 THEN 3
   WHEN c.num_clasificaciones = 2 THEN 2
   WHEN c.num_clasificaciones = 1 THEN 1
END
FROM clasificaciones_por_linea c
WHERE l.cve_unica = c.linea_id;

update operaciones set "USO MIXTO" = 0 where "USO MIXTO" is null;



------------------------------------------------------------ USO PÚBLICO -----------------------------------------------------------------------
--Identificamos los espacios publicos
select * from redes.espacios ep;

select distinct edificio, edificio_e, nombre_act, nom_estab from redes.espacios ep;

create table redes.espacios_publicos as select *
from redes.espacios ep 
where edificio ilike 'EL MIRADOR' 
or edificio ilike 'PLAZA %' 
or edificio ilike '22 DE ENERO';

select * from redes.espacios_publicos ep;

select distinct edificio, geom as geom from redes.espacios_publicos;

create table redes.espacios_3 as select distinct edificio, geom as geom
from redes.espacios_publicos;

select * from redes.espacios_3 ep;

select * from redes.servicios_punto_lomas;
select distinct  "GEOGRAFICO" from redes.servicios_punto_lomas spl;

create table redes.espacios_2 as select * from redes.servicios_punto_lomas where "GEOGRAFICO" in ('Mercado', 'Templo', 'Instalación Deportiva o Recreativa');
select * from redes.espacios_2;

--Identificamos los nodos cercanos a los espacios públicos
SELECT array_agg(DISTINCT s.source) AS source_nodes
FROM redes.espacios_3 ep
JOIN redes.calle s
  ON ST_DWithin(ep.geom, s.geom, 32); -- '354', '368', '369', '371', '399', '403', '404', '483', '497','498', '503', '516', '517', '610', '616', '651', '659', '673', '684', 
  --                                     '691', '706', '708', '721', '727', '735', '748', '749', '759', '760', '761', '765', '769'
  
SELECT array_agg(DISTINCT s.source) AS source_nodes
FROM redes.espacios_2 ep
JOIN redes.calle s
  ON ST_DWithin(ep.geom, s.geom, 32); -- '225', '245', '249', '273', '274', '275', '277', '278', '288', '374', '476', '481', '490', '495', '511', '624'

SELECT array_agg(DISTINCT s.source) AS source_nodes
FROM redes.areas_v_lomas avl 
JOIN redes.calle s
  ON ST_DWithin(avl.geom, s.geom, 10); -- '244', '263', '264', '269', '270', '272', '276', '279', '281', '283', '286', 
  --                                      '289', '295', '296', '297', '298', '299', '531', '620', '625', '626', '627', '628', '629', '630', '639', '640', '641', '645', 
  --                                      '652', '728', '729', '730', '731'

SELECT array_agg(DISTINCT s.source) AS source_nodes
FROM redes.servicios_area_lomas sal 
JOIN redes.calle s
  ON ST_DWithin(sal.geom, s.geom, 10); -- '221', '256', '280', '282', '284', '285', '287', '290', '304', '309', '312'


-- VAMOS a calcular el área de serivicio para una caminata de 240 s ~ 4 min
SELECT *
FROM pgr_drivingDistance(
  'SELECT id, source, target, cost FROM redes.calle',
  ARRAY[354,368,369,371,399,403,404,483,497,498,503,516,517,610,616,651,659,673,684,691,706,708,721,727,735,748,749,759,760,761,765,769,225,245,249,273,274,275,277,278,288,374,476,481,490,495,511,624, 
  		244,263,264,269,270,272,276,279,281,283,286,289,295,296,297,298,299,531,620,625,626,627,628,629,630,639,640,641,645,652,728,729,730,731,221,256,280,282,284,285,287,290,304,309,312],  -- IDs de los source nodos
  240,
  directed := false
);

create table redes.up_a4min as
WITH driving_area AS (
  SELECT *
  FROM pgr_drivingDistance(
    'SELECT id, source, target, cost FROM redes.calle',
    ARRAY[354,368,369,371,399,403,404,483,497,498,503,516,517,610,616,651,659,673,684,691,706,708,721,727,735,748,749,759,760,761,765,769,225,245,249,273,274,275,277,278,288,374,476,481,490,495,511,624, 
  		244,263,264,269,270,272,276,279,281,283,286,289,295,296,297,298,299,531,620,625,626,627,628,629,630,639,640,641,645,652,728,729,730,731,221,256,280,282,284,285,287,290,304,309,312],  -- arreglo de nodos
    240,
    directed := false
  )
)
SELECT s.*
FROM driving_area d
JOIN redes.calle s ON d.edge = s.id;

-- Ahora el área de servicio para una caminata de 320 s ~ 5 min
create table redes.up_a5min as
WITH driving_area AS (
  SELECT *
  FROM pgr_drivingDistance(
    'SELECT id, source, target, cost FROM redes.calle',
    ARRAY[354,368,369,371,399,403,404,483,497,498,503,516,517,610,616,651,659,673,684,691,706,708,721,727,735,748,749,759,760,761,765,769,225,245,249,273,274,275,277,278,288,374,476,481,490,495,511,624, 
  		244,263,264,269,270,272,276,279,281,283,286,289,295,296,297,298,299,531,620,625,626,627,628,629,630,639,640,641,645,652,728,729,730,731,221,256,280,282,284,285,287,290,304,309,312],  -- arreglo de nodos
    320,
    directed := false
  )
)
SELECT s.*
FROM driving_area d
JOIN redes.calle s ON d.edge = s.id;

--Finalmente para la caminata de 640 min ~ 8 min
create table redes.up_a10min as
WITH driving_area AS (
  SELECT *
  FROM pgr_drivingDistance(
    'SELECT id, source, target, cost FROM redes.calle',
    ARRAY[354,368,369,371,399,403,404,483,497,498,503,516,517,610,616,651,659,673,684,691,706,708,721,727,735,748,749,759,760,761,765,769,225,245,249,273,274,275,277,278,288,374,476,481,490,495,511,624, 
  		244,263,264,269,270,272,276,279,281,283,286,289,295,296,297,298,299,531,620,625,626,627,628,629,630,639,640,641,645,652,728,729,730,731,221,256,280,282,284,285,287,290,304,309,312],  -- arreglo de nodos
    640,
    directed := false
  )
)
SELECT s.*
FROM driving_area d
JOIN redes.calle s ON d.edge = s.id;


-- Ahora hacemos la asignación
alter table operaciones add column "USO PUBLICO" int;

UPDATE operaciones
SET "USO PUBLICO" = CASE
    WHEN EXISTS (
        SELECT 1 FROM redes.up_a4min b 
        WHERE ST_Intersects(st_buffer(b.geom, 8), operaciones.geom)
    ) THEN 3
    WHEN EXISTS (
        SELECT 1 FROM redes.up_a5min b
        WHERE ST_Intersects(st_buffer(b.geom, 8), operaciones.geom)
    ) THEN 2
    WHEN EXISTS (
        SELECT 1 FROM redes.up_a10min b
        WHERE ST_Intersects(st_buffer(b.geom, 8), operaciones.geom)
    ) THEN 1
    ELSE 0
END;

update operaciones set "USO PUBLICO" = 0 where cve_unica in ('03180222', '03180224', '03180234', '03180252', '03220012', '03220022', '03220024', 
'03220071', '03220114', '03220224', '03220231', '03370102', '03410155');

update operaciones set "USO PUBLICO" = 1 where cve_unica in ('03030091', '03030172', '03030173', '03030174', '03030182', '03030184', '03030192', '03180022', '03180032', '03180032',
'03180042', '03180094', '03180104', '03180124', '03180132', '03180181', '03180182', '03180184', '03180192', '03180194', 
'03180202', '03180204', '03180231', '03180244', '03180253', '03180254', '03180271', '03180273', '03180282', '03180291', 
'03180293', '03220032', '03220034', '03220042', '03220082', '03220092', '03220094', '03220102', '03220104', '03220112', 
'03220124', '03220144', '03220152', '03220204', '03220211', '03220241', '03220242', '03220251', '03220252', '03220254',
'03370012', '03370021', '03370024', '03370074', '03370092', '03370093', '03370104', '03370112', '03370122', '03370164',
'03370192', '03370194', '03370202', '03370204', '03370212', '03370222', '03370224', '03370231', '03370232', '03370234',
'03370242', '03370244', '03410052', '03410064', '03410072', '03410074', '03410084', '03410344', '03410403', '06380082',
'06380094', '06380232', '06380242', '06380244', '06380252', '06380254');

update operaciones set "USO PUBLICO" = 2 where cve_unica in ('03030102', '03030104', '03030194', '03180012' ,'03180024', '03180072', '03180074', '03180084', '03180102', '03180103', 
'03180111', '03180134', '03180142', '03180191', '03180223', '03180232', '03180242', '03180291', '03220044', '03220052', 
'03220134', '03220142', '03220154', '03220212', '03220214', '03220223', '03220234', '03370032', '03370064', '03370072', 
'03370082', '03370084', '03370094', '03370124', '03370134', '03370142', '03370181', '03370182', '03370193', '03370243',
'03410082', '03410094', '03410153', '03410264', '03410372', '03410412', '03410414', '06380211', '06380221', '06380222', 
'06380234', '03220232', '03220244', '03370241');

update operaciones set "USO PUBLICO" = 3 where cve_unica in ('03180021', '03180031', '03180041', '03180071', '03180101', '03220011', '06230224', '03180131', '03370011');

------------------------------------------------------------------------------------------------------------

