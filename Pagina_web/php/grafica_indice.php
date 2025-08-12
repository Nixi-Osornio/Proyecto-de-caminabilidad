<?php
header('Content-Type: application/json');
include("conexion.php");

$calle = $_GET['calle'] ?? '';
$clasificacion = $_GET['clasificacion'] ?? '';

if ($calle !== '' && $clasificacion !== '') {
    // Escenario 1: Calle y clasificación específicas
    $query = "SELECT COUNT(*) AS total
              FROM fm_captura
              WHERE nomvial = $1 AND indice_clas = $2";
    $result = pg_query_params($conexion, $query, [$calle, $clasificacion]);
    $row = pg_fetch_assoc($result);

    echo json_encode([
        'label' => "Frentes en $calle con clasificación $clasificacion",
        'labels' => [$clasificacion],
        'values' => [(int)$row['total']],
        'clasificaciones' => [$clasificacion]
    ]);
    exit;

} elseif ($calle !== '') {
    // Escenario 2: Solo calle → ver clasificación de todos los frentes en esa calle
    $query = "SELECT indice_clas, COUNT(*) AS total
              FROM fm_captura
              WHERE nomvial = $1
              GROUP BY indice_clas
              ORDER BY indice_clas";
    $result = pg_query_params($conexion, $query, [$calle]);

    $labels = [];
    $values = [];
    while ($row = pg_fetch_assoc($result)) {
        $labels[] = $row['indice_clas'];
        $values[] = (int)$row['total'];
    }

    echo json_encode([
        'label' => "Clasificaciones en $calle",
        'labels' => $labels,
        'values' => $values,
        'clasificaciones' => $labels
    ]);
    exit;

} elseif ($clasificacion !== '') {
    // Escenario 3: Solo clasificación → ver cuántos frentes hay por calle
    $query = "SELECT nomvial, COUNT(*) AS total
              FROM fm_captura
              WHERE indice_clas = $1
              GROUP BY nomvial
              ORDER BY total DESC
              LIMIT 10";
    $result = pg_query_params($conexion, $query, [$clasificacion]);

    $labels = [];
    $values = [];
    while ($row = pg_fetch_assoc($result)) {
        $labels[] = $row['nomvial'];
        $values[] = (int)$row['total'];
    }

    echo json_encode([
        'label' => "Calles con clasificación $clasificacion",
        'labels' => $labels,
        'values' => $values,
        'clasificaciones' => array_fill(0, count($labels), $clasificacion)
    ]);
    exit;

} else {
    // Escenario 4: sin calle ni clasificación → clasificaciones totales
    $query = "SELECT indice_clas, COUNT(*) AS total
              FROM fm_captura
              GROUP BY indice_clas
              ORDER BY indice_clas";
    $result = pg_query($conexion, $query);

    $labels = [];
    $values = [];
    while ($row = pg_fetch_assoc($result)) {
        $labels[] = $row['indice_clas'];
        $values[] = (int)$row['total'];
    }

    echo json_encode([
        'label' => "Total por clasificación",
        'labels' => $labels,
        'values' => $values,
        'clasificaciones' => $labels
    ]);
    exit;
}

?>
