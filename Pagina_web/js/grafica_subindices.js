document.getElementById('form2').addEventListener('submit', function (e) {
    e.preventDefault();

    const subindice = document.getElementById('subindice').value;
    const clasificacion = document.getElementById('clasificacion_indice').value;

fetch(`php/grafica_subindices.php?subindice=${subindice}&clasificacion=${clasificacion}`)
    .then(res => res.json())
    .then(data => {
        const mensajeDiv = document.getElementById('mensaje');
        const graficaDiv = document.getElementById('grafica2');

        // Verifica si no hay datos
        if (!data.values || data.values.length === 0 || data.values.every(v => v === 0)) {
            mensajeDiv.textContent = 'No se encontraron resultados para esa combinación, ingresa otros valores.';
            graficaDiv.style.display = 'none'; // Oculta la gráfica
            return;
        }

        mensajeDiv.textContent = ''; // Limpia mensaje
        graficaDiv.style.display = 'block'; // Muestra gráfica si estaba oculta

        const ctx = document.getElementById('grafica2').getContext('2d');
        if (window.miGrafica) window.miGrafica.destroy();

        window.miGrafica = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: data.labels, // ['Óptimo', etc.]
                datasets: [{
                    label: data.label, // 
                    data: data.values, // 
                    backgroundColor: 'rgba(75, 192, 192, 0.6)',
                    borderColor: 'rgba(75, 192, 192, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { display: true },
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

        // Scroll a la gráfica
        document.getElementById("grafica2").scrollIntoView({ behavior: 'smooth' });
    });


});
