<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json; charset=utf-8');

$connection = pg_connect("host=localhost dbname=caminabilidad port=5432 user=postgres password=ubuntu");
if (!$connection) {
    echo json_encode(['success' => false, 'error' => 'No se pudo conectar a la base de datos.']);
    exit;
}

// Obtener datos
$nombre = $_POST['nombre'];
$edad = $_POST['edad'];
$correo = $_POST['email'];
$mensaje = $_POST['mensaje'];
$genero = $_POST['genero'];
$nomvial = $_POST['nomvial'];
$cve_unica = $_POST['cve_unica'];

pg_query($connection, "BEGIN");

$sql = "INSERT INTO colabora.colabora (nombre, edad, correo, comentario, genero, nomvial, cve_unica)
        VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id";

$result = pg_query_params($connection, $sql, array(
  $nombre, $edad, $correo, $mensaje, $genero, $nomvial, $cve_unica
));

if ($result) {
    $row = pg_fetch_assoc($result);
    $id = $row['id'];
    pg_query($connection, "COMMIT");
    echo json_encode(['success' => true, 'id' => $id]);
} else {
    pg_query($connection, "ROLLBACK");
    $error = pg_last_error($connection);
    echo json_encode(['success' => false, 'error' => $error]);
}

pg_close($connection);
?>
