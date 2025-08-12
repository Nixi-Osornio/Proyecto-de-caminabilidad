document.addEventListener("DOMContentLoaded", function () {
    // Inicializar el mapa en el div con id="mapa"
    var map = L.map('mapa', {
        maxBounds: [
            [19.26558, -99.24282], // esquina suroeste
            [19.30940, -99.17741]  // esquina noreste
        ],
        maxBoundsViscosity: 1.0
    }).setView([19.29400, -99.22114], 16);

    //LEYENDA
    var leyenda = L.control({ position: 'bottomright' });

    leyenda.onAdd = function (map) {
        var div = L.DomUtil.create('div', 'info legend');
        var niveles = ['Muy insuficiente', 'Insuficiente', 'Aceptable', 'Suficiente', 'Óptimo'];
        var colores = ['#e35e3d', '#f4a261', '#e8c87b', '#94d2bd', '#4a8931'];

        for (var i = 0; i < niveles.length; i++) {
            div.innerHTML +=
                `<i style="background:${colores[i]}; width: 18px; height: 18px; float: left; margin-right: 8px; opacity: 1;"></i> ${niveles[i]}<br>`;
        }

        return div;
    };

    leyenda.addTo(map);



    // Capa base: OpenStreetMap
    var OpenStreetMap_Mapnik = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(map);

    // Capa alternativa: OpenTopoMap
    var OpenTopoMap = L.tileLayer('https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', {
        maxZoom: 17,
        attribution: 'Map data: &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, <a href="http://viewfinderpanoramas.org">SRTM</a> | Map style: &copy; <a href="https://opentopomap.org">OpenTopoMap</a>'
    });

    // Capas base
    var capasBase = {
        "Calles Mapnik": OpenStreetMap_Mapnik,
        "Topo Map": OpenTopoMap
    };

    // Inicializa overlayMaps vacío
    var overlayMaps = {};

    //FUNCIÓN PARA COLORES DEL MAPA
    function estiloCaminabilidad(feature) {
        const valor = parseFloat(feature.properties.indice_seguro);

        return {
            color: valor >= 0.8 ? '#4a8931' :      // verde fuerte
                valor >= 0.6 ? '#94d2bd' :      // verde limón
                valor >= 0.4 ? '#e8c87b' :      // naranja
                valor >= 0.2 ? '#f4a261' :      // rojo fuerte
                                '#e35e3d',       // rojo oscuro
            weight: 2.5
        };
    }


    // Cargar GeoJSON desde PHP
    fetch('php/seguro.php')
        .then(response => response.json())
        .then(data => {
            // Crear capa GeoJSON con estilo
            var capaCaminabilidad = L.geoJSON(data, {
                style: estiloCaminabilidad,
                onEachFeature: (feature, layer) => {
                    const props = feature.properties;
                    layer.bindPopup(`
                        <strong>${props.nomvial}</strong><br>
                        Clave: ${props.cve_unica}<br>
                        Índice Seguro: ${props.indice_seguro}<br>
                        Crímenes: ${props.crimenes}<br>
                        Atropellamientos: ${props.atropellamientos}<br>
                        Cruces: ${props.cruces}<br>
                        Iluminación: ${props.iluminacion}
                    `);
                }
            }).addTo(map);


            // Agregar capa al overlay y actualizar control de capas
            overlayMaps["Índice de Caminabilidad"] = capaCaminabilidad;
            L.control.layers(capasBase, overlayMaps).addTo(map);
            
        })
        .catch(error => {
            console.error("Error cargando GeoJSON:", error);
        });
});

