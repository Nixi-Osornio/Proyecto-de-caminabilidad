document.addEventListener("DOMContentLoaded", function () {
    var map = L.map('mapa', {
        maxBounds: [
            [19.26558, -99.24282],
            [19.30940, -99.17741]
        ],
        maxBoundsViscosity: 1.0
    }).setView([19.29400, -99.22114], 16);

    var OpenStreetMap_Mapnik = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(map);

    var OpenTopoMap = L.tileLayer('https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', {
        maxZoom: 17,
        attribution: 'Map data: &copy; OpenStreetMap contributors, SRTM | Map style: &copy; OpenTopoMap'
    });

    var capasBase = {
        "Calles Mapnik": OpenStreetMap_Mapnik,
        "Topo Map": OpenTopoMap
    };

    var overlayMaps = {};

    let capaCaminabilidad; // variable global para la capa
    let featureSeleccionada = null; // para la feature seleccionada

    fetch('php/colabora.php')
        .then(response => response.json())
        .then(data => {
            capaCaminabilidad = L.geoJSON(data, {
                style: function(feature) {
                    return {
                        color: '#3388ff',
                        weight: 2,
                        fillOpacity: 0.3
                    };
                },
                onEachFeature: (feature, layer) => {
                    const props = feature.properties;

                    layer.on('click', function () {
                        // Deseleccionar anterior
                        if (featureSeleccionada) {
                            capaCaminabilidad.resetStyle(featureSeleccionada);
                        }

                        // Seleccionar actual (pintar amarillo)
                        layer.setStyle({
                            color: 'red',
                            weight: 3,
                            fillOpacity: 0.7
                        });

                        featureSeleccionada = layer;

                        // Mostrar popup
                        layer.bindPopup(`
                            <strong>${props.nomvial}</strong><br>
                            Clave: ${props.cve_unica}
                        `).openPopup();

                        // Llenar campos ocultos
                        document.getElementById('nomvial').value = props.nomvial;
                        document.getElementById('cve_unica').value = props.cve_unica;
                    });
                }
            }).addTo(map);

            overlayMaps["Índice de Caminabilidad"] = capaCaminabilidad;
            L.control.layers(capasBase, overlayMaps).addTo(map);
        })
        .catch(error => {
            console.error("Error cargando GeoJSON:", error);
        });

    L.control.layers(capasBase, overlayMaps).addTo(map);
});

$(document).ready(function() {
  $('#formulario-consulta').on('submit', function(e) {
    e.preventDefault();

    let nombre = $('#nombre').val().trim();
    let correo = $('#email').val().trim();
    let mensaje = $('#mensaje').val().trim();
    let edad = $('#edad').val().trim();
    let genero = $('#genero').val().trim();
    let cve_unica = $('#cve_unica').val().trim();

    // Validaciones
    if (nombre === "" || correo === "" || mensaje === "" || edad === "" || genero === "") {
      alert("Por favor, completa todos los campos.");
      return false;
    }
    if (cve_unica === "") {
      alert("Por favor, selecciona un frente de manzana.");
      return false;
    }
    if (!/^\d+$/.test(edad) || edad <= 0 || edad > 200) {
      alert("Por favor, escribe una edad válida (número entero entre 1 y 200).");
      return false;
    }

    function mostrarMensaje(texto, tipo = 'exito') {
    const mensajeDiv = $('#mensaje-general');
    mensajeDiv
        .removeClass('exito error')
        .addClass(tipo)
        .text(texto)
        .fadeIn();

    // Ocultar después de 4 segundos
    setTimeout(() => {
        mensajeDiv.fadeOut();
    }, 4000);
    }
    // Si pasa validaciones, envía vía Ajax
    $.ajax({
        type: 'POST',
        url: 'php/guardar_colabora.php',
        data: $('#formulario-consulta').serialize(),
        dataType: 'json',  // <--- Esto ayuda a que jQuery trate la respuesta como JSON automáticamente
        success: function(data) {
            if (data.success) {
                mostrarMensaje(`¡Gracias! Datos enviados correctamente. Número de registro: ${data.id}`, 'exito');
                $('#formulario-consulta')[0].reset();
            } else {
                mostrarMensaje(`Error: ${data.error || "Error desconocido"}`, 'error');
            }
        },
        error: function() {
            mostrarMensaje("Error al enviar los datos.", 'error');
        }
    });
  });
});