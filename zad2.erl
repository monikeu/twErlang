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

prod(N, State, Waiting, Resources, Left, Buff) ->
  case State of
    start ->
      Buff ! {self(), N, producer},
      prod(N, await, 0, [], Left, Buff);
    await ->
      receive
        {List, message} ->
          io:format("Producer: Received N elems from Buffer~n"),
          prod(N, produce, Waiting, List, N, Buff);
        _ ->
          prod(N, await, Waiting + 1, [], 0, Buff)
      end;
    produce ->
      case Left of
        0 ->
          Buff ! {N, Resources, full, flag},
          io:format("Producer: Produced N elems, sending to buffer~n"),
          prod(N, start, 0, [], 0, Buff);
        _ ->
          io:format("Producer: dooopaaa~n"),
          prod(N, produce, Waiting, Resources, Left - 1, Buff)
      end
  end.

cons(N, State, Waiting, Resources, Left, Buff, Help) ->
  case State of
    start ->
      Buff ! {consumer,  N, self()},
      cons(N, await, 0, [], 0, Buff);
    await ->
      receive
        {elemsforProducer, List} ->
          io:format("Consumer: Received N elems from Buffer ~n"),
          cons(N, consume, Waiting, List, N, Buff);
        _ ->
          cons(N, await, Waiting + 1, [], 0, Buff)
      end;
    consume ->
      case Left of
        0 ->
          Buff ! {N, Resources, free, flag},
          io:format("Consumer: consumed N elems, sending to buffer~n"),
          cons(N, start, 0, [], 0, Buff);
        _ ->
          cons(N, consume, Waiting, Resources, Left - 1, Buff)
      end
  end.


freeQ(Free, FreeCount) ->

  receive
    {buff, free, BuffElPid} ->
      freeQ(Free ++ [BuffElPid], FreeCount + 1);

    {producent, N, ProdPid} when N =< FreeCount ->
      ToSend = getAmountElems(N, Free, []),
      ProdPid ! {elemsforProducer, ToSend},
      freeQ(Free -- ToSend, FreeCount-N)
  end.

fullQ(Full, FullCount) ->
  receive
    {buff, full, BuffElPid} ->
      fullQ(Full ++ [BuffElPid], FullCount + 1);
    {consument, N, ConsPid} when N =< FullCount ->
      ToSend =  getAmountElems(N, Full, []),
      ConsPid ! {elemsForConsumer, ToSend},
      fullQ(Full -- ToSend, FullCount - N)
  end.

buffEl(FullQ, FreeQ, State) ->
  receive
    {bufferElemFull, Pid} ->
      io:format("Buffer: filled by producer ~s ~n", integer_to_list(Pid));
    {bufferElemFree, Pid} ->
      io:format("Buffer: got free by consumer ~s ~n", integer_to_list(Pid))
  end.

getAmountElems(Amount, FullList, Returned) ->
  case Amount of
    0 -> Returned;
    N -> [X | Tail] = FullList,
      A = [X],
      getAmountElems(Amount - 1, Tail, Returned ++ A)
  end.

