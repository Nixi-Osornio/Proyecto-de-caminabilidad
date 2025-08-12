
document.addEventListener("DOMContentLoaded", function () {
    // Inicializar el mapa en el div con id="mapa"
    var map = L.map('mapa', {
        maxBounds: [
            [19.26558, -99.24282], // esquina suroeste
            [19.30940, -99.17741]  // esquina noreste
        ],
        maxBoundsViscosity: 1.0
    }).setView([19.29400, -99.22114], 16);

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

    // Capas WMS desde GeoServer (a personalizar)
    var url = 'http://192.168.1.98/geoserver/wms';
    var wmsLayer = L.tileLayer.wms(url, {
         layers: 'caminabilidad:lomas_padierna',
         format: 'image/png',
         transparent: true,
         opacity: 0.7
     }).addTo(map);

     
    var overlayMaps = {
         "Límite de la colonia": wmsLayer,      
     };

    // Cargar GeoJSON desde PHP
    fetch('php/colabora.php')
        .then(response => response.json())
        .then(data => {
            // Crear capa GeoJSON con estilo
            var capaCaminabilidad = L.geoJSON(data, {
            
                onEachFeature: (feature, layer) => {
                    const props = feature.properties;
                    layer.bindPopup(`
                        <strong>${props.nomvial}</strong><br>
                        Clave: ${props.cve_unica}
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

    

    // Control de capas
    L.control.layers(capasBase, overlayMaps).addTo(map);
});



