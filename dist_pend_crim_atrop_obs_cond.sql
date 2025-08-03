-- SCRIPT PARA ASIGNAR GEOMETRÍA A LAS FICHAS --
create schema levantamientos;

select * from levantamientos.levantamientos_revisado lr;

ALTER TABLE levantamientos.levantamientos_revisado
ADD COLUMN geom geometry(MultiLineString, 32614);

UPDATE levantamientos.levantamientos_revisado
SET geom = b.geom
FROM public."FM_Captura" b
WHERE levantamientos.levantamientos_revisado.clave = b.cve_unica;

select * from levantamientos.levantamientos_revisado where geom is null;

select distinct clave from levantamientos.levantamientos_revisado lr;

--   REVISAMOS DUPLICADOS --
SELECT clave, COUNT(*)
FROM levantamientos.levantamientos_revisado
GROUP BY clave
HAVING COUNT(*) > 1;

select * from levantamientos.levantamientos_revisado lr where clave ilike '0341005_';

SELECT *
FROM levantamientos.levantamientos_revisado
WHERE ctid NOT IN (
  SELECT MIN(ctid)
  FROM levantamientos.levantamientos_revisado
  GROUP BY clave, fecha, integrante
);

DELETE FROM levantamientos.levantamientos_revisado
WHERE ctid NOT IN (
  SELECT MIN(ctid)
  FROM levantamientos.levantamientos_revisado
  GROUP BY clave, fecha, integrante
);


select count(*) from levantamientos.levantamientos_revisado lr;

update levantamientos.levantamientos_revisado lr set clave='206603611' where clave = '20660311';

INSERT INTO levantamientos.levantamientos_revisado (clave, fecha, latitud, longitud, integrante, 
inicio_cruce_peatonal, inicio_cruce_rampa, inicio_cruce_obs_visual, inicio_cruce_sema_peatonal, inicio_cruce_bolardo, inicio_cruce_otro, inicio_material, inicio_transversal, inicio_franja_circula, inicio_banqueta, 
medio_material, medio_transversal, medio_franja_circula, medio_banqueta, 
fin_cruce_peatonal, fin_cruce_rampa, fin_cruce_obs_visual, fin_cruce_sema_peatonal, fin_cruce_bolardos, fin_cruce_otro, fin_material, fin_transversal, fin_franja_circula, fin_banqueta, 
cant_obs_fisicas, arb_jardin, estacionamiento, puesto_ambulante, poste, desnivel, obs_fisico_otro, nota)
VALUES ('03410043', '05/05/2025 13:25:00', 19.2911275, -99.2174289, 'Crisol', 
'false', 'false', 'true', 'false', 'false', '', 'Ambos', 'Plana', 170, 187, 
'Ambos', 'Plana', 144, 220, 
'false', 'false', 'true', 'false', 'false', '', 'Material de buena calidad', 'Plana', 130, 250, 
1, 'false', 'false', 'false', 'false', 'true','', '');

INSERT INTO levantamientos.levantamientos_revisado (clave, fecha, latitud, longitud, integrante, 
inicio_cruce_peatonal, inicio_cruce_rampa, inicio_cruce_obs_visual, inicio_cruce_sema_peatonal, inicio_cruce_bolardo, inicio_cruce_otro, inicio_material, inicio_transversal, inicio_franja_circula, inicio_banqueta, 
medio_material, medio_transversal, medio_franja_circula, medio_banqueta, 
fin_cruce_peatonal, fin_cruce_rampa, fin_cruce_obs_visual, fin_cruce_sema_peatonal, fin_cruce_bolardos, fin_cruce_otro, fin_material, fin_transversal, fin_franja_circula, fin_banqueta, 
cant_obs_fisicas, arb_jardin, estacionamiento, puesto_ambulante, poste, desnivel, obs_fisico_otro, nota)
VALUES ('06420093', '25/06/2025 17:57:00', 19.2911275, -99.2174289, 'Crisol', 
'false', 'false', 'true', 'false', 'false', '', 'Material de buena calidad', 'Inclinada', 104, 205, 
'', '', null, null, 
'false', 'false', 'true', 'false', 'false', '', 'Ambos', 'Inclinada', 100, 166, 
'3 o más', 'false', 'true', 'false', 'false', 'true','negocio base ambulancias', '');

select * from levantamientos.levantamientos_revisado ;
-------------------------------------------------------------------------------------------------------------------------------------------------
-- SCRIPT PARA LA NUEVA TABLA DE OPERACIONES --
select * from public."FM_Captura" ;

create table public.operaciones as
select cve_unica, id, geom
from public."FM_Captura" fc;



-------------------------------------------------------------------DISTANCIA----------------------------------------------------------------------
alter table public.operaciones add column "longitud" float;

update public.operaciones
set "longitud" = st_length(geom);

alter table public.operaciones add column "DISTANCIA" int;

update public.operaciones set "DISTANCIA" = case
	when "longitud" <= 111.00 then 3
	when "longitud" > 111.00 and "longitud" <= 130.00 then 2
	when "longitud" > 130.00 and "longitud" <= 150.00 then 1
	when "longitud" > 150.00 then 0
end;

update "FM_Captura" fc set "DIMENSION"=o."DISTANCIA" from operaciones o where fc.cve_unica =o.cve_unica;

----------------------------------------------------------------PENDIENTE-----------------------------------------------------------------------
alter table public.operaciones add column valor_pediente float;

update operaciones o set valor_pediente = p.slope_mean
from datos.pendientes p 
where o.cve_unica = p.cve_unica;

alter table public.operaciones add column "PENDIENTE" int;
update operaciones o set "PENDIENTE" = case 
	when o.valor_pediente >=2 and o.valor_pediente <=4 then 3
	when o.valor_pediente >4 and o.valor_pediente <=5 then 2
	when o.valor_pediente >5 and o.valor_pediente <=6 then 1
	when o.valor_pediente >6 or o.valor_pediente <2 then 0
end;



---------------------------------------------------------------ROBOS---------------------------------------------------------------------------
alter table datos.robos_lpadierna add column id_frente_cercano varchar;

select * from datos.robos_lpadierna rl;

UPDATE datos.robos_lpadierna a
SET id_frente_cercano = sub.id_frente
FROM (
   SELECT a.id AS asalto_id, f.cve_unica AS id_frente
   FROM datos.robos_lpadierna a
   JOIN LATERAL (
       SELECT f.cve_unica
       FROM public.operaciones f
       ORDER BY a.geom <-> f.geom
       LIMIT 1
   ) f ON true
) sub
WHERE a.id = sub.asalto_id;

select * from operaciones o where cve_unica in ('03030114', '06570324', '03410153', '06420242', '03180121', '03220033',
												'03220211', '06570322', '03370101');

alter table operaciones add column "ROBO" int;

update operaciones
set "ROBO" = case
	when operaciones.cve_unica = robos.id_frente_cercano then 0
end
from datos.robos_lpadierna as robos
where operaciones.cve_unica = robos.id_frente_cercano;
UPDATE operaciones
SET "ROBO" = 3
WHERE cve_unica NOT IN (
   SELECT id_frente_cercano FROM datos.robos_lpadierna
   WHERE id_frente_cercano IS NOT NULL
);




--------------------------------------------------------ATROPELLAMIENTOS-----------------------------------------------------------------------------------------
select * from datos.atropellados_lomas_ssc als;

SELECT o.cve_unica AS id_frente, a.id AS id_atropello, o.geom
	FROM operaciones o
	JOIN datos.atropellados_lomas_ssc a
 		ON ST_DWithin(o.geom, a.geom, 12);  -- 12 metros de distancia
 		
SELECT array_agg(DISTINCT o.cve_unica) AS cve_frentes
FROM operaciones o
JOIN datos.atropellados_lomas_ssc a
ON ST_DWithin(o.geom, a.geom, 12); --hacemos un array de los frentes del query anterior

alter table operaciones add column "ATROPELLAMIENTO" int;

update operaciones
set "ATROPELLAMIENTO" = case
	when operaciones.cve_unica in ('03030111', '03030114', '03030192', '03030193', '03180022', '03180023', '03180031', '03180032', '03180093', '03180094', '03180101', '03180104', '03180113', '03180114', '03180143', '03180144', 
'03180151', '03180152', '03180153', '03180154', '03180183', '03180184', '03180212', '03180213', '03180221', '03180224', '03180241', '03180244', '03180251', '03180252', '03180263', '03180264', 
'03180281', '03180282', '03220032', '03220033', '03220053', '03220054', '03220141', '03220142', '03220144', '03220151', '03220152', '03220161', '03220163', '03220164', '03220171', '03220172', 
'03220173', '03220182', '03220183', '03370013', '03370014', '03370022', '03370023', '03370031', '03370032', '03370033', '03370034', '03370041', '03370044', '03370051', '03370052', '03370073', 
'03370074', '03370112', '03370113', '03370114', '03370121', '03370122', '03370123', '03370124', '03370141', '03370144', '03370153', '03370154', '03370162', '03370163', '03370181', '03370182', 
'03370192', '03370193', '03370241', '03370244', '03370251', '03370252', '03410053', '03410054', '03410061', '03410064', '03410073', '03410074', '03410081', '03410082', '03410083', '03410093', 
'03410094', '03410152', '03410153', '03410212', '03410241', '03410242', '03410243', '03410244', '03410341', '03410342', '03410351', '03410354', '03410361', '03410362', '03410371', '03410373', 
'03410374', '03410411', '03410412', '03410413', '03410414', '052A0251', '052A0252', '052A0253', '06230211', '06230212', '06230213', '06230241', '06230242', '06230243', '06230251', '06230254', 
'06380073', '06380074', '06380092', '06380093', '06380103', '06380104', '06420071', '06420072', '06420073', '06420074', '06420083', '06420084', '06420091', '06420092', '06420171', '06420172', 
'06420181', '06420184', '06420242', '06420243', '06420244', '06570303', '06570304', '06570321', '06570322', '06570323', '13690461', '13690462', '1EP1', '1EP2', '1EP3', '1EP4', 
'2EP1', '2EP2', '2EP3', '2EP4') then 0
	else 3
end;



--------------------------------------------------------------OBTRUCCIONES----------------------------------------------------------------------------
-- Vamos a hacer la evaluación de las obstrucciones del piso --
select * from levantamientos.levantamientos_revisado lr;

alter table levantamientos.levantamientos_revisado add column "OBSTRUCCIONES" int;

update levantamientos.levantamientos_revisado set "OBSTRUCCIONES" = case
	when cant_obs_fisicas ilike 'Ninguno' then 3
	when cant_obs_fisicas ilike '1' then 2
	when cant_obs_fisicas ilike '2' then 1
	when cant_obs_fisicas ilike '3 o más' then 0
end;

alter table operaciones add column "OBSTRUCCIONES" int;

update operaciones
set "OBSTRUCCIONES" = b."OBSTRUCCIONES"
from levantamientos.levantamientos_revisado b
where operaciones.cve_unica = b.clave;




--------------------------------------------------------------CONDICIONES CALLE-----------------------------------------------------------------
-- Vamos a hacer la evaluación  las condiciones de la calle --
/* La evaluación se hace por tramo de banqueta para después sacar el promedio
	Los puntos se otorgan de la siguiente manera:
	Material de banqueta:
		Ambas = 2 puntos
		Material de buena material = 1 punto
		Material estable, antiderrapante, etc = 1 punto
		Ninguno o no hay banqueta = 0 puntos
	Pendiente transversal
		Plana = 1 punto
		Inclinada = 0.5 puntos
		Muy inclinada o no hay banqueta 0
*/
-- Hagamos la evaluación para el inicio de banqueta
alter table levantamientos.levantamientos_revisado add column inicio_condiciones float;

select clave, inicio_material, inicio_transversal, inicio_condiciones
from levantamientos.levantamientos_revisado lr;

update levantamientos.levantamientos_revisado
set inicio_condiciones =
	case inicio_material
		when 'Ambos' then 2
		when 'Material de buena calidad' then 1
		when 'Regular, estable y antiderrapante' then 1
		when 'Ninguno' then 0.5
		when 'No hay banqueta' then 0
	end +
	case inicio_transversal
		when 'Plana' then 1
		when 'Inclinada' then 0.5
		when 'Muy inclinada' then 0
		when 'No hay banqueta' then 0
	end;

select distinct inicio_transversal 
from levantamientos.levantamientos_revisado lr;
-- Hagamos la evaluación para la mitad de banqueta
alter table levantamientos.levantamientos_revisado add column medio_condiciones float;

select clave, medio_material , medio_transversal , medio_condiciones
from levantamientos.levantamientos_revisado lr;

update levantamientos.levantamientos_revisado
set medio_condiciones =
	case medio_material
		when 'Ambos' then 2
		when 'Material de buena calidad' then 1
		when 'Regular, estable y antiderrapante' then 1
		when 'Ninguno' then 0.5
		when 'No hay banqueta' then 0
	end +
	case medio_transversal
		when 'Plana' then 1
		when 'Inclinada' then 0.5
		when 'Muy inclinada' then 0
		when 'No hay banqueta' then 0
	end;
-- Hagamos la evaluación para el final de banqueta
alter table levantamientos.levantamientos_revisado add column fin_condiciones float;

select clave, fin_material , fin_transversal, fin_condiciones
from levantamientos.levantamientos_revisado lr;

update levantamientos.levantamientos_revisado
set fin_condiciones =
	case fin_material
		when 'Ambos' then 2
		when 'Material de buena calidad' then 1
		when 'Regular, estable y antiderrapante' then 1
		when 'Ninguno' then 0.5
		when 'No hay banqueta' then 0
	end +
	case fin_transversal
		when 'Plana' then 1
		when 'Inclinada' then 0.5
		when 'Muy inclinada' then 0
		when 'No hay banqueta' then 0
	end;
-- Hagamos la evaluación de todo el frente, la cual consiste en el promedio de los 3 tramos
alter table levantamientos.levantamientos_revisado add column "CONDICIONES" float;

update levantamientos.levantamientos_revisado a
set "CONDICIONES" = b.promedio_evaluacion
from (
	SELECT *,
	  (
	    COALESCE(inicio_condiciones, 0) +
	    COALESCE(medio_condiciones, 0) +
	    COALESCE(fin_condiciones, 0)
	  ) /
	  (
	    (CASE WHEN inicio_condiciones IS NOT NULL THEN 1 ELSE 0 END) +
	    (CASE WHEN medio_condiciones IS NOT NULL THEN 1 ELSE 0 END) +
	    (CASE WHEN fin_condiciones IS NOT NULL THEN 1 ELSE 0 END)
	  )::float AS promedio_evaluacion
	FROM levantamientos.levantamientos_revisado) b
where a.clave = b.clave;

select clave, inicio_condiciones, medio_condiciones, fin_condiciones, "CONDICIONES"
from levantamientos.levantamientos_revisado lr;

alter table operaciones add column "CONDICIONES" int;

update operaciones a
set "CONDICIONES" = round(b."CONDICIONES")
from levantamientos.levantamientos_revisado b
where a.cve_unica = b.clave;



-------------------------------------------------------------------------------------------------------------------------------------------------






