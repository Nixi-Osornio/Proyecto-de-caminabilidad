<?php
$conexion = pg_connect("host=localhost dbname=caminabilidad port=5432 user=postgres password=ubuntu");

if (!$conexion) {
  die("No se ha podido establecer conexion con la bd.");
}

?>