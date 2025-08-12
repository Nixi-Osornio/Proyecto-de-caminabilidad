document.addEventListener("DOMContentLoaded", function () {
    var map = L.map('mapa', {
        maxBounds: [
            [19.26558, -99.24282],
            [19.30940, -99.17741]
        ],
        maxBoundsViscosity: 1.0
    }).setView([19.29400, -99.22114], 16);

    // Leyenda
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

    // Capas base
    var OpenStreetMap_Mapnik = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(map);

    var OpenTopoMap = L.tileLayer('https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', {
        maxZoom: 17,
        attribution: 'Map data: &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, <a href="http://viewfinderpanoramas.org">SRTM</a> | Map style: &copy; <a href="https://opentopomap.org">OpenTopoMap</a>'
    });

    var capasBase = {
        "Calles Mapnik": OpenStreetMap_Mapnik,
        "Topo Map": OpenTopoMap
    };
    var overlayMaps = {};

    // Función de colores
    function estiloCaminabilidad(feature) {
        const valor = parseFloat(feature.properties.indice_general);
        return {
            color: valor >= 0.8 ? '#4a8931' :
                valor >= 0.6 ? '#94d2bd' :
                valor >= 0.4 ? '#e8c87b' :
                valor >= 0.2 ? '#f4a261' :
                                '#e35e3d',
            weight: 2.5
        };
    }

    // Función para actualizar tarjetas y rankings
    function actualizarUI(features) {
    let categorias = {
        optimo: [],
        suficiente: [],
        aceptable: [],
        insuficiente: [],
        muy_insuficiente: []
    };

    features.forEach(f => {
        const nombre = f.properties.nomvial;
        const indice = parseFloat(f.properties.indice_general);
        const clave = f.properties.cve_unica;

        if (indice >= 0.8) categorias.optimo.push({ nombre, indice, clave });
        else if (indice >= 0.6) categorias.suficiente.push({ nombre, indice, clave });
        else if (indice >= 0.4) categorias.aceptable.push({ nombre, indice, clave });
        else if (indice >= 0.2) categorias.insuficiente.push({ nombre, indice, clave });
        else categorias.muy_insuficiente.push({ nombre, indice, clave });
    });

    let total = features.length || 1; // evitar división por cero

    document.getElementById("cardOptimo").textContent = `Óptimo: ${(categorias.optimo.length / total * 100).toFixed(1)}%`;
    document.getElementById("cardSuficiente").textContent = `Suficiente: ${(categorias.suficiente.length / total * 100).toFixed(1)}%`;
    document.getElementById("cardAceptable").textContent = `Aceptable: ${(categorias.aceptable.length / total * 100).toFixed(1)}%`;
    document.getElementById("cardInsuficiente").textContent = `Insuficiente: ${(categorias.insuficiente.length / total * 100).toFixed(1)}%`;
    document.getElementById("cardMuy_Insuficiente").textContent = `Muy Insuficiente: ${(categorias.muy_insuficiente.length / total * 100).toFixed(1)}%`;

    let todasCalles = features.map(f => ({
        nombre: f.properties.nomvial,
        indice: parseFloat(f.properties.indice_general),
        clave: f.properties.cve_unica
    }));

    let mejores = [...todasCalles].sort((a, b) => b.indice - a.indice).slice(0, 5);
    let peores = [...todasCalles].sort((a, b) => a.indice - b.indice).slice(0, 5);

    let listaMejores = document.getElementById("listaMejores");
    let listaPeores = document.getElementById("listaPeores");

    listaMejores.innerHTML = "";
    mejores.forEach(c => {
        let li = document.createElement("li");
        li.textContent = `${c.nombre} (Clave: ${c.clave}, Índice: ${c.indice.toFixed(2)})`;
        listaMejores.appendChild(li);
    });

    listaPeores.innerHTML = "";
    peores.forEach(c => {
        let li = document.createElement("li");
        li.textContent = `${c.nombre} (Clave: ${c.clave}, Índice: ${c.indice.toFixed(2)})`;
        listaPeores.appendChild(li);
    });
}


    // Cargar datos
    let geojsonData = null;
    let capaCaminabilidad = null;

    fetch('php/indice_caminabilidad.php')
        .then(response => response.json())
        .then(data => {
            geojsonData = data;

            capaCaminabilidad = L.geoJSON(data, {
                style: estiloCaminabilidad,
                onEachFeature: (feature, layer) => {
                    const props = feature.properties;
                    layer.bindPopup(`
                        <strong>${props.nomvial}</strong><br>
                        Clave: ${props.cve_unica}<br>
                        Índice General: ${props.indice_general}<br>
                        Transitable: ${props.indice_transitable}<br>
                        Accesible: ${props.indice_accesible}<br>
                        Seguro: ${props.indice_seguro}<br>
                        Práctico: ${props.indice_practicom}
                    `);
                }
            }).addTo(map);

            overlayMaps["Índice de Caminabilidad"] = capaCaminabilidad;
            L.control.layers(capasBase, overlayMaps).addTo(map);

            // Inicializar tarjetas y ranking con todos los datos
            actualizarUI(geojsonData.features);
        })
        .catch(error => console.error("Error cargando GeoJSON:", error));

    // Evento del formulario para filtrar
    document.getElementById("form2").addEventListener("submit", function (e) {
        e.preventDefault();
        const calle = document.getElementById("calle").value;
        const clasificacion = document.getElementById("clasificacion_calle").value;

        if (!geojsonData) return;

        let filtradas = geojsonData.features.filter(f => {
            const indice = parseFloat(f.properties.indice_general);
            let pasaCalle = !calle || f.properties.nomvial.toLowerCase().includes(calle.toLowerCase());
            let pasaClasif = true;

            if (clasificacion) {
                if (clasificacion === "optimo") pasaClasif = indice >= 0.8;
                else if (clasificacion === "suficiente") pasaClasif = indice >= 0.6 && indice < 0.8;
                else if (clasificacion === "aceptable") pasaClasif = indice >= 0.4 && indice < 0.6;
                else if (clasificacion === "insuficiente") pasaClasif = indice >= 0.2 && indice < 0.4;
                else if (clasificacion === "muy_insuficiente") pasaClasif = indice < 0.2;
            }

            return pasaCalle && pasaClasif;
        });

        // Actualizar mapa con filtradas
        if (capaCaminabilidad) {
            capaCaminabilidad.clearLayers();
            capaCaminabilidad.addData(filtradas);
        }

        // Actualizar tarjetas y ranking
        actualizarUI(filtradas);
    });
});
