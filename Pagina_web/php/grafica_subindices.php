<?php
header('Content-Type: application/json');
include("conexion.php");

$subindice = $_GET['subindice'] ?? '';
$clasificacion = $_GET['clasificacion'] ?? '';

// Lista blanca de subindices válidos
$subindices_validos = ['indice', 'transitable', 'accesible', 'seguro', 'practicom']; 
if (!in_array($subindice, $subindices_validos)) {
    echo json_encode(['error' => 'Subindice no válido']);
    exit;
}

$columna = $subindice . '_clas';

if ($clasificacion !== '') {
    // Total de frentes que cumplen con esa clasificación en el subindice
    $query = "SELECT COUNT(*) AS total
              FROM fm_captura
              WHERE $columna = $1";
    $result = pg_query_params($conexion, $query, [$clasificacion]);
    $row = pg_fetch_assoc($result);

    echo json_encode([
        'label' => "Frentes con '$clasificacion' en $subindice",
        'labels' => [$clasificacion],
        'values' => [(int)$row['total']],
        'clasificaciones' => [$clasificacion]
    ]);
    exit;
} else {
    // Todas las clasificaciones (como antes)
    $query = "SELECT $columna AS clas, COUNT(*) AS total
              FROM fm_captura
              GROUP BY clas
              ORDER BY clas";
    $result = pg_query($conexion, $query);

    $labels = [];
    $values = [];
    while ($row = pg_fetch_assoc($result)) {
        $labels[] = $row['clas'];
        $values[] = (int)$row['total'];
    }

    echo json_encode([
        'label' => "Total por clasificación en $subindice",
        'labels' => $labels,
        'values' => $values,
        'clasificaciones' => $labels
    ]);
    exit;
}
?>
