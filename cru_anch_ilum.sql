---------------------------------------------- VÍAS PRIMARIAS, SECUNDARIAS Y TERCIARIAS --------------------------------------------------------
select distinct "name", highway from planet_osm_line pol where highway in ('secondary', 'tertiary') order by highway asc;
-- VIAS PRIMARIAS Y SECUNDARIAS: Boulevard Picacho Ajusco, Avenida Unión, Calle Popolna, Calle Seyé, Calle Tizimín, Calle Yucalpetén
--Calles que si se encuentran en los frentes de manzana --
select distinct "NOMVIAL" from "FM_Captura" fc order by "NOMVIAL" asc;
-- Boulevard Picacho Ajusco, Unión, Popolna, Seye, Tizimín, Yucalpeten

alter table operaciones add column nom_vial varchar;
update operaciones o 
set nom_vial = fc."NOMVIAL"
from "FM_Captura" fc 
where o.cve_unica = fc.cve_unica;



-------------------------------------------------------------CRUCES------------------------------------------------------------------------------
alter table levantamientos.levantamientos_revisado add column nom_vial varchar;

update levantamientos.levantamientos_revisado a 
set nom_vial = b.nom_vial
from operaciones b 
where a.clave=b.cve_unica;

-- Se tienen dos evaluaciones por cada frente (inicio y fin), por lo que saca la evaluación de cada extremo y después se promedia

--											 		Hagamos la evaluación del inicio															--
select clave, inicio_cruce_peatonal, inicio_cruce_rampa, inicio_cruce_obs_visual,  inicio_cruce_sema_peatonal,
		inicio_cruce_bolardo, inicio_cruce_otro, inicio_cruce_calif, nom_vial
from levantamientos.levantamientos_revisado;

--Primero las calles terciarias, no se toman en cuenta bolardos ni semáforos peatonales
update levantamientos.levantamientos_revisado
set inicio_cruce_calif =
	case inicio_cruce_peatonal
		when 'true' then 1
		when 'false' then 0
	end +
	case inicio_cruce_rampa
		when 'true' then 1
		when 'false' then 0
	end +
	case inicio_cruce_obs_visual
		when 'true' then 1
		when 'false' then 0
	end +
	case inicio_cruce_otro
		when '' then 0
		when 'n' then 0
		when 'c' then 0
		when 'noaplica' then 0
	end
where nom_vial not in ('Boulevard Picacho Ajusco', 'Unión', 'Popolna', 'Seye', 'Tizimín', 'Yucalpeten');

--Ahora calles primarias y secundarias, aquí si toma en cuenta bolardos y semáforos peatonales
update levantamientos.levantamientos_revisado
set inicio_cruce_calif =
	case inicio_cruce_peatonal
		when 'true' then 0.6
		when 'false' then 0
		else 0
	end +
	case inicio_cruce_rampa
		when 'true' then 0.6
		when 'false' then 0
		else 0
	end +
	case inicio_cruce_obs_visual
		when 'true' then 0.6
		when 'false' then 0
		else 0
	end +
	case inicio_cruce_sema_peatonal 
		when 'true' then 0.6
		when 'false' then 0
		else 0
	end +
	case inicio_cruce_bolardo
		when 'true' then 0.6
		when 'false' then 0
		else 0
	end +
	case inicio_cruce_otro
		when '' then 0
		when 'n' then 0
		when 'c' then 0
		when 'noaplica' then 0
		else 0
	end
where nom_vial in ('Boulevard Picacho Ajusco', 'Unión', 'Popolna', 'Seye', 'Tizimín', 'Yucalpeten');


-- 												Ahora hagamos la evaluación del fin de banqueta 												--
select clave, fin_cruce_peatonal, fin_cruce_rampa, fin_cruce_obs_visual, fin_cruce_sema_peatonal, 
		fin_cruce_bolardos, fin_cruce_otro, fin_cruce_Calif, nom_vial
from levantamientos.levantamientos_revisado;

--Primero las calles terciarias, no se toman en cuenta bolardos ni semáforos peatonales
update levantamientos.levantamientos_revisado
set fin_cruce_calif =
	case fin_cruce_peatonal
		when 'true' then 1
		when 'false' then 0
	end +
	case fin_cruce_rampa
		when 'true' then 1
		when 'false' then 0
	end +
	case fin_cruce_obs_visual
		when 'true' then 1
		when 'false' then 0
	end +
	case fin_cruce_otro
		when '' then 0
		when 'n' then 0
		when 'c' then 0
		when 'noaplica' then 0
	end
where nom_vial not in ('Boulevard Picacho Ajusco', 'Unión', 'Popolna', 'Seye', 'Tizimín', 'Yucalpeten');

--Ahora calles primarias y secundarias, aquí si toma en cuenta bolardos y semáforos peatonales
update levantamientos.levantamientos_revisado
set fin_cruce_calif =
	case fin_cruce_peatonal
		when 'true' then 0.6
		when 'false' then 0
		else 0
	end +
	case fin_cruce_rampa
		when 'true' then 0.6
		when 'false' then 0
		else 0
	end +
	case fin_cruce_obs_visual
		when 'true' then 0.6
		when 'false' then 0
		else 0
	end +
	case fin_cruce_sema_peatonal 
		when 'true' then 0.6
		when 'false' then 0
		else 0
	end +
	case fin_cruce_otro
		when 'true' then 0.6
		when 'false' then 0
		else 0
	end +
	case fin_cruce_otro
		when '' then 0
		when 'n' then 0
		when 'c' then 0
		when 'noaplica' then 0
		else 0
	end
where nom_vial in ('Boulevard Picacho Ajusco', 'Unión', 'Popolna', 'Seye', 'Tizimín', 'Yucalpeten');





-- 										Finalmente la evaluación de todo el frente es el promedio del inicio y fin 								--
alter table levantamientos.levantamientos_revisado add column prom_cruce float;

update levantamientos.levantamientos_revisado set prom_cruce = (inicio_cruce_calif + fin_cruce_calif)/2.0;

select clave, inicio_cruce_Calif, fin_cruce_calif, prom_cruce from levantamientos.levantamientos_revisado lr;

update operaciones a
set "CRUCE" = round(b.prom_cruce)
from levantamientos.levantamientos_revisado b
where a.cve_unica = b.clave;

select cve_unica, "CRUCE" from operaciones o;


--------------------------------------------------------------ANCHO BANQUETA -------------------------------------------------------------------
alter table levantamientos.levantamientos_revisado add column prom_franja float;

select clave, inicio_franja_circula, medio_franja_circula, fin_franja_circula, prom_franja from levantamientos.levantamientos_revisado lr;

update levantamientos.levantamientos_revisado set inicio_franja_circula = null where inicio_franja_circula = 'n';
update levantamientos.levantamientos_revisado set inicio_franja_circula = null where inicio_franja_circula = '';
update levantamientos.levantamientos_revisado set medio_franja_circula = null where medio_franja_circula = 'n';
update levantamientos.levantamientos_revisado set medio_franja_circula = null where medio_franja_circula = '';
update levantamientos.levantamientos_revisado set fin_franja_circula = null where fin_franja_circula = 'n';
update levantamientos.levantamientos_revisado set fin_franja_circula = null where fin_franja_circula = '';
update levantamientos.levantamientos_revisado set fin_franja_circula = null where fin_franja_circula = 'c';


alter table levantamientos.levantamientos_revisado 
alter column inicio_franja_circula type int
using inicio_franja_circula::int;

alter table levantamientos.levantamientos_revisado 
alter column medio_franja_circula type int
using medio_franja_circula::int;

alter table levantamientos.levantamientos_revisado 
alter column fin_franja_circula type int
using fin_franja_circula::int;

update levantamientos.levantamientos_revisado a
set prom_franja = b.promedio_evaluacion
from (
	SELECT *,
	  (
	    COALESCE(inicio_franja_circula, 0) +
	    COALESCE(medio_franja_circula, 0) +
	    COALESCE(fin_franja_circula, 0)
	  )::float /
	  NULLIF(
	    (CASE WHEN inicio_franja_circula IS NOT NULL THEN 1 ELSE 0 END) +
	    (CASE WHEN medio_franja_circula IS NOT NULL THEN 1 ELSE 0 END) +
	    (CASE WHEN fin_franja_circula IS NOT NULL THEN 1 ELSE 0 END),
	    0
	  ) AS promedio_evaluacion
	FROM levantamientos.levantamientos_revisado) b
where a.clave = b.clave;

alter table operaciones add column "ANCHO" int;
alter table operaciones add column prom_franja float;
update operaciones o set prom_franja = b.prom_franja from levantamientos.levantamientos_revisado b where o.cve_unica = b.clave;

UPDATE operaciones o
SET "ANCHO" = 
  CASE
    WHEN prom_franja >= 180.00 THEN 3
    WHEN prom_franja < 180.00 AND prom_franja >= 120.00 THEN 2
    WHEN prom_franja < 120.00 AND prom_franja >= 60.00 THEN 1
    WHEN prom_franja < 60.00 THEN 0
  END
WHERE nom_vial NOT IN (
  'Boulevard Picacho Ajusco', 'Unión', 'Popolna', 'Seye', 'Tizimín', 'Yucalpeten');

UPDATE operaciones o
SET "ANCHO" = 
  CASE
    WHEN prom_franja >= 275.00 THEN 3
    WHEN prom_franja < 275.00 AND prom_franja >= 180.00 THEN 2
    WHEN prom_franja < 180 AND prom_franja >= 120.00 THEN 1
    WHEN prom_franja < 120.00 THEN 0
  END
WHERE nom_vial IN (
  'Boulevard Picacho Ajusco', 'Unión', 'Popolna', 'Seye', 'Tizimín', 'Yucalpeten');


select cve_unica, nom_vial, prom_franja, "ANCHO" from operaciones o;

select clave, inicio_franja_circula, medio_franja_circula,fin_franja_circula, prom_franja from levantamientos.levantamientos_revisado lr ;


-------------------------------------------------------------------ILUMINACIÓN-----------------------------------------------------------
--Creamos una tabla que se exportará para llenarse en excel
alter table datos.inegi add column cve_unica varchar;

UPDATE datos.inegi SET cve_unica = CONCAT("CVE_AGEB", "CVE_MZA", "CVEFT");

select cve_unica,"ALUMPUB", "ALUMPUB_D"  from datos.inegi i;

alter table operaciones add column alum_inegi varchar;

select distinct nom_vial from operaciones o ;

update operaciones o set alum_inegi = i."ALUMPUB_D"
from datos.inegi i
where o.cve_unica = i.cve_unica;

create table levantamientos.levantamiento_noct as
select cve_unica, alum_inegi, nom_vial, geom from operaciones o;

--Una vez que se tiene la información de cada frente como Iluminado u Oscuro se hace la evaluación, se sube de nuevo la tabla y se hace la evaluación
select * from levantamientos.nocturno n;

alter table levantamientos.nocturno add column "ILUMINACION" INT;

update levantamientos.nocturno set alum_inegi = null where alum_inegi = '';

update levantamientos.nocturno set "ILUMINACION" = case
	when alum_inegi = 'Dispone' and levantamiento = 'Iluminado' then 3
	when alum_inegi = 'No dispone' and levantamiento = 'Iluminado' then 2
	when alum_inegi = 'Dispone' and levantamiento = 'Oscuro' then 1
	when alum_inegi = 'No dispone' and levantamiento = 'Oscuro' then 0
	when alum_inegi is null and levantamiento = 'Iluminado' then 3
	when alum_inegi is null and levantamiento = 'Oscuro' then 0
end;

alter table operaciones add column "ILUMINACION" int;
update operaciones a set "ILUMINACION" = b."ILUMINACION" from levantamientos.nocturno b where a.cve_unica = b.cve_unica;
update "FM_Captura" a set "ILUMINACION" = b."ILUMINACION" from levantamientos.nocturno b where a.cve_unica = b.cve_unica;

-----------------------------------------------------REGISTROS DE LA AMPLIACIÓN-----------------------------------------------------------------
delete from operaciones where cve_unica in ('20660361','206603610','206603611','206603612', '20660362', '20660363', '20660364', '20660365',
'20660366', '20660367', '20660368', '20660369', '20660371', '20660372', '20660373', '20660374', '20660401', '20660402', '20660403', '20660404',
'20660405', '20660406', '20660411', '20660412', '20660413', '20660414', '20660421', '20660422', '20660423', '20660424', '20660431', '20660432',
'20660433', '20660434', '20660441', '20660442', '20660443', '20660444', '20660451', '20660452', '20660453', '20660454');

delete from "FM_Captura" where cve_unica in ('20660361','206603610','206603611','206603612', '20660362', '20660363', '20660364', '20660365',
'20660366', '20660367', '20660368', '20660369', '20660371', '20660372', '20660373', '20660374', '20660401', '20660402', '20660403', '20660404',
'20660405', '20660406', '20660411', '20660412', '20660413', '20660414', '20660421', '20660422', '20660423', '20660424', '20660431', '20660432',
'20660433', '20660434', '20660441', '20660442', '20660443', '20660444', '20660451', '20660452', '20660453', '20660454');

-----------------------------------------------------REGISTROS DE LA BARDA-----------------------------------------------------------------
delete from operaciones where cve_unica in ('03410091','03410101', '03410112', '03410122', '03410271', '03410281', '03410285', '03410111', '03410121');

delete from "FM_Captura" where cve_unica in ('20660361','206603610','206603611','206603612', '20660362', '20660363', '20660364', '20660365',
'20660366', '20660367', '20660368', '20660369', '20660371', '20660372', '20660373', '20660374', '20660401', '20660402', '20660403', '20660404',
'20660405', '20660406', '20660411', '20660412', '20660413', '20660414', '20660421', '20660422', '20660423', '20660424', '20660431', '20660432',
'20660433', '20660434', '20660441', '20660442', '20660443', '20660444', '20660451', '20660452', '20660453', '20660454');


-----------------------------------------------------------ACTUALIZACIÓN-----------------------------------------------------------------
select * from "FM_Captura";

update "FM_Captura" a set "ATROPELLAMIENTOS" = b."ATROPELLAMIENTO"
from operaciones b
where a.cve_unica = b.cve_unica;

select * from datos."Sombra_Cali" sc;
select * from operaciones o;
alter table operaciones add column "SOMBRA" int;
update operaciones a set "SOMBRA"=b."SOMBRA" from datos."Sombra_Cali" b where a.cve_unica =b.cve_unica;
update "FM_Captura" a set "SOMBRA"=b."SOMBRA" from datos."Sombra_Cali" b where a.cve_unica =b.cve_unica;















