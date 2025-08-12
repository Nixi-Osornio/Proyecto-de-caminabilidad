document.getElementById('form1').addEventListener('submit', function (e) {
    e.preventDefault();

    const indicador = document.getElementById('indicador').value;
    const clasificacion = document.getElementById('clasificacion').value;

    const niveles = ['muy_insuficiente', 'insuficiente', 'aceptable', 'suficiente', 'optimo'];
    const colores = ['#e35e3d', '#f4a261', '#e8c87b', '#94d2bd', '#4a8931'];

    fetch(`php/grafica_indicadores.php?indicador=${encodeURIComponent(indicador)}&clasificacion=${encodeURIComponent(clasificacion)}`)
        .then(res => res.json())
        .then(data => {
            const mensajeDiv = document.getElementById('mensaje1');
            const canvas = document.getElementById('grafica1');

            // Verifica si hay datos
            if (!data.values || data.values.length === 0 || data.values.every(v => v === 0)) {
                mensajeDiv.textContent = 'No se encontraron resultados para esa combinación, ingresa otros valores.';
                canvas.style.display = 'none';
                return;
            }

            mensajeDiv.textContent = '';
            canvas.style.display = 'block';

            // Generar colores dinámicamente según los niveles
            const coloresBarras = data.labels.map(label => {
                const index = niveles.indexOf(label);
                return index !== -1 ? colores[index] : '#999999';
            });

            const ctx = canvas.getContext('2d');
            if (window.miGrafica1) window.miGrafica1.destroy();

            window.miGrafica1 = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: data.labels,
                    datasets: [{
                        label: data.label,
                        data: data.values,
                        backgroundColor: coloresBarras,
                        borderColor: coloresBarras,
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        legend: { display: false },
                        tooltip: { enabled: true }
                    },
                    scales: {
                        x: {
                             ticks: { color: 'white' }, // etiquetas del eje X
                         },
                        y: {
                            beginAtZero: true,
                            title: { display: true, text: 'Número de frentes',color: 'white'},
                            ticks: { color: 'white' }
                        }
                    }
                }
            });

            canvas.scrollIntoView({ behavior: 'smooth' });
        })
        .catch(err => {
            console.error('Error al cargar datos de la gráfica:', err);
        });
});





document.getElementById('form2').addEventListener('submit', function (e) {
    e.preventDefault();

    const calle = document.getElementById('calle').value;
    const clasificacion = document.getElementById('clasificacion_calle').value;

    const niveles = ['Muy_insuficiente', 'Insuficiente', 'Aceptable', 'Suficiente', 'optimo'];
    const colores = ['#e35e3d', '#f4a261', '#e8c87b', '#94d2bd', '#4a8931'];

    fetch(`php/grafica_practicom.php?calle=${encodeURIComponent(calle)}&clasificacion=${encodeURIComponent(clasificacion)}`)
        .then(res => res.json())
        .then(data => {
            const mensajeDiv = document.getElementById('mensaje2');
            const canvas = document.getElementById('grafica2');

            if (!data.values || data.values.length === 0 || data.values.every(v => v === 0)) {
                mensajeDiv.textContent = 'No se encontraron resultados para esa combinación, ingresa otros valores.';
                canvas.style.display = 'none';
                return;
            }

            mensajeDiv.textContent = '';
            canvas.style.display = 'block';

            // Mostrar etiquetas recibidas (debug)
            console.log('Etiquetas recibidas (grafica2):', data.labels);

            // Asignar colores según niveles
            const coloresBarras = data.labels.map(label => {
                const normalizado = label.trim().toLowerCase();
                const index = niveles.findIndex(n => n.toLowerCase() === normalizado);
                return index !== -1 ? colores[index] : '#999999';
            });

            // Opcional: advertencias si no hay coincidencias
            data.labels.forEach(label => {
                const normalizado = label.trim().toLowerCase();
                const match = niveles.find(n => n.toLowerCase() === normalizado);
                if (!match) {
                    console.warn(`Etiqueta sin color definido en grafica2: "${label}"`);
                }
            });

            const ctx = canvas.getContext('2d');
            if (window.miGrafica2) window.miGrafica2.destroy();

            window.miGrafica2 = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: data.labels,
                    datasets: [{
                        label: data.label,
                        data: data.values,
                        backgroundColor: coloresBarras,
                        borderColor: coloresBarras,
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        legend: { display: false },
                        tooltip: { enabled: true }
                    },
                    scales: {
                         x: {
                             ticks: { color: 'white' }, // etiquetas del eje X
                         },
                        y: {
                            beginAtZero: true,
                            title: { display: true, text: 'Número de frentes',color: 'white'},
                            ticks: { color: 'white' }
                        }
                    }
                }
            });

            canvas.scrollIntoView({ behavior: 'smooth' });
        })
        .catch(err => {
            console.error('Error al cargar datos de la gráfica:', err);
        });
});
