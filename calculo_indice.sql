-------------------------------------------------------------------------------------------------------------------------------------------
--CORRECIONES
update operaciones o set "ANCHO" = 0 where o."ANCHO" is null;
----------------------------------------------------------------CALCULO DEL ÍNDICE-------------------------------------------------------------
alter table operaciones add column indice float;

select * from operaciones o;

alter table "FM_Captura" add column "INDICE" float;

update operaciones set indice = 
	"OBSTRUCCIONES" * 0.1225 +
	"PENDIENTE" * 0.105 +
	"ANCHO" * 0.07 +
	"CONDICIONES" * 0.0525 +
	"TRANSPORTE" * 0.12 +
	"USO MIXTO" * 0.09 +
	"USO PUBLICO" * 0.09 +
	"ROBO" * 0.06 +
	"ATROPELLAMIENTO" * 0.06 +
	"CRUCE" * 0.04 +
	"ILUMINACION" * 0.04 +
	"DISTANCIA" * 0.10 +	
	"SOMBRA" * 0.05 ;

select cve_unica, indice from operaciones order by indice asc;

select * from "FM_Captura";
-----------------------------------------------------------PRUEBA CON VARIABLES NORMALIZADAS----------------------------------------------
--drop table datos.operaciones_norm;

create table datos.operaciones_norm as 
	select cve_unica, geom, "CONDICIONES","OBSTRUCCIONES", "ANCHO" as "ANCHURA", "PENDIENTE", "DISTANCIA" as "DIMENSION", "TRANSPORTE", 
	"USO MIXTO" as "USOS_MIXTOS", "USO PUBLICO" as "USO_PUBLICO", "ILUMINACION", "ROBO" as "CRIMENES", 
	"CRUCE" as "CRUCES", "ATROPELLAMIENTO" as "ATROPELLAMIENTOS"
	from operaciones;

alter table datos.operaciones_norm add column "SOMBRA" FLOAT;
update datos.operaciones_norm a set "SOMBRA"=b."SOMBRA" from datos."Sombra_Cali" b where a.cve_unica =b.cve_unica;

select * from datos.operaciones_norm;

alter table datos.operaciones_norm alter column "CONDICIONES" set data type float;

update datos.operaciones_norm a
set "CONDICIONES" = b."CONDICIONES"
from levantamientos.levantamientos_revisado b
where a.cve_unica = b.clave;

update datos.operaciones_norm a
set "CRUCES" = b.prom_cruce
from levantamientos.levantamientos_revisado b
where a.cve_unica = b.clave;

--NORMALIZACIÓN DE VARIABLES--
/* Como la escala original va de 0 a 3, quiere decir que la puntuación máxima es de 3, al normalizar las variables se desea cambiar a 
 * una escala más compresinble (en este caso será de 0 a 1) por lo que solo debemos dividir todo entre 3, pues así el valor más alto
 * será de 1. Para esto necesitamos que las variables que fueron redondeadas regresen a su valor real pues así será más confiable el 
 * resultado*/
select * from datos.operaciones_norm;

update datos.operaciones_norm on2 set "CONDICIONES" = "CONDICIONES"/3;

update datos.operaciones_norm on2 set "OBSTRUCCIONES" = "OBSTRUCCIONES"/3;

update datos.operaciones_norm on2 set "ANCHURA" = "ANCHURA"/3;

update datos.operaciones_norm on2 set "PENDIENTE" = "PENDIENTE"/3;

update datos.operaciones_norm on2 set "DIMENSION" = "DIMENSION"/3;

update datos.operaciones_norm on2 set "TRANSPORTE" = "TRANSPORTE"/3;

update datos.operaciones_norm on2 set "USOS_MIXTOS" = "USOS_MIXTOS"/3;

update datos.operaciones_norm on2 set "USO_PUBLICO" = "USO_PUBLICO"/3;

update datos.operaciones_norm on2 set "ILUMINACION" = "ILUMINACION"/3;

update datos.operaciones_norm on2 set "CRIMENES" = "CRIMENES"/3;

update datos.operaciones_norm on2 set "CRUCES" = "CRUCES"/3;

update datos.operaciones_norm on2 set "ATROPELLAMIENTOS" = "ATROPELLAMIENTOS"/3;

update datos.operaciones_norm on2 set "SOMBRA" = "SOMBRA"/3;

---CACULO DEL ÍNDICE CON VALORES NORMALIZADOS

--SUB-ÍNDICES
--TRANSITABLE: Obstrucciones + Pendiente + Anchura + Condiciones
alter table datos.operaciones_norm add column "INDICE_TRANSITABLE" numeric;
update datos.operaciones_norm set "INDICE_TRANSITABLE" = 
	"OBSTRUCCIONES" * 0.35 +
	"PENDIENTE" * 0.30 +
	"ANCHURA" * 0.20 +
	"CONDICIONES" * 0.15 ;

update datos.operaciones_norm on2 set "INDICE_TRANSITABLE" = ROUND("INDICE_TRANSITABLE", 2);

--Accesible: Transporte + Usos mixtos + Uso público 
alter table datos.operaciones_norm add column "INDICE_ACCESIBLE" numeric;
update datos.operaciones_norm set "INDICE_ACCESIBLE" = 
	"TRANSPORTE" * 0.40 +
	"USOS_MIXTOS" * 0.30 +
	"USO_PUBLICO" * 0.30 ;

update datos.operaciones_norm on2 set "INDICE_ACCESIBLE" = ROUND("INDICE_ACCESIBLE", 2);

--Seguro: Crimenes + Atropellamientos + Cruces + Iluminación
alter table datos.operaciones_norm add column "INDICE_SEGURO" numeric;
update datos.operaciones_norm set "INDICE_SEGURO" = 
	"CRIMENES" * 0.30 +
	"ATROPELLAMIENTOS" * 0.30 +
	"CRUCES" * 0.20 +
	"ILUMINACION" * 0.20;

update datos.operaciones_norm on2 set "INDICE_SEGURO" = ROUND("INDICE_SEGURO", 2);

--Practi-Cómodo: Dimensión manzanas + Sombra
alter table datos.operaciones_norm add column "INDICE_PRACTICOM" numeric;
update datos.operaciones_norm set "INDICE_PRACTICOM" = 
	"DIMENSION" * 0.60 +	
	"SOMBRA" * 0.40 ;

update datos.operaciones_norm on2 set "INDICE_PRACTICOM" = ROUND("INDICE_PRACTICOM", 2);


-----CÁCULO DEL ÍNDICE GENERAL
alter table datos.operaciones_norm add column "INDICE" float;

select * from datos.operaciones_norm;

update datos.operaciones_norm set "INDICE" = 
	"INDICE_TRANSITABLE" * 0.35 + 
	"INDICE_ACCESIBLE" * 0.30 +
	"INDICE_SEGURO" * 0.20 + 
	"INDICE_PRACTICOM" * 0.15;

update datos.operaciones_norm on2 set "INDICE" = ROUND("INDICE", 2);

alter table datos.operaciones_norm alter column "INDICE" set data type NUMERIC;

-------
select * from "FM_Captura";

alter table "FM_Captura" alter column "SOMBRA" set data type numeric;
update "FM_Captura" a set "INDICE_PRACTICOM" = b."INDICE_PRACTICOM" from datos.operaciones_norm b where a.cve_unica = b.cve_unica;

alter table "FM_Captura" add column "INDICE_TRANSITABLE" numeric;
alter table "FM_Captura" add column "INDICE_ACCESIBLE" numeric;
alter table "FM_Captura" add column "INDICE_SEGURO" numeric;
alter table "FM_Captura" add column "INDICE_PRACTICOM" numeric;




select count(*) from "FM_Captura" fc;

select * from datos.operaciones_norm on2 where cve_unica = '03410284';

















