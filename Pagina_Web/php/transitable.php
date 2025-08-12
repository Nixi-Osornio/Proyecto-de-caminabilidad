<?php
include("conexion.php");

// Consulta para exportar los datos como GeoJSON
$query = "
SELECT jsonb_build_object(
    'type', 'FeatureCollection',
    'features', jsonb_agg(
        jsonb_build_object(
            'type', 'Feature',
            'geometry', ST_AsGeoJSON(ST_Transform(geom, 4326))::jsonb,
            'properties', to_jsonb(row) - 'geom'
        )
    )
) AS geojson
FROM (
    SELECT 
        cve_unica,
        nomvial,
        indice_transitable,
        obstrucciones,
        pendiente,
        anchura,
        condiciones,
        geom
    FROM fm_captura
) row;
";

$resultado = pg_query($conexion, $query);
$fila = pg_fetch_assoc($resultado);

// Devuelve el GeoJSON
header('Content-Type: application/json');
echo $fila['geojson'];
?>

