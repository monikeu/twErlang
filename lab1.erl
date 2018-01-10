%%%-------------------------------------------------------------------
%%% @author monikeu
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. sty 2018 08:16
%%%-------------------------------------------------------------------
-module(lab1).
-author("monikeu").

%% API
-export([startProg/0, prod/6, cons/6, bufferFun/4, getAmountElems/3]).

%%start() ->
%%%%  C = spawn(?MODULE, procC, []),
%%  C = spawn(?MODULE, procC1(a), []),
%%
%%  register(procCC, C),
%%
%%  spawn(?MODULE, procB, []),
%%  spawn(?MODULE, procA, []).
%%
%%procA() ->
%%  procCC ! aaa,
%%  procA().
%%
%%procB() ->
%%  procCC ! bbb,
%%  procA().
%%
%%procC() ->
%%  receive
%%    aaa ->
%%      io:format("Proc: Received message from A~n"),
%%      procC();
%%    bbb ->
%%      io:format("Proc: Received message from A~n"),
%%      procC()
%%  end.
%%
%%procC1(Value) ->
%%  case Value of
%%    a ->
%%      receive
%%        aaa ->
%%          io:format("Proc: Received message from A~n"),
%%          procC1(b)
%%      end;
%%    b ->
%%      receive
%%        bbb ->
%%          io:format("Proc: Received message from A~n"),
%%          procC1(a)
%%      end
%%  end.

%% zarejestrowac bufor

startProg() ->
  Buff = spawn(fun() -> bufferFun(lists:seq(1, 10), [], 10, 0) end),
%%  register(buffer, Buff),
  spawn(fun() -> cons(2, start, 0, [], 0, Buff) end),
  spawn(fun() -> prod(2, start, 0, [], 0, Buff) end),
  spawn(fun() -> prod(5, start, 0, [], 0, Buff) end),
  spawn(fun() -> cons(5, start, 0, [], 0, Buff) end).

prod(N, State, Waiting, Resources, Left, Buff) ->
  timer:sleep(500),
  case State of
    start ->
      Buff ! {self(), N, producer},
      prod(N, await, 0, [], Left, Buff);
    await ->
      receive
        {List, message} ->
          io:format("Producer: Received ~s elems from Buffer~n", [integer_to_list(N)]),
          prod(N, produce, Waiting, List, N, Buff);
        _ ->
          prod(N, await, Waiting + 1, [], 0, Buff)
      end;
    produce ->
      case Left of
        0 ->
          Buff ! {N, Resources, full, flag},
          io:format("Producer: Produced ~s elems, sending to buffer~n", [integer_to_list(N)]),
          prod(N, start, 0, [], 0, Buff);
        _ ->
          prod(N, produce, Waiting, Resources, Left - 1, Buff)
      end
  end.

cons(N, State, Waiting, Resources, Left, Buff) ->
  timer:sleep(500),
  case State of
    start ->
      Buff ! {self(), N, consumer},
      cons(N, await, 0, [], 0, Buff);
    await ->
      receive
        {List, message} ->
          io:format("Consumer: Received ~s elems from Buffer ~n", [integer_to_list(N)]),
          cons(N, consume, Waiting, List, N, Buff);
        _ ->
          cons(N, await, Waiting + 1, [], 0, Buff)
      end;
    consume ->
      case Left of
        0 ->
          Buff ! {N, Resources, free, flag},
          io:format("Consumer: consumed ~s elems, sending to buffer~n", [integer_to_list(N)]),
          cons(N, start, 0, [], 0, Buff);
        _ ->
          cons(N, consume, Waiting, Resources, Left - 1, Buff)
      end
  end.

bufferFun(FreeList, FullList, Free, Full) ->
  receive
    {Pid, Amount, producer} when Amount =< Free ->
      io:format("Buffer: producer gets elems~n"),
      ToSend = getAmountElems(Amount, FreeList, []),
      Pid ! {ToSend, message},
      bufferFun(FreeList--ToSend, FullList, Free - Amount, Full);

    {Pid, Amount, consumer} when Amount =< Full ->
      io:format("Buffer: consumer gets elems~n"),
      ToSend = getAmountElems(Amount, FullList, []),
      Pid ! {ToSend, message},
      bufferFun(FreeList, FullList--ToSend, Free, Full - Amount);

    {Amount, Resources, free, flag} ->
      io:format("Buffer: got free~n"),
      bufferFun(FreeList ++ Resources, FullList, Free + Amount, Full);

    {Amount, Resources, full, flag} ->
      io:format("Buffer: got full~n"),
      bufferFun(FreeList, FullList ++ Resources, Free, Full + Amount)
  end.



getAmountElems(Amount, FullList, Returned) ->
  case Amount of
    0 -> Returned;
    N -> [X | Tail] = FullList,
      A = [X],
      getAmountElems(Amount - 1, Tail, Returned ++ A)
  end.



