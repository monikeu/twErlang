%%%-------------------------------------------------------------------
%%% @author monikeu
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. sty 2018 02:26
%%%-------------------------------------------------------------------
-module(zad2).
-author("monikeu").

%% API
-export([]).

prod(N, State, Waiting, Resources, Left,Buff) ->
  case State of
    start ->
      Buff ! {self(), N, producer},
      prod(N, await, 0, [], Left,Buff);
    await ->
      receive
        {List, message} ->
          io:format("Producer: Received N elems from Buffer~n"),
          prod(N, produce, Waiting, List, N,Buff);
        _ ->
          prod(N, await, Waiting + 1, [], 0,Buff)
      end;
    produce ->
      case Left of
        0 ->
          Buff ! {N, Resources, full, flag},
          io:format("Producer: Produced N elems, sending to buffer~n"),
          prod(N, start, 0, [], 0,Buff);
        _ ->
          io:format("Producer: dooopaaa~n"),
          prod(N, produce, Waiting, Resources, Left - 1,Buff)
      end
  end.

cons(N, State, Waiting, Resources, Left,Buff) ->
  case State of
    start ->
      Buff ! {self(), N, consumer},
      cons(N, await, 0, [], 0,Buff);
    await ->
      receive
        {List,message} ->
          io:format("Consumer: Received N elems from Buffer ~n"),
          cons(N, consume, Waiting, List, N,Buff);
        _ ->
          cons(N, await, Waiting + 1, [], 0,Buff)
      end;
    consume ->
      case Left of
        0 ->
          Buff ! {N, Resources, free, flag},
          io:format("Consumer: consumed N elems, sending to buffer~n"),
          cons(N, start, 0, [], 0,Buff);
        _ ->
          cons(N, consume, Waiting, Resources, Left - 1,Buff)
      end
  end.

prodQ(FreeQ) ->
  receive
    {emptyQ, N, ListOfBufferElemsPids} ->
      receive
        {Pid, M} ->
          case N > M of
            true ->
              ToSend = getAmountElems(N, ListOfBufferElemsPids, []),
              Pid ! ToSend,
%%              odsylam nieuzyte
              FreeQ ! {used, ToSend, N-M};

            false ->
              self() ! {Pid, M},
              FreeQ ! {used, []},
              prodQ(FreeQ)
          end
      end;
    _ -> prodQ(FreeQ)
  end,
  prodQ(FreeQ).

consQ(FullQ) ->
  receive
    {fullQ, N, ListOfBufferElemsPids} ->
      receive
        {Pid, M} ->
          case N > M of
            true ->
              ToSend = getAmountElems(N, ListOfBufferElemsPids, []),
              Pid ! ToSend,
%%              odsylam nieuzyte
              FullQ ! {used, ToSend, N-M};

            false ->
              self() ! {Pid, M},
              FullQ ! {used, []},
              consQ(FullQ)
          end
      end;
    _ -> consQ(FullQ)
  end,
  consQ(FullQ).

freeQ(ProdQ, Free, FreeCount) ->

  ProdQ ! {emptyQ ,FreeCount, Free},

  receive
    {buff, free, BuffElPid} ->
      freeQ(ProdQ, Free ++ [BuffElPid], FreeCount +1);
    {notUsed, Used, N} ->
      freeQ(ProdQ, Free -- Used, Free) %%
  end.

fullQ(ConsQ, Full, FullCount) ->

  ConsQ ! {emptyQ ,FullCount, Full},

  receive
    {buff, full, BuffElPid} ->
      fullQ(ConsQ, Full ++ [BuffElPid], FullCount +1);
    {notUsed, Used, N} ->
      fullQ(ConsQ, Full -- Used, Full) %%
  end.

buffEl(FullQ, FreeQ, State)->
  case State of
    free ->
      FreeQ ! {buff, free, self()};
    full ->
      FullQ ! {buff, full, self()}
  end.

getAmountElems(Amount, FullList, Returned) ->
  case Amount of
    0 -> Returned;
    N -> [X | Tail] = FullList,
      A = [X],
      getAmountElems(Amount - 1, Tail, Returned ++ A)
  end.

