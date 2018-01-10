%%%-------------------------------------------------------------------
%%% @author monikeu
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. sty 2018 08:16
%%%-------------------------------------------------------------------
-module(zad2).
-author("monikeu").

%% API
-export([startProg/0, prod/7, cons/7, bufferFun/4, getAmountElems/3, runBufferProceses/2]).

startProg() ->
  BufferPids = runBufferProceses(10, []),
  Buff = spawn(fun() -> bufferFun(BufferPids, [], 10, 0) end),
  spawn(fun() -> cons(2, start, 0, [], 0, Buff,[]) end),
  spawn(fun() -> prod(2, start, 0, [], 0, Buff,[]) end),
  spawn(fun() -> prod(5, start, 0, [], 0, Buff,[]) end),
  spawn(fun() -> cons(5, start, 0, [], 0, Buff,[]) end).


runBufferProceses(N, Processes) ->
  case N of
    0 -> Processes;
    N ->
      Pid = spawn(fun() -> bufferElem(state) end),
      runBufferProceses(N-1, Processes ++ [Pid])
  end.


prod(N, State, Waiting, Resources, Left, Buff, LeftToProduce) ->
  timer:sleep(500),
  case State of
    start ->
      Buff ! {self(), N, producer},
      prod(N, await, 0, [], Left, Buff, []);
    await ->
      receive
        {List, message} ->
          io:format("Producer: Received ~s elems from Buffer~n", [integer_to_list(N)]),
          prod(N, produce, Waiting, List, N, Buff,List);
        _ ->
          prod(N, await, Waiting + 1, [], 0, Buff,[])
      end;
    produce ->
      case Left of
        0 ->
          Buff ! {N, Resources, full, flag},
          io:format("Producer: Produced ~s elems, sending to buffer~n", [integer_to_list(N)]),
          prod(N, start, 0, [], 0, Buff,[]);
        _ ->
          [OnePid | Rest] = LeftToProduce,
          OnePid ! {bufferElemFull, self()},
          prod(N, produce, Waiting, Resources, Left - 1, Buff, Rest)
      end
  end.

cons(N, State, Waiting, Resources, Left, Buff, LeftToConsume) ->
  timer:sleep(500),
  case State of
    start ->
      Buff ! {self(), N, consumer},
      cons(N, await, 0, [], 0, Buff,[]);
    await ->
      receive
        {List, message} ->
          io:format("Consumer: Received ~s elems from Buffer ~n", [integer_to_list(N)]),
          cons(N, consume, Waiting, List, N, Buff,List);
        _ ->
          cons(N, await, Waiting + 1, [], 0, Buff, [])
      end;
    consume ->
      case Left of
        0 ->
          Buff ! {N, Resources, free, flag},
          io:format("Consumer: consumed ~s elems, sending to buffer~n", [integer_to_list(N)]),
          cons(N, start, 0, [], 0, Buff, []);
        _ ->
          [OnePid | Rest] = LeftToConsume,
          OnePid !{bufferElemFree, self()},
          cons(N, consume, Waiting, Resources, Left - 1, Buff, Rest)
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

bufferElem(State) ->
  receive
    {bufferElemFull, Pid} ->
      io:format("Buffer: filled by producer ~p ~n", [Pid]),
      bufferElem(State);
    {bufferElemFree, Pid} ->
      io:format("Buffer: got free by consumer ~p ~n", [Pid]),
      bufferElem(State)
  end.

getAmountElems(Amount, FullList, Returned) ->
  case Amount of
    0 -> Returned;
    N -> [X | Tail] = FullList,
      A = [X],
      getAmountElems(Amount - 1, Tail, Returned ++ A)
  end.



