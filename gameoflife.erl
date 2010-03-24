-module(gameoflife).
-author("Mustafa Paksoy").
-export([start/1, start/3]).

% Runs a game of life simulation by starting up a cell to process each node.

start(Generations) ->
    start(Generations, 3, [alive_, alive_, alive_, alive_, alive_, alive_, alive_, alive_, alive_]).

start(Generations, Width, States) ->
    io:fwrite("Start state~n"),
    printMatrix(Width, States),

    io:fwrite("Initializing processes~n"),
    Cells = spawnCells(States),
    CellArray = array:from_list(Cells),
    StateArr = array:from_list(States),

    io:fwrite("Starting processes~n"),
    startAll(Width, Generations, CellArray, StateArr),

    io:fwrite("Reading final state~n"),
    Result = recvAll(Cells),
    printMatrix(Width, Result),
    Result.

spawnCells([]) ->
    [];
spawnCells([_S | States]) ->
    [spawn(fun cell/0) |
     spawnCells(States)].

% Receive final status from all processes
recvAll([]) ->
    [];
recvAll([P | Procs]) ->
    [receive
        {result, P, R} -> R
    end | recvAll(Procs)].

startAll(Width, Generations, ProcArray, StateArr) ->
    startAll(Width, Generations, ProcArray, StateArr, array:size(ProcArray) - 1).

startAll(_Width, _Generations, _ProcArray, _StateArr, -1) ->
    ok;

startAll(Width, Generations, ProcArray, StateArr, I) ->
    debug("Sending start signal to proces ~p~n", [I]),
    P = array:get(I, ProcArray),
    P ! {start, self(), Generations, array:get(I, StateArr), getNeighbors(Width, ProcArray, I)},
    startAll(Width, Generations, ProcArray, StateArr, I - 1).

getNeighbors(Width, ProcArray, I) ->
    getNeighbor(Width, ProcArray, I, north).

getNeighbor(Width, ProcArray, I, north) ->
    J = I - Width,
    if
        J >= 0 ->
            debug("process ~p has north neighbor~n", [I]),
            [array:get(J, ProcArray) |
             getNeighbor(Width, ProcArray, I, south)];
        true ->
             getNeighbor(Width, ProcArray, I, south)
    end;

getNeighbor(Width, ProcArray, I, south) ->
    J = I + Width,
    Len = array:size(ProcArray),
    if
        (J < Len) ->
            debug("process ~p has south neighbor~n", [I]),
            [array:get(J, ProcArray) |
             getNeighbor(Width, ProcArray, I, east)];
        true ->
             getNeighbor(Width, ProcArray, I, east)
    end;

getNeighbor(Width, ProcArray, I, east) ->
    J = I + 1,
    IRow = I div Width,
    JRow = J div Width,
    if
        (IRow == JRow) ->
            debug("process ~p has east neighbor~n", [I]),
            [array:get(J, ProcArray) |
             getNeighbor(Width, ProcArray, I, west)];
        true ->
             getNeighbor(Width, ProcArray, I, west)
    end;

getNeighbor(Width, ProcArray, I, west) ->
    J = I - 1,
    IRow = I div Width,
    JRow = J div Width,
    if
        (J >= 0) and (IRow == JRow) ->
            debug("process ~p has west neighbor~n", [I]),
            [array:get(J, ProcArray)];
        true ->
             []
    end.

% Start and wait till we get the go signal
cell() ->
    receive
        {start, From, Generations, StartState, Neighbors} ->
            debug("starting process: ~p start state: ~p neighbors: ~p~n",
                [self(), StartState, Neighbors]),
            cell(StartState, From, Generations, Neighbors)
    end.

% When done running send final state to parent
cell(State, Parent, 0, _Neighbors) ->
    Parent ! {result, self(), State};
cell(State, Parent, GenerationsLeft, Neighbors) ->
    sendState(State, Neighbors),
    cell(receiveState(State, Neighbors), Parent,
         GenerationsLeft - 1, Neighbors).

receiveState(State, Neighbors) ->
    receiveState(State, 0, Neighbors).

% Cell with too few (less than 2) too many (more than 3) is always dead
receiveState(_State, Alives, []) when (Alives < 2) or (Alives > 3) ->
    dead;
% If cell is alive, it lives on. Or if it has 3 neighbors it comes alive.
receiveState(State, Alives, []) when (State == alive_) or (Alives == 3) ->
    alive_;
% Otherwise it stays dead
receiveState(_State, _Alives, []) ->
    dead;
receiveState(State, Alives, [N | Neighbors]) ->
    receive
        {state, N, alive_} ->
            receiveState(State, Alives + 1, Neighbors);
        {state, N, dead} ->
            receiveState(State, Alives, Neighbors)
    end.

sendState(_State, []) ->
    [];
sendState(State, [N | Neighbors]) ->
    N ! {state, self(), State},
    sendState(State, Neighbors).

printMatrix(Width, Matrix) ->
    printMatrix(Width, Matrix, 0).

printMatrix(_Width, [], _X) ->
    io:fwrite("~n");
% Last item in row print
printMatrix(Width, [alive_ | Matrix], X) ->
    io:fwrite("o"),
    if
        (((X + 1) rem Width) == 0) ->
            io:fwrite("~n");
        true -> ok
    end,
    printMatrix(Width, Matrix, X + 1);
printMatrix(Width, [dead | Matrix], X) ->
    io:fwrite(" "),
    if
        (((X + 1) rem Width) == 0) ->
            io:fwrite("~n");
        true -> ok
    end,
    printMatrix(Width, Matrix, X + 1).

debug(Formatstr, Args) ->
    %io:fwrite(Formatstr, Args),
    ok.
