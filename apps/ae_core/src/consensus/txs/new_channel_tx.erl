-module(new_channel_tx).
-export([go/3, make/9, good/1, spk/2, cid/1,
	 entropy/1, acc1/1, acc2/1, id/1]).
-record(nc, {acc1 = 0, acc2 = 0, fee = 0, nonce = 0, 
	     bal1 = 0, bal2 = 0, entropy = 0, 
	     delay = 10, id = -1}).

acc1(X) -> X#nc.acc1.
acc2(X) -> X#nc.acc2.
id(X) -> X#nc.id.
good(Tx) ->
    %make sure that the money is a fair balance of ours and theirs.
    Delay = Tx#nc.delay,
    io:fwrite("new channel "),
    io:fwrite(packer:pack(Tx)),
    io:fwrite("\n"),
    {ok, MinChannelDelay} = application:get_env(ae_core, min_channel_delay),
    {ok, MaxChannelDelay} = application:get_env(ae_core, max_channel_delay),
    true = Delay > MinChannelDelay,
    true = Delay < MaxChannelDelay,
    K = keys:pubkey(),
    Acc1 = Tx#nc.acc1,
    Acc2 = Tx#nc.acc2,
    Bal1 = Tx#nc.bal1,
    Bal2 = Tx#nc.bal2,
    Top = case K of
	Acc1 -> 
	    Bal1;
	Acc2 -> 
	    Bal2;
	X -> X = Acc1
    end,
    Frac = Top / (Bal1 + Bal2),
    {ok, MCR} = application:get_env(ae_core, min_channel_ratio),
    io:fwrite(float_to_list(Frac)),
    io:fwrite(" "),
    io:fwrite(float_to_list(MCR)),
    io:fwrite("\n"),
    true = Frac < MCR,
    true.
cid(Tx) -> Tx#nc.id.
entropy(Tx) -> Tx#nc.entropy.
spk(Tx, Delay) -> spk:new(Tx#nc.acc1, Tx#nc.acc2, Tx#nc.id,
			  [], 0,0, 0, Delay, 
			  Tx#nc.entropy).
make(ID,Trees,Acc1,Acc2,Inc1,Inc2,Entropy,Delay, Fee) ->
    true = is_integer(Entropy),
    Accounts = trees:accounts(Trees),
    {_, A, Proof} = accounts:get(Acc1, Accounts),
    Nonce = accounts:nonce(A),
    {_, _, Proof2} = accounts:get(Acc2, Accounts),
    %Entropy = channel_feeder:entropy(ID, [Acc1, Acc2])+1,
    %true = (Rent == 0) or (Rent == 1),
    Tx = #nc{id = ID, acc1 = Acc1, acc2 = Acc2, 
	     fee = Fee, nonce = Nonce+1, bal1 = Inc1,
	     bal2 = Inc2, entropy = Entropy, 
	     delay = Delay
	     },
    {Tx, [Proof, Proof2]}.
				 
go(Tx, Dict, NewHeight) ->
    ID = Tx#nc.id,
    OldChannel = channels:dict_get(ID, Dict),
    true = case OldChannel of
	       empty -> true;
	       _ ->
                   CCT = governance:dict_get_value(channel_closed_time, Dict),
		   channels:closed(OldChannel)
		       and ((NewHeight - channels:last_modified(OldChannel)) > CCT)
	   end,
    Aid1 = Tx#nc.acc1,
    Aid2 = Tx#nc.acc2,
    false = Aid1 == Aid2,
    Bal1 = Tx#nc.bal1,
    true = Bal1 >= 0,
    Bal2 = Tx#nc.bal2,
    true = Bal2 >= 0,
    Entropy = Tx#nc.entropy,
    Delay = Tx#nc.delay,
    NewChannel = channels:new(ID, Aid1, Aid2, Bal1, Bal2, NewHeight, Entropy, Delay),
    Dict2 = channels:dict_write(NewChannel, Dict),
    CCFee = governance:dict_get_value(create_channel_fee, Dict) div 2,
    Acc1 = accounts:dict_update(Aid1, Dict, -Bal1-CCFee, Tx#nc.nonce, NewHeight),
    Acc2 = accounts:dict_update(Aid2, Dict, -Bal2-CCFee, none, NewHeight),
    Dict3 = accounts:dict_write(Acc1, Dict2),
    accounts:dict_write(Acc2, Dict3).
