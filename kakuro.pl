:- use_module(graficos).

:- pce_image_directory('./').

% ======================================================
% juegos predefinidos
% ======================================================

juego(1,[
[n,c(9),c(34),c(4),n],
[f(9),_,_,_,n],
[f(13),_,_,_,n],
[f(13),_,_,c(11),c(3)],
[n,f(7),_,_,_],
[n,f(19),_,_,_]
]).

juego(2,[
[n,n,n,c(7),c(16)],
[n,n,p(13,6),_,_],
[n,p(11,4),_,_,_],
[f(6),_,_,_,n],
[f(3),_,_,n,n]
]).

juego(3,[
[n,c(9),c(24),n,c(13),c(14),n,n],
[f(4),_,_,f(14),_,_,n,n],
[f(14),_,_,p(5,11),_,_,c(31),n],
[n,p(15,9),_,_,p(11,7),_,_,c(6)],
[f(22),_,_,_,_,p(13,13),_,_],
[f(3),_,_,p(15,15),_,_,_,_],
[n,f(3),_,_,p(11,11),_,_,c(15)],
[n,n,f(8),_,_,f(8),_,_],
[n,n,f(16),_,_,f(16),_,_]
]).

% ======================================================
% lógica principal de juego
% ======================================================

% kalog(+Tablero) <- despliega un Tablero y permite que el usuario humano lo complete.
kalog(Tablero) :-
    tam_tablero(Tablero,F,C),
    gr_crear_tablero(F, C, [boton('Reiniciar',reiniciar),boton('Resolver',resolver), boton('Salir',salir)], Visual),
    loop(Visual,Tablero,e(none,none)),
    !,
    gr_destruir(Visual).

% kalog(+Tablero,+Tecnica) <- resuelve el kakuro definido en Tablero con la técnica Tecnica.
% Tecnica puede tener los valores std o clpfd.
kalog(_,_).

% kalog(+Filas,+Columnas,-Tablero) <- genera un kakuro de tamaño (Filas, Columnas).
kalog(_,_,_).

% loop principal del juego, el estado guarda información sobre lo que el usuario está haciendo,
% en principio el estado es e(CasilleroSeleccionado,NumeroSeleccionado)
% CasilleroSeleccionado puede ser none o un par (Fila,Columna) que indica la posición en el tablero
% NumeroSeleccionado puede ser none o una tupla (Fila,Columna,Num) que indica la posición y el valor en la lista de números
loop(Visual,Tablero,Estado) :-
    gr_evento(Visual,E),
    procesar_evento(E,Visual,Tablero,Estado,NuevoEstado),
    !,
    loop(Visual,Tablero,NuevoEstado).
loop(_,_,_).

% botón salir
procesar_evento(salir,Visual,_,Estado,Estado) :-
 !, gr_opciones(Visual, 'Seguro?', ['Si', 'No'], 'No').

% botón reiniciar
procesar_evento(reiniciar, Visual, Tablero, _ , e(none,none)) :-
 !,
 tam_tablero(Tablero,F,C),
 gr_inicializar_tablero(Visual,F,C).

% boton resolver
procesar_evento(resolver, _, _, Estado, Estado).

% el evento es un click -> actualizo mensaje y proceso.
procesar_evento(click(Fila,Columna),Visual,T,Estado,NuevoEstado) :-
    sformat(Msg, 'Click en (~w, ~w)', [Fila,Columna]),
    gr_estado(Visual,Msg),
    procesar_click(Fila,Columna,Visual,T,Estado,NuevoEstado).


% click en una casilla, sin número seleccionado
procesar_click(FilaC,ColC,Visual,Tablero,e(CasViejo,none),e((FilaC, ColC),none)):-
    casillero_valido(FilaC, ColC, Tablero),
    !,
    desmarcar(Visual, CasViejo),
    gr_marcar_seleccion(Visual, FilaC, ColC).

% click en una casilla, con número seleccionado
procesar_click(FilaC, ColC, Visual,Tablero,e(none,(FNum,CNum,N)),e(none,none)):-
    casillero_valido(FilaC, ColC, Tablero),
    !,
    desmarcar(Visual, (FNum, CNum)),
    procesar_asignar_numero(Visual,FilaC, ColC, N).

% click en número sin casilla seleccionada.
procesar_click(FilaN,ColN,Visual,Tablero,e(none,NumOld),e(none,(FilaN,ColN,N))):-
    numero_valido(FilaN, ColN, Tablero, N),
    !,
    desmarcar(Visual, NumOld),
    gr_marcar_seleccion(Visual, FilaN, ColN).

% click en número con casilla seleccionada.
procesar_click(FilaN, ColN, Visual, Tablero, e((FilaC,ColC),none),e(none,none)):-
    numero_valido(FilaN, ColN, Tablero, N),
    !,
    desmarcar(Visual, (FilaC, ColC)),
    procesar_asignar_numero(Visual, FilaC, ColC, N).

% click en cualquier otro lado -> ignorar.
procesar_click(_,_,_,_,Estado,Estado).

procesar_asignar_numero(Visual, FilaC, ColC, x):-
    !,
    gr_eliminar_numero(Visual, FilaC, ColC).
procesar_asignar_numero(Visual, FilaC, ColC, N):-
    between(1,9,N),
    gr_dibujar_numero(Visual, FilaC, ColC, N).

%quita la marca de seleccionado de casillas y números.
desmarcar(Visual, (Fila,Columna,_)):-
    !,
    gr_desmarcar_seleccion(Visual, Fila, Columna).
desmarcar(Visual, (Fila,Columna)):-
    !,
    gr_desmarcar_seleccion(Visual, Fila, Columna).
desmarcar(_,_).

% ======================================================
% predicados auxiliares
% ======================================================

%determina si (Fila,Columna) corresponde a un casillero para llenar.
casillero_valido(Fila,Columna,Tablero):-
    tam_tablero(Tablero,MaxF,MaxC),
    between(1,MaxF,Fila),
    between(1,MaxC,Columna).

%determina si (Fila,Columna) corresponde a un número.
numero_valido(Fila, Columna, Tablero, N):-
    tam_tablero(Tablero, MaxF, _),
    Fila is MaxF+2,
    between(1,10,Columna),
    valor_columna(Columna,N).

%devuelve el valor de la columna, o x para eliminar un valor.
valor_columna(N,N):-
    N =< 9.
valor_columna(10,x).

% obtiene el tamaño de un tablero representado como lista de listas
tam_tablero([Fila|Filas],F,C):-
    length([Filas|Filas],F),
    length(Fila,C).