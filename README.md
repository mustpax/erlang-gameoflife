# The Skinny
This is a [Game of Life][gol] implementation written in Erlang. Each cell is
handled by a single process and each process talks to nearby cells via message
passing to figure out state. At the end of the simulation the cells send their
final state back to the root node i.e. the process that spawned them. I tried
to stick with Erlang conventions for recursion and whatnot, but there are some
rough edges, aesthetically speaking around the array handling. Still it works,
as far as I can tell, hope it helps.

[gol]: <http://en.wikipedia.org/wiki/Conway's_Game_of_Life> "Conways Game of Life"

