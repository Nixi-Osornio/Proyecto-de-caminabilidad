document.getElementById('form1').addEventListener('submit', function (e) {
    e.preventDefault();

    const indicador = document.getElementById('indicador').value;
    const clasificacion = document.getElementById('clasificacion').value;

fetch(`php/grafica_indicadores.php?indicador=${indicador}&clasificacion=${clasificacion}`)
    .then(res => res.json())
    .then(data => {
        const mensajeDiv = document.getElementById('mensaje');
        const graficaDiv = document.getElementById('grafica1');

        // Verifica si no hay datos
        if (!data.values || data.values.length === 0 || data.values.every(v => v === 0)) {
            mensajeDiv.textContent = 'No se encontraron resultados para esa combinación, ingresa otros valores.';
            graficaDiv.style.display = 'none'; // Oculta la gráfica
            return;
        }

        mensajeDiv.textContent = ''; // Limpia mensaje
        graficaDiv.style.display = 'block'; // Muestra gráfica si estaba oculta

        const ctx = document.getElementById('grafica1').getContext('2d');
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
                    y: {
                        beginAtZero: true,
                        title: { display: true, text: 'Número de frentes' }
                    }
                }
            }
        });

        // Scroll a la gráfica
        document.getElementById("grafica1").scrollIntoView({ behavior: 'smooth' });
    });


});
