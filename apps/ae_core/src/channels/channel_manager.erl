
-module(channel_manager).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2, dump/0,
	 keys/0,read/1,delete/1,write/2]).
-define(LOC, constants:channel_manager()).
init(ok) -> 
    process_flag(trap_exit, true),
    X = db:read(?LOC),
    Ka = if
	     X == "" -> dict:new();
	     true -> X
	 end,
    %process_flag(trap_exit, true),
    {ok, Ka}.
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, K) -> 
    db:save(?LOC, K),
    io:format("died!"), ok.
handle_info(_, X) -> {noreply, X}.
handle_cast({dump}, _) ->
    {noreply, dict:new()};
handle_cast({write, CID, Data}, X) -> 
    NewX = dict:store(CID, Data, X),
    db:save(?LOC, NewX),
    %this db:save is only for power failures. Without it, you could lose channel data on power failure. This line can be removed to make the node update channels faster.
    {noreply, NewX};
handle_cast({delete, CID}, X) -> 
    NewX = dict:erase(CID, X),
    db:save(?LOC, NewX),
    %this db:save is only for power failures. Without it, you could lose channel data on power failure. This line can be removed to make the node update channels faster.
    {noreply, NewX};
handle_cast(_, X) -> {noreply, X}.
handle_call(keys, _From, X) ->
    {reply, dict:fetch_keys(X), X};
handle_call({read, CID}, _From, X) -> 
    {reply, dict:find(CID, X), X};
handle_call(_, _From, X) -> {reply, X, X}.
dump() ->
    gen_server:cast(?MODULE, {dump}).
read(CID) -> 
    gen_server:call(?MODULE, {read, CID}).
keys() -> gen_server:call(?MODULE, keys).
delete(CID) -> gen_server:cast(?MODULE, {delete, CID}).
write(CID, Data) -> 
    %io:fwrite("writing channel "),
    %io:fwrite(packer:pack({ch, CID})),
    A = is_list(channel_feeder:script_sig_them(Data)),
    B = is_list(channel_feeder:script_sig_me(Data)),
    C = length(channel_feeder:script_sig_me(Data)) == 
        length(spk:bets(channel_feeder:me(Data))),
    D = length(channel_feeder:script_sig_them(Data)) == 
        length(spk:bets(testnet_sign:data(channel_feeder:them(Data)))),
    if
        A and B and C and D ->
            gen_server:cast(?MODULE, {write, CID, Data});
        true -> ok
    end.

