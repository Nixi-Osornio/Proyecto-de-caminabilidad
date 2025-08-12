//Ejecutar función en el evento click
document.getElementById("btn_open").addEventListener("click", open_close_menu);
document.getElementById("indicadores_btn").addEventListener("click", toggle_submenu);

//Declaración de variables
var menu_lateral = document.getElementById("menu_lateral");
var btn_open = document.getElementById("btn_open");
var body = document.getElementById("body");
var submenu = document.querySelector(".submenu");

//Evento para mostrar y ocultar menú
    function open_close_menu(){
        body.classList.toggle("body_move");
        menu_lateral.classList.toggle("menu_lateral_move");

        // Cierra el submenú si está abierto
        if (submenu.classList.contains("open")) {
            submenu.classList.remove("open");
        }
    }

// Función para abrir/cerrar submenú
    function toggle_submenu(e) {
        e.preventDefault();

        // Alternar el menú lateral
        body.classList.toggle("body_move");
        menu_lateral.classList.toggle("menu_lateral_move");

        // Alternar el submenú
        submenu.classList.toggle("open");
}


//Si el ancho de la página es menor a 760px, ocultará el menú al recargar la página

if(window.innerWidth < 760){
   
    body.classList.add("body_move")
    menu_lateral.classList.add("menu_lateral_move");
}

//Haciendo el menú responsive

window.addEventListener("resize", function(){

    if(this.window.innerWidth > 760){

        body.classList.remove("body_move");
        menu_lateral.classList.remove("menu_lateral_move");
    }

    if(this.window.innerWidth < 760){

        body.classList.add("body_move");
        menu_lateral.classList.remove("menu_lateral_move");
    }

});



