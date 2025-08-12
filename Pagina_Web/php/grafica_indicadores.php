<?php
header('Content-Type: application/json');
include("conexion.php");

$indicador = $_GET['indicador'] ?? '';
$clasificacion = $_GET['clasificacion'] ?? '';

// Lista blanca de indicadores válidos
$indicadores_validos = ['condiciones', 'obstrucciones', 'anchura', 'pendiente', 'dimension', 'transporte', 'usos_mixtos', 'uso_publico', 'iluminacion', 'crimenes', 'cruces', 'atropellamientos', 'sombra']; 
if (!in_array($indicador, $indicadores_validos)) {
    echo json_encode(['error' => 'Indicador no válido']);
    exit;
}

$columna = $indicador . '_clas';

if ($clasificacion !== '') {
    // Total de frentes que cumplen con esa clasificación en el indicador
    $query = "SELECT COUNT(*) AS total
              FROM fm_captura
              WHERE $columna = $1";
    $result = pg_query_params($conexion, $query, [$clasificacion]);
    $row = pg_fetch_assoc($result);

    echo json_encode([
        'label' => "Frentes con '$clasificacion' en $indicador",
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
        'label' => "Total por clasificación en $indicador",
        'labels' => $labels,
        'values' => $values,
        'clasificaciones' => $labels
    ]);
    exit;
}

?>
